---
description: >
  Habit Tracker project development guide. Use for any new feature, refactor,
  or design decision. Enforces single-file architecture best practices,
  premium UI standards, and i18n-aware design across all 7 languages and 4 themes.
---

# Habit Tracker · Development Guide

## Project Architecture

**Stack**: Vanilla HTML/CSS/JS · Single `index.html` · No build tools · No dependencies  
**Deployment**: GitHub Pages via `.github/workflows/deploy.yml`

### localStorage Schema
| Key | Type | Content |
|---|---|---|
| `habitList` | `Habit[]` | `{id, name, timeStart?, timeEnd?}` — user's habit definitions |
| `habitData` | `Record<id,{dates:string[]}>` | ISO date strings per habit (YYYY-MM-DD) |
| `habitMeta` | `{xp, perfectDays[], freezeTokens}` | Gamification state |
| `habitTheme` | `string` | Active theme: `dark` / `light` / `github` / `classic` |
| `habitLang`  | `string` | Active lang: `en` / `zh` / `es` / `ko` / `ja` / `vi` / `th` |

### Core Data Flow
```
localStorage → load*() → pure helpers → DOM via build() / applyLanguage()
                ↑
User interaction → save*() → update UI (never full reload)
```

---

## UI Standards

### Design Principles
- **Minimal**: No visual noise. Every pixel earns its place.
- **Smooth**: All state changes use CSS `transition` (0.15–0.5 s). No jarring jumps.
- **Dark-first**: The `dark` theme is the canonical design reference.
- **Consistent rhythm**: 500 px max-width column · 18 px card padding · 10 px card gap.
- **Typography**: System font stack · Uppercase + letter-spacing for labels · `var(--text-dim)` for secondary.
- **Touch-friendly**: Interactive targets ≥ 28 × 28 px.

### CSS Variable System
**Always** use variables — never hard-code hex values in new rules.  
When adding a new color state, add the variable to **all 4** theme blocks simultaneously.

```css
/* Required variables for any new themed component */
--bg  --surface  --border  --border-hover
--accent  --accent-light  --accent-subtle
--text  --text-dim  --text-muted
--modal-bg  --modal-border  --input-bg  --input-border
--toolbar-hover  --ripple-color
```

### New Component Checklist
- [ ] Uses only CSS variables (no hard-coded colors)
- [ ] Has `:hover` transition ≤ 0.2 s
- [ ] Visually correct in all 4 themes
- [ ] Text content wired through `t('key')` for i18n
- [ ] Icon-only buttons have `title` and `aria-label`
- [ ] Works at 375 px viewport width

---

## Feature Development Pattern

### Step-by-step for any new feature
1. **Schema first** — define the localStorage key and shape before touching DOM.
2. **Pure helpers** — write date/calculation helpers as pure functions (no side effects).
3. **CSS variables** — add new variables to all 4 theme blocks at once.
4. **i18n strings** — add every visible string to `I18N` for all 7 languages (`en zh es ko ja vi th`).
5. **Build integration** — card-level renders go in `build()`; page-level static text in `applyLanguage()`.
6. **Theme test** — visually verify dark → light → github → classic.
7. **Lang test** — switch through EN → 中 → ES to confirm no layout break.

### Notification / Toast
Use `showNotif(emoji, title, sub, borderColor, duration)` — **never** add new toast elements.

### Settings Popover Items
Follow the `.settings-action` button pattern inside `build()`. Use `t()` for label text.

### XP & Rewards
- Per-habit check-in: +10 XP
- Perfect day bonus: +50 XP (all habits done)
- Streak milestones: 3d +10 · 7d +30 · 14d +50 · 30d +100 · 100d +500 XP
- Freeze tokens: +1 every 7 consecutive perfect days

---

## Code Style
- `const` / `let` only — no `var`.
- Reload from storage before mutating: `const m = loadMeta(); m.xp += 10; saveMeta(m);`
- `loadData()` / `saveData()` for habit check-in history.
- `loadHabits()` / `saveHabits()` for habit list.
- `loadMeta()` / `saveMeta()` for XP/level/freeze.
- Use `(() => { ... })()` IIFE for isolated script blocks.
- All visible strings via `t('key')` — never inline user-facing text in JS.

---

## Quality Bar — Before Every Commit
- [ ] No layout shift on language or theme switch
- [ ] All interactive elements have visible hover/focus states
- [ ] Confetti palette matches the active theme
- [ ] XP/streak logic is idempotent
- [ ] No `console.error` in any theme × language combination
- [ ] `localStorage` keys are consistent (see schema above)
