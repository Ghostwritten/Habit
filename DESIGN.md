# Habit — Design System
**Aesthetic Direction:** Precision Discipline  
**Version:** 1.0 · 2026-06-06  
**Stack:** Vanilla HTML/CSS/JS · Single-file · No build tools

> 行为改变的基础设施。每个像素证明自己的存在。  
> Behavior change infrastructure — not another to-do app.

---

## 1. Aesthetic Direction

**Precision Discipline** — the visual language of systems that take you seriously.

Inspired by: Linear's precision + Duolingo's reward moments + high-end financial tool quality.  
Not minimalist for decoration — minimal because every element earns its place.

**Three-word filter for any design decision:** *Serious. Rewarding. Trustworthy.*  
If a proposed element can't pass this filter, remove it.

---

## 2. Color System

### Theme Tokens (CSS Custom Properties)

All components use semantic tokens — **never hard-code hex values**.  
Apply themes by setting `data-theme` on the root `<html>` element.

| Token | Role |
|---|---|
| `--bg` | Page canvas |
| `--surface` | Cards, panels, containers |
| `--border` | Dividers, outlines, separators |
| `--border-hover` | Hover/focus border state |
| `--accent` | Primary action, brand color, checked state |
| `--accent-light` | Gradient endpoint, hover tints |
| `--accent-subtle` | Faint accent background (7–8% opacity) |
| `--accent-rgb` | Raw RGB for dynamic `rgba()` composition |
| `--text` | Primary copy |
| `--text-dim` | Secondary labels, meta, placeholder |
| `--text-muted` | Tertiary, decorative |
| `--modal-bg` | Modal/popover background |
| `--modal-border` | Modal/popover border |
| `--stat-bg` | Stats row background |
| `--stat-border` | Stats row dividers |
| `--cb-border` | Unchecked checkbox border |
| `--dot-past` | 7-day dot: completed past day |
| `--toolbar-hover` | Toolbar button hover background |
| `--ripple-color` | Checkbox ripple overlay |

### Theme Palette Reference

| Token | Dark | Light | GitHub | Classic |
|---|---|---|---|---|
| `--bg` | #0a0a0a | #f5f7fa | #0d1117 | #1a1a2e |
| `--surface` | #131313 | #ffffff | #161b22 | #16213e |
| `--border` | #1c1c1c | #e8eaed | #30363d | #0f3460 |
| `--accent` | #7c6af7 | #6c5ce7 | #238636 | #e94560 |
| `--accent-light` | #a89bf7 | #a29bfe | #3fb950 | #ff6b81 |
| `--text` | #e2e2e2 | #1a1a2e | #c9d1d9 | #eaeaea |
| `--text-dim` | #555555 | #8888aa | #6e7681 | #8892a4 |

### Gamification Palette — Theme Invariant

These colors **do not change** when the user switches themes. They carry semantic meaning across all contexts.

| Role | Hex | Usage |
|---|---|---|
| H Currency / Achievement | `#ffd700` | H balance, floating +H text, XP bar, achievement gold |
| Streak / Warning | `#ffa020` | Active streak label, missed warning, amber badge |
| Growth / New streak | `#6bcb77` | 3-day badge, early streak |
| Freeze / Special | `#64d8ff` | Freeze token, 30-day badge |
| Deduction / Danger | `#e05050` | H penalty, delete action, missed streak broken |

```css
/* Reference — do not override per theme */
--g-gold:      #ffd700;
--g-gold-dim:  rgba(255,215,0,.15);
--g-amber:     #ffa020;
--g-amber-dim: rgba(255,160,32,.15);
--g-green:     #6bcb77;
--g-green-dim: rgba(107,203,119,.15);
--g-cyan:      #64d8ff;
--g-cyan-dim:  rgba(100,216,255,.15);
--g-red:       #e05050;
--g-red-dim:   rgba(224,80,80,.15);
```

---

## 3. Typography

**Primary font:** Inter → `-apple-system, BlinkMacSystemFont, 'Inter', 'Segoe UI', sans-serif`  
No web font loading required. System stack ensures zero layout shift and native CJK fallback.

**Key rule:** All numeric values that carry economic or progress meaning use `font-variant-numeric: tabular-nums`. Numbers that look like instruments build the right mental model for H as currency.

### Type Scale

| Size | Weight | Usage |
|---|---|---|
| 0.60rem | 700 | Section labels, component tags — uppercase + letter-spacing |
| 0.64–0.66rem | 400 | Meta text, timestamps, help copy |
| 0.72rem | 400–500 | Streak labels, secondary stats, dot row |
| 0.80–0.82rem | 400–500 | Button text, modal labels, picker options |
| 0.88–0.92rem | 500 | Habit names, primary card content |
| 1.10rem | 600 | App title — uppercase, letter-spacing: .12em |
| Numbers | 700 | H balance, streak count — tabular-nums, gold color |

### Label Convention
Secondary labels: `text-transform: uppercase; letter-spacing: .06–.16em; font-size: .60–.72rem`  
Applied to: section headers, stat labels, toolbar button text, progress meta.

---

## 4. Spacing & Layout

**Base unit:** 4px  
**Grid:** 8pt (all spacing in multiples of 4)  
**Max content width:** 500px, centered  
**Page padding:** 16px horizontal, 56px top, 64px bottom

### Spacing Scale
| Token | Value | Usage |
|---|---|---|
| gap-1 | 4px | Icon-to-text gap, dot spacing |
| gap-2 | 8px | Tight component groups |
| gap-3 | 12px | Component internal padding |
| gap-4 | 16px | Section internal spacing |
| gap-5 | 20px | Larger component padding |
| gap-6 | 24px | Modal padding |
| gap-8 | 32px | Section gap |
| gap-12 | 48px | Large section separation |

### Border Radius Scale
| Size | Value | Applied to |
|---|---|---|
| xs | 5px | Streak badges, small pills |
| sm | 8–9px | Checkboxes, small buttons, time inputs |
| md | 10px | Toolbar buttons, picker options |
| lg | 12–14px | Popovers, dropdowns, stats row |
| xl | 18px | Habit cards, add button |
| 2xl | 20px | Modals, toasts |

---

## 5. Motion Library

**Core principle:** Spring easing is the language of reward. Use it only when the user *earns* something. Routine interactions use ease-out.

### 5-Tier System

| Tier | Duration | Easing | Usage |
|---|---|---|---|
| **Micro** | 150–180ms | `ease-out` | Hover states, button presses, color transitions |
| **Standard** | 200–250ms | `ease-out` | State transitions, checkbox fill, banner fade |
| **Reveal** | 300ms | `cubic-bezier(.22,1,.36,1)` | Dropdowns, banners, progress bar width |
| **Spring ★** | 350–450ms | `cubic-bezier(.34,1.56,.64,1)` | Check-in, badge pop, toast entry, H float |
| **Transition** | 480ms | `cubic-bezier(.22,1,.36,1)` | Calendar slide, page transitions |

★ Spring has emotional weight — it signals positive outcomes. Never use for deletions, errors, or neutral navigation.

### Specific Timings
| Element | Duration | Easing |
|---|---|---|
| Checkbox fill + scale | 220ms | Spring |
| Checkbox ripple | 550ms | ease-out |
| Card pop (check) | 350ms | Spring |
| Today dot (check) | 300ms | ease-out |
| Progress bar width | 500ms | `cubic-bezier(.22,1,.36,1)` |
| XP/H bar width | 600ms | ease-out |
| Floating H text | 1100ms | ease-out |
| Toast entry | 450ms | Spring |
| Modal entry | 200ms | ease-out |
| Dropdown open | 160ms | ease-out |
| Calendar slide | 480ms | `cubic-bezier(.22,1,.36,1)` |
| Badge pop | 400ms | Spring |

---

## 6. Component Specifications

### Habit Card
```
Border radius:    18px
Padding:          18px top/bottom · 22px left · 14px right
Gap (elements):   14px
Card gap:         10px between cards
Max width:        500px

States:
  default  → --surface bg, --border border
  done     → --surface-done bg, --border-done border, name color → --text-dim, streak → --accent
  missed   → rgba(255,155,30,.25) border, amber missed label below streak
  popping  → scale 1 → 1.025 → 0.992 → 1, 350ms Spring
```

### Checkbox
```
Size:         30 × 30px
Border radius: 9px
Unchecked:    transparent fill, 1.5px --cb-border
Checked:      --accent fill + border, white checkmark SVG, scale 1.12
Transition:   220ms Spring
Ripple:       absolute overlay, rgba(accent,.35), scale 0→2.5, 550ms ease-out
```

### 7-Day Dot Row
```
Dot size:    5 × 5px, border-radius 50%
Gap:         5px
past-done:   --dot-past color
today-done:  --accent color, scale 1.3, 300ms ease-out
today-empty: --dot-empty-bg fill, --dot-empty-border border
past-empty:  --border color
```

### Stats Row
```
Border radius:  14px
Padding:        10px vertical · 6px horizontal per cell
Dividers:       1px --stat-border between cells
Icon:           ~15px (emoji)
Value:          .88rem, font-weight 700, tabular-nums
Label:          .60rem, uppercase, letter-spacing .06em, --text-dim
```

### H Balance Display
```
Number:   font-size varies by context, font-weight 700, color #ffd700, tabular-nums
Unit:     "H" — same weight, rgba(255,215,0,.6) color
Format:   "2,840 H" (comma-separated thousands, space before H)
Never:    "2840H" — no comma, no space = wrong
```

### Floating H Text
```
Earn:  +N H · color #ffd700 · font-size .76rem · font-weight 700
Lose:  −N H · color #e05050 · font-size .76rem · font-weight 700
Animation: translateY 0→−44px, opacity 1→0, 1100ms ease-out
Position: near checkbox center, z-index 700
```

### H Transaction History Row
```
Label:      .78rem, --text
Sub-label:  .66rem, --text-dim
Amount earn: .84rem, font-weight 700, #ffd700, tabular-nums
Amount lose: .84rem, font-weight 700, #e05050, tabular-nums
Separator:  1px --border bottom (except last row)
```

### Progress Bar (habit completion)
```
Height:       2px
Background:   --border (track)
Fill:         linear-gradient(90deg, --accent, --accent-light)
Border radius: 1px
Transition:   width 500ms cubic-bezier(.22,1,.36,1)
```

### H Level Bar
```
Height:       2px
Fill:         linear-gradient(90deg, #f0c040, #ffd700)
Transition:   width 600ms ease-out
```

### Toast
```
Position:     fixed, top 20px, centered horizontally
Border radius: 18px
Padding:      14px vertical · 20px horizontal
Min-width:    240px
Emoji:        1.8rem
Title:        .90rem, font-weight 600
Sub:          .74rem, --text-dim
Entry:        translateY(-120px) → 0, 450ms Spring
Exit:         fade + slide up, 300ms ease-out
Duration:     3000–4500ms depending on context

Border color by type:
  streak/level  → rgba(--accent-rgb, .35)
  perfect day   → rgba(255,215,0,.35)
  freeze        → rgba(100,216,255,.35)
  danger/level  → rgba(233,69,96,.35)
```

### Modal
```
Max-width:    360px
Border radius: 20px
Padding:      24px
Backdrop:     rgba(0,0,0,.55)
Entry:        translateY(10px) scale(.97) → natural, 200ms ease-out
Exit:         reverse, 180ms
```

### Add Habit Button
```
Height:       48px
Border:       1.5px dashed --border-hover
Border radius: 14px
Hover:        border → --accent, color → --accent, bg → --accent-subtle
```

### Settings Popover
```
Min-width:    200px
Border radius: 12px
Padding:      6px
Entry:        scale(.97) opacity(0) → natural, 150ms ease-out
Shadow:       0 8px 24px rgba(0,0,0,.2)
```

### Streak Badge
```
Font size:    .62rem
Padding:      1px 6px
Border radius: 5px
Font weight:  600
Entry:        scale(0) → scale(1), 400ms Spring

Thresholds:
  ≥3   🌱  bg rgba(107,203,119,.15)  text #6bcb77
  ≥7   🔥  bg rgba(255,165,0,.15)    text #ffa020
  ≥14  ⚡  bg rgba(255,215,0,.15)    text #ffd700
  ≥30  💎  bg rgba(100,216,255,.15)  text #64d8ff
  ≥100 👑  bg rgba(255,215,0,.2)     text #ffd700  border rgba(255,215,0,.3)
```

---

## 7. H Currency Design Rules

1. **Always use tabular-nums** — `font-variant-numeric: tabular-nums`
2. **Always gold** — `#ffd700` for earned/balance, `#e05050` for deductions
3. **Always include unit** — "2,840 H" not "2840"
4. **Always format thousands** — comma separator
5. **Earn animation = Spring** — floating +H uses Spring easing
6. **Lose animation = fast ease-out** — deduction is immediate, no celebration
7. **Transaction history** — show label, sub-label, and colored amount
8. **H ≠ XP** — H is the economic unit (spendable), XP determines level (never decreases on un-check)

---

## 8. Empty States

Every empty state requires three things:
1. **Icon** — emoji, .6 opacity, 2.4rem, warm not clinical
2. **Title** — honest, human
3. **Sub-copy** — honest context, no marketing language
4. **Primary action** — one CTA button (omit only if read-only context)

Border: 1.5px dashed --border-hover  
Background: --surface  
Border radius: 18px  
Padding: 40px 24px  
Text align: center

---

## 9. Confirmation / Penalty Dialogs

When an action costs H, the confirmation dialog must:
- Show the exact cost in red: `−20 H`
- Name the action clearly in the button: "Cancel Check-in (−20 H)"
- Primary action = keep/safe, secondary action = destructive
- Never reverse button order (safe always left, destructive always right)

---

## 10. Accessibility Standards

- Touch targets: minimum 44 × 44px on mobile
- Icon-only buttons: must have `title` and `aria-label`
- Color contrast: test all theme × gamification color combinations at WCAG AA
- Keyboard: all interactive elements focusable, visible focus ring using `--accent`
- Reduced motion: skip confetti particle animation, preserve toast/badge (they carry information)
- Screen readers: habit completion state communicated via `aria-checked` or role

---

## 11. Responsive Behavior

**Single breakpoint: 500px**  
Below 500px: content fills viewport minus 16px padding each side.  
Above 500px: content column fixed at 500px, centered.

**Mobile-specific:**
- Settings button always visible (not hover-only)
- Touch targets expand to 44px minimum
- Modal appears from bottom (sheet) not center

---

## 12. Anti-Patterns

| ✕ Never | ✓ Always |
|---|---|
| Hard-code hex: `color: #7c6af7` | Use token: `color: var(--accent)` |
| Spring on destructive actions | Spring only for reward/positive events |
| Display H without unit: `2840` | Display with unit and format: `2,840 H` |
| Empty state with only "No items" | Empty state: icon + copy + primary action |
| Gradient on surface/card backgrounds | Gradients only on progress bars and achievement elements |
| Add new themed component without all 4 theme variables | Always add to dark, light, github, classic simultaneously |
| Inline user-facing text strings in JS | All strings via `t('key')` for i18n |

---

## 13. New Component Checklist

Before shipping any new component:
- [ ] Uses only CSS variables — no hard-coded hex
- [ ] Has `:hover` transition ≤ 0.2s
- [ ] Visually correct in all 4 themes
- [ ] Text content wired through `t('key')`
- [ ] Icon-only buttons have `title` and `aria-label`
- [ ] Works at 375px viewport width
- [ ] H amounts shown with tabular-nums + correct color
- [ ] Empty state designed if applicable
- [ ] Documented in `docs/features.md`

---

*Maintained by: Claude Sonnet (AI pair programmer) + Product Owner*  
*Preview: `design-preview.html` in project root*
