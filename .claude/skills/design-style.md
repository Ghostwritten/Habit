---
description: >
  Habit project design philosophy and aesthetic standards.
  Read this before proposing or implementing ANY UI — layout, component,
  color, copy, or interaction. Violations will be rejected.
---

# Habit · Design Language

## Core Aesthetic

> **简约、唯美、大气、高端**  
> Minimal · Beautiful · Grand · Premium

Every screen should feel like a well-crafted object — nothing superfluous,
nothing missing. If a UI element cannot justify its existence in one sentence,
remove it.

---

## The Four Laws

### 1. Restraint over richness
- One focal point per screen. Never compete for attention.
- Decorative elements (badges, icons, labels, dividers) must earn their place.
  When in doubt, cut it.
- White space is not empty — it is the material. Protect it.

### 2. Clarity over cleverness
- Users should never have to think about what to do next.
- Labels and copy: short, lowercase when possible, no exclamation marks.
- Avoid gamification clutter (badges, achievement walls, leaderboard widgets)
  unless it directly solves a user problem with no simpler alternative.

### 3. Texture through typography, not decoration
- Hierarchy is created with weight, size, and opacity — not borders or cards.
- Use `var(--text-dim)` for secondary information; never add a box around it.
- Section labels: `0.7rem · uppercase · letter-spacing: .07em · color: var(--text-dim)`.
  Use sparingly — max 2 per screen.

### 4. Motion that respects
- Transitions: `0.15–0.35 s` · ease or cubic-bezier, never linear for UI.
- Entrance animations: subtle fade or translate-Y (≤ 8 px). No bounces.
- Never animate something just because you can.

---

## What This Product Is Not

| ❌ Avoid | ✅ Instead |
|----------|------------|
| Achievement badge grids | Meaningful single stat or milestone |
| Confetti / celebration noise | Quiet toast at bottom of screen |
| Leaderboards in personal views | Only show in explicit social context |
| "Gamification" UI walls | Data that speaks for itself |
| Cards inside cards | Flat sections with breathing room |
| Emoji in headings | Emoji only in toasts or habit names (user-controlled) |
| Shadow-heavy surfaces | Border `1px solid var(--border)` or flat |
| More than 2 typeface weights on one screen | Bold + regular only |

---

## Component Guidelines

### Stat / number display
```
Large value  (1.4–1.8rem · font-weight 700 · color: var(--text))
Small label  (0.7rem · uppercase · letter-spacing · color: var(--text-dim))
No surrounding card unless grouping 2+ stats in a grid.
```

### Interactive text (inline edit, click-to-change)
```
Default state : color var(--text-dim), no border visible
Hover state   : dashed border 1px var(--border-hover), color var(--text)
Active state  : border 1.5px solid var(--accent), background var(--input-bg)
```

### Page max-width
- Content column: `max-width: 440px`, centered.
- Horizontal padding: `16px` each side on mobile.

### Buttons
- Ghost/text buttons preferred over filled for secondary actions.
- Filled accent button only for the single primary CTA per screen.
- Border-radius: `10–14px` for cards/buttons, `50%` for avatars/circular.

---

## Color Usage

Always use CSS variables. Never hardcode hex.

| Role | Variable | Usage |
|------|----------|-------|
| Page background | `var(--bg)` | body only |
| Raised surface | `var(--surface)` | cards, modals |
| Primary text | `var(--text)` | headings, values |
| Secondary text | `var(--text-dim)` | labels, captions |
| Placeholder / empty | `var(--text-muted)` | empty states |
| Brand / action | `var(--accent)` | one element per screen |
| Subtle accent | `rgba(var(--accent-rgb), 0.12)` | backgrounds, glows |

---

## Screen-level Checklist

Before any commit involving UI:

- [ ] Can I remove one more element without losing meaning?
- [ ] Is there a single clear focal point?
- [ ] Does it look correct in the `white` theme (primary ship target)?
- [ ] Does it look correct in `dark` and `github` themes?
- [ ] No hardcoded colors — only CSS variables?
- [ ] Tested at 375 px viewport width?
- [ ] All visible strings in i18n for 7 languages?
- [ ] Animations feel calm, not excited?
