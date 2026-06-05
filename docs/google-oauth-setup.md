# Google OAuth 接入指南

> 适用于：Supabase Auth + Google Cloud Console（新版 Google Auth Platform 界面）  
> 完成后效果：用户可在登录页点击 "Continue with Google" 一键授权登录

---

## 前置条件

- 已有 Supabase 项目并开启 Authentication
- 已有 Google 账号，可访问 [Google Cloud Console](https://console.cloud.google.com)
- 前端登录页已集成 Supabase JS SDK（`sb.auth.signInWithOAuth`）

---

## 一、Google Cloud Console 配置

### 1.1 创建或选择项目

进入 [console.cloud.google.com](https://console.cloud.google.com)，在顶部项目选择器中选择已有项目，或新建一个专属项目（建议以产品名命名，便于管理）。

### 1.2 初始化 Google Auth Platform

新项目默认未配置 OAuth。进入左侧菜单 **Google Auth Platform**（旧版为 APIs & Services → OAuth consent screen），若页面显示 "not configured yet"：

1. 点击 **Get started** 进入配置向导
2. **Branding**：
   - App name：填写产品名称（如 `Habit Tracker`）
   - User support email：选择你的邮箱
3. **Audience**：
   - 选择 **External**（允许任何 Google 账号登录）
   - 开发阶段选 External + Testing 模式即可
4. 一路 **Next** → **Finish** 完成向导

> **注意**：External 模式下，App 默认处于 Testing 状态，只有添加到 Test Users 列表的邮箱才能登录。正式上线前需提交 Google 审核。

### 1.3 添加测试用户（Testing 阶段必须）

左侧菜单 → **Audience** → 滚动到 **Test users** 区域 → **+ Add users**  
填入开发期间需要测试登录的 Google 邮箱，保存。

### 1.4 创建 OAuth 客户端凭据

左侧菜单 → **Clients** → **+ Create client**：

| 字段 | 填写内容 |
|------|---------|
| Application type | **Web application** |
| Name | 自定义（如 `Habit Tracker Web`），仅用于控制台识别，不展示给用户 |
| Authorized JavaScript origins | 你的应用域名（见下表） |
| Authorized redirect URIs | Supabase 回调地址（见下节获取） |

**Authorized JavaScript origins 参考值：**

```
# 本地开发
http://localhost:3737

# GitHub Pages（替换为你的实际域名）
https://your-username.github.io

# 自定义域名（如有）
https://your-domain.com
```

**Authorized redirect URIs：**  
填写 Supabase 提供的回调地址（格式见下节），此处只填一条。

点击 **Create** 后，弹窗会显示 **Client ID** 和 **Client Secret**。

> ⚠️ **Client Secret 只在创建时显示一次，立即复制保存。**  
> 后续可在 Clients 列表重新生成，但旧的 Secret 会立即失效。

---

## 二、Supabase 配置

### 2.1 获取 Callback URL

进入 Supabase Dashboard → 你的项目 → **Authentication** → **Sign In / Providers** → 找到 **Google**。

启用 Google Provider 后，页面会显示：

```
Callback URL (for OAuth):
https://<your-project-ref>.supabase.co/auth/v1/callback
```

复制此 URL，回到 Google Cloud Console 的 **Authorized redirect URIs** 填入。

### 2.2 填入 Google 凭据

在同一 Google Provider 配置页面：

| 字段 | 值 |
|------|---|
| Client ID | 从 Google Cloud Console 复制 |
| Client Secret | 从 Google Cloud Console 复制 |

点击 **Save**。

---

## 三、前端代码

Supabase JS SDK 的调用方式（本项目 `auth.html` 已实现）：

```javascript
async function signInWithGoogle() {
  const { error } = await sb.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: window.location.origin + '/auth.html'
      // 登录成功后 Supabase 回调到此地址
      // onAuthStateChange 监听到 SIGNED_IN 事件后跳转主页
    }
  });
  if (error) console.error(error.message);
}
```

登录成功后 Supabase 自动处理 token，`onAuthStateChange` 捕获 `SIGNED_IN` 事件完成跳转：

```javascript
sb.auth.onAuthStateChange((event, session) => {
  if (session && event === 'SIGNED_IN') {
    window.location.replace('index.html');
  }
});
```

---

## 四、发布前检查清单

### 4.1 Testing → Production（面向真实用户前必须完成）

Google OAuth App 处于 Testing 状态时，只有 Test Users 列表中的账号可登录。正式上线需：

1. **Google Cloud Console → Audience** → 点击 **Publish app**
2. 填写必要信息（隐私政策 URL、服务条款 URL）
3. 如应用请求了敏感权限（email、profile 除外），需提交 Google 安全审查（通常 1-3 个工作日）
4. 审核通过后，任何 Google 账号均可登录

### 4.2 域名变更时的更新步骤

如果部署域名发生变化（如从 GitHub Pages 迁移到自定义域名）：

1. Google Cloud Console → **Clients** → 编辑对应客户端
2. **Authorized JavaScript origins** 添加新域名
3. **Authorized redirect URIs** 确认 Supabase Callback URL 未变（通常不变）
4. **Supabase** → Authentication → URL Configuration → 更新 **Site URL** 和 **Redirect URLs**

### 4.3 Supabase URL 配置（重要）

进入 Supabase Dashboard → **Authentication** → **URL Configuration**：

| 字段 | 建议值 |
|------|-------|
| Site URL | 生产环境主域名（如 `https://your-domain.com`） |
| Redirect URLs | 所有允许跳转的地址，每行一个（含 localhost 用于开发） |

示例 Redirect URLs：
```
http://localhost:3737/auth.html
https://your-username.github.io/auth.html
https://your-domain.com/auth.html
```

---

## 五、常见问题

**Q: 点击 Google 登录后报错 "redirect_uri_mismatch"**  
A: Google Cloud Console 中的 Authorized redirect URIs 与 Supabase Callback URL 不一致。检查是否多了/少了斜杠，或 http/https 不匹配。

**Q: 登录弹窗提示 "Access blocked: This app has not completed Google's verification process"**  
A: App 处于 Testing 状态，当前用户不在 Test Users 列表。在 Google Cloud Console → Audience → Test users 添加该邮箱，或将 App 发布。

**Q: Google 登录成功但页面没有跳转**  
A: 检查 `onAuthStateChange` 是否在页面初始化时注册，以及 `SIGNED_IN` 事件处理逻辑。也可能是 Supabase Redirect URLs 未包含当前页面地址。

**Q: Client Secret 泄露了怎么办**  
A: 立即在 Google Cloud Console → Clients → 对应客户端 → **Reset secret** 生成新 Secret，并在 Supabase 同步更新。旧 Secret 立即失效，不影响已登录用户的 session。

---

*文档版本：v1.0 · 2026-06-06*  
*适用项目：Habit Tracker*
