# Supabase Auth 平台配置指南

> 本文档记录 Supabase 平台层的认证配置。
> 各 OAuth Provider 的接入细节见独立文档（如 `google-oauth-setup.md`）。

---

## 一、URL Configuration（必须配置，否则 OAuth 回调失败）

进入：**Supabase Dashboard → Authentication → URL Configuration**

### Site URL
填写生产环境主域名：
```
https://ghostwritten.github.io/Habit
```
这是 OAuth 登录成功后的默认跳转地址。若不配置，Supabase 回调到默认的 `localhost:3000`。

### Redirect URLs（允许跳转白名单）
每行一条，添加所有合法的回调地址：
```
https://ghostwritten.github.io/Habit/auth.html
http://localhost:3737/auth.html
```

> **常见问题：** Google/GitHub 登录后浏览器跳回 `localhost:3000` 并报"无法访问此网站"
> **原因：** Site URL 未设置，或 redirectTo 地址不在白名单内
> **修复：** 按上述配置填写 Site URL 和 Redirect URLs，保存即生效

---

## 二、Email Provider 配置

进入：**Supabase Dashboard → Authentication → Sign In / Providers → Email**

### Confirm email（邮件确认开关）

| 阶段 | 建议设置 | 原因 |
|------|---------|------|
| 验证期（当前）| **关闭** | 注册即可登录，减少流失；无需等待确认邮件 |
| 规模化后 | **开启** | 防止垃圾账号，提升账号安全性 |

> ⚠️ 关闭后，用户注册时不会收到确认邮件，直接登录成功。
> 开启时记得在 Email Templates 中自定义确认邮件内容，避免显示 Supabase 默认样式。

---

## 三、GitHub OAuth Provider

进入：**Supabase Dashboard → Authentication → Sign In / Providers → GitHub**

### 步骤 1 — 创建 GitHub OAuth App

前往：[github.com/settings/developers](https://github.com/settings/developers) → **New OAuth App**

| 字段 | 填写内容 |
|------|---------|
| Application name | `Habit Tracker` |
| Homepage URL | `https://ghostwritten.github.io/Habit` |
| Authorization callback URL | `https://gwxncicsscmaxjxolvwu.supabase.co/auth/v1/callback` |

创建后，在 App 详情页生成 **Client Secret**（只显示一次，立即复制）。

### 步骤 2 — 填入 Supabase

在 GitHub Provider 配置页：
- **Client ID**：从 GitHub OAuth App 复制
- **Client Secret**：从 GitHub OAuth App 复制
- 点击 **Save**

### 步骤 3 — 验证

在登录页点击 "Continue with GitHub"，用 GitHub 账号完成授权，确认跳回主页。

---

## 四、Google OAuth Provider

详见：[google-oauth-setup.md](google-oauth-setup.md)

---

## 五、配置检查清单

部署到新环境时，按此清单逐项确认：

```
□ Site URL 已设置为生产域名
□ Redirect URLs 包含生产域名 + 本地开发地址
□ Email Confirm 开关按当前阶段设置（验证期关闭）
□ Google Provider：Client ID + Secret 已填，Provider 已启用
□ GitHub Provider：Client ID + Secret 已填，Provider 已启用
□ Google Cloud Console：Authorized redirect URIs 包含 Supabase Callback URL
□ GitHub OAuth App：Callback URL 与 Supabase Callback URL 一致
```

---

*文档版本：v1.0 · 2026-06-06*
*适用项目：Habit Tracker*
