# GitHub OAuth 接入指南

> 适用于：Supabase Auth + GitHub OAuth Apps
> 完成后效果：用户可在登录页点击 "Continue with GitHub" 一键授权登录

---

## 前置条件

- 已有 Supabase 项目并开启 Authentication
- 已有 GitHub 账号，可访问 GitHub Developer Settings
- 前端登录页已集成 Supabase JS SDK（`sb.auth.signInWithOAuth`）

---

## 一、创建 GitHub OAuth App

进入：[github.com/settings/developers](https://github.com/settings/developers) → **OAuth Apps** → **New OAuth App**

| 字段 | 填写内容 |
|------|---------|
| Application name | `Habit Tracker`（用户授权时会看到此名称） |
| Homepage URL | `https://ghostwritten.github.io/Habit` |
| Application description | 可选，填写产品简介 |
| Authorization callback URL | `https://gwxncicsscmaxjxolvwu.supabase.co/auth/v1/callback` |
| Enable Device Flow | **不勾选**（Web 应用不需要） |

点击 **Register application**。

---

## 二、生成 Client Secret

在 OAuth App 详情页：

1. 复制页面顶部的 **Client ID**
2. 点击 **Generate a new client secret**
3. 立即复制 **Client Secret**

> ⚠️ Client Secret 只显示一次，关闭页面后无法再查看。
> 若遗失，需重新生成（旧 Secret 立即失效）。

> ⚠️ **常见错误**：复制 Client ID 时，不要把页面上的标签文字"Client ID"一起复制进去。
> 正确示例：`Ov23likp3iPUu9v7749Y`
> 错误示例：`Client ID Ov23likp3iPUu9v7749Y`（多了前缀，OAuth 请求会 404）

---

## 三、Supabase 配置

进入：**Supabase Dashboard → Authentication → Sign In / Providers → GitHub**

1. 打开启用开关
2. 填入：
   - **Client ID**：从 GitHub OAuth App 复制（仅填 ID 值，不含标签）
   - **Client Secret**：从 GitHub OAuth App 复制
3. 点击 **Save**

---

## 四、前端代码

Supabase JS SDK 调用方式（本项目 `auth.html` 已实现）：

```javascript
async function signInWithGitHub() {
  const { error } = await sb.auth.signInWithOAuth({
    provider: 'github',
    options: {
      redirectTo: window.location.origin + '/auth.html'
    }
  });
  if (error) console.error(error.message);
}

document.getElementById('btn-github').addEventListener('click', () => signInWithGitHub());
```

---

## 五、域名变更时的更新步骤

如果部署域名发生变化：

1. GitHub OAuth App → **Edit** → 更新 Homepage URL 和 Authorization callback URL
   - Homepage URL：新域名
   - Callback URL：Supabase Callback URL（通常不变）
2. Supabase → Authentication → URL Configuration → 更新 Site URL 和 Redirect URLs

---

## 六、常见问题

**Q: 点击 GitHub 登录后显示 404**
A: Client ID 填写有误，检查是否把标签文字"Client ID"一起粘贴进了 Supabase 的 Client ID 字段。只填 ID 值本身。

**Q: 授权后报错 "redirect_uri_mismatch"**
A: GitHub OAuth App 的 Authorization callback URL 与 Supabase Callback URL 不一致。检查是否有多余空格或 http/https 不匹配。

**Q: Client Secret 泄露了怎么办**
A: 立即在 GitHub OAuth App 详情页 → **Generate a new client secret**，旧 Secret 立即失效。在 Supabase 同步更新新 Secret。

**Q: 用户看到的授权页显示的是什么名称**
A: 显示 GitHub OAuth App 的 Application name（即 `Habit Tracker`），不是 Supabase 项目名。

---

*文档版本：v1.0 · 2026-06-06*
*适用项目：Habit Tracker*
