# Google Play 上架资料包

本目录包含上传 Google Play 所需的全部素材与文案，以及可重复生成的脚本。

## 目录结构

```
store/
├── assets/
│   ├── app-icon-512.png              商店图标 512×512 RGBA PNG（457 KB）
│   ├── feature-graphic-1024x500.png  特色图片 PNG
│   └── feature-graphic-1024x500.jpg  特色图片 JPG（上传用这个，体积更小）
├── screenshots/
│   └── zh/                           1080×1920 商店截图（含标题排版）
│       ├── 01-home.png               720 字，6 阶段循序渐进
│       ├── 02-lessons.png            30 门主题课，每课 4 字
│       ├── 03-stroke-order.png       笔顺演示 + 手指描红纠错
│       ├── 04-words.png              单字 · 组词 · 例句，一点即读
│       ├── 05-radicals.png           174 个部首，按部首查字
│       └── 06-strokes.png            按笔画难度，零基础也能学
├── raw/                              未排版原始截图（如需自行设计时使用）
└── listing.md                        5 语言商店文案（已校验字符上限）
```

## 上传顺序（Play Console）

1. **创建应用**：名称填 `入学必备720字 - 儿童识字启蒙`，默认语言选 `中文（简体）`，应用类型选「应用」，免费。
2. **商店设置 → 主要商店信息**：从 `listing.md` 复制对应语言的名称、简短说明、完整说明。
3. **商店设置 → 图形资源**：
   - 应用图标 → `assets/app-icon-512.png`
   - 特色图片 → `assets/feature-graphic-1024x500.jpg`
   - 手机截图 → `screenshots/zh/01..06.png`（按顺序上传，最多 8 张）
4. **应用内容**（逐项完成后才能发布）：
   - 隐私政策 → `https://<user>.github.io/StudyChineseWord/privacy-policy.html`
   - 广告 → 否
   - 应用访问权限 → 所有功能无需登录
   - 内容分级 → 填写 IARC 问卷（教育类，无暴力/无用户交互）
   - 目标受众 → 勾选儿童年龄段（会触发 Families 政策，本项目符合）
   - 数据安全 → **不收集、不共享任何数据**
   - 新闻/政府/金融/健康 → 全部否
5. **发布 → 内部测试**：上传 `build/app/outputs/bundle/release/app-release.aab`。
6. **封闭测试**：个人开发者账号需 12 名测试者连续 opt-in 14 天。
7. **申请生产权限** → 提交审核。

## 素材规格对照

| 素材 | 规格 | 状态 |
| --- | --- | --- |
| 应用图标 | 512×512，32 位 PNG，≤1 MB | ✅ 512×512 RGBA，457 KB |
| 特色图片 | 1024×500，JPG/PNG，≤15 MB | ✅ 1024×500 |
| 手机截图 | 1080×1920，2–8 张 | ✅ 6 张 |
| 7 寸平板截图 | 1200×1920 | ⬜ 可选，建议补 |
| 10 寸平板截图 | 1600×2560 | ⬜ 可选，建议补 |
| TV 横幅 | 320×180 | ⬜ 仅上架 TV 时需要 |

> 平板截图不影响审核，但缺失会降低大屏设备的推荐曝光。补拍方式见下方「重新生成截图」。

## 重新生成

```bash
# 商店图标 + 特色图片
python scripts/build_store_assets.py

# 重新抓取真实界面截图（需要先构建 web 并起本地服务）
flutter build web --release
python -m http.server 8765 --directory build/web
python scripts/shoot_flow.py            # 输出到 store/raw/
python scripts/build_screenshot_frames.py  # 排版到 store/screenshots/zh/

# 校验 5 语文案的字符数上限
python scripts/check_listing_lengths.py
```

截图脚本用 `360×640 @3x` 的真实手机逻辑尺寸渲染，得到的就是 App 的实际手机布局，不是拼贴图。

## 安全提醒

- `android/key.properties` 和 `android/app/upload-keystore.jks` 已加入 `.gitignore`，**不会被提交**。
- 请立即把这两个文件复制到密码管理器或离线加密盘：
  - 丢失上传密钥可向 Google 申请重置，但流程需要时间；
  - 泄露则他人可上传冒充包，务必保密。
- 上传签名证书 SHA-256：`C0:4D:1B:A6:C6:CE:F6:AB:1D:DA:95:5E:6D:83:44:E3:78:43:DB:05:61:E1:2A:06:46:0E:E6:74:05:53:8C:86`

## 待人工确认

1. **支持邮箱**：`docs/` 与 `listing.md` 里用的是 `manyi100@gmail.com`（取自本机 git 配置），如不想公开请替换。
2. **GitHub Pages**：按 `docs/README.md` 开启，拿到真实隐私政策 URL 后再填 Play Console。
3. **多语言截图**：目前只做了中文截图；英/日/韩/越商店页可复用同一批图，或把 App 切到对应语言后重跑截图脚本。
