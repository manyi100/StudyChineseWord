# 上架资料（Google Play）

这个目录同时充当 **GitHub Pages** 站点根目录，用于给 Google Play 提供一个公网可访问的隐私政策 URL。

## 文件

| 文件 | 用途 |
| --- | --- |
| `index.html` | 落地页（可选） |
| `privacy-policy.html` | **隐私政策**（中英双语，Play Console 必填 URL） |
| `terms-of-service.html` | **服务条款**（中英双语，交易者身份需填；非交易者也建议保留） |
| `app-icon-512.png` | 商店图标 512×512（由脚本生成） |

## 部署到 GitHub Pages

1. 仓库已推送到 GitHub：`https://github.com/manyi100/StudyChineseWord`。
2. 仓库 **Settings → Pages**：
   - Source 选 `Deploy from a branch`
   - Branch 选 `main`，目录选 **`/docs`**
3. 保存后等待 1–2 分钟，访问：
   - 隐私政策：`https://manyi100.github.io/StudyChineseWord/privacy-policy.html`
   - 英文版：`https://manyi100.github.io/StudyChineseWord/privacy-policy.html?lang=en`
4. 把该 URL 填到 **Play Console → 应用内容 → 隐私政策**。

## 上架前必须替换

- `manyi100@gmail.com`：当前用的是本机 git 配置里的邮箱，请确认这是你愿意公开的支持邮箱（建议单独注册一个，避免个人邮箱暴露）。
- 生效日期：`privacy-policy.html` 中的 `2026 年 11 月 17 日`，如果你延期上架请同步修改。

## 与 Play「数据安全」表单保持一致

本政策声明：**不收集、不共享任何数据**。填写 Play Console 表单时请选择：

- 是否收集或共享任何必需的用户数据类型：**否**
- 是否有独立的安全实践：可不填
- 是否遵循 Families 政策：目标受众含儿童时必须勾选

如果以后加入联网、账号、统计或广告，务必先更新本政策再发版，否则会因「政策与表单不一致」被拒。
