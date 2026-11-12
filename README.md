# 入学必备 720 字

一个面向学龄前 / 低年级儿童和中文学习者的离线识字 App（Flutter + Android）。内置 720 个常用汉字，每字配拼音、部首、笔顺、组词、例句和插画，并支持笔顺描红、点读发音、阶段化学习与中英文界面。

当前版本：`1.0.0`（构建号 1）

---

## 一、功能概览

### 1. 学习分类：阶段 + 主题课 + 多维度浏览

首页不再使用容易误导的“一年级 / 二年级”说法，改为**第 1~6 阶段**，并把原书同一行的 4 个主题相近的字组织成“一课”：

- **6 个阶段**，每阶段 **30 课**，每课 **4 字**，共 **180 课 / 720 字**
- 首页顶部可切换三种浏览方式：
  - **按主题**：阶段 → 课程列表 → 4 字学习（默认）
  - **按部首**：174 个部首按字数排序（木 41、氵 38、口 29、扌 26…）
  - **按笔画**：1~3 画、4~5 画、6~7 画、8~9 画、10~12 画、13 画以上
- 阶段卡片显示：已学字数、完成课数、进度条
- 解锁规则保持不变：学完上一阶段的全部 120 字后，解锁下一阶段；第 1 阶段始终解锁
- “已解锁阶段连续学”入口只包含当前已解锁的字，不绕过解锁机制

> 说明：这里的“阶段”是按原书顺序和难度做的**自编分级**，不是部编版教材的真实年级识字表。

### 2. 学习卡片

每个字一张卡片，包含：

- **配图**：按图片真实宽高比铺满，不裁切、不留白
- **拼音四线三格** + **田字格楷体大字**
- **笔顺演示**：打开卡片自动按笔顺逐笔描出，可随时重播
- **手指跟写描红**：
  - 当前笔画用浅红底提示，标出起笔红点、虚线走向、收笔箭头
  - 校验起笔位置、收笔位置、书写方向和轨迹贴合度
  - 写对自动进入下一笔，全部完成给出鼓励提示
  - 写错或轻点格子会自动演示当前笔画
  - 田字格内使用独立手势识别，写“横”时不会误触发翻页
- **组词**：固定一行三等分，三个词语不会换行；词语单行显示，过长自动轻微缩放
- **例句**：点击整句朗读
- **收藏**：星标位于卡片右上角（配图右上角），空心/实心切换
- **学完自动进入下一课**：一课的 4 个字都看过后，在最后一页继续左滑会直接切换到下一课；没看完时会提示先看完本课

### 3. 点读与音频提示

所有核心内容都可以点击发声：

| 位置 | 提示 | 点击反馈 |
|---|---|---|
| 田字格汉字 | 点田字格即可 | 朗读单字 |
| 词语 | 词语行内小喇叭 | 词块变绿、喇叭跳动 |
| 句子 | 句首喇叭 + “朗读中” | 整句朗读，读完自动恢复 |
| 配图 | 左上角喇叭角标 | 朗读例句，图片底部浮出句子气泡，读完淡出 |

> 笔顺操作栏不再放喇叭按钮，避免和“笔顺演示 / 手写描红”抢注意力；点田字格仍然可以朗读单字。

- 首次进入学习页会显示一次性提示：“点汉字、词语、句子或图片，都能听发音”，9 秒后自动消失
- 连续点击不同内容会自动打断上一段朗读，不串音
- 朗读结束优先使用 TTS 完成回调；部分国产 ROM 回调不稳定时，按“字数 × 0.38 秒 + 1.4 秒”兜底自动收起动效
- 点击图片的朗读顺序：**例句 → 第一个组词 → 单字**
- 小米 / 红米机型已在 `AndroidManifest.xml` 声明 `TTS_SERVICE` 查询权限，并会枚举已安装语音引擎逐个尝试中文发音；没有可用引擎时会提示去系统设置安装

### 4. 收藏与复习

- 每张卡片的星标位于右上角，点击即收藏 / 取消收藏
- 收藏数据跨阶段共用，保存在本地
- **“收藏复习”入口位于首页底部**，显示已收藏字数，点击进入集中复习列表
- 学习页顶部不再显示 `1/4`、`2/4` 之类的数字序号

### 5. 进度记录

- 浏览到过的字记为“已学”（`viewedIds`），退出 App 不丢失
- 每个阶段、每门课程、每个部首 / 笔画分组分别记住上次看到的位置
- 阶段进度 = 该阶段已学字数 / 120；课程进度 = 该课已学字数 / 4

### 6. 数据与资源

- `assets/data/hanzi_data.json`：720 字的拼音、部首、结构、笔画数、笔顺名称、组词、例句、配图路径
- `assets/data/stroke_data.json`：720 字的笔顺矢量数据（约 1.6 MB，包含每一笔的外轮廓和中心骨架）
  - 数据来源：[Make Me a Hanzi](https://github.com/skishore/makemeahanzi)，图形数据源自 Arphic 字体（Arphic Public License）
  - 生成脚本：`scripts/fetch_stroke_data.py`
- `assets/images/`：720 张 WebP 插画（526×290，约 26.8 MB），已全部替换旧版 GIF
- `assets/fonts/LXGWWenKai-Subset.ttf`：楷体子集字体，仅保留 720 字实际用到的字形（约 288 KB）
  - 来源：[LXGW WenKai](https://github.com/lxgw/LxgwWenKai)，SIL Open Font License 1.1
  - 协议文件：`assets/fonts/OFL.txt`，发布时请勿删除

### 7. 拼音校对

2026-11 对全部 720 个字、2160 个组词、720 个例句做了一次系统校对，修正了单字读音、声调以及词组 / 例句中的连带错误，例如：

- 雨 `yù → yǔ`、语 `yù → yǔ`、主 `zhù → zhǔ`
- 跑 `páo → pǎo`、打 `dá → dǎ`、拉 `lá → lā`
- 脚 `jué → jiǎo`、袜 `mò → wà`、织 `zhì → zhī`、采 `cài → cǎi`
- 场 `cháng → chǎng`、转 `zhuàn → zhuǎn`、吐 `tù → tǔ`、曲 `qǔ → qū`
- 教室 / 教师由 `jiāo` 改为 `jiào`，少年由 `shǎo` 改为 `shào`
- 名词后缀“子”统一读轻声 `zi`（莲子、棋子等仍读 `zǐ`）
- 例句中的 `gě（盖）`、`yún（员）`、`wù（乌）` 等错音已全部修正
- `一`、`不` 采用本调 `yī`、`bù`，未做变调标注

### 8. 中英文界面

- 开屏（选择学习阶段）右上角有语言切换按钮：中文界面显示 `EN`，英文界面显示 `中文`，点一下立即切换
- 选择结果保存在本地（`app_language`），退出重进后保持不变
- 切换的只是**界面语言**：汉字、拼音、组词、例句以及朗读内容始终是中文，方便外国学习者把英文说明和中文内容对照起来学
- 英文界面覆盖全部页面：阶段 / 课程 / 部首 / 笔画、学习卡片、田字格按钮与状态、收藏页、空状态和 SnackBar 提示
- 笔顺名称也做了英文映射，例如 横 → horizontal、竖 → vertical、横折钩 → horizontal-turn hook
- 文案集中在 `lib/l10n/app_strings.dart`，新增语言只需要在该文件加一个分支

---

## 二、目录结构

```
lib/
├── main.dart
├── l10n/
│   └── app_strings.dart          # 中英文文案 + 语言状态 / 持久化
├── models/
│   ├── hanzi_model.dart          # 汉字数据模型 + 阶段元信息
│   └── hanzi_course.dart         # 课程 / 部首组 / 笔画组模型
├── screens/
│   ├── grade_select_screen.dart  # 首页：按主题 / 按部首 / 按笔画
│   ├── course_list_screen.dart   # 某阶段的 30 课列表
│   ├── hanzi_grid_screen.dart    # 部首 / 笔画分组的汉字网格
│   ├── home_screen.dart          # 学习页（通用字表 + 左右翻页）
│   └── favorites_screen.dart     # 收藏复习
├── services/
│   ├── hanzi_repository.dart     # 字库、课程、部首、笔画分组
│   ├── stroke_repository.dart    # 笔顺矢量数据解析
│   ├── tts_service.dart          # 朗读 + 朗读状态通知
│   ├── storage_service.dart      # 本地进度 / 收藏 / 提示标记
│   └── progress_service.dart     # 阶段解锁逻辑
└── widgets/
    ├── character_card.dart       # 学习卡片
    ├── tian_zi_ge_box.dart       # 田字格 + 笔顺演示 + 手写描红
    ├── pinyin_grid_text.dart     # 拼音四线三格
    ├── language_button.dart      # 开屏右上角中英文切换按钮
    ├── content_frame.dart        # 宽屏内容最大宽度（iPad / 横屏居中）
    └── audio_feedback.dart       # 喇叭图标、声波动效、气泡、首次提示

scripts/
├── generate_images_nanobanana.py # 批量生成配图
├── make_brand_assets.py          # 由 1024 源图生成图标 / 启动图素材
├── fetch_stroke_data.py          # 生成笔顺矢量数据
├── crop_hanzi_grid.py            # 四宫格切图（旧版）
└── crop_hanzi_gridv2.py          # 四宫格切图（新版）
```

---

## 三、使用方式

1. 打开 App 进入“选择学习阶段”首页
2. 点右上角语言按钮可在中文 / English 之间切换；汉字与朗读内容仍保持中文
3. 默认“按主题”：点某个阶段的卡片 → 查看 30 课 → 点某一课开始学习
4. 也可以切换“按部首”“按笔画”，点分组进入汉字网格，再点任意字学习
5. 学习页左右滑动切换汉字；点汉字 / 词语 / 句子 / 图片都可以朗读
6. 一课 4 个字都看过后，在最后一页继续左滑会自动进入下一课
7. 点“笔顺演示”看动画；直接在田字格里写即可进入手写描红
8. 点卡片右上角星标收藏；回首页底部进入“收藏复习”

---

## 四、开发与构建

```bash
flutter pub get
flutter test                          # 含 360dp 宽度布局检查
flutter build apk --release           # 产物：build/app/outputs/flutter-apk/HanziRoots-v1.0.0.apk
```

安装到设备：

```bash
adb install -r build/app/outputs/flutter-apk/HanziRoots-v1.0.0.apk
```

### 应用标识与 APK 命名

| 项目 | 值 |
| --- | --- |
| 应用包名（applicationId / namespace） | `com.ailexin.HanziRoots` |
| 启动 Activity | `com.ailexin.HanziRoots.MainActivity` |
| APK 文件名 | `HanziRoots-v<版本号>.apk`，版本号取自 `pubspec.yaml` 的 `version` |
| 当前产物 | `build/app/outputs/flutter-apk/HanziRoots-v1.0.0.apk` |
| iOS Bundle ID | `com.ailexin.HanziRoots`（RunnerTests 为 `.RunnerTests`） |
| iOS 产物 | `build/ios/ipa/Runner.ipa`（`flutter build ipa`） |

- 命名规则写在 `android/app/build.gradle.kts`：`assemble*` 结束后由 `copyNamedApk*` 任务把 `app-<mode>.apk` 另存为带版本号的副本
- `app-release.apk` 仍保留，`flutter install`、`flutter run` 等工具依赖该固定文件名
- 改版本号只需改 `pubspec.yaml` 的 `version`，重新构建后 APK 名会自动跟着变化
- 包名变更后与旧包 `com.example.untitled` 属于两个独立应用，需要先卸载旧包或手动清理

### iOS / iPad 打包

Flutter 的 iOS 产物**只能在 macOS 上用 Xcode 编译**，Windows 上无论怎么配置都打不出 `.ipa`。可选的三种环境：

| 方式 | 说明 | 适用 |
| --- | --- | --- |
| 本地 Mac | 安装 Xcode + CocoaPods，免费 Apple ID 可真机调试（签名 7 天有效） | 开发调试 |
| 租用云 Mac | MacinCloud、MacStadium 等远程桌面，按小时计费 | 偶尔发版 |
| CI 构建 | Codemagic、GitHub Actions `macos-latest` runner，无需自备 Mac | 持续集成 / 自动发版 |

上架 App Store 需要 **Apple Developer Program（99 美元/年）**；免费账号只能装到自己的设备，且 7 天要重签。

#### 一、首次配置（在 Mac 上，只需做一次）

```bash
flutter pub get
cd ios && pod install && cd ..
open ios/Runner.xcworkspace      # 必须打开 xcworkspace，不是 xcodeproj
```

Xcode 里：

1. 左侧选中 `Runner` target → **Signing & Capabilities**
2. `Team` 选择自己的 Apple ID / 开发者团队，勾选 **Automatically manage signing**
3. `Bundle Identifier` 已是 `com.ailexin.HanziRoots`；若被占用，改成自己的（如 `com.ailexin.HanziRoots.cn`），同时同步 `android/app/build.gradle.kts`
4. 真机首次运行需在 iPhone「设置 → 通用 → VPN 与设备管理」里信任开发者证书

#### 二、日常打包

```bash
# 真机调试
flutter run -d <device-id>

# 打 IPA（自动 archive + 导出）
flutter build ipa --release
# 产物：build/ios/ipa/Runner.ipa        （App 名是 Runner，可自行重命名）
#       build/ios/archive/Runner.xcarchive
```

导出方式按用途选择：

| 命令 | 用途 |
| --- | --- |
| `flutter build ipa --export-method app-store` | 上传 App Store Connect / TestFlight |
| `flutter build ipa --export-method ad-hoc` | 指定 UDID 的设备内测 |
| `flutter build ipa --export-method development` | 开发团队内部分发 |
| `flutter build ipa --export-method enterprise` | 企业账号内部分发 |

想和 APK 一样带版本号，导出后重命名即可：

```bash
cp build/ios/ipa/Runner.ipa build/ios/ipa/HanziRoots-v1.0.0.ipa
```

#### 三、iPhone / iPad 适配现状

| 项目 | 状态 |
| --- | --- |
| 设备族 | `TARGETED_DEVICE_FAMILY = "1,2"`，iPhone / iPad 共用一份产物 |
| 屏幕方向 | iPhone 竖屏 + 左右横屏；iPad 四方向均允许（见 `ios/Runner/Info.plist`） |
| 最低系统 | iOS 13.0 |
| 依赖 | 仅 `flutter_tts`、`shared_preferences`，均支持 iOS，无需额外原生代码 |
| 朗读 | iOS 用系统 `AVSpeechSynthesizer`，中文语音离线可用 |
| 显示名 | `入学必备720字`（`CFBundleDisplayName`） |
| 宽屏布局 | 内容最大宽度 720，iPad / 横屏自动居中（`lib/widgets/content_frame.dart`） |

宽屏处理细节：

- 首页、课程列表、部首 / 笔画网格、收藏页、学习卡片、点读提示条都套了 `ContentFrame`
- 手机竖屏宽度小于 720，布局与之前完全一致；只有 iPad / 折叠屏展开 / 横屏才会居中
- 翻页手势仍由整屏 `PageView` 接收，只是卡片本身被收窄，不会出现“只能滑中间一块”的问题

建议在真机上再确认几点：

- 英文界面下底部提示、按钮在 iPad 分屏窄宽度时是否溢出
- 首次朗读若没声音，检查「设置 → 辅助功能 → 朗读内容 → 声音 → 中文」是否已下载

#### 四、上架前清单

1. **图标**：已生成 iOS / Android 全尺寸（含自适应图标）。上架前确认 App Store Connect 的 1024 图标与 `assets/branding/app_icon.png` 一致
2. **启动图**：已生成，iPhone / iPad / Android 12+ 均为米色底 + 居中 Logo
3. **版本号**：已是 `1.0.0+1`，iOS 的 `CFBundleShortVersionString` / `CFBundleVersion` 自动取这两个值；每次提审 build 号必须递增
4. **隐私清单**：`ios/Runner/PrivacyInfo.xcprivacy` 已提供（声明 `UserDefaults` 用途 CA92.1）。**需在 Xcode 里把它拖进 Runner target 的 Copy Bundle Resources**，只放文件不生效
5. **App Store 资料**：中英文名称、副标题、截图（6.7"/6.5"/12.9" iPad）、隐私政策 URL（本 App 不收集数据，填“不收集”）
6. **体积**：图片 26.8 MB + 笔顺 1.6 MB，IPA 约 80–90 MB，仍在 200 MB 蜂窝下载限制内

### 图标与启动图

源图放在 `assets/branding/app_icon_source.png`（1024×1024，允许带透明圆角）。当前图标已按这套流程生成，换图后重跑三条命令即可：

```bash
python scripts/make_brand_assets.py      # 生成 app_icon / adaptive 前景 / 启动图 Logo
dart run flutter_launcher_icons          # 生成 Android + iOS 全尺寸图标
dart run flutter_native_splash:create    # 生成各平台启动图
```

| 产物 | 用途 |
| --- | --- |
| `assets/branding/app_icon.png` | 1024×1024 铺满无透明，iOS / 桌面图标 |
| `assets/branding/app_icon_foreground.png` | Android 自适应图标前景（内容占 72%，留安全区） |
| `assets/branding/splash_logo.png` | 启动图 Logo（内容占 62%） |

脚本会打印采样到的纸张底色（当前是 `#F4EAD8`），它已同步到 `pubspec.yaml` 的 `adaptive_icon_background`、`flutter_native_splash.color` 与 `android_12.color`，所以图标圆角、启动图背景是同一个颜色，切换时没有色块跳变。

生成结果：

| 平台 | 产物 |
| --- | --- |
| Android | `mipmap-*/ic_launcher.png`（5 档）+ `mipmap-anydpi-v26/ic_launcher.xml` 自适应图标 + `drawable*/splash.png`、`android12splash.png` |
| iOS | `Assets.xcassets/AppIcon.appiconset` 全尺寸（无透明通道，符合审核要求） |
| 启动图 | `drawable*/launch_background.xml`、`values*/styles.xml`、`LaunchImage/LaunchBackground` |

> 自适应图标前景按 66% 安全区生成，圆形 / 方形遮罩都不会裁到“HanziRoots”字样；未开 `fullscreen`，启动图期间保留系统状态栏。

### Gradle 全局仓库配置说明

如果本机 `GRADLE_USER_HOME/init.d/init.gradle` 对所有工程注入了 `mavenLocal()` 或镜像仓库，可能与 Flutter 自带的 `FAIL_ON_PROJECT_REPOS` 设置冲突，报错：

```
Build was configured to prefer settings repositories over project repositories
but repository 'MavenLocal' was added by settings file 'settings.gradle.kts'
```

当前环境的全局 `init.gradle` 已改为兼容写法：检测到 `FAIL_ON_PROJECT_REPOS` 时跳过工程级仓库注入，其他工程保持原有镜像加速。

---

## 五、配图批量生成（可选）

仓库里 720 张 `assets/images/NNNN.webp` 已经全部生成完毕（526×290、纯插画、无文字），
正常开发不需要再跑这个脚本。需要重画或换风格时再用
`scripts/generate_images_nanobanana.py`。

**三个图像服务**（`--provider` 切换，不写则读 `IMAGE_PROVIDER`，再没有就用 cloudflare）：

| provider | 服务 | 免费额度 | 提示词语言 | 一次出几张 |
|---|---|---|---|---|
| `cloudflare`（默认） | Cloudflare Workers AI `flux-1-schnell` | 每天约 173 张 | 英文 | 1 |
| `modelscope` | 魔搭 `Qwen/Qwen-Image` | 约 250 张/天，需实名、限非商用 | 中文 | 1 |
| `gemini` | Google `gemini-2.5-flash-image` | 无，约 $0.039/张 | 中文 | 4（2×2 四宫格） |

```bash
pip install requests pillow

# Cloudflare（推荐，免费）
export CLOUDFLARE_ACCOUNT_ID=你的account_id
export CLOUDFLARE_API_TOKEN=你的api_token          # 权限勾 Workers AI:Read
python3 scripts/generate_images_nanobanana.py --limit 20

# 魔搭 Qwen-Image
export MODELSCOPE_API_TOKEN=你的token
python3 scripts/generate_images_nanobanana.py --provider modelscope --limit 20

# Gemini（付费，四宫格）
export GEMINI_API_KEY=你的key
python3 scripts/generate_images_nanobanana.py --provider gemini --limit 20
```

| 参数 | 作用 |
|---|---|
| `--all` | 跑完全部剩余汉字，忽略 `--limit` |
| `--limit N` | 本轮最多生成 N 张（默认 20） |
| `--dry-run` | 只打印提示词，不调用 API、不写文件 |
| `--overlay none\|textbook` | `none`（默认）只出纯插画；`textbook` 用 PIL 把左上角字、左下角圈号、底部例句印在图上 |
| `--reset 51-74` | 清掉这些 id 的配图记录并删除对应 webp，换风格重画（只删脚本生成的 `.webp`，教材原图 `.gif` 不碰） |
| `--translate-prompts` | 用 Cloudflare 免费文本模型把例句翻成英文画面描述写回 `promptEn`，不生成图片 |

脚本特性：

- **画面内容来自例句**，比单纯画字更有叙事感
- **文字默认不叠在图上**：和当前 App 一致，字/拼音/例句由 Flutter 卡片渲染；
  需要旧教材页版式时加 `--overlay textbook`
- **固定风格前缀 / 后缀**（扁平卡通、清晰描边、纯白背景、无文字），整批风格统一；
  Gemini 还支持传入参考图锁定风格
- **提示词里不要出现中文**：FLUX 看到中文容易把它当画面内容画出来，导致和图上的文字重复。
  跑一次 `--translate-prompts` 把例句翻成英文描述写回 `promptEn`，之后 prompt 里就没有中文字符了
- **输出统一为 526×290 WebP（q85）**，并自动写回 `imageAsset`
- **已有配图的字自动跳过**，支持断点续跑，不重复调用、不覆盖旧图
- **默认每轮 20 张**，便于先检查质量

> 文字合成用的字体：项目自带的 `LXGWWenKai-Subset.ttf` 只是 720 个单字的子集，
> 画不了例句。脚本会依次尝试 `IMAGE_OVERLAY_FONT` → Noto Sans SC → 系统黑体
> （macOS 冬青黑体 W6 / Windows 微软雅黑 Bold / Linux Noto CJK）。

---

## 六、验证清单

1. 首页三种分类（按主题 / 按部首 / 按笔画）是否都能切换并正常进入
2. 阶段卡片是否显示“已学 X / 120 字 · 完成 Y / 30 课”
3. 进入阶段后是否看到 30 课，每课 4 个主题字
4. 学习页左右滑动是否流畅，顶部是否**没有** `1/4` 之类的数字
5. 组词区三个词语是否始终在一行、不换行，小喇叭是否居中且高度紧凑
6. 点汉字 / 词语 / 句子 / 图片是否都有声音，朗读时图标是否变成声波、读完是否自动恢复
7. 点图片是否朗读例句，并浮出句子气泡
8. 卡片右上角星标是否可收藏；首页底部“收藏复习”是否显示已收藏数量
9. 笔顺演示是否按顺序逐笔描出；田字格手写时是否不会误翻页
10. 学完一个阶段 120 字后，下一阶段是否解锁
11. 没有中文语音引擎时，是否弹出安装 / 启用提示
12. 退出重进后，学习位置、收藏、已学进度是否保留
13. 首页右上角语言按钮能否在中文 / English 之间切换，退出重进后是否保持
14. 英文界面下阶段 / 课程 / 部首 / 笔画 / 学习卡片 / 收藏页文案是否完整，360dp 窄屏是否不溢出

---

## 七、更新日志

### 2026-11

- **分类改版（P0 + P1）**
  - “年级”改为“第 1~6 阶段”，避免与真实教材年级混淆
  - 新增 180 门主题课（每课 4 字，每阶段 30 课）
  - 首页新增“按主题 / 按部首 / 按笔画”三种浏览方式
  - 新增部首、笔画分组的汉字网格页
- **点读与音频提示**
  - 汉字、词语、句子、配图均可点击朗读
  - 常驻小喇叭 + 朗读声波动效 + “朗读中”提示，读完自动消失
  - 点击配图朗读例句并显示句子气泡
  - 首次进入学习页显示一次性点读提示
- **学习卡片调整**
  - 组词固定一行三等分，不再换行；词块高度压缩、喇叭居中
  - 收藏星标移到卡片右上角
  - “收藏复习”入口从学习页移到首页底部
  - 移除顶部四字导航条和数字序号
  - 学完一课 4 个字后，在最后一页继续左滑进入下一课
  - “朗读中”标签水平、垂直居中
  - 移除田字格操作栏的喇叭按钮，点田字格仍可朗读
- **笔顺描红**
  - 内置 720 字离线笔顺矢量数据
  - 自动笔顺动画 + 手指跟写描红（方向 / 起笔 / 收笔校验）
- **数据与资源**
  - 720 张配图由 GIF 全量替换为 WebP，APK 约 72.5 MB
  - 全量校对 720 字、2160 个组词、720 个例句的拼音与声调
- **中英文界面**
  - 开屏右上角新增语言切换按钮，支持中文 / English
  - 全站文案集中到 `lib/l10n/app_strings.dart`，切换即时生效并本地保存
  - 笔顺名称增加英文映射，英文界面下显示 horizontal / vertical 等
  - 学习内容（汉字、拼音、组词、例句）保持中文，朗读仍为中文
- **应用标识与产物命名**
  - 包名由 `com.example.untitled` 改为 `com.ailexin.HanziRoots`，MainActivity 同步迁移
  - APK 产物自动命名为 `HanziRoots-v<版本号>.apk`，例如 `HanziRoots-v1.0.0.apk`
  - iOS Bundle ID 同步为 `com.ailexin.HanziRoots`，显示名改为“入学必备720字”
  - 新增 `ios/Runner/PrivacyInfo.xcprivacy`（UserDefaults 用途声明）
  - README 新增 iOS / iPad 打包与上架说明
- **版本与宽屏适配**
  - 版本号提升到 `1.0.0+1`，Android `versionName` / iOS `CFBundleShortVersionString` 自动跟随
  - 新增 `ContentFrame`：iPad / 横屏内容最大宽度 720 并居中，手机竖屏布局不变
  - 新增 1024×1366（iPad Pro）宽度断言测试
- **图标与启动图**
  - 接入 `flutter_launcher_icons` 与 `flutter_native_splash`
  - 新增 `scripts/make_brand_assets.py`，由一张 1024 源图生成图标、自适应前景和启动图 Logo
  - 已生成正式图标（Android 自适应 + iOS 全尺寸，无透明通道）与 `#F4EAD8` 米色启动图
  - 自适应图标前景控制在 66% 安全区，避免文字被系统遮罩裁掉
- **测试**
  - 增加 360dp 窄屏导航与布局冒烟测试，替换原默认计数器测试
  - 增加中英文切换测试（首页 → 阶段 → 课程 → 切回中文）

---

## 八、后续可做

1. **掌握度与复习队列（P2）**
   - 把“描红通过 + 跟读”作为掌握信号，而不是仅“浏览过”
   - 增加易错字、到期复习、今日新字队列
2. **课程主题名**
   - 当前课程标题就是 4 个汉字，可人工校订 180 个主题名（如“数字”“方位”“家人称呼”）
3. **教材映射（P3）**
   - 如需与学校同步，可把 720 字映射到部编版 12 册识字表
4. **内容人工抽查**
   - 组词、例句仍建议人工过一遍，尤其是生僻字的用词适龄性
5. **更多界面语言**
   - 如需面向日本 / 韩国学习者，可在 `app_strings.dart` 增加日文、韩文分支
   - 汉字释义（英文词义）可在现有组词之外补充，加深非母语学习者理解
