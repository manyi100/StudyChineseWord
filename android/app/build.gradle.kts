plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
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
