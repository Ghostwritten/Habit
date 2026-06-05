# Design: Auth 入口重构 + 登录 UI 升级
Date: 2026-06-06 | Mode: Product

---

## Problem Statement

当前 auth.html 是强制入口——用户未登录即被拦截，无法体验产品。
登录 UI 视觉廉价（黑色背景、toggle 切换注册/登录），
与目标定位"极简高端"严重不符。

---

## 目标体验

参照 Chatly.ai 登录页：
- 白色背景，干净克制，留白充足
- 社交登录按钮清晰分层（Google 主推 / GitHub 次要）
- 邮箱流程分两步：先填邮箱 → 再填密码（不一次暴露所有字段）
- 隐私声明放底部（建立信任）

参照 Claude.ai 主入口：
- 未登录可直接使用，Login 按钮在右上角
- 登录后数据同步到账户；Guest 数据不保留（无迁移弹窗）

---

## 方案：登录层重构（Approach B）

### 架构变化

```
旧：
  访问任意页面 → auth.html（强制登录）→ index.html

新：
  访问 index.html → 直接可用（Guest 模式）
                  → 右上角 Login 按钮 → 登录 Modal
  auth.html → 仅作 OAuth 回调处理器（不对外展示）
```

### Guest 模式规则
- 数据存 localStorage（当前会话内有效）
- 刷新后数据保留（localStorage 持久）
- 登录后：从 Supabase 加载账户数据，localStorage Guest 数据**不导入**
- Toolbar 右上角：登录状态显示头像/名字；Guest 状态显示 "Login" 文字按钮

---

## 登录 Modal 视觉规格

### 布局
```
┌─────────────────────────────────┐
│  [brand mark]                   │
│  Habit                          │
│  Build better every day         │
│                                 │
│  ┌───────────────────────────┐  │
│  │  G  Continue with Google  │  │  ← 黑底白字（主推）
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  ⌥  Continue with GitHub  │  │  ← 白底黑字描边
│  └───────────────────────────┘  │
│                                 │
│  ────────── or ──────────       │
│                                 │
│  ┌───────────────────────────┐  │
│  │  Email address            │  │
│  └───────────────────────────┘  │
│  ┌───────────────────────────┐  │
│  │  Continue with Email  →   │  │  ← 灰底，输入邮箱后激活
│  └───────────────────────────┘  │
│                                 │
│  🔒 Your data is safe & private │
│  By continuing, you agree to    │
│  Terms · Privacy                │
└─────────────────────────────────┘
```

### 颜色
| 元素 | 值 |
|------|---|
| 背景（页面）| `#F5F5F5` 或纯白 `#FFFFFF` |
| Modal 卡片 | `#FFFFFF`，`border-radius: 16px`，轻阴影 |
| Google 按钮 | `background: #000`, `color: #fff` |
| GitHub 按钮 | `background: #fff`, `border: 1.5px solid #d0d0d0` |
| 邮箱输入框 | 极简边框，focus 时底部蓝色线或全边框 accent |
| Continue 按钮 | `background: #000`, `color: #fff`（输入后激活） |
| 文字 | 主文 `#0a0a0a`，辅助 `#888` |

### 邮箱流程（两步）
```
Step 1: 输入邮箱 → 点 "Continue with Email"
Step 2: 
  - 已注册用户 → 显示密码框 + "Sign In"
  - 新用户     → 显示密码框 + "Create Account"
  （Supabase signInWithPassword 失败则引导注册，或前端通过 fetchSignInMethodsForEmail 判断）
```

---

## 技术实现要点

### 1. index.html initApp() 改造
```javascript
async function initApp() {
  const { data: { session } } = await sb.auth.getSession();

  if (!session) {
    // Guest 模式：从 localStorage 加载，不跳转
    habits = JSON.parse(localStorage.getItem('habitList') || '[]');
    _habitDataCache = JSON.parse(localStorage.getItem('habitData') || '{}');
    _metaCache = JSON.parse(localStorage.getItem('habitMeta') || 
      '{"xp":0,"perfectDays":[],"freezeTokens":0}');
    if (habits.length === 0) seedDefaultHabitsLocal();
    showGuestUI();   // toolbar 显示 Login 按钮
    hideLoader();
    applyLanguage(currentLang);
    return;
  }

  // 已登录：从 Supabase 加载（现有逻辑不变）
  currentUser = session.user;
  // ... 现有 DB 加载逻辑
}
```

### 2. 登录 Modal 注入到 index.html
- 不依赖 auth.html 页面跳转
- Modal HTML 内嵌于 index.html 底部
- 点 Login 按钮 → `document.getElementById('login-modal').classList.add('open')`

### 3. auth.html 职责收窄
- 只处理 OAuth 回调（Supabase 需要此页面作为 redirectTo）
- 登录成功后立即 `window.location.replace('index.html')`
- 页面本身不展示任何 UI（只有 loading spinner）

### 4. Guest 数据保存路径
- `saveHabits()` → `localStorage.setItem('habitList', JSON.stringify(habits))`
- `saveData()` → `localStorage.setItem('habitData', ...)`  
- `saveMeta()` → `localStorage.setItem('habitMeta', ...)`（Guest 时不调用 Supabase）

---

## Toolbar 状态

| 状态 | 右上角显示 |
|------|-----------|
| Guest | `Login` 文字按钮（黑色，圆角）|
| 已登录 | 用户头像或名字首字母圆形 + 下拉菜单 |

---

## GitHub OAuth Bug 修复（独立任务）

与本设计无关，单独修复：
- Supabase Dashboard → Authentication → Sign In / Providers → GitHub
- 开启 GitHub Provider，填入 GitHub OAuth App 的 Client ID + Secret
- GitHub OAuth App 创建：github.com/settings/developers → New OAuth App
  - Homepage URL: `https://ghostwritten.github.io/Habit`
  - Callback URL: `https://gwxncicsscmaxjxolvwu.supabase.co/auth/v1/callback`

---

## Premises（已确认）

1. 当前强制登录入口是错的，用户应能先用后登录 ✅
2. auth.html 作为唯一入口废弃，index.html 直接可用 ✅
3. 登录 Modal：白色背景，Google/GitHub/邮箱，邮箱两步流程 ✅
4. Guest 数据不迁移，登录后从账户加载（Claude 策略）✅

---

## Open Questions

1. **邮箱注册确认邮件**：当前 Supabase 默认需要邮件确认才能登录，
   是否关闭确认（降低注册摩擦）？建议：先关闭，验证期结束后再开启。
2. **Modal 触发方式**：点 Login 按钮弹出 Modal，还是跳转到独立 `/login` 路径？
   建议：Modal（无页面跳转，体验更流畅）。
3. **移动端适配**：Modal 在小屏是否全屏？建议：< 480px 时全屏覆盖。

---

## 实施顺序

```
1. GitHub OAuth bug 修复（30分钟，独立）
2. index.html Guest 模式改造（initApp 分支 + localStorage 读写）
3. Login Modal HTML + CSS（白色极简，Chatly 参照）
4. Modal 逻辑：Google/GitHub 按钮 + 邮箱两步流程
5. auth.html 收窄为纯 OAuth 回调处理器
6. Toolbar Login/Avatar 状态切换
```

---

## What I noticed

你没有说"我想要漂亮的登录页"——你说的是"应该奠定一个专业颜色基调"和"友善、便利"。
这两个词指向的是产品哲学，不是视觉喜好：**入门零摩擦，品质有据可依**。

Chatly 的截图选得很准——它的白色 Modal 不是"好看"，
是"这家公司知道自己在做什么"的信号。
这和你的产品定位（反复失败的人需要的外部约束）高度一致：
产品要有权威感，不是温柔感。

---

*文档版本：v1.0 · 2026-06-06*
