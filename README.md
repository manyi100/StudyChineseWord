# 入学必备 720 字

**使用说明 / User Guides**：[简体中文](README_zh.md) | [English](README_en.md) | [日本語](README_ja.md) | [한국어](README_ko.md) | [Tiếng Việt](README_vi.md) · [五语合集](hanziroots.md)

一个面向学龄前 / 低年级儿童和中文学习者的离线识字 App（Flutter + Android）。内置 720 个常用汉字，每字配拼音、部首、笔顺、组词、例句和插画，并支持笔顺描红、点读发音、阶段化学习与中英文界面。

当前版本：`1.3.1`（构建号 5）

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
- **右滑回上一课**：在本课第一页继续右滑，直接回到上一课的最后一个字（不用点左上角返回），与「左滑进下一课」对称

### 3. 点读与音频提示

所有核心内容都可以点击发声：

| 位置 | 提示 | 点击反馈 |
|---|---|---|
| 田字格汉字 | 点田字格即可 | 朗读单字 |
| 词语 | 词语行内小喇叭 | 词块变绿、喇叭跳动 |
| 句子 | 句首喇叭 | 整句朗读，读完自动恢复 |
| 配图 | 左上角喇叭角标 | 朗读例句，图片底部浮出句子气泡，读完淡出 |

> 笔顺操作栏不再放喇叭按钮，避免和“笔顺演示 / 手写描红”抢注意力；点田字格仍然可以朗读单字。

- 首次进入学习页会显示一次性提示：“点汉字、词语、句子或图片，都能听发音”，9 秒后自动消失
- 连续点击不同内容会自动打断上一段朗读，不串音
- 朗读结束优先使用 TTS 完成回调；部分国产 ROM 回调不稳定时，按“字数 × 0.38 秒 + 1.4 秒”兜底自动收起动效
- 点击图片的朗读顺序：**例句 → 第一个组词 → 单字**
- **朗读优先播放随包内置的音频**（见「内置朗读音频」），不依赖系统 TTS；只有查不到音频时才回退系统引擎
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

### 8. 多语言界面（中 / 英 / 日 / 韩 / 越）

汉字文化圈里大量接触汉字的国家和地区：

| 国家 / 地区 | 汉字使用情况 |
| --- | --- |
| 中国（含港澳台） | 母语，小学阶段识字 2500–3000 字 |
| 日本 | 常用汉字 2136 个，小学 6 年学 1026 个（教育汉字） |
| 韩国 | 汉字（한자）为选修，中学阶段 1800 个基础汉字 |
| 越南 | 历史上使用汉字与字喃，现多为兴趣学习、汉越词研究 |
| 新加坡 / 马来西亚 | 华文教育，采用简体字，与国内教材接近 |

因此界面提供五种语言：

- 开屏右上角是语言按钮，显示当前语言（`中` / `EN` / `日` / `한` / `VI`），点开后在菜单里选择
- **首次安装跟随手机系统语言**：系统是 `ja_JP` / `ko-KR` / `vi-VN` / `zh-CN` / `en-US` 就直接进对应界面；法语、德语等未支持的系统语言回落中文
- 选择结果保存在本地（`app_language`，取值为 `zh` / `en` / `ja` / `ko` / `vi`），退出重进后保持不变；一旦手动选过，就不再跟系统语言走
- 切换的只是**界面语言**：汉字、拼音、组词、例句以及朗读内容始终是中文，方便学习者把母语说明和中文内容对照起来
- 覆盖全部页面：阶段 / 课程 / 部首 / 笔画、学习卡片、田字格按钮与状态、收藏页、空状态和 SnackBar 提示
- 笔顺名称本地化：日文（横 / 縦 / 左払い / 横折れ鉤）、韩文（가로 / 세로 / 왼삐침）、英越用英文名（horizontal / vertical / left-falling）
- 文案集中在 `lib/l10n/app_strings.dart`，每个文案一行、按「中英日韩越」顺序给出，新增语言只需在 `AppLang` 与 `_t(...)` 里各加一项

### 9. 内置朗读音频（不依赖系统 TTS）

海外设备、电视盒子、投影仪经常没有中文 TTS 引擎，系统朗读会直接无声。现在把朗读音频随 App 打包：

| 内容 | 条数 | 说明 |
| --- | --- | --- |
| 单字 | 720 | 每个字的独立读音 |
| 组词 | 1954 | 与卡片上的词语一一对应（2160 条去重后） |
| 例句 | 706 | 整句朗读（720 条去重后） |
| 合计 | 3380 条 | 24 kHz 单声道 mp3，共 28.5 MB |

播放策略：**内置音频 → 系统 TTS → 提示安装引擎**。`assets/audio/manifest.json` 里查不到文本（例如以后新增内容）时才回退系统 TTS，所以缺文件也不会哑。

多音字用「同音字替换」保证读音正确——单字音频只承载音节，用同音字合成不会改变发音：

| 字 | 数据标注 | 引擎默认读法 | 实际合成 |
| --- | --- | --- | --- |
| 长 | cháng | zhǎng | 常 |
| 干 | gān | gàn | 竿 |
| 薄 | bó | báo | 博 |
| 教 | jiāo | jiào | 蕉 |
| 种 | zhòng | zhǒng | 重 |
| 划 | huá | huà | 滑 |
| 泊 | bó | pō | 博 |
| 子 | zǐ | zi | 紫 |
| 脏 | zāng | zàng | 赃 |
| 缝 | féng | fèng | 逢 |

（`爪 zhuǎ` 在常用字里没有同音字，单字音频仍是 zhǎo，属于已知小瑕疵。）

重新生成或补录内容：

```bash
python scripts/generate_audio.py --limit 10   # 先验证音色
python scripts/generate_audio.py              # 全量生成，已存在会自动跳过
```

- 需要联网；走代理先设 `HTTPS_PROXY`
- 音色默认 `zh-CN-XiaoxiaoNeural`，可用 `--voice` 更换
- 生成完成后会重写 `assets/audio/manifest.json`（文本 → 资源路径）
- 商用前请确认音源授权：Edge TTS 是微软在线服务的免费接口，正式发行建议换成 Azure 付费语音或真人录音

### 10. 英文释义（可关闭、不参与朗读）

单字、组词、例句都可以带一行英文释义，给非中文母语的学习者和家长做理解辅助：

| 位置 | 示例 | 字号 / 颜色 |
| --- | --- | --- |
| 单字（田字格下方） | 长 → `long; length` | 13sp，黑 55% |
| 组词（chips 下方一行） | `right hand  /  left hand  /  right side` | 11sp，黑 45% |
| 例句（句框内第二行） | 今天下雨了。→ `It rained today.` | 13sp，左对齐 |

交互约定：

- 学习页右上角有 **EN** 胶囊开关，点一下显示 / 再点收起；状态存在 `show_meanings`
- 默认值跟随界面语言：中文界面默认**关**，英 / 日 / 韩 / 越界面默认**开**（可随时手动改）
- 释义固定英文，不随界面语言变化——界面语言只切换界面文案
- 释义行用 `IgnorePointer` 包裹：点它不会朗读、不会误触，也不影响田字格、词块、例句的既有点读
- 关闭时返回 0 尺寸，完全不占高度；查不到释义时同样不显示（不留空行）

数据：

| 内容 | 条数 | 来源 |
| --- | --- | --- |
| 单字 | 720 / 720 | CC-CEDICT（按数据标注的读音精确匹配，多音字不会串义） |
| 组词 | 1926 / 1954 | CC-CEDICT + 172 条手工补充 |
| 例句 | 706 / 706 | 人工翻译 |

- 数据文件是 `assets/data/meanings_en.json`，按「文本」为 key（`chars` / `words` / `sentences` 三张表），不混进 `hanzi_data.json`；新增内容缺释义会自动跳过
- 英文在 `lib/services/meaning_service.dart` 里查表，界面组件在 `lib/widgets/meaning_text.dart`
- 释义在后台加载（`_revision` + `Listenable.merge`），不阻塞首帧；加载完成后只重建释义行

重新生成：

```bash
# build/cedict.txt 是 CC-CEDICT 解压后的词典（已 gitignore）
python scripts/build_meanings_en.py
```

- 覆盖表在脚本里：`CHAR_OVERRIDES`（单字冷僻义项修正）、`WORD_OVERRIDES`（量词与常用词）
- 补充词义 `scripts/data/word_en_extra.tsv`，例句译文 `scripts/data/sent_en.tsv`（序号 = `hanzi_data.json` 里例句出现顺序，脚本按出现顺序编号）
- **授权提醒**：CC-CEDICT 采用 CC BY-SA 4.0，商用需评估署名与传染性条款，或替换为自建 / 付费词库（结构保持一致即可）

### 11. 新手引导（首次启动四页图片说明）

首次安装后进入首页会弹出一份四页指引，看完一次就记在本地（`has_seen_onboarding_v131`），之后不再打扰；想再看点首页右上角 **?** 即可。

| 页 | 图片 | 内容 |
|---|---|---|
| 1 | `onboarding_step_1.webp` | 阶段闯关 · 三维检索（6 阶段 / 180 课 / 174 部首 / 6 档笔画） |
| 2 | `onboarding_step_2.webp` | 四区即点即读 · 3,380 条离线语音 |
| 3 | `onboarding_step_3.webp` | 自动笔顺演示 · 手指跟写描红 |
| 4 | `onboarding_step_4.webp` | 五语界面 · EN 释义 · 跨课滑动 |

- 图片在 `assets/onboarding/`（720 × 986 竖图，标题与要点已排进图里，中英双语），`pubspec.yaml` 按目录整体打包
- **左滑进入下一步**，底部页码圆点同步；最后一页按钮变「开始学习」，中途可点「跳过」或点遮罩关闭
- 组件在 `lib/widgets/onboarding_dialog.dart`：图片按容器等比缩放（`BoxFit.contain`），360dp 窄屏与 iPad / 投屏都不溢出；每页 `semanticLabel` 取 `AppStrings.onboardingTitle*`，读屏仍有标题
- 首次弹窗在 `GradeSelectScreen.initState` 的 `addPostFrameCallback` 里触发，不阻塞首帧

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
│   ├── meaning_service.dart      # 英文释义查表 + 显隐开关（show_meanings）
│   ├── storage_service.dart      # 本地进度 / 收藏 / 提示标记
│   └── progress_service.dart     # 阶段解锁逻辑
└── widgets/
    ├── character_card.dart       # 学习卡片
    ├── meaning_text.dart         # 单字 / 组词 / 例句释义行（IgnorePointer）
    ├── tian_zi_ge_box.dart       # 田字格 + 笔顺演示 + 手写描红
    ├── pinyin_grid_text.dart     # 拼音四线三格
    ├── language_button.dart      # 开屏右上角中英文切换按钮
    ├── onboarding_dialog.dart    # 首次启动四页使用说明（右上角「?」可重看）
    ├── content_frame.dart        # 宽屏内容最大宽度（iPad / 横屏居中）
    └── audio_feedback.dart       # 喇叭图标、声波动效、气泡、首次提示

assets/
├── data/                         # 720 字数据 + 笔顺矢量数据
├── onboarding/                   # 四页新手引导插图（webp，中英双语）
├── images/                       # 720 张 WebP 插画
├── fonts/                        # 楷体子集字体
├── branding/                     # 图标 / 启动图源图与生成素材
└── audio/                        # 内置朗读音频（chars / words / sentences + manifest.json）

scripts/
├── generate_images_nanobanana.py # 批量生成配图
├── generate_audio.py             # 批量生成离线朗读音频
├── build_meanings_en.py          # 由 CC-CEDICT + 人工译文生成 meanings_en.json
├── data/
│   ├── sent_en.tsv               # 706 条例句英文译文
│   └── word_en_extra.tsv         # 172 条补充组词词义
├── make_brand_assets.py          # 由 1024 源图生成图标 / 启动图素材
├── fetch_stroke_data.py          # 生成笔顺矢量数据
├── crop_hanzi_grid.py            # 四宫格切图（旧版）
└── crop_hanzi_gridv2.py          # 四宫格切图（新版）
```

---

## 三、使用方式

1. 打开 App 进入“选择学习阶段”首页（首次安装会先弹出四页使用说明，可跳过，之后点右上角「?」重看）
2. 点右上角语言按钮可在中文 / English 之间切换；汉字与朗读内容仍保持中文
3. 默认“按主题”：点某个阶段的卡片 → 查看 30 课 → 点某一课开始学习
4. 也可以切换“按部首”“按笔画”，点分组进入汉字网格，再点任意字学习
5. 学习页左右滑动切换汉字；点汉字 / 词语 / 句子 / 图片都可以朗读
6. 一课 4 个字都看过后，在最后一页继续左滑会自动进入下一课；在本课第一页继续右滑则回到上一课（停在它的最后一个字）
7. 点“笔顺演示”看动画；直接在田字格里写即可进入手写描红
8. 点卡片右上角星标收藏；回首页底部进入“收藏复习”
9. 学习页右上角的 **EN** 胶囊开关控制英文释义：中文界面默认关，其它语言默认开；释义不可点读

---

## 四、开发与构建

```bash
flutter pub get
flutter test                          # 含 360dp 宽度布局检查
flutter build apk --release           # 产物：build/app/outputs/flutter-apk/HanziRoots-v1.3.1.apk
```

安装到设备：

```bash
adb install -r build/app/outputs/flutter-apk/HanziRoots-v1.3.1.apk
```

### 在 Android TV / 投影仪上安装

已实测坚果 S700 投影仪（Android 11、armeabi-v7a、1920×1080）：

```bash
adb connect 192.168.0.16:5555          # 投影仪需开启「网络调试 / ADB 调试」
adb install -r build/app/outputs/flutter-apk/HanziRoots-v1.3.1.apk
adb shell am start -n com.ailexin.HanziRoots/com.ailexin.HanziRoots.MainActivity
```

注意事项：

- 通用 APK 已包含 `armeabi-v7a`，32 位电视盒子 / 投影仪可直接安装
- 横屏 1920×1080 下内容按 `ContentFrame` 居中（720dp），列表与学习卡片显示正常
- **遥控器操作**（无触摸屏的设备）：
  - **方向键 ← / →**：课内切换到上一个 / 下一个字；已经在最后一页再按 → 直接进下一课，在第一页再按 ← 回到上一课最后一个字
  - **OK / 确认键**：重播当前字的读音
  - **飞鼠 / 鼠标指针**：按住拖动即可翻页（`AppScrollBehavior` 已把 `mouse` 加入 `dragDevices`，Flutter 默认不接收鼠标拖拽）
  - 课程列表、阶段卡片本身是 `InkWell`，方向键上下移动焦点、OK 进入
- **朗读**依赖系统 TTS 引擎。坚果 S700 自带系统里没有中文 TTS（只有语音助手 `com.jmgo.ai.voice`），已实测安装离线引擎并可正常朗读：

  ```bash
  # sherpa-onnx 离线中文 TTS 引擎（126 MB，无需 GMS / 联网）
  adb install -r sherpa-onnx-1.12.22-armeabi-v7a-zh-tts-engine-vits-zh-hf-fanchen-ZhiHuiLaoZhe.apk
  adb shell settings put secure tts_default_synth com.k2fsa.sherpa.onnx.tts.engine
  adb shell settings put secure tts_enabled_plugins com.k2fsa.sherpa.onnx.tts.engine
  ```

  - 引擎包名：`com.k2fsa.sherpa.onnx.tts.engine`，自带中文模型，语速可在其设置页调节
  - 未装引擎时进入学习页会提示“没有可用的中文语音”，属于预期行为
  - Google 文字转语音在该机型上不可行：系统无 GMS，中文语音包依赖 Google 服务在线下载
- 部分坚果机型带“学习模式 / 题了个题”桌面，会盖住第三方应用；按返回键或退出学习模式即可
- 遥控器若支持空鼠 / 鼠标模式，可直接点击；纯方向键下 Flutter 的默认焦点高亮较淡

### 应用标识与 APK 命名

| 项目 | 值 |
| --- | --- |
| 应用包名（applicationId / namespace） | `com.ailexin.HanziRoots` |
| 启动 Activity | `com.ailexin.HanziRoots.MainActivity` |
| APK 文件名 | `HanziRoots-v<版本号>.apk`，版本号取自 `pubspec.yaml` 的 `version` |
| 当前产物 | `build/app/outputs/flutter-apk/HanziRoots-v1.3.1.apk` |
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
cp build/ios/ipa/Runner.ipa build/ios/ipa/HanziRoots-v1.3.1.ipa
```

#### 三、用 GitHub Actions 生成 ipa（无需 Mac、无需付费账号）

仓库已带工作流 `.github/workflows/ios-unsigned-ipa.yml`：在 GitHub 的 macOS runner
上跑 `flutter build ios --release --no-codesign`，把 `Runner.app` 打成
`Payload/` 结构的**未签名 ipa**，作为 artifact 上传。

> 未签名 ipa 不能直接双击安装，也不能传 App Store；下载后用 Sideloadly / AltStore
> 等工具拿你的 **免费 Apple ID 在本地重新签名**，才能装进 iPhone / iPad。

**1. 触发构建**

- 手动：仓库页面 → **Actions** → 左侧 `Build unsigned iOS IPA` → **Run workflow**
- 自动：推送 `v*` 标签时触发，例如 `git tag v1.0.0 && git push origin v1.0.0`

一次完整构建约 8–15 分钟。

**2. 下载 ipa**

构建完成后进入这次 run 的页面，底部 **Artifacts** → 下载
`HanziRoots-unsigned-ipa-r<构建号>`，解压得到 `HanziRoots-unsigned-<构建号>.ipa`。
artifact 默认保留 30 天，需要长期保存请自己转存。

**3. 用免费 Apple ID 安装**

推荐 [Sideloadly](https://sideloadly.io/)（Windows / macOS 都有）：

1. 电脑安装 Sideloadly，iPhone 用数据线连电脑
2. 把 `.ipa` 拖进 Sideloadly，`Apple account` 填自己的 Apple ID
3. 点 **Start**，按提示输入 Apple ID 密码 / 双重认证验证码
4. iPhone 上「设置 → 隐私与安全性 → 开发者模式」打开并重启（iOS 16+ 必须）
5. 「设置 → 通用 → VPN 与设备管理」里信任刚生成的开发者证书

也可以用 [AltStore](https://altstore.io/)：电脑装 AltServer，手机装 AltStore，
在 AltStore 的 `My Apps` 里用 `+` 选择 ipa 安装，之后每周在同一 Wi-Fi 下自动续签。

**免费账号的限制**

| 限制 | 说明 |
| --- | --- |
| 有效期 7 天 | 到期 App 打不开，重新用 Sideloadly 装一次即可，数据通常保留 |
| 最多 3 个 App | 同一 Apple ID 同时签名的 App 数量 |
| 每周 10 个 App ID | 频繁改 Bundle Identifier 会更快耗尽额度 |
| 无推送等能力 | 本 App 只用了 `flutter_tts` / `shared_preferences`，不受影响 |

**4. 注意事项**

- 每次发新版本前先把 `pubspec.yaml` 的 `version: 1.3.1+5` 里的 build 号 `+1` 递增
- 免费签名和 Bundle Identifier 绑定；如果 `com.ailexin.HanziRoots` 在你的账号下
  已被占用，改成自己的（见上一节），并同步 `android/app/build.gradle.kts`
- GitHub Actions 的 macOS 分钟数：公开仓库免费；私有仓库按 10 倍计费
  （免费额度 2000 分钟/月 ≈ 200 分钟 macOS，约 15–20 次构建）

#### 四、iPhone / iPad 适配现状

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

#### 五、上架前清单

1. **图标**：已生成 iOS / Android 全尺寸（含自适应图标）。上架前确认 App Store Connect 的 1024 图标与 `assets/branding/app_icon.png` 一致
2. **启动图**：已生成，iPhone / iPad / Android 12+ 均为米色底 + 居中 Logo
3. **版本号**：已是 `1.2.0+3`，iOS 的 `CFBundleShortVersionString` / `CFBundleVersion` 自动取这两个值；每次提审 build 号必须递增
4. **隐私清单**：`ios/Runner/PrivacyInfo.xcprivacy` 已提供（声明 `UserDefaults` 用途 CA92.1）。**需在 Xcode 里把它拖进 Runner target 的 Copy Bundle Resources**，只放文件不生效
5. **App Store 资料**：中英文名称、副标题、截图（6.7"/6.5"/12.9" iPad）、隐私政策 URL（本 App 不收集数据，填“不收集”）
6. **体积**：图片 26.8 MB + 笔顺 1.6 MB + 音频 28.5 MB，IPA 约 95–105 MB，仍在 200 MB 蜂窝下载限制内

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
13. 首页右上角语言菜单能否在中 / 英 / 日 / 韩 / 越之间切换，退出重进后是否保持
14. 英文界面下阶段 / 课程 / 部首 / 笔画 / 学习卡片 / 收藏页文案是否完整，360dp 窄屏是否不溢出
15. 在**没有中文 TTS 引擎**的设备（坚果投影仪）上，点读是否仍有声音（走内置音频）
16. 学习页 **EN** 开关是否可显示 / 收起释义，切换后退出重进是否保持；点释义行是否不发声
17. 第 2 课第一页右滑是否直接回到第 1 课「四」；第 1 课第一页右滑是否不再变化；最后一页左滑是否仍进下一课，且下一课停在第 1 个字、读音完整不被截断
18. 句子区是否已没有「朗读中」三个字，朗读时只有喇叭动效
19. 全新安装后是否自动弹出四页图片引导，左滑能否翻到下一页；点「跳过 / 开始学习」后重进不再弹出；右上角「?」能否重看
20. 把手机系统语言改成日语 / 韩语 / 越南语后全新安装，首次界面是否直接是对应语言；改回中文或法语时是否回落中文界面
21. 学完一课（含继续左滑进下一课的情况）后按左上角返回，课程列表里的这一课是否**立刻**显示已学字数 / 已完成，不需要再进一次
22. 在投影仪 / 电视上用遥控器：← / → 能否翻字并跨课、OK 能否重播当前字；用飞鼠按住拖动能否翻页

---

## 七、更新日志

### 2026-11

- **手势与文案打磨（1.3.1）**
  - 新增「第一页右滑回上一课」：在第 2 课第一页右滑直接回到第 1 课，并停在它的最后一个字；第 1 课再右滑无反应
  - 右滑导航改为手指离开屏幕后再触发，避免新页被同一段滑动继续带跑
  - 删除句子区的「朗读中」标签，朗读时只保留喇叭声波动效
  - 修复「划到下一课时读音很短促」：旧学习页被替换后，转场结束时不再无条件停止朗读（只停本课自己的音频），新页的读音完整播完
  - 修复「左滑进下一课偶尔连跳几课 / 跳到第 7 课」：跨课进入的下一课固定停在第 1 个字，不再沿用该课上次停下的最后一个字
  - 修复「学完一课返回，课程卡片还是 0 / 4 字」：返回列表时用 `RouteObserver.didPopNext` 重新读进度；跨课滑动会让原来的 `await push` 提前结束，之前那种写法不会再刷新
  - 支持电视 / 投影仪：遥控器 ← / → 翻字与跨课、OK 重播当前字；飞鼠 / 鼠标按住拖动也能翻页（`dragDevices` 增加 `mouse`）
  - 新增首次启动四页新手引导（阶段检索 / 四区点读 / 笔顺描红 / 五语·释义·跨课手势），看过一次不再弹，右上角「?」可重看
  - 引导页改为**图片版**：四张 `assets/onboarding/onboarding_step_*.webp`（中英双语、标题与要点已排进图里），左滑进入下一步，底部圆点同步
  - 首次安装的界面语言改为跟随手机系统语言（中/英/日/韩/越），未支持的系统语言回落中文；手动选过语言后以保存值为准，EN 释义默认值同步跟随
- **英文释义（1.3.0）**
  - 单字 / 组词 / 例句各加一行英文释义，学习页右上角 **EN** 开关整体控制
  - 中文界面默认关、其它语言默认开；释义不可点读，不影响田字格、词块、例句的既有点读
  - 数据独立成 `assets/data/meanings_en.json`（720 字 / 1926 词 / 706 句），缺条目自动不显示
  - 单字与组词按「数据标注的读音」精确匹配 CC-CEDICT，多音字不会串义；另加约 60 处人工覆盖
  - 新增 `scripts/build_meanings_en.py`、`scripts/data/sent_en.tsv`、`scripts/data/word_en_extra.tsv`
  - 释义后台加载并监听刷新，不阻塞首帧
- **内置朗读音频（1.2.0）**
  - 720 单字 + 1954 组词 + 706 例句（去重后 3380 条，28.5 MB）全部离线打包，彻底不依赖系统 TTS
  - 播放优先级：内置音频 → 系统 TTS → 提示（缺文件也不会哑）
  - 多音字用同音字合成校正（长→常、干→竿、教→蕉…），读音可控可校对
  - 新增 `scripts/generate_audio.py`，支持断点续跑与 `--limit` 试听
  - Android / iOS 统一用 `just_audio` 播放 mp3，无额外权限
- **多语言界面（1.1.0）**
  - 新增日本語 / 한국어 / Tiếng Việt 三套界面文案，加上原有中英文共五种
  - 语言入口改为菜单，胶囊按钮显示当前语言（中 / EN / 日 / 한 / VI），选择结果本地保存
  - 笔顺名称增加日文、韩文映射（横 / 縦 / 左払い、가로 / 세로 / 왼삐침）
  - 阶段名、课名、进度、田字格状态、收藏页、TTS 提示全部按语言本地化
  - 修复越南语 “Giai đoạn” 阶段标题在 360dp 窄屏下溢出的问题
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
  - 720 张配图由 GIF 全量替换为 WebP；内置音频后 APK 约 109 MB
  - 全量校对 720 字、2160 个组词、720 个例句的拼音与声调
- **中英文界面**
  - 开屏右上角新增语言切换按钮，支持中文 / English
  - 全站文案集中到 `lib/l10n/app_strings.dart`，切换即时生效并本地保存
  - 笔顺名称增加英文映射，英文界面下显示 horizontal / vertical 等
  - 学习内容（汉字、拼音、组词、例句）保持中文，朗读仍为中文
- **应用标识与产物命名**
  - 包名由 `com.example.untitled` 改为 `com.ailexin.HanziRoots`，MainActivity 同步迁移
  - APK 产物自动命名为 `HanziRoots-v<版本号>.apk`，例如 `HanziRoots-v1.3.1.apk`
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
