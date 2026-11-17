import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------------------------------------------------------------------------
// 正式签名（Google Play 上传用）
//
// android/key.properties 保存密码与密钥路径，已加入 .gitignore，禁止提交。
// 文件格式（由 keytool 生成后手写）：
//   storePassword=***
//   keyPassword=***
//   keyAlias=upload
//   storeFile=upload-keystore.jks   ← 相对 android/app/ 目录
//
// 首次在新机器上构建前，需从安全备份恢复以下两个文件：
//   android/key.properties
//   android/app/upload-keystore.jks
// ---------------------------------------------------------------------------
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}

android {
    namespace = "com.ailexin.HanziRoots"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.ailexin.HanziRoots"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // 缺少 key.properties 时不能让 release 静默使用 debug 签名，
                // 否则打出来的包无法正常上架，也容易在不知情的情况下分发出去。
                logger.warn(
                    "[签名] 未找到 android/key.properties，release 将回退到 debug 签名，仅限本地调试，禁止上传 Google Play。"
                )
                signingConfig = signingConfigs.getByName("debug")
            }
            // 关闭依赖元数据写入，避免 Play 从 AAB 中读取额外依赖信息
            dependenciesInfo {
                includeInApk = false
                includeInBundle = false
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// ---------------------------------------------------------------------------
// APK 产物命名：HanziRoots-v<版本号>.apk
//
// Flutter 构建结束后会把 AGP 产物复制到 build/app/outputs/flutter-apk/ 下，
// 文件名为固定的 app-<mode>.apk。这里在 assemble 任务结束后再复制一份带版本号
// 的副本，方便直接分发；app-<mode>.apk 保留，flutter install 等工具仍可正常使用。
// ---------------------------------------------------------------------------
val apkOutputDir = layout.buildDirectory.dir("outputs/flutter-apk")
val versionName = flutter.versionName ?: "0.0.0"

// 每种构建模式单独一个任务，只复制本次真正构建出来的那个 APK，
// 避免目录里残留的旧 app-debug.apk 覆盖掉 release 产物。
fun registerNamedApkCopy(mode: String) {
    val taskName = "copyNamedApk${mode.replaceFirstChar { it.uppercase() }}"
    tasks.register(taskName) {
        description = "把 app-$mode.apk 另存为 HanziRoots-v<版本号>.apk"
        val outputDirProvider = apkOutputDir
        val sourceName = "app-$mode.apk"
        val targetName = "HanziRoots-v$versionName.apk"
        doLast {
            val dir = outputDirProvider.get().asFile
            val source = dir.resolve(sourceName)
            if (source.exists()) {
                source.copyTo(dir.resolve(targetName), overwrite = true)
                logger.lifecycle("[APK] 已生成 $targetName")
            } else {
                logger.lifecycle("[APK] 未找到 $sourceName，跳过命名")
            }
        }
    }
    tasks.matching { it.name == "assemble${mode.replaceFirstChar { it.uppercase() }}" }
        .configureEach { finalizedBy(taskName) }
}

registerNamedApkCopy("release")
registerNamedApkCopy("debug")
registerNamedApkCopy("profile")
