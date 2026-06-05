# Habit Tracker — Cross-Platform Feature Specification

> **Purpose of this document**
> Every feature is described in platform-agnostic terms so that an AI assistant
> (or a human developer) can re-implement the full product on iOS, Android,
> macOS, or Windows without access to the original source code.
>
> **Conventions**
> - Colors are expressed as semantic roles (`accent`, `surface`, `text-dim`, …)
>   not hex values; each platform chooses its own palette.
> - Storage is described as key/value pairs; the actual engine (UserDefaults,
>   SharedPreferences, SQLite, CoreData, …) is left to the implementer.
> - Timing is in milliseconds. Easing is described as named curves
>   (`ease-out`, `spring`, `linear`).

---

## Feature: Core Habit Tracking

### Purpose
Allow users to define a personal list of daily habits and record whether they
completed each habit on a given day.

### UX Behavior
1. The home screen shows a vertically-scrollable list of habit cards.
2. Each card displays: the habit name, a checkbox (or toggle), the current
   day-streak count, and a 7-day dot row showing the past week's activity.
3. Tapping the checkbox marks the habit as done for today.
   - The checkbox animates to a filled/checked state.
   - A ripple effect radiates from the checkbox center.
   - The card briefly scales up then settles (pop animation).
   - The streak count increments immediately.
   - The 7-day dot for today changes to the accent color and scales up.
4. Tapping again un-marks it (streak decrements; today's dot reverts).
5. State persists across sessions and app restarts.
6. A progress bar at the top shows X / N habits completed today.
   It animates width changes with a smooth ease-out transition.

### Data Model
```
habitList : Array<Habit>
  Habit {
    id        : string   // unique, e.g. "habit_<timestamp>" or UUID
    name      : string   // display label, max 60 chars
    timeStart : string?  // "HH:MM" 24-hour, optional
    timeEnd   : string?  // "HH:MM" 24-hour, optional
  }

habitData : Map<habitId, HabitRecord>
  HabitRecord {
    dates : Array<string>  // ISO dates "YYYY-MM-DD" on which habit was done
  }
```
Default habits seeded on first launch if `habitList` is absent:
`Morning meditation`, `Exercise`, `Read 30 minutes`,
`Drink 8 glasses of water`, `No social media after 9 pm`.

### Business Logic
- **Today's date** is computed at app launch in local time (`YYYY-MM-DD`).
  It does not change mid-session even if midnight passes.
- A habit is **done today** if `today` appears in `HabitRecord.dates`.
- **Streak** = longest consecutive run of dates ending on today (if done today)
  or yesterday (if not done today).
  ```
  calcStreak(dates):
    set  = Set(dates)
    cursor = today if today ∈ set else yesterday
    if cursor ∉ set → return 0
    n = 0
    while cursor ∈ set:
      n++; cursor = cursor − 1 day
    return n
  ```
- **Progress** = count of habits where `today ∈ dates` / total habits.

### UI / Layout Specification
- Max content width: 500 dp/pt, centered on wider screens.
- Card: rounded corners (18 dp radius), surface background, 18 dp vertical
  padding, 22 dp left padding, 14 dp right padding.
- Checkbox: 30 × 30 dp, 9 dp corner radius.
  Unchecked: transparent fill, 1.5 dp border (border-dim color).
  Checked: accent fill, white checkmark SVG, scales to 112%.
- 7-day dot row: 7 circles of 5 dp diameter, 5 dp gap.
  Past done: dim-accent color. Today done: accent, 130% scale.
  Today empty: slightly visible outline. Past empty: border color.
- Progress bar: 2 dp tall, full width, gradient (accent → accent-light),
  border-radius 1 dp, animates width over 500 ms ease-out.

### Animations & Micro-interactions
| Event | Element | Animation |
|---|---|---|
| Check | Checkbox | Fill + scale to 112% over 220 ms spring |
| Check | Ripple overlay | Expands from center, fades out, 550 ms ease-out |
| Check | Card | Scale 1 → 1.025 → 0.992 → 1, 350 ms spring |
| Check | Today dot | Background → accent, scale → 1.3, 300 ms ease-out |
| Uncheck | Checkbox | Reverse fill, scale to 100%, 220 ms |

### Cross-platform Notes
- **iOS**: Use `UserDefaults` or `AppStorage` for `habitList`/`habitData`.
  `Toggle` or custom `UIControl` for checkbox. `withAnimation(.spring())` in SwiftUI.
- **Android**: `DataStore` or `SharedPreferences` (JSON). `Checkbox` composable
  in Jetpack Compose. Ripple via `indication = rememberRipple()`.
- **macOS**: Same as iOS SwiftUI. Consider `NSUserDefaults` for persistence.
- **Windows**: `ApplicationData.Current.LocalSettings` or SQLite via MAUI.

---

## Feature: Habit Management (Add / Delete / Time Range)

### Purpose
Let users create custom habits, optionally bound to a time window,
and remove habits they no longer need.

### UX Behavior

**Add habit**
1. A dashed-border button labeled "+ Add Habit" sits below the habit list.
2. Tapping it opens a modal sheet from the bottom (or center on desktop).
3. The sheet contains:
   - A text input for the habit name (auto-focused, max 60 chars).
   - Two optional time pickers ("From" / "To") in 24-hour format.
   - Cancel and Add buttons.
4. Pressing Add (or Enter/Return on keyboard) appends the habit to the list
   and closes the sheet. The new card appears at the bottom of the list.
5. Pressing Cancel or tapping the backdrop closes the sheet without saving.

**Settings per habit**
1. A vertical-ellipsis (⋮) icon button appears on a card when the user
   hovers or long-presses (mobile).
2. Tapping it opens a small popover/context menu anchored to the button.
3. The popover contains:
   - **Time range**: Two time pickers (From / To). Changes save immediately
     on dismissal. The time is shown as a small subtitle below the streak.
   - **Delete habit**: Tapping shows a confirmation (or deletes immediately
     with undo snackbar). Removes the habit and all its history.

### Data Model
Same as Core Habit Tracking. `timeStart`/`timeEnd` are optional fields on `Habit`.
On delete: remove the `Habit` from `habitList` AND remove its key from `habitData`.

### Business Logic
- New habit `id` = `"habit_" + unix_timestamp_ms` (or UUID v4).
- An empty name must not be accepted; show inline validation.
- Time range is display-only; the app does not enforce or notify based on it
  (future feature). It is shown as `"HH:MM – HH:MM"` below the streak label.

### UI / Layout Specification
- Add button: full-width (max 500 dp), 48 dp tall, dashed border (1.5 dp),
  border-radius 14 dp. On hover/press: border and text switch to accent color,
  background gets a faint accent tint (7% opacity).
- Modal sheet: 360 dp max-width, 20 dp corner radius, 24 dp internal padding.
  Appears with a subtle scale-up + fade (200 ms ease-out).
  Backdrop: 55% black overlay.
- Popover: 200 dp wide, 12 dp corner radius, 6 dp internal padding,
  elevation shadow. Appears with scale 0.97→1 + fade, 150 ms ease-out.
- Settings button: 28 × 28 dp, 8 dp corner radius.
  Hidden by default; visible on card hover (desktop) or always visible (mobile).

### Animations & Micro-interactions
- Sheet entry: `translateY(10dp) scale(0.97)` → natural, 200 ms ease-out.
- Sheet exit: reverse, 180 ms.
- Popover entry: `scale(0.97) opacity(0)` → natural, 150 ms ease-out.

### Cross-platform Notes
- **iOS**: `.sheet()` modifier in SwiftUI. `DatePicker` in `.hourAndMinute` mode.
  Swipe-down to dismiss. Context menu via `.contextMenu()` or custom popover.
- **Android**: `ModalBottomSheet` composable. `TimePicker` dialog.
  Long-press gesture for the settings menu (`DropdownMenu`).
- **macOS / Windows**: Show the "add" sheet as a centered dialog.
  Use native time picker controls.

---

## Feature: Streak & Day-Streak Badges

### Purpose
Reward consistency by tracking how many consecutive days each habit has been
completed, and highlight milestone streaks with a visual badge.

### UX Behavior
1. Below the habit name, a streak label reads:
   - `🔥 N day streak` when streak > 0.
   - `○ 0 day streak` when streak = 0.
2. When the streak reaches a milestone, a colored badge appears inline:
   | Streak | Badge | Color role |
   |--------|-------|------------|
   | ≥ 3    | 🌱 3+ | green tint |
   | ≥ 7    | 🔥 7+ | orange tint |
   | ≥ 14   | ⚡ 14+ | gold tint |
   | ≥ 30   | 💎 30+ | cyan tint |
   | ≥ 100  | 👑 100+ | gold with border |
3. Badge animates in with a scale-from-zero spring when it first appears.
4. When a habit is checked and a milestone is first crossed, a "Milestone!"
   toast notification pops up (see Notification feature).

### Data Model
No additional storage. Streak is computed on-the-fly from `HabitRecord.dates`
using `calcStreak()` (see Core Habit Tracking).

### Business Logic
- Milestone XP bonuses (see XP & Level System):
  - 3-day streak: +10 bonus XP
  - 7-day streak: +30 bonus XP
  - 14-day streak: +50 bonus XP
  - 30-day streak: +100 bonus XP
  - 100-day streak: +500 bonus XP
- A milestone bonus is awarded only on the **first check-in that crosses the
  threshold** within a session. If the user unchecks and re-checks, the bonus
  fires again (idempotency is not enforced at milestone level).

### UI / Layout Specification
- Streak label: 0.72 rem (≈11 dp), text-dim color normally,
  switches to accent color when the card is in "done" state.
- Badge: inline pill, 0.62 rem, 1 dp horizontal padding, 5 dp corner radius,
  colored background at 15% opacity, colored text.

### Cross-platform Notes
- **iOS/macOS**: `Text` + `Label` with `Image(systemName:)` for emoji fallbacks.
  Consider SF Symbols equivalents: flame, leaf, bolt, diamond.
- **Android**: `Chip` composable with `leadingIcon`.
- The streak calculation algorithm must be timezone-aware. Use the device's
  local calendar; do not compare UTC dates.

---

## Feature: XP & Level System

### Purpose
Provide a long-term progression mechanic that rewards sustained engagement
and gives users a sense of growing mastery.

### H Currency Integration

**H** is the product's native currency unit (H = Habit). XP and H share the
same earning events and numeric values. They serve different roles:

| Dimension | XP | H |
|---|---|---|
| Role | Level progression (honor) | Economic unit (spendable) |
| Direction | Additive only, never decreases | Can be earned and spent |
| Display | Level bar progress | Balance shown in stats row |
| Phase 0 | Identical numeric value | Identical numeric value |
| Phase 1+ | Decoupled — XP for levels only | H becomes rechargeable currency |

In Phase 0 (current): treat XP and H as the same number stored in `habitMeta.xp`.
UI gradually replaces "XP" label with "H" while keeping level logic unchanged.

### UX Behavior
1. Below the progress bar, a stats row shows three cells:
   - 🔥 **Perfect** — consecutive perfect days count.
   - ⚡ **Lv.N Title** — current level number and title.
   - ❄️ **×N Freeze** — available streak-freeze tokens.
2. Beneath the stats row, a thin gold progress bar shows H progress toward
   the next level. A small label shows `current H` on the left and
   `→ next threshold` on the right.
3. When the user completes a habit check-in, a small `+N H` text floats
   upward from the checkbox and fades out (1.1 s ease-out).
4. On level-up, a "Level Up!" toast appears (see Notifications).

### Data Model
```
habitMeta {
  xp           : number   // total H balance (also used for level calc); never decreases on un-check
  perfectDays  : Array<string>  // ISO dates of perfect days
  freezeTokens : number   // available freeze tokens (see Streak Freeze)
}
```

### Business Logic

**H earnings**
| Event | H awarded |
|---|---|
| Check in any habit | +10 H |
| Perfect day bonus | +50 H (once per calendar day) |
| 3-day streak milestone | +10 H |
| 7-day streak milestone | +30 H |
| 14-day streak milestone | +50 H |
| 30-day streak milestone | +100 H |
| 100-day streak milestone | +500 H |

**H costs (penalty mechanic)**
| Event | H cost |
|---|---|
| Edit an active habit | −20 H |
| Cancel a completed check-in | −10 H |
| Force-delete an active habit | −30 H |

**Level thresholds**
| Level | Min XP | Title (EN) | Title (ZH) |
|---|---|---|---|
| 1 | 0 | Newcomer | 新手 |
| 2 | 100 | Consistent | 稳定 |
| 3 | 300 | Dedicated | 专注 |
| 4 | 700 | Focused | 精进 |
| 5 | 1,500 | Master | 大师 |
| 6 | 3,000 | Champion | 强者 |
| 7 | 6,000 | Legend | 传奇 |

Level titles must be localised (see i18n feature).

**XP bar progress**
```
pct = (xp - currentLevelMin) / (nextLevelMin - currentLevelMin) × 100
```
Capped at 100%. At max level (7), bar shows 100% and label shows "MAX LEVEL 👑".

**Level-up detection**
After awarding XP, compare old level index with new level index.
If they differ, trigger the Level Up toast.

### UI / Layout Specification
- Stats row: full width (max 500 dp), equal 3-column flex row,
  rounded rectangle container (14 dp radius), surface background, 10 dp padding.
  Dividers between columns (1 dp, border color).
- Each stat cell: icon (emoji, ~15 dp), bold value text (0.88 rem),
  uppercase label (0.6 rem, text-dim).
- XP bar: 2 dp tall, gold gradient left-to-right, width animates 600 ms ease-out.
- Floating XP text: 0.76 rem, bold, gold/yellow, rises 44 dp then fades,
  1.1 s ease-out. Positioned near the checkbox center.

### Cross-platform Notes
- **iOS**: Use `@AppStorage` or `Codable` + `UserDefaults` for `habitMeta`.
  Animate the XP bar width with `withAnimation(.easeOut(duration: 0.6))`.
  Floating text: `ViewModifier` with `offset` + `opacity` animation.
- **Android**: `LinearProgressIndicator` for XP bar. `AnimatedVisibility`
  + `offset` modifier for floating text.
- H (stored as `xp`) is **additive only on un-check** — un-checking does NOT refund H.
  Spending H (edits, cancels, deletes) is a separate deduction path.

---

## Feature: Perfect Day & Confetti Celebration

### Purpose
Create a memorable moment of delight when a user completes every habit in a
single day, reinforcing the all-or-nothing daily goal.

### UX Behavior
1. When the last unchecked habit is checked (all N habits done for today):
   - After a 350 ms delay, a full-screen particle confetti animation launches
     from the top of the screen and falls downward.
   - Simultaneously, a "Perfect Day!" toast slides down from the top.
     It shows a 🎉 emoji, the title, and "+50 bonus XP" sub-text.
   - The perfect-day counter in the stats row increments by 1.
   - If this perfect day triggers a level-up, a second "Level Up!" toast
     appears 1.6 s later (so toasts don't overlap).
2. The celebration fires **once per calendar day per session**.
   If the user unchecks a habit and re-checks it, `perfectCelebrated` flag
   prevents a second confetti burst in the same session.
3. If a perfect day was already counted on a previous session for today,
   the toast still fires but the "+50 bonus XP" text is omitted.

### Data Model
- `habitMeta.perfectDays` array stores ISO date strings of confirmed perfect days.
- `perfectCelebrated` is a **session-only** boolean flag (not persisted).

### Business Logic
```
onLastHabitChecked():
  if perfectCelebrated → return
  perfectCelebrated = true
  allDone = all habits have today in their dates
  if not allDone → return   // guard: re-check after uncheck

  isNew = today ∉ habitMeta.perfectDays
  if isNew:
    habitMeta.perfectDays.push(today)
    habitMeta.xp += 50
    checkFreezeTokenReward()
    saveMeta()

  launchConfetti()
  showToast("🎉", "Perfect Day!", subtitle, accentColor, 4500 ms)
  checkLevelUp(prevXP, newXP)
```

**Confetti system**
- 170 particles spawned off-screen top.
- Each particle: random x position, random fall speed (2–6 dp/frame),
  random horizontal swing (sine wave), random rotation.
- Two shapes: rectangle (60%) and ellipse (40%).
- Colors: 6–7 per-theme palette entries.
- Particles fade out after ~110 frames; removed when opacity ≤ 0.
- Canvas/layer runs at native frame rate (60 fps target).

### UI / Layout Specification
- Confetti layer: fixed/overlay, full screen, pointer-events disabled
  (does not block interaction).
- Toast: centered horizontally, 20 dp from top edge.
  240 dp min-width, 18 dp corner radius, elevation shadow.
  Entry: slides in from `translateY(-120dp)` with spring bounce (450 ms).
  Exit: fades + slides up, 300 ms.

### Animations & Micro-interactions
- Confetti particle: falls at `speed` dp per frame, swings ±`swing` dp
  horizontally via `sin(angle)`, rotates continuously at `rotSpeed` rad/frame.
- Toast entry spring: overshoot ~5%, settle 450 ms.

### Cross-platform Notes
- **iOS**: Use `CAEmitterLayer` with `CAEmitterCell` for performant particles,
  or `SpriteKit` scene overlay. SwiftUI `.overlay` + `ZStack` for toast.
- **Android**: `Canvas` + `ValueAnimator` or Jetpack Compose `Canvas` with
  `LaunchedEffect` + `drawWithCache`. `Snackbar` or custom composable for toast.
- **macOS/Windows**: Same particle approach in a transparent overlay window layer.
- Respect `prefers-reduced-motion` / accessibility settings: skip confetti,
  show toast only.

---

## Feature: Punishment / Recovery System

### Purpose
Gently remind users of missed habits without being discouraging, using loss
aversion (visible streak damage) plus a constructive recovery nudge.

### UX Behavior

**"Streak broken" card indicator**
1. On app open, habits that meet the "missed yesterday" condition show a small
   amber label (⚡ "Streak broken" or locale equivalent) below the streak line.
2. The card also gets a subtle amber border glow.
3. The label disappears as soon as the habit is checked today (recovers streak
   from the streak-freeze token if used).

**Recovery banner**
1. If any habits qualify as "missed yesterday" on app open, a dismissible
   banner appears above the habit list.
   - Text: "You missed N habit(s) yesterday" + sub-text encouragement.
   - Color: warm amber, 7% background, 20% border.
   - A × button dismisses it for the session (not persisted).
2. The banner is not shown again after dismissal in the same session.
3. The banner hides automatically if all missed habits are completed today
   (even without dismissal).

### Data Model
No new keys. Derived at runtime from `habitData`.

### Business Logic
```
isMissedYesterday(habit):
  dates = habitData[habit.id].dates
  oneWeekAgo = today - 7 days
  hasRecentHistory = any date in dates ≥ oneWeekAgo
  return hasRecentHistory
      AND yesterday ∉ dates
      AND today    ∉ dates
```
"Recent history" threshold (7 days) prevents showing the warning for habits
the user added but never used.

```
countMissedYesterday():
  return habits.filter(h → isMissedYesterday(h)).length
```

### UI / Layout Specification
- Missed label: 0.66 rem, amber (#FFA020 or similar), flex row, gap 4 dp.
- Card border glow: `rgba(255,155,30, 0.25)` 1 dp border.
- Recovery banner: full width (max 500 dp), 13 dp corner radius, 11 dp
  vertical / 14 dp horizontal padding. Icon (💫 1.15 rem) + text block + × button.
  Appears with `translateY(-8dp) → 0` + fade-in, 300 ms ease-out.

### Cross-platform Notes
- **iOS**: Banner as a `VStack` section above the list, animated with
  `withAnimation(.easeOut)`. Persist dismissal flag with `@State` (session only).
- **Android**: `AnimatedVisibility` composable wrapping the banner card.
- Streak calculation is purely date-arithmetic; no server clock needed.

---

## Feature: Streak Freeze Token

### Purpose
Reduce churn caused by accidentally missed days by giving users an "insurance"
token they can spend to protect a streak they care about.

### UX Behavior
1. The ❄️ **×N Freeze** stat cell in the stats row shows available tokens.
2. **Earning**: Every 7th consecutive perfect day awards +1 token.
   A "Freeze Earned!" toast fires ("❄️ Streak Freeze earned! · ×N total").
3. **Using**: When a habit qualifies as "missed yesterday" (see Recovery)
   and the user has ≥ 1 token, the habit's settings popover shows an
   "❄️ Use Streak Freeze (×N)" button.
   - Tapping it: inserts yesterday's date into the habit's date array,
     decrements `freezeTokens` by 1, rebuilds the card, shows
     "Streak Protected!" toast.
4. Token count can be 0. Negative is not possible.

### Data Model
```
habitMeta.freezeTokens : number   // non-negative integer
```

### Business Logic
```
onPerfectDayConfirmed():
  consecutivePerfectStreak = calcPerfectStreak(habitMeta.perfectDays)
  if consecutivePerfectStreak > 0 AND consecutivePerfectStreak % 7 == 0:
    habitMeta.freezeTokens++
    showFreezeEarnedToast(consecutivePerfectStreak, habitMeta.freezeTokens)

calcPerfectStreak(perfectDays):
  // same algorithm as habit streak but over perfectDays array
  set    = Set(perfectDays)
  cursor = today if today ∈ set else yesterday
  if cursor ∉ set → return 0
  n = 0
  while cursor ∈ set: n++; cursor = cursor − 1 day
  return n

useFreeze(habit):
  habitData[habit.id].dates.push(yesterday)
  habitMeta.freezeTokens--
  save both
  rebuildHabitCard(habit)
  showToast("❄️", "Streak Protected!", "×N remaining", cyanColor, 3000ms)
```

### Cross-platform Notes
- **iOS/Android**: Show the "Use Freeze" action in a context menu or action
  sheet, not only in a settings panel, for discoverability.
- Consider showing a proactive notification: "You have a freeze token —
  use it to protect your streak!" if the user hasn't opened the app by evening.

---

## Feature: Theme System

### Purpose
Let users personalise the visual feel of the app to match their taste and
reduce eye strain in different lighting conditions.

### UX Behavior
1. A palette icon button in the top-right toolbar opens a dropdown menu.
2. Four themes available: **Dark**, **Light**, **GitHub**, **Classic**.
3. Selecting a theme instantly applies it to the entire UI (no reload).
4. The selected theme persists across sessions.
5. The active theme is highlighted (accent-colored text) in the menu.

### Data Model
```
habitTheme : string   // "dark" | "light" | "github" | "classic"
```

### Business Logic
Apply theme = set a `data-theme` attribute on the root element (or equivalent
platform mechanism), which cascades to all child components via design tokens.

**Semantic color tokens per theme**

| Token | Dark | Light | GitHub | Classic |
|---|---|---|---|---|
| bg | #0a0a0a | #f5f7fa | #0d1117 | #1a1a2e |
| surface | #131313 | #ffffff | #161b22 | #16213e |
| border | #1c1c1c | #e8eaed | #30363d | #0f3460 |
| accent | #7c6af7 | #6c5ce7 | #238636 | #e94560 |
| accent-light | #a89bf7 | #a29bfe | #3fb950 | #ff6b81 |
| text | #e2e2e2 | #1a1a2e | #c9d1d9 | #eaeaea |
| text-dim | #555555 | #8888aa | #6e7681 | #8892a4 |

### UI / Layout Specification
- Palette button: 34 × 34 dp, 10 dp corner radius, icon-only with tooltip.
- Dropdown: appears below the button, 128 dp min-width, 12 dp corner radius,
  5 dp padding. Opens with `scale(0.96) opacity(0)` → natural, 160 ms ease-out.
- Each option: 34 dp tall, 10 dp horizontal padding, 8 dp corner radius,
  small colored dot (8 dp circle) + label text (0.8 rem).

### Cross-platform Notes
- **iOS**: Use `@Environment(\.colorScheme)` for system Dark/Light, then
  extend with custom color assets in `.xcassets`. Apply via `@EnvironmentObject` theme model.
- **Android**: Use `MaterialTheme` with `darkColorScheme`/`lightColorScheme`.
  Persist with `DataStore<Preferences>`.
- **macOS**: Leverage AppKit's `NSAppearance` for the system themes;
  define custom color sets for GitHub and Classic.
- **Windows**: `ResourceDictionary` with theme-specific brush definitions.

---

## Feature: Multi-Language (i18n)

### Purpose
Make the app accessible to users in their native language without changing
functionality.

### UX Behavior
1. A language button (showing the current language's short code: EN, 中, ES …)
   sits in the toolbar beside the theme picker.
2. Tapping it opens a dropdown listing all 7 supported languages with their
   native script names.
3. Selecting a language immediately re-renders all visible text in the new
   language. The date also reformats to the language's locale.
4. The selection persists across sessions.

### Data Model
```
habitLang : string   // "en" | "zh" | "es" | "ko" | "ja" | "vi" | "th"
```

### Business Logic
- All user-visible strings are keyed (e.g. `t('title')`, `t('dayStreak', n)`).
- Function-keyed strings (like streak labels) accept parameters.
- Date formatting uses the locale's standard: `new Date().toLocaleDateString(locale, opts)`.
- Calendar weekday headers use `narrow` weekday format for the locale (single
  character in CJK, two chars in Latin scripts).

**Supported languages and locales**
| Code | Native name | Locale tag |
|---|---|---|
| en | English | en-US |
| zh | 中文 | zh-CN |
| es | Español | es-ES |
| ko | 한국어 | ko-KR |
| ja | 日本語 | ja-JP |
| vi | Tiếng Việt | vi-VN |
| th | ภาษาไทย | th-TH |

**Level titles per language**
| Level | EN | ZH | ES | KO | JA | VI | TH |
|---|---|---|---|---|---|---|---|
| 1 | Newcomer | 新手 | Novato | 초보자 | 初心者 | Người mới | มือใหม่ |
| 2 | Consistent | 稳定 | Constante | 꾸준함 | 安定 | Kiên định | สม่ำเสมอ |
| 3 | Dedicated | 专注 | Dedicado | 헌신 | 専念 | Chuyên tâm | ทุ่มเท |
| 4 | Focused | 精进 | Enfocado | 집중 | 精進 | Tập trung | มุ่งมั่น |
| 5 | Master | 大师 | Maestro | 달인 | 達人 | Bậc thầy | เชี่ยวชาญ |
| 6 | Champion | 强者 | Campeón | 챔피언 | 強者 | Vô địch | แชมป์ |
| 7 | Legend | 传奇 | Leyenda | 전설 | 伝説 | Huyền thoại | ตำนาน |

### UI / Layout Specification
- Language button: same size as theme button (34 × 34 dp), displays the short
  code as bold text (0.72 rem) instead of an icon.
- Dropdown: same pattern as theme dropdown, 160 dp min-width.
  Each row: short code (bold, accent color, 22 dp fixed width) + full native name.

### Cross-platform Notes
- **iOS**: Use `Bundle.localizedString(forKey:)` or `String(localized:)` (iOS 15+).
  Ship `.lproj` folders for each language. `Locale(identifier:)` for date formatting.
- **Android**: `strings.xml` per locale in `res/values-<locale>/`. `DateTimeFormatter`
  with `Locale`.
- **macOS/Windows**: Same as iOS and Android respectively for their native i18n APIs.
- Right-to-left (RTL) languages are not currently in scope but the layout should
  not hard-code LTR assumptions (use `start`/`end` semantics, not `left`/`right`).

---

## Feature: Calendar Heatmap View

### Purpose
Give users a bird's-eye view of their habit history across months, using color
intensity to convey how consistently they performed on each day.

### UX Behavior
1. A calendar icon button in the toolbar opens the calendar view with a
   right-to-left slide animation (home slides out, calendar slides in).
2. The calendar view is a full-screen scrollable list of month grids, from
   the oldest tracked month (or 12 months ago, whichever is older) to the
   current month. Newest month is at the bottom.
3. On open, the view auto-scrolls (instantly, no animation) to show the
   current month at the top of the visible area.
4. Each month block shows:
   - Month name + year in the current locale.
   - A 7-column (Mon–Sun) header row of abbreviated weekday names.
   - A grid of day cells, padded with empty cells at the start to align the
     first day to its correct weekday column.
5. Each day cell shows:
   - The date number.
   - A fill color whose opacity encodes completion percentage (see logic below).
   - A small ✦ mark in the top-right corner for perfect days (all habits done).
   - A ring border for today's date.
   - Future dates are rendered at 25% opacity with no fill.
6. Hovering (or long-pressing on mobile) a cell shows a tooltip:
   `"Month Day · N/Total"` or `"Month Day · ✦ Perfect"`.
7. A legend row at the top of the scroll area shows 5 sample cells from empty
   to full, labeled "Less" and "More".
8. A ← back button (top-left, sticky) and Esc key close the calendar.

### Data Model
Derived entirely from `habitList` and `habitData`. No additional storage.

### Business Logic
```
buildCompletionMap():
  map = {}
  for each habit h in habitList:
    for each date d in habitData[h.id].dates:
      map[d] = (map[d] ?? 0) + 1
  return map   // "YYYY-MM-DD" → count

cellFillOpacity(date):
  done  = completionMap[date] ?? 0
  total = habitList.length
  if total == 0 OR done == 0 → return 0
  pct = done / total               // 0.0 – 1.0
  return 0.08 + pct × 0.84        // range: 0.08 – 0.92

isPerfect(date):
  return habitList.length > 0
      AND completionMap[date] == habitList.length

monthRange():
  earliest = min date across all habitData OR today − 11 months
  return [start of earliest month … start of current month]

weekdayOffset(year, month):
  // 0 = Monday, 6 = Sunday (Mon-first calendar)
  firstDayJSSunday = new Date(year, month, 1).getDay()  // 0=Sun
  return (firstDayJSSunday + 6) % 7
```

**Color fill levels** (visual reference for designers)
| Completion | Opacity | Perceived intensity |
|---|---|---|
| 0% | 0 | Invisible (surface background shows) |
| 20% | ~0.25 | Very light tint |
| 40% | ~0.42 | Light |
| 60% | ~0.58 | Medium |
| 80% | ~0.75 | Strong |
| 100% | 0.92 | Near-full accent color |

### UI / Layout Specification
- Calendar overlay: full screen, same background as home (`bg` token).
  Slides in from right: `translateX(100%)` → `translateX(0)`, 480 ms
  `cubic-bezier(0.22, 1, 0.36, 1)` (fast-out-slow-in).
- Sticky header: 50 dp tall, 1 dp bottom border (border color).
  Back arrow (24 dp icon, 36 dp tap target) · centered title · invisible spacer.
- Scroll area: fills remaining height, `overflow-y: auto`, momentum scrolling.
- Month block: max 500 dp wide, centered, 48 dp bottom margin.
- Month title: 1 rem, semibold, month name + lighter year beside it (0.78 rem, text-dim).
- Day cell: `1fr` of a 7-column grid, square aspect ratio, 10 dp corner radius,
  4 dp gap. Min tap target: 44 × 44 dp on mobile (cells expand as needed).
- Today cell: 2 dp accent-color border ring.
- Perfect mark ✦: absolute top-right corner, 0.5 rem, white at 90% opacity.
- Weekday label: 0.65 rem, text-dim, centered, uppercase.
- Legend: flex row, 14 × 14 dp legend cells with 4 dp gap, 0.66 rem labels.

### Animations & Micro-interactions
- Slide in: 480 ms `cubic-bezier(0.22, 1, 0.36, 1)`.
- Slide out (back): same duration and curve, reversed.
- Cell hover (desktop): `scale(1.08)`, 150 ms ease-out.
- Initial scroll to current month: instant (no scroll animation) to avoid
  the user watching a long scroll on open.

### Cross-platform Notes
- **iOS (SwiftUI)**: Use `LazyVStack` with `ScrollViewReader` + `.scrollTo(id:anchor:)`
  for auto-scroll. `Color(red:green:blue:opacity:)` for the fill.
  `NavigationView` slide transition or `.fullScreenCover` with custom transition.
- **Android (Compose)**: `LazyColumn` + `ScrollState` / `LazyListState.animateScrollToItem`.
  `Canvas` + `drawRoundRect` for cells, or `Box` with `alpha` modifier.
  `AnimatedVisibility` or `Crossfade` for the slide transition.
- **macOS**: `NSScrollView` / SwiftUI `ScrollViewReader`. Consider adding a
  sidebar calendar alongside the habit list (split-view) instead of an overlay.
- **Windows**: `ScrollViewer` in WinUI 3. `Grid` with uniform column definitions.
- Cell size must adapt to screen width: use a `1fr` fraction grid so cells
  auto-size. On iPad/tablet, consider a 2-column layout showing two months side-by-side.
- The heatmap is read-only. Tapping a past date does **not** retroactively mark
  a habit (by design — prevents data manipulation).

---

*Last updated: 2026-06-05*
*Maintained by: Claude Sonnet (AI pair programmer)*
