# HanziRoots（入学必备 720 字）核心卖点与五语使用说明

> **版本信息**：`v1.3.1`（Build 5） | **应用包名**：`com.ailexin.HanziRoots` | **支持平台**：Android 手机/平板、iPhone/iPad、Android TV/智能投影仪  
> **开源资源鸣谢**：笔顺矢量数据基于 [Make Me a Hanzi](https://github.com/skishore/makemeahanzi)，楷体字形采用 [LXGW WenKai（霞鹜文楷）](https://github.com/lxgw/LxgwWenKai)。

## 第一部分：App 核心卖点（Core Selling Points）

### 1. 科学阶段化闯关 + 三维立体检索体系
* **6 大阶段、180 门主题课、720 个高频字**：摒弃容易误导的“一年级/二年级”教材标签，将 720 个入学核心汉字按难度与主题相关性划分为 **6 个阶段**，每阶段 **30 课**，每课聚焦 **4 个主题相近的汉字**。
* **循序渐进的闯关解锁机制**：第 1 阶段默认开启，学完当前阶段全部 120 字后自动解锁下一阶段，并提供“已解锁阶段连续学”模式，兼顾成就感与系统性。
* **三种检索维度自由切换**：首页顶部支持 **按主题**（阶段 → 30 课列表 → 4 字卡片）、**按部首**（174 个部首按所含字数排序，如“木 41 字、氵 38 字、口 29 字、扌 26 字”）和 **按笔画**（1~3 画、4~5 画、6~7 画、8~9 画、10~12 画、13 画以上共 6 档）多维查字与专项学习。

### 2. “字、音、形、义、画”五位一体沉浸式学习卡片
* **叙事级高清无字插画**：内置 720 张 `526×290` WebP 高清插画，画面紧扣例句情境，按真实宽高比完整铺满且无文字遮挡，看图即可联想字义与句意。
* **规范四线三格与田字格楷体**：配备标准拼音四线三格与田字格大字（内置 [LXGW WenKai](https://github.com/lxgw/LxgwWenKai) 楷体子集，字形端正优美）。
* **全量精校的词句体系**：每字精选 **3 个常用组词**（共 2,160 词，单行三等分防换行排版）与 **1 条情境例句**（共 720 句）。全部字、词、句均经过系统声调与多音字校对（如名词后缀“子”轻声规范、易错多音字修正）。

### 3. 智能笔顺动画演示 + 手指跟写描红纠错
* **自动逐笔动画演示**：内置 720 字离线笔顺矢量骨架数据（源自 [Make Me a Hanzi](https://github.com/skishore/makemeahanzi)），打开卡片自动按正确笔顺逐笔描出，支持随时重播。
* **高精度手指跟写描红**：当前笔画以浅红底高亮提示，清晰标出**起笔红点、虚线走向与收笔箭头**；实时校验起笔位置、收笔位置、书写方向和轨迹贴合度。写对自动进入下一笔并在完成时给出鼓励提示；写错或轻点田字格会自动演示当前笔画。
* **防误触独立手势识别**：田字格区域采用独立手势拦截，书写“横”画或折笔时不会误触发卡片左右翻页。

### 4. 全离线 3,380 条高质量点读音频（零网络、零 TTS 依赖）
* **全量随包离线音频**：内置 **720 个单字 + 1,954 个去重组词 + 706 条去重例句**，共 **3,380 条** 24kHz MP3 语音（仅占 28.5 MB），并对多音字采用同音字合成校正（如“长 cháng”、“干 gān”、“教 jiāo”等）。
* **三级容错播放策略**：优先播放内置音频，查不到时回退系统 TTS，无引擎时弹出引导提示——即使在海外无中文语音包的设备、无 GMS 平板、电视盒子或投影仪上也能即点即读、绝不静音。
* **四区点读与动态声波反馈**：汉字、组词、例句、插画全部支持点读。点击插画会按“**例句 → 第一个组词 → 单字**”顺序连贯朗读并浮出句子气泡；连续点击不同区域会自动打断上一段音频，绝不串音。

### 5. 汉字文化圈五语界面 + 一键 EN 英文释义辅助
* **五国语言界面即时切换**：支持 **简体中文（中）、英语（EN）、日语（日）、韩语（한）、越南语（VI）** 五套完整界面文案，连带笔顺名称同步本地化（日文“横 / 縦 / 左払い”、韩文“가로 / 세로 / 왼삐침”、英越“horizontal / vertical”），而核心学习内容与发音保持纯正中文。
* **独立 EN 英文释义开关**：学习页右上角设有 **EN** 胶囊按钮，可一键开启/隐藏单字（720 条）、组词（1,926 条）、例句（706 条）的英文释义（基于 CC-CEDICT 按精确读音匹配 + 人工精译）。中文界面默认关闭，非中文界面默认开启；释义行采用防误触（`IgnorePointer`）与收起零占位设计，不干扰点读操作。

### 6. 直觉式跨课手势、本地记忆与全平台护眼适配
* **无缝跨课滑动**：学完一课 4 字后在末页继续左滑，直接进入下一课；在当前课第 1 页继续右滑（松手触发），直接回到上一课最后一个字。
* **星标收藏与断点续学**：支持卡片右上角一键星标收藏，并在首页底部“收藏复习”中集中巩固；自动记忆每个阶段、每门课、每个部首及笔画分组的上次学习位置。
* **跨设备响应式体验与零隐私收集**：支持手机竖屏、iPad/平板四向旋转与电视/投影仪 1080P 横屏居中显示（`ContentFrame` 720dp 居中约束 + 360dp 窄屏防溢出），完全离线运行，不收集任何用户个人数据。

### 核心卖点速览表（五语市场定位对照）

| 核心维度 | 关键指标与技术亮点 | 解决的核心痛点 |
| :--- | :--- | :--- |
| **课程体系** | 6 阶段 × 30 课 × 4 字 = 720 字；支持按主题 / 174 部首 / 6 档笔画检索 | 解决传统识字书缺乏多维检索、按年级划分易与学校教材混淆的问题 |
| **书写训练** | 离线矢量笔顺动画 + 起笔/走向/收笔实时描红校验 + 田字格独立手势防误滑 | 解决儿童只认不写、倒插笔、在屏幕上写“横”画容易误翻页的痛点 |
| **离线点读** | 内置 3,380 条校准音频（字/词/句全覆盖）+ 插画三连读气泡反馈 | 解决海外设备、投影仪、平板无中文 TTS 导致无法发声或多音字误读的问题 |
| **多语与释义** | 中/英/日/韩/越五语 UI + 笔顺名称本地化 + 独立 EN 英文释义开关 | 解决非中文母语学习者及海外家长看不懂界面、理解字词句含义困难的痛点 |
| **隐私与跨端** | 100% 离线可用、零数据收集、适配 iPhone/iPad/Android 手机及 TV 投影仪 | 解决儿童 App 广告干扰、网络依赖及大屏设备排版变形的问题 |

## 第二部分：五国语言使用说明（Multilingual User Guides）

### 1. 中文使用说明（简体中文）

#### 应用简介
**入学必备 720 字（HanziRoots）** 是一款专为学龄前与低年级儿童、海外华裔少儿以及全球中文初学者打造的离线汉字学习应用。应用精选 720 个高频核心汉字，集**情境插画、标准拼音、笔顺动画、手写描红、真人级离线点读、英文释义辅助**于一体，无需联网即可随时随地高效识字。

#### 快速上手指南
1. **切换界面语言**：打开应用进入首页，点击右上角的语言胶囊按钮（显示 `中` / `EN` / `日` / `한` / `VI`），即可在中文、英语、日语、韩语、越南语五种界面语言间切换。切换后汉字与发音仍保持纯正中文，设置会自动保存。
2. **选择浏览与学习模式**：
   * **按主题（默认）**：首页展示第 1~6 阶段卡片（显示已学字数、完成课数与进度条）。点击任一已解锁阶段可查看 30 门主题课（每课 4 个汉字），点击课程即可开始学习；也可点击“已解锁阶段连续学”连贯学习所有已解锁汉字。
   * **按部首**：切换至顶部“按部首”标签，从 174 个常用部首分组中选择目标部首进入汉字网格。
   * **按笔画**：切换至顶部“按笔画”标签，按 1~3 画、4~5 画、6~7 画、8~9 画、10~12 画、13 画以上六个区间查找汉字。
3. **四区互动点读（即点即听）**：
   * **点田字格汉字**：朗读当前单字标准发音。
   * **点组词词块**：朗读对应词语，词块高亮变绿且小喇叭动态跳动。
   * **点例句喇叭**：朗读完整例句，读完自动恢复。
   * **点顶部插画**：按“**例句 → 第一个组词 → 单字**”顺序依次朗读，同时图片底部浮出例句气泡提示。
4. **观看笔顺与手指描红**：
   * 打开汉字卡片时会自动按笔顺逐笔动画演示，点击**“笔顺演示”**可随时重播。
   * 直接用手指在田字格内书写即可进入**手写描红模式**：跟随浅红底高亮笔画，从**红点**起笔，沿**虚线**写向**箭头**收笔。写对自动进入下一笔，全部写完会有鼓励提示；写错或轻点田字格会自动演示当前笔画。
5. **开启或关闭英文释义（EN 开关）**：点击学习页右上角的 **EN** 胶囊按钮，可一键显示或隐藏单字、组词和例句的英文翻译（中文界面默认关闭，其他语言界面默认开启）。英文释义仅作理解辅助，点击不会触发朗读。
6. **翻页与跨课手势**：
   * 左右滑动屏幕可在当前课程的 4 个汉字间切换。
   * **左滑进下一课**：看完本课全部 4 个汉字后，在最后一页继续左滑即可直接进入下一课。
   * **右滑回上一课**：在本课第 1 页继续右滑并松手，可直接返回上一课的最后一个字。
7. **星标收藏与集中复习**：点击卡片右上角（插画右上角）的**星标图标**即可收藏重点或难记汉字。返回首页底部点击**“收藏复习”**，即可对所有收藏汉字进行专项巩固。
8. **阶段解锁与进度记忆**：学完当前阶段的全部 120 个汉字后，下一阶段自动解锁。所有已学状态、收藏列表及各分类上次学习位置均自动保存在本地，退出应用不会丢失。

### 2. English User Guide (英文使用说明)

#### Overview
**HanziRoots (Essential 720 Chinese Characters)** is a 100% offline Chinese character learning app designed for preschoolers, early elementary students, heritage learners, and global Mandarin beginners. Featuring **720 essential Chinese characters**, the app combines story-driven illustrations, standard Pinyin, animated stroke order, interactive finger tracing, built-in offline audio, and toggleable English meanings—all with zero ads and complete offline privacy.

#### Step-by-Step User Guide
1. **Switch Interface Language**: Tap the language pill button in the top-right corner of the home screen (`中` / `EN` / `日` / `한` / `VI`) to switch the interface between Chinese, English, Japanese, Korean, and Vietnamese. All learning content and audio remain in authentic Mandarin Chinese, and your language preference is saved automatically.
2. **Choose How You Browse & Learn**:
   * **By Topic (Default)**: Progress through **Stages 1 to 6** (30 thematic lessons per stage, 4 related characters per lesson, 720 characters in total). Stage 1 is unlocked by default; completing all 120 characters in a stage unlocks the next stage. You can also tap **Continuous Study** to review all unlocked characters sequentially.
   * **By Radical**: Switch to the **Radicals** tab at the top to browse characters grouped across 174 Chinese radicals (sorted by character count).
   * **By Stroke Count**: Switch to the **Strokes** tab to explore characters grouped into 6 stroke-count tiers (1–3, 4–5, 6–7, 8–9, 10–12, and 13+ strokes).
3. **Tap Anywhere to Hear Native Audio**:
   * **Tap the Character Grid (Tian Zi Ge)**: Hear the individual character's pronunciation.
   * **Tap Any Word Chip**: Hear the compound word read aloud while the chip highlights in green with an animated speaker icon.
   * **Tap the Sentence Speaker**: Hear the full example sentence read aloud.
   * **Tap the Illustration**: Trigger a guided audio sequence (**Example Sentence → First Word → Single Character**) accompanied by a floating sentence bubble at the bottom of the picture.
4. **Watch Stroke Order & Practice Finger Tracing**:
   * Every card automatically plays a stroke-by-stroke animation when opened. Tap **Stroke Demo** anytime to replay it, and view localized stroke names (e.g., *horizontal*, *vertical*, *left-falling*).
   * Draw directly inside the character grid with your finger to start **Guided Tracing**: follow the light-red highlighted stroke from the **red starting dot**, along the **dashed path**, to the **ending arrow**. Correct strokes advance automatically with encouraging feedback upon completion; tapping the grid or making a mistake replays the current stroke demonstration. Independent touch recognition prevents horizontal strokes from accidentally flipping the page.
5. **Toggle English Meanings (`EN` Button)**: Tap the **EN** pill button in the top-right corner of the study screen to show or hide English definitions for the character, compound words, and example sentence (enabled by default in English, Japanese, Korean, and Vietnamese interfaces; disabled by default in Chinese). English meanings are touch-transparent so they never interfere with audio playback.
6. **Swipe & Cross-Lesson Navigation**:
   * Swipe left or right to move between the 4 characters in a lesson.
   * **Swipe Left to Next Lesson**: Once all 4 characters in the current lesson have been viewed, swipe left on the last page to jump straight into the next lesson.
   * **Swipe Right to Previous Lesson**: Swipe right and release on the first page of a lesson to return directly to the last character of the previous lesson.
7. **Bookmark Favorites & Review**: Tap the **Star icon** in the top-right corner of any card to bookmark challenging characters. Tap **Favorites Review** at the bottom of the home screen to practice all your starred characters in one place.
8. **Automatic Progress Saving**: Every viewed character, lesson progress bar, bookmark, and last-visited position across stages, radicals, and stroke groups is automatically saved on your device.

### 3. 日本語ご利用ガイド (日文使用说明)

#### アプリ概要
**HanziRoots（入学必須 720 字）** は、就学前〜小学校低学年の子どもや、世界中の中国語（普通話）初学者のために設計された**完全オフライン対応の中国語漢字学習アプリ**です。基礎となる **720 個の重要漢字**を厳選し、ストーリー性のあるイラスト、ピンイン（四線三格）、書き順アニメーション、指でなぞる書き取り練習、3,380 件の内蔵音声、英語意味表示機能をひとつに凝縮しています。

#### 使い方ガイド
1. **表示言語の切り替え**：ホーム画面右上の言語ボタン（`中` / `EN` / `日` / `한` / `VI`）をタップすると、アプリのUI表示を日本語・中国語・英語・韓国語・ベトナム語の5言語に切り替えられます。学習する漢字・ピンイン・音声はすべて中国語のままで、書き順の名称も日本語（横・縦・左払い・横折れ鉤など）で分かりやすく表示されます。
2. **3つの学習・検索モード**：
   * **テーマ別（デフォルト）**：**第1〜第6ステージ**（各ステージ30課、1課につき関連する漢字4字、計180課・720字）で構成されています。前のステージの120字をすべて学習すると次のステージが解放されます。「解放済みステージを連続学習」からまとめて復習することも可能です。
   * **部首別**：上部の「部首別」タブに切り替えると、174個の部首グループ（文字数順）から漢字を探せます。
   * **画数別**：上部の「画数別」タブに切り替えると、画数（1〜3画、4〜5画、6〜7画、8〜9画、10〜12画、13画以上）から漢字を検索できます。
3. **タップして発音を聞く（オフライン音声内蔵）**：
   * **田字格（漢字マス）をタップ**：漢字一文字の発音を再生します。
   * **単語（熟語）チップをタップ**：選択した単語を読み上げ、チップが緑色にハイライトされます。
   * **例文のスピーカーアイコンをタップ**：例文全体を読み上げます。
   * **イラストをタップ**：「**例文 → 1つ目の単語 → 漢字単体**」の順に連続で読み上げ、イラスト下部に例文の吹き出しが表示されます。
4. **書き順アニメーションと指なぞり練習（描紅）**：
   * カードを開くと正しい書き順アニメーションが自動再生されます。「書き順デモ」ボタンでいつでも再生できます。
   * 田字格の中を指で直接なぞると**書き取り練習モード**になります。薄赤色で示された現在の画を、**赤い始点**から**破線**に沿って**矢印の終点**までなぞってください。正しく書けると次の画に進み、書き間違えたり軽くタップした場合はお手本アニメーションが再生されます。マス内は独立したタッチ判定のため、「一（横画）」を書いてもページがめくれてしまうことはありません。
5. **英語訳の表示切り替え（`EN` ボタン）**：学習画面右上の **EN** ボタンをタップすると、単字・熟語・例文の英語訳を表示／非表示にできます（日本語UIでは初期状態でON）。
6. **スワイプ操作と課の移動**：
   * 左右にスワイプして課内の漢字を切り替えます。
   * **次の課へ進む**：1課4字をすべて見た後、最後のページでさらに左へスワイプすると自動的に次の課へ進みます。
   * **前の課へ戻る**：最初のページで右へスワイプして指を離すと、前の課の最後の漢字に直接戻ります。
7. **お気に入り登録と復習**：カード右上の**星マーク**をタップするとお気に入りに登録できます。ホーム画面下部の「お気に入り復習」から、登録した漢字を集中的に復習できます。
8. **学習進捗の自動保存**：学習済みの漢字や最後に開いていた位置、お気に入りデータはすべて端末内に自動保存されます。

### 4. 한국어 사용 가이드 (韩文使用说明)

#### 앱 소개
**HanziRoots(입학 필수 720자)**는 미취학 아동 및 초등 저학년 어린이부터 전 세계 중국어 입문자까지 누구나 쉽게 활용할 수 있는 **100% 오프라인 중국어 한자 학습 앱**입니다. 필수 기초 한자 **720자**를 엄선하여 상황별 일러스트, 한어병음, 필순 애니메이션, 손가락 따라 쓰기, 3,380개의 내장 음성, 영어 뜻풀이 기능을 모두 인터넷 연결 없이 제공합니다.

#### 상세 사용 방법
1. **인터페이스 언어 변경**: 홈 화면 오른쪽 상단의 언어 버튼(`中` / `EN` / `日` / `한` / `VI`)을 탭하여 한국어, 중국어, 영어, 일본어, 베트남어 중 원하는 UI 언어를 선택하세요. 한자와 발음 오디오는 중국어 원어민 표준으로 유지되며, 필순 명칭은 한국어(가로, 세로, 왼삐침 등)로 친절하게 표시됩니다.
2. **3가지 학습 및 탐색 모드**:
   * **주제별 학습(기본)**: **1~6단계**(단계별 30과, 과별 연관 한자 4자, 총 180과 / 720자)로 구성되어 있습니다. 이전 단계의 120자를 모두 학습하면 다음 단계가 잠금 해제되며, '잠금 해제된 단계 연속 학습' 기능도 지원합니다.
   * **부수별 탐색**: 상단 탭에서 '부수별'을 선택하면 글자 수 순으로 정렬된 174개 부수 그룹별로 한자를 모아 볼 수 있습니다.
   * **획수별 탐색**: 상단 탭에서 '획수별'을 선택하면 1~3획, 4~5획, 6~7획, 8~9획, 10~12획, 13획 이상의 6구간으로 나누어 한자를 찾을 수 있습니다.
3. **터치하여 발음 듣기 (내장 오프라인 오디오)**:
   * **한자 칸(전자격) 터치**: 해당 한자의 단자 발음을 들려줍니다.
   * **단어 칩 터치**: 3개의 필수 단어 중 터치한 단어를 읽어주며, 칩이 초록색으로 강조됩니다.
   * **예문 스피커 아이콘 터치**: 전체 예문을 자연스럽게 읽어줍니다.
   * **일러스트 이미지 터치**: '**예문 → 첫 번째 단어 → 단일 한자**' 순서로 연속 재생되며, 그림 하단에 예문 말풍선이 나타납니다.
4. **필순 애니메이션 및 손가락 따라 쓰기**:
   * 카드를 열면 올바른 필순 애니메이션이 자동 재생되며, 언제든 다시 볼 수 있습니다.
   * 한자 칸 안에 손가락으로 직접 글씨를 쓰면 **따라 쓰기 모드**가 시작됩니다. 연한 빨간색으로 표시된 현재 획을 **빨간색 시작점**에서 **점선**을 따라 **화살표 끝점**까지 그어 보세요. 시작점·방향·끝점이 맞으면 다음 획으로 넘어가며, 틀리거나 가볍게 탭하면 현재 획의 시범 애니메이션이 다시 재생됩니다. 한자 칸 내부는 독립된 제스처로 인식되어 가로획('一')을 그을 때 페이지가 넘어가지 않습니다.
5. **영어 뜻풀이 표시 스위치 (`EN` 버튼)**: 학습 화면 오른쪽 상단의 **EN** 버튼을 눌러 한자, 단어, 예문의 영어 번역을 켜거나 끌 수 있습니다(한국어 UI에서는 기본 켜짐). 뜻풀이 텍스트는 터치해도 오디오가 재생되지 않아 학습을 방해하지 않습니다.
6. **스와이프 및 단원 간 이동**:
   * 좌우로 스와이프하여 한 과의 4개 한자를 이동합니다.
   * **다음 과로 이동**: 한 과의 4글자를 모두 본 뒤 마지막 페이지에서 왼쪽으로 스와이프하면 바로 다음 과로 넘어갑니다.
   * **이전 과로 이동**: 첫 번째 페이지에서 오른쪽으로 스와이프한 뒤 손을 떼면 이전 과의 마지막 한자로 돌아갑니다.
7. **즐겨찾기 및 집중 복습**: 카드 오른쪽 상단의 **별 모양 아이콘**을 눌러 헷갈리는 한자를 저장하고, 홈 화면 하단의 **'즐겨찾기 복습'**에서 한꺼번에 복습할 수 있습니다.
8. **자동 진도 저장**: 학습 완료한 한자, 단계별 진행률, 마지막 학습 위치 및 즐겨찾기 목록은 기기에 자동 저장됩니다.

### 5. Hướng Dẫn Sử Dụng Tiếng Việt (越南文使用说明)

#### Giới thiệu ứng dụng
**HanziRoots (720 Chữ Hán Cần Thiết)** là ứng dụng học chữ Hán **hoạt động hoàn toàn ngoại tuyến (offline)** dành cho trẻ mầm non, học sinh tiểu học và người mới bắt đầu học tiếng Trung trên toàn thế giới. Ứng dụng tích hợp **720 chữ Hán cốt lõi** cùng tranh minh họa theo ngữ cảnh, Pinyin chuẩn, hoạt ảnh thứ tự nét viết, luyện tô chữ bằng ngón tay, 3.380 tệp âm thanh tích hợp sẵn và phần giải nghĩa tiếng Anh tiện lợi.

#### Hướng dẫn sử dụng chi tiết
1. **Chuyển đổi ngôn ngữ giao diện**: Nhấn vào nút ngôn ngữ ở góc trên bên phải màn hình chính (`中` / `EN` / `日` / `한` / `VI`) để chuyển đổi giao diện giữa Tiếng Việt, Tiếng Trung, Tiếng Anh, Tiếng Nhật và Tiếng Hàn. Nội dung chữ Hán và phát âm luôn giữ chuẩn tiếng Trung Phổ thông, cài đặt ngôn ngữ sẽ được lưu tự động.
2. **3 Chế độ duyệt và học chữ**:
   * **Theo chủ đề (Mặc định)**: Gồm **6 Giai đoạn** (mỗi giai đoạn 30 bài, mỗi bài 4 chữ Hán cùng chủ đề, tổng cộng 180 bài / 720 chữ). Giai đoạn 1 được mở sẵn; sau khi học hết 120 chữ của giai đoạn hiện tại, giai đoạn tiếp theo sẽ tự động mở khóa. Bạn cũng có thể chọn học liên tục toàn bộ các giai đoạn đã mở khóa.
   * **Theo bộ thủ**: Chuyển sang tab **Bộ thủ** ở phía trên để tra cứu chữ Hán theo 174 bộ thủ (được sắp xếp theo số lượng chữ).
   * **Theo số nét**: Chuyển sang tab **Số nét** để tìm chữ Hán theo 6 nhóm nét viết (1–3 nét, 4–5 nét, 6–7 nét, 8–9 nét, 10–12 nét và từ 13 nét trở lên).
3. **Chạm để nghe phát âm chuẩn (Âm thanh tích hợp sẵn)**:
   * **Chạm vào ô chữ Hán (Ô Điền Tự)**: Nghe phát âm của từng chữ Hán.
   * **Chạm vào thẻ từ ghép**: Nghe phát âm của từ ghép, thẻ từ sẽ chuyển sang màu xanh lá cùng biểu tượng loa chuyển động.
   * **Chạm vào biểu tượng loa ở câu ví dụ**: Nghe đọc trọn vẹn cả câu ví dụ.
   * **Chạm vào tranh minh họa**: Ứng dụng sẽ đọc lần lượt theo thứ tự **"Câu ví dụ → Từ ghép đầu tiên → Chữ Hán đơn"** đồng thời hiển thị khung thoại câu ví dụ ở phía dưới bức tranh.
4. **Xem thứ tự nét viết & Luyện tô chữ bằng ngón tay**:
   * Khi mở thẻ học, ứng dụng tự động phát hoạt ảnh viết từng nét theo đúng thứ tự chuẩn; bạn có thể nhấn nút phát lại bất cứ lúc nào.
   * Dùng ngón tay viết trực tiếp vào ô chữ để vào **Chế độ luyện tô chữ**: viết theo nét được tô nền đỏ nhạt, bắt đầu từ **chấm đỏ**, kéo theo **đường nét đứt** đến **mũi tên kết thúc**. Nếu viết đúng điểm đầu, hướng nét và điểm cuối, ứng dụng sẽ tự động chuyển sang nét tiếp theo và khen thưởng khi hoàn thành; nếu viết sai hoặc chạm nhẹ vào ô, ứng dụng sẽ chiếu lại nét mẫu. Ô luyện viết nhận diện cử chỉ độc lập nên khi viết nét ngang ("一") sẽ không bị lật trang nhầm.
5. **Bật / Tắt giải nghĩa tiếng Anh (Nút `EN`)**: Nhấn vào nút **EN** ở góc trên bên phải màn hình học để hiện hoặc ẩn nghĩa tiếng Anh của chữ đơn, từ ghép và câu ví dụ (mặc định bật khi dùng giao diện Tiếng Việt, Tiếng Anh, Tiếng Nhật, Tiếng Hàn). Dòng nghĩa tiếng Anh không nhận cảm ứng đọc âm thanh nên không gây bấm nhầm.
6. **Cử chỉ vuốt chuyển trang và chuyển bài**:
   * Vuốt sang trái hoặc phải để chuyển đổi giữa 4 chữ Hán trong bài.
   * **Vuốt trái sang bài tiếp theo**: Sau khi đã xem đủ 4 chữ trong bài, vuốt tiếp sang trái ở trang cuối cùng để chuyển thẳng sang bài kế tiếp.
   * **Vuốt phải về bài trước**: Ở trang đầu tiên của bài, vuốt sang phải rồi thả tay để quay lại chữ cuối cùng của bài trước đó.
7. **Đánh dấu yêu thích & Ôn tập**: Nhấn vào **biểu tượng Ngôi sao** ở góc trên bên phải thẻ để lưu lại những chữ khó nhớ. Tại màn hình chính, nhấn vào mục **Ôn tập yêu thích** ở phía dưới cùng để ôn luyện tập trung.
8. **Tự động lưu tiến độ học tập**: Toàn bộ chữ đã học, tiến độ từng giai đoạn, danh sách yêu thích và vị trí học gần nhất đều được lưu tự động trên thiết bị của bạn.
