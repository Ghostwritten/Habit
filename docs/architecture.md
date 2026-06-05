# Habit — System Architecture & Infrastructure Guide

> **Purpose of this document**
> Record technical decisions, stack evolution triggers, and infrastructure
> planning so that future development stays on the correct path.
> Before adding new infrastructure or migrating the stack, check this document first.

*Last updated: 2026-06-06*

---

## Current Architecture (Phase 0 — Validation)

```
┌─────────────────────────────────────────────────────┐
│                     Browser                         │
│  ┌─────────────┐  ┌─────────────┐                  │
│  │  auth.html  │  │  index.html │                   │
│  │  (登录入口)  │  │  (主 App)   │                   │
│  └──────┬──────┘  └──────┬──────┘                  │
└─────────┼────────────────┼─────────────────────────┘
          │   Vanilla JS (no build tool)              │
          ▼                ▼
┌─────────────────────────────────────────────────────┐
│                   Supabase (BaaS)                   │
│  ┌──────────────┐  ┌────────────┐  ┌─────────────┐ │
│  │  Auth        │  │ PostgreSQL │  │  Realtime   │ │
│  │  (Email OTP) │  │  (数据存储) │  │  (未来社交) │ │
│  └──────────────┘  └────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────┘
          │
┌─────────▼────────┐
│   GitHub Pages   │  ← 静态托管，CDN 全球分发
└──────────────────┘
```

**Files:**
```
Habit/
├── index.html       ← 主 App（单文件，Vanilla JS）
├── auth.html        ← 登录/注册页
├── DESIGN.md        ← 设计系统（Precision Discipline，13章节）
├── design-preview.html
└── docs/
    ├── architecture.md   ← 本文件
    ├── features.md       ← 跨平台功能规格
    └── product-design.md ← 产品设计文档
```

**Local dev:**
```bash
npx serve -p 3737 .   # 在 Habit/ 目录下运行
```

**Current known bug:**
- `#page-loading` overlay 在 Supabase auth 回调后未隐藏 → 首屏卡住

---

## Authentication Strategy

### Current (Phase 0)
**Supabase Auth — Email Magic Link**
```
用户 → 输入邮箱 → Supabase 发 Magic Link → 点击 → JWT → localStorage
```
- 已实现，无摩擦，无需密码

### Roadmap

| Phase | Method | When to add | Reason |
|-------|--------|-------------|--------|
| 0（当前）| Email Magic Link | 已实现 | 零摩擦注册 |
| 社交层前 | Google OAuth | 用户数 > 100 | 中美主流，一键登录，显著降低注册摩擦 |
| 中国区 | 微信登录 | 面向中国用户增长时 | 微信生态必须，否则转化率极低 |
| 深度层（押注）| 手机号 + 短信验证 | 引入真实货币前 | 实名合规要求，防多账号作弊 |

**Supabase Auth 支持以上全部方式，无需更换后端。**

---

## Tech Stack Evolution

### Phase 0 — 验证期（当前）✅ 保持不变

```
前端:  Vanilla HTML/CSS/JS（单文件）
后端:  Supabase（Auth + PostgreSQL + Storage）
部署:  GitHub Pages
```

**触发迁移的条件（满足其一再迁移，否则不动）：**
- 社交层功能需要多个共享组件（用户卡片、动态流、关注按钮）
- 单文件 index.html 超过 3,000 行且难以维护
- 需要服务端渲染（SEO）或动态路由

---

### Phase 1 — 社交层（1 → 10 万用户）

```
前端:  React (Vite) + TypeScript
       原因：组件复用（社交流/用户卡片需要），开发效率 3–5x
后端:  Supabase（Row Level Security 天然支持社交数据隔离）
       + Supabase Edge Functions（押注结算/通知逻辑）
部署:  Vercel（支持动态路由 + 环境变量 + Preview Deploys）
```

**迁移方式：不需要完整重写。**
- 先将 index.html 拆为独立的 React 组件
- Supabase 后端不变
- GitHub Pages → Vercel（一次性迁移，约 1 小时）

---

### Phase 2 — 深度层/规模化（10 万+ DAU 或合规要求）

```
前端:  Next.js (App Router)
后端:  Supabase + 独立 Node.js 服务（押注合约 + 支付处理）
支付:  Stripe（国际）+ 微信/支付宝（中国）
部署:  AWS 或 Vercel（视合规要求，中国数据可能需境内节点）
```

---

## Page Layout Summary

| Route | File | Purpose | Status |
|-------|------|---------|--------|
| `/auth.html` | auth.html | 注册/登录（Email Magic Link） | ✅ Done |
| `/index.html` | index.html | 主界面：习惯列表、打卡、H货币、日历、统计 | ✅ Done |
| `/profile` | 未实现 | 用户主页（社交层） | ⬜ Pending |
| `/feed` | 未实现 | 社区动态流（社交层） | ⬜ Pending |
| `/challenge` | 未实现 | 群体挑战（社交层） | ⬜ Pending |
| `/bet` | 未实现 | 双人对赌合约（深度层） | ⬜ Pending |

**Current Main App Sections (index.html):**
```
Header (Logo + Theme + Language + Settings)
  ↓
Progress Bar (今日完成 X/N)
  ↓
Stats Row (Perfect Days · Level · Freeze Tokens)
  ↓
XP/H Bar (Level Progress)
  ↓
Recovery Banner (如有未完成习惯)
  ↓
Habit Cards (List)
  ↓
Add Habit Button
```
Calendar View is a full-screen overlay (slide from right).

---

## Capacity Planning

### User Scale Estimates

| Stage | DAU | Peak QPS | Daily Data |
|-------|-----|----------|-----------|
| 验证期 | 10–100 | < 1 | < 1 MB |
| 增长期 | 1K–10K | ~50 | ~10 MB |
| 规模期 | 100K+ | ~500 | ~100 MB |

### Supabase Tier Thresholds

| Tier | Monthly Cost | Capacity | When to upgrade |
|------|-------------|----------|-----------------|
| Free | $0 | 500MB DB, 2GB storage, 50K MAU | 验证期完全够用 |
| Pro | $25/mo | 8GB DB, 100GB storage, 100K MAU | DAU > 5,000 或 MAU > 50,000 |
| Team | $599/mo | 无限 MAU + SLA | 商业化且需要保障时 |

**结论：Supabase Free Tier 可支撑约 10,000 DAU，无需额外成本。**

---

## AWS Infrastructure (Phase 2 Reference Only)

> 只在真正规模化（10万+ DAU）或合规强制要求时才迁移到 AWS。
> 在此之前，Supabase + Vercel 性价比远超自建。

### Architecture

```
CloudFront (CDN + Static Assets)
       ↓
ALB (Load Balancer)
       ↓
┌─────────────────┐    ┌──────────────────┐
│  EC2 / ECS      │    │  RDS PostgreSQL   │
│  (App Server)   │    │  (Primary DB)     │
└─────────────────┘    └──────────────────┘
       ↓
ElastiCache Redis  ← 打卡去重、排行榜缓存、会话
```

### Resource Sizing

| Component | 1万 DAU | 10万 DAU | Estimated Cost/mo |
|-----------|---------|---------|-------------------|
| EC2 App Server | t3.small × 2 (2vCPU/2GB each) | t3.medium × 4 (2vCPU/4GB each) | $30–$120 |
| RDS PostgreSQL | db.t3.micro (1vCPU/1GB) | db.t3.medium (2vCPU/4GB) | $15–$60 |
| ElastiCache Redis | cache.t3.micro | cache.t3.small | $15–$30 |
| CloudFront CDN | 按流量（静态资源低） | 同左 | ~$5 |
| **Total** | | | **$65–$215/月** |

---

## Data Model (Current)

> Full specs in `features.md`. Summary for architecture reference:

```
Supabase Tables:
  users           ← Supabase Auth manages, no custom table needed
  habits          ← id, user_id, name, timeStart, timeEnd, created_at
  habit_logs      ← id, habit_id, user_id, date (YYYY-MM-DD)
  habit_meta      ← user_id (PK), xp, perfect_days[], freeze_tokens

LocalStorage (Phase 0 fallback / offline cache):
  habitList       ← Array<Habit>
  habitData       ← Map<habitId, {dates[]}>
  habitMeta       ← {xp, perfectDays[], freezeTokens}
  habitTheme      ← "dark"|"light"|"github"|"classic"
  habitLang       ← "en"|"zh"|"es"|"ko"|"ja"|"vi"|"th"
```

**H Currency Storage:** `habitMeta.xp` field. Phase 0: H = XP numerically.
Do not rename until Phase 1 decoupling. See `product-design.md` for H roadmap.

---

## Development Priorities (as of 2026-06-06)

```
Now (this week):
  1. Fix loading bug: #page-loading overlay 未在 Supabase auth 回调后隐藏
  2. Add Google OAuth (Supabase Dashboard → Auth → Providers → Google, ~30min)

After user validation (3–5 real users, 1 week):
  3. Social layer architecture design (use /think before coding)
  4. Evaluate React migration (depends on social complexity)

Future (scale-up):
  5. WeChat Login for China market
  6. Payment integration (Stripe + WeChat Pay)
  7. Legal/compliance review for real-money features
```

---

## Decisions Log

| Date | Decision | Reason | Alternatives Rejected |
|------|----------|--------|----------------------|
| 2026-06-06 | 保持 Vanilla JS 单文件 | 验证期，避免过早架构 | React（过度工程） |
| 2026-06-06 | Supabase 而非自建后端 | 零运维，Auth/DB/Realtime 一体 | Firebase（数据导出限制）, 自建 Node（运维成本） |
| 2026-06-06 | GitHub Pages 部署 | 免费，CDN 全球，零配置 | Vercel（功能足够但此阶段不必要） |
| 2026-06-06 | H 货币 Phase 0 纯虚拟 | 无监管风险，验证期不需要真实货币 | 直接接入支付（合规风险高） |
| 2026-06-06 | 双人对赌是深度层功能 | 只适合有可观测输出的习惯，不能作为入口 | 作为社交层核心（限制产品宽度） |
