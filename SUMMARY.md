# 1.3.1 开发总结

> 版本：`1.3.1+5`（Build 5） | 包名：`com.ailexin.HanziRoots` | 签名：`CN=HanziRoots`
> 汇总时间：2026-11-18 | 五语使用说明见 [README_zh](README_zh.md) / [README_en](README_en.md) / [README_ja](README_ja.md) / [README_ko](README_ko.md) / [README_vi](README_vi.md)

---

## 一、本次做了什么

| 类别 | 内容 | 主要文件 |
|---|---|---|
| 手势 | 新增「本课第 1 页继续右滑 → 回到上一课最后一个字」；第 1 课右滑无反应 | `lib/screens/home_screen.dart`、`lib/screens/course_list_screen.dart` |
| 手势 | 右滑导航改为**松手后**触发，避免手指未抬起时新页被同一段滑动继续带跑 | `lib/screens/home_screen.dart` |
| 手势 | 左滑进下一课固定落在**第 1 个字**（不再沿用该课上次的最后一个字） | `lib/screens/course_list_screen.dart` |
| 文案 | 删除句子区「朗读中」标签，朗读只保留喇叭声波动效 | `lib/widgets/character_card.dart` |
| 新手引导 | 新增四页**图片版**引导（`assets/onboarding/*.webp`），左滑翻页，看完一次不再弹，右上角 `?` 可重看 | `lib/widgets/onboarding_dialog.dart`、`lib/l10n/app_strings.dart`、`lib/services/storage_service.dart`、`lib/screens/grade_select_screen.dart` |
| 多语言 | 首次安装**跟随手机系统语言**（中/英/日/韩/越），其它系统语言回落中文；手动选过语言后以保存值为准 | `lib/l10n/app_strings.dart` |
| 音频 | 修复「划到下一课读音很短促」：旧页 dispose 不再无条件停止朗读 | `lib/screens/home_screen.dart` |
| 进度 | 修复「学完一课返回，列表仍显示 0 / 4 字」：列表用 `RouteObserver` 在重新可见时刷新 | `lib/app_route_observer.dart`、`lib/main.dart`、`lib/screens/course_list_screen.dart` |

---

## 二、三个线上问题的根因

### 1. 划到下一课时读音「短促」

单字音频本身是 **0.98–1.15 秒**，实测同课内划字播放 **888 ms**（完整），只有跨课只响 **410 ms**。

```
22:32:46.468 AudioTrack start      ← 新一课开始朗读
22:32:46.878 ExoPlayerImpl Release ← 410ms 后被 stop，之后再无声音
```

原因：`pushReplacement` 后新学习页立即朗读，约 400 ms 后转场结束，**旧学习页 dispose 里的 `TtsService.stop()`** 把新页的声音掐掉了。

修复：`dispose()` 只在「当前朗读 tag 属于本课四个字」时才停止（tag 形如 `char_0001` / `word_0001_中国`），新页的朗读不再被旧页误停。

### 2. 左滑进下一课偶尔连跳几课 / 跳到第 7 课

原因：跨课进入时 `initialIndex` 传 `null`，于是读该课上次的进度——而这些课上次都停在最后一个字，从最后一页再划一下又会进下一课。

修复：跨课进入固定 `initialIndex: 0`（第一个字），右滑回上一课仍固定落在最后一个字。

### 3. 返回后课程没标记为已学

原因：列表刷新只靠 `await Navigator.push(...)` 后面的 `_load()`；而跨课用的是 `pushReplacement`，会让这个 await **提前完成**，之后按返回时列表不再刷新。

修复：新增全局 `appRouteObserver`，`CourseListScreen` 改 `RouteAware`，在 `didPopNext()` 里重新读进度。

---

## 三、验证

| 项 | 结果 |
|---|---|
| `flutter analyze` | 0 error / 0 warning |
| `flutter test` | 9 个用例全过（新增：图片引导、系统语言、下一课落在第 1 字、列表返回刷新） |
| 真机（小米 2509FPN0BC） | 跨课朗读 862 ms 完整；下一课落在第 1 字；右滑回上一课落在最后 1 字；返回后卡片立即刷新 |
| 回归用例有效性 | 临时注释 `didPopNext()` 后新用例失败，恢复后通过 |

测试覆盖的“反例”都在 `test/widget_test.dart` 里，改动相关逻辑时可直接跑：

```bash
flutter test
flutter build apk --release   # 产物：build/app/outputs/flutter-apk/HanziRoots-v1.3.1.apk
```

---

## 四、签名与安装注意

- 正式包使用 `android/app/upload-keystore.jks`（`android/key.properties`），证书 `CN=HanziRoots`；
- **debug 签名包与正式包不能互相覆盖**，混装会报 `INSTALL_FAILED_UPDATE_INCOMPATIBLE`，需先卸载（会清空本机进度与收藏）；
- 缺少 `key.properties` 时 Gradle 会回退到 debug 签名（`build.gradle.kts` 里有告警），只用于本地调试，禁止分发。

---

## 五、待办

1. 发布 `v1.3.1` Release：APK 已就绪；推 `v*` tag 触发 Actions 产出未签名 IPA 后补挂。
2. 投影仪（`192.168.0.16:5555`）当前离线，大屏排版仍待复验。
3. 引导图为中英双语静态图；如需日/韩/越版本，需要重新出图。
4. `app_strings.dart` 中早期四页文字版引导的标题/正文/标签文案暂时保留（现用于图片的无障碍标题），确认不再需要可清理。
