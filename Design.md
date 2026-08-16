# CropCare AI — Design System & UX Specification (design.md)

**Version:** 1.0
**Platform:** Android-first, responsive to iOS
**Design Foundation:** Material Design 3 (Material You)
**Status:** Source of truth for all design, engineering, and AI-assisted development

---

## How to Use This Document

This document is the single source of truth for the visual design, interaction patterns, content standards, and technical design tokens of CropCare AI. Any designer, engineer, or AI coding assistant building a screen, component, or flow for this product should be able to do so from this document alone, without additional clarification. Where a decision has been made, it is stated as a rule, not an option. Where flexibility is intentional, it is called out explicitly.

---

## Table of Contents

1. Design Philosophy
2. Material Design Foundation
3. Color System
4. Typography
5. Spacing System
6. Shape Language
7. Iconography
8. Elevation
9. Motion System
10. Components
11. Screen Templates
12. AI Experience Guidelines
13. Accessibility
14. Offline Experience
15. Empty States
16. Error States
17. Design Tokens
18. UX Writing Guidelines
19. Internationalization
20. Future Scalability

---

# 1. Design Philosophy

## 1.1 Core Emotional Goal

CropCare AI exists to turn anxiety into action. A farmer opening this app has usually just noticed something wrong with a crop they depend on for income and food security. The design's job is to replace that anxiety with a calm, confident, guided path to an answer. Every screen should feel like a knowledgeable, patient field agent standing next to the farmer — never like a cold diagnostic machine and never like a black box.

## 1.2 The Five Feelings

The interface must consistently feel:

| Feeling | What it means in practice |
|---|---|
| **Trustworthy** | The AI is transparent about confidence and limits. Nothing is overstated. Sources and reasoning are visible on request. |
| **Calm** | Generous whitespace, muted supporting colors, no aggressive reds except for genuine severity/error states, no visual clutter. |
| **Clear** | One primary action per screen. Large, legible text. Icons paired with labels, never icons alone for critical actions. |
| **Grounded** | Visual language draws from natural, agricultural tones (soil, leaf, harvest) rather than generic "tech" gradients or neon accents. |
| **Capable** | The product looks modern and competent — like a well-built tool, not a hobby project — so that the advice it gives is taken seriously. |

## 1.3 Visual Identity Summary

- **Not sterile-medical, not corporate-agtech, not "cutesy farm."** The tone sits between a modern health app (Material 3 rigor) and a trusted field handbook (warm, natural palette, plain language).
- **Photography-forward for AI results.** The crop photo the farmer took is always the hero of the results screen — the UI frames it, it doesn't compete with it.
- **Restraint over decoration.** No illustrations for illustration's sake. Every visual element earns its place by aiding comprehension or reducing anxiety.
- **Consistency builds trust.** The same badge, same card, same iconography must be used every time a concept (confidence, severity, treatment) appears, anywhere in the app.

## 1.4 Design North Star Statement

> "A 58-year-old farmer, standing in bright sun with a cracked phone screen and patchy signal, should be able to photograph a diseased leaf and understand — within seconds and without reading a paragraph — what's wrong, how sure the app is, and what to do next."

Every design decision in this document should be testable against that statement.

---

# 2. Material Design Foundation

CropCare AI is built directly on **Material Design 3 (M3)**, using its token-based theming architecture so that color, type, shape, and elevation stay systematically consistent and dynamically themeable.

## 2.1 Why M3

- M3's **role-based color system** (not fixed hex-to-component mapping) lets us define semantic meaning once (e.g., `error`, `success`) and propagate it safely across components.
- M3's **elevation-via-tone** approach (surfaces lighten/tint rather than relying purely on drop shadow) performs better in bright outdoor sunlight, where soft shadows are hard to perceive.
- M3 components (buttons, cards, sheets, nav bar) are pre-solved for accessibility and platform conventions, letting us focus design effort on the AI-specific components that don't exist in the standard library.

## 2.2 Surface Hierarchy

CropCare AI uses M3's tonal surface system to express hierarchy without heavy borders or shadows:

| Surface Role | Usage |
|---|---|
| `surface` | Default screen background |
| `surface-container-lowest` | Recessed areas, image wells, camera viewfinder backdrop |
| `surface-container-low` | Subtle grouping background (e.g., section wrapper) |
| `surface-container` | Standard cards (History Card, Recommendation Card) |
| `surface-container-high` | Elevated cards that need to stand out (AI Result Card, active state cards) |
| `surface-container-highest` | Modals, bottom sheets, dialogs |
| `inverse-surface` | Snackbars, high-contrast toasts |

Rule: **never stack more than 3 surface levels on one screen.** More than that reintroduces visual noise, which works against the "calm" principle.

## 2.3 Adaptive Layouts

- **Phone (compact width, <600dp):** single-column layout, bottom navigation bar, full-width cards with 16dp screen margins.
- **Large phone / small tablet (600–840dp):** content max-width capped at 640dp and centered; bottom nav becomes optional navigation rail if the device is in landscape.
- **Tablet (≥840dp):** navigation rail (left-anchored, permanent), two-pane layout on Diagnosis Results (photo + result summary on left, tabs/detail on right) and on History (list + detail).
- Breakpoints follow M3 window size classes: **Compact / Medium / Expanded**.

## 2.4 Color Roles (Summary — full palette in Section 3)

CropCare AI implements the full M3 role set: `primary`, `on-primary`, `primary-container`, `on-primary-container`, and equivalents for `secondary`, `tertiary`, `error`, plus `surface`/`surface-variant`/`outline` roles. In addition, CropCare AI defines **product-specific semantic roles** not in stock M3: `success`, `warning`, `info`, `ai-highlight`, and a 3-step `confidence` scale and 4-step `severity` scale (Section 3.6–3.7).

## 2.5 Dynamic Color

Android 12+ dynamic color (wallpaper-derived theming) is **disabled by default** for CropCare AI. Rationale: this is a decision-critical agricultural tool where color coding (severity, confidence, success/error) must be 100% consistent and predictable across every device — user-wallpaper-driven theming would compromise the reliability of these signals. The static brand palette in Section 3 is used on all devices. This is a deliberate exception to default M3 behavior and should not be "fixed" by future contributors.

## 2.6 Elevation Philosophy

M3 elevation is expressed primarily through **surface tone changes**, with shadow as a secondary cue — this matters because shadows can be nearly invisible in direct sunlight, but tonal contrast remains visible. Full elevation table is in Section 8.

## 2.7 Motion Foundation

CropCare AI uses M3's **emphasized easing** for primary transitions (camera capture, screen navigation) and **standard easing** for small in-place state changes (toggles, chip selection). Full spec in Section 9.

---

# 3. Color System

All colors are defined as **M3 roles**, each with a light-theme and dark-theme HEX value. CropCare AI supports both themes, but **defaults to Light Theme** on first install, since outdoor legibility in direct sunlight is materially better on light backgrounds with dark text.

## 3.1 Brand Core Colors

| Role | Light HEX | Dark HEX | Usage |
|---|---|---|---|
| Primary | `#2E7D32` | `#8BD68F` | Primary buttons, active nav item, key brand moments, links |
| On Primary | `#FFFFFF` | `#00390B` | Text/icons on top of Primary |
| Primary Container | `#B4F1AE` | `#0B5B14` | Filled containers for primary actions (e.g., "Scan Now" FAB background) |
| On Primary Container | `#00210A` | `#B4F1AE` | Text/icons on Primary Container |
| Secondary | `#54634C` | `#BBCCB0` | Secondary buttons, selected chip backgrounds, supporting UI |
| On Secondary | `#FFFFFF` | `#263422` | Text/icons on Secondary |
| Secondary Container | `#D7E8CB` | `#3C4B35` | Chips, tags, secondary card accents |
| On Secondary Container | `#121F0E` | `#D7E8CB` | Text/icons on Secondary Container |
| Tertiary | `#38656A` | `#A0CED3` | Informational accents, links inside AI explanations, highlight of secondary data (e.g., weather tie-ins) |
| On Tertiary | `#FFFFFF` | `#00363B` | Text/icons on Tertiary |
| Tertiary Container | `#BCEBF0` | `#1E4D52` | Info callouts, tips banners |
| On Tertiary Container | `#002023` | `#BCEBF0` | Text/icons on Tertiary Container |

## 3.2 Semantic Status Colors

| Role | Light HEX | Dark HEX | Usage |
|---|---|---|---|
| Success | `#2E7D32` | `#8BD68F` | Treatment applied confirmations, healthy-plant results, successful upload |
| Success Container | `#B4F1AE` | `#0B5B14` | Background for success banners/snackbars |
| Warning | `#8A5700` | `#FFB74D` | Moderate severity, low-confidence notices, "verify before acting" prompts |
| Warning Container | `#FFE0B2` | `#5C3D00` | Background for warning banners |
| Error | `#BA1A1A` | `#FFB4AB` | Failed uploads, no-connection failures, invalid input, severe/urgent disease alerts |
| Error Container | `#FFDAD6` | `#93000A` | Background for error banners, destructive-action confirmation dialogs |
| Info | `#0061A4` | `#9ECAFF` | Neutral system messages, tips, "did you know" content |
| Info Container | `#D1E4FF` | `#00497D` | Background for info banners |

**Contrast rule:** every color/container pair above meets or exceeds **4.5:1 contrast** for text at body size, verified against both light and dark backgrounds (WCAG 2.2 AA). See Section 13 for full contrast audit approach.

## 3.3 Neutral / Surface Colors

| Role | Light HEX | Dark HEX | Usage |
|---|---|---|---|
| Background | `#FBFDF8` | `#10140F` | App background |
| Surface | `#FBFDF8` | `#10140F` | Default screen surface |
| Surface Variant | `#DEE5D8` | `#42493E` | Input fields, dividers backdrop, subdued containers |
| Surface Container Lowest | `#FFFFFF` | `#0A0F0A` | Camera viewfinder frame, recessed wells |
| Surface Container Low | `#F5F7F0` | `#181D14` | Section backgrounds |
| Surface Container | `#EFF2E9` | `#1C211A` | Standard cards |
| Surface Container High | `#E9EBE4` | `#272C24` | Elevated cards (AI Result Card) |
| Surface Container Highest | `#E3E6DE` | `#31362E` | Sheets, dialogs |
| Outline | `#72796C` | `#8C9388` | Borders, dividers, unfocused input outlines |
| Outline Variant | `#C2C9BB` | `#42493E` | Subtle dividers, disabled borders |

## 3.4 Text & Icon Colors

| Role | Light HEX | Dark HEX | Usage |
|---|---|---|---|
| On Surface (primary text) | `#1A1C18` | `#E2E3DB` | Headlines, body text |
| On Surface Variant (secondary text) | `#42493E` | `#C2C9BB` | Captions, helper text, timestamps |
| On Surface (icons, default) | `#42493E` | `#C2C9BB` | Standard icons |
| On Surface (icons, active) | `#2E7D32` | `#8BD68F` | Selected nav/tab icons |
| Disabled Content | `#1A1C18` @ 38% opacity | `#E2E3DB` @ 38% opacity | Disabled text/icons |
| Disabled Container | `#1A1C18` @ 12% opacity | `#E2E3DB` @ 12% opacity | Disabled button/field fills |

## 3.5 AI Highlight Color

| Role | Light HEX | Dark HEX | Usage |
|---|---|---|---|
| AI Highlight | `#6750A4` | `#D0BCFF` | Reserved exclusively to mark AI-generated content and AI-specific UI (AI badge, "Ask AI to explain" affordances, AI Result Card top border). Never reused for any non-AI purpose, so users learn to trust it as a consistent signal of "this came from the model." |
| AI Highlight Container | `#EADDFF` | `#4F378B` | Background for the AI badge chip |

This color is intentionally a **distinct hue family (violet)** from the natural green/soil palette used everywhere else, so AI-originated content is instantly, subconsciously distinguishable from farmer-entered or system content — supporting the "explain AI decisions clearly" and "trustworthy AI" principles.

## 3.6 Confidence Colors

A 3-tier scale used exclusively on the **Confidence Badge** component (Section 10) and anywhere a confidence score is surfaced.

| Tier | Score Range | Light HEX | Dark HEX | Label shown to user |
|---|---|---|---|---|
| High Confidence | 80–100% | `#2E7D32` | `#8BD68F` | "High confidence" |
| Medium Confidence | 50–79% | `#8A5700` | `#FFB74D` | "Moderate confidence" |
| Low Confidence | 0–49% | `#8C4A00` on `#FFE0B2`* | `#FFB4A1` | "Low confidence — verify with an expert" |

\*Low confidence deliberately uses a more saturated warning-adjacent tone than Medium to visually separate "proceed with normal caution" from "seek human verification." Never render a confidence score below 50% in a color that could read as "safe" (green).

## 3.7 Severity Colors

A 4-tier scale used on the **Severity Badge**, treatment urgency indicators, and Diagnosis Results header.

| Tier | Light HEX | Dark HEX | Meaning |
|---|---|---|---|
| Healthy / None | `#2E7D32` | `#8BD68F` | No disease/pest detected |
| Mild | `#7C8C00` | `#C6D46B` | Early-stage, monitor and treat on normal schedule |
| Moderate | `#8A5700` | `#FFB74D` | Treat soon, yield risk if ignored |
| Severe | `#BA1A1A` | `#FFB4AB` | Immediate action recommended, expert referral suggested |

## 3.8 Color Usage Rules

1. Never use Error red for anything that isn't a genuine failure, destructive action, or Severe-tier result. Overuse desensitizes users to real alerts.
2. Confidence and Severity colors are **never used interchangeably** even though some hex values are shared — they are separate semantic systems tied to separate badge components, and both should never appear ambiguously on the same element.
3. All primary actions use `Primary`/`On Primary`. All destructive actions (e.g., "Delete scan history") use `Error`/`On Error`, never Primary.
4. Minimum contrast for any text on any background: **4.5:1** for body text, **3:1** for large text (24sp+/18sp bold+) and icons, per WCAG 2.2 AA — see Section 13.

---

# 4. Typography

## 4.1 Font Family

- **Primary typeface: Roboto Flex** (variable font), Google's default M3 typeface — excellent legibility at small sizes, wide language/glyph coverage (important for regional language support, Section 19), and native Android rendering performance.
- **Fallback stack:** `Roboto Flex, Roboto, Noto Sans, sans-serif` — Noto Sans is included specifically as a fallback so that non-Latin scripts (Devanagari, Tamil, Telugu, Kannada, etc.) render correctly without tofu/missing-glyph boxes.
- Do not use a decorative or serif face anywhere in-product, including marketing surfaces inside the app (onboarding). Consistency and legibility outrank personality here.

## 4.2 Type Scale

Based on the M3 type scale, with sizes increased slightly beyond M3 defaults at the body level for outdoor/low-vision legibility (see 4.7).

| Style | Size / Line Height | Weight | Letter Spacing | Usage |
|---|---|---|---|---|
| Display Large | 57sp / 64sp | Regular (400) | -0.25sp | Not used in-app (reserved for future marketing/splash) |
| Headline Large | 32sp / 40sp | Medium (500) | 0sp | Screen-level hero numbers (e.g., large confidence % on results) |
| Headline Medium | 28sp / 36sp | Medium (500) | 0sp | Primary screen titles (e.g., "Diagnosis Result") |
| Headline Small | 24sp / 32sp | Medium (500) | 0sp | Section headers within a screen |
| Title Large | 22sp / 28sp | Medium (500) | 0sp | Card titles (e.g., disease name in AI Result Card) |
| Title Medium | 18sp / 24sp | Medium (500) | 0.15sp | Dialog titles, list item primary text |
| Title Small | 16sp / 20sp | Medium (500) | 0.1sp | Sub-card titles, tab labels |
| Body Large | 17sp / 26sp | Regular (400) | 0.15sp | **Default body text app-wide** (increased from M3's 16sp default) |
| Body Medium | 15sp / 22sp | Regular (400) | 0.25sp | Secondary body text, descriptions |
| Body Small | 13sp / 18sp | Regular (400) | 0.4sp | Rarely used; only for dense metadata lists, never for critical info |
| Label Large | 15sp / 20sp | Medium (500) | 0.1sp | Button text |
| Label Medium | 13sp / 16sp | Medium (500) | 0.5sp | Chip labels, badges |
| Label Small | 12sp / 16sp | Medium (500) | 0.5sp | Timestamps, fine print, legal text only |

## 4.3 Weight Usage

Only two weights are used across the entire app: **Regular (400)** for body copy and **Medium (500)** for anything requiring emphasis (titles, buttons, badges). **Bold (700)** is reserved exclusively for the single most important number on a screen (e.g., the confidence percentage, the disease name) — using it sparingly preserves its power to draw the eye.

## 4.4 Buttons & Captions

| Element | Style | Notes |
|---|---|---|
| Filled/Outlined button text | Label Large, ALL-CAPS **not** used (sentence case only, per M3 guidance and readability for non-native speakers) | e.g., "Scan another leaf" not "SCAN ANOTHER LEAF" |
| Text button | Label Large | |
| Caption / helper text | Body Small minimum, Label Small only for legal/timestamps | Never go below 12sp anywhere in the app |

## 4.5 Line Height & Spacing Rules

- Body text line-height is fixed at **1.5×** font size minimum, exceeding M3 default slightly, to aid readers with dyslexia or low literacy.
- Paragraphs are separated by a minimum of 8dp; never rely on line-height alone to separate paragraphs.
- Line length (measure) capped at ~60 characters per line for body copy blocks (explanations, treatment steps) — enforced via `max-width` on text containers, not truncation.

## 4.6 Accessibility Recommendations

- The app **must** respect the OS-level font scaling setting (Android "Font size" and "Display size") up to **200%** without clipping, overlapping, or truncating text. Layouts use scalable units (`sp` for text) and flexible containers, never fixed-height text containers.
- Never encode meaning by size or weight alone — always pair with color, icon, or explicit label (supports color-blind and low-vision users).
- Minimum body text size in the product is **17sp** (Body Large), higher than typical app defaults, in direct response to the "older adults / poor eyesight" user characteristic in the brief.
- A **"Large Text" in-app toggle** (independent of OS setting) is available in Settings, jumping the entire type scale up one additional step (e.g., Body Large 17sp → 19sp) for users who want extra size without changing system-wide settings.

---

# 5. Spacing System

## 5.1 Base Unit

CropCare AI uses an **8dp base grid**, with a **4dp half-step** permitted only for tight, small-scale relationships (icon-to-label gap, badge internal padding). All spacing values are multiples of 4dp; never use arbitrary values like 6dp or 10dp.

## 5.2 Spacing Scale (Tokens)

| Token | Value | Typical usage |
|---|---|---|
| `space-2` | 2dp | Icon optical adjustments only |
| `space-4` | 4dp | Icon-to-label gap, badge internal padding |
| `space-8` | 8dp | Compact internal padding, gap between related items (e.g., chip row gap) |
| `space-12` | 12dp | Internal card padding (compact cards), gap between icon and text block |
| `space-16` | 16dp | **Standard screen margin**, default card padding, gap between unrelated inline elements |
| `space-24` | 24dp | Gap between major elements within a section (e.g., photo and result summary) |
| `space-32` | 32dp | Section-to-section spacing |
| `space-48` | 48dp | Large section breaks (e.g., onboarding slide top margin) |
| `space-64` | 64dp | Splash/hero vertical rhythm only |

## 5.3 Screen Margins

- **Standard screen margin: 16dp** on left/right for compact width devices.
- **24dp** on medium/expanded width devices (tablets), to avoid content feeling cramped against a wider viewport.
- Top safe-area respects system status bar; bottom safe-area respects gesture nav / nav bar with an additional 8dp buffer above any bottom sheet or nav bar.

## 5.4 Card Spacing

- Padding inside a standard card: **16dp** all sides.
- Padding inside a compact card (e.g., chip-like History Card in a dense list): **12dp**.
- Gap between stacked cards in a list: **12dp**.
- Gap between a card's internal sections (e.g., title → body → actions within AI Result Card): **8dp** between title/body, **16dp** before the action row.

## 5.5 Touch Target Spacing

Every interactive element maintains a **minimum 8dp gap** from any adjacent interactive element, on top of meeting the 48dp minimum touch target itself (Section 13), to prevent mis-taps — critical for users operating the app one-handed in a field or with reduced dexterity.

## 5.6 Section Spacing Summary Table

| Relationship | Spacing |
|---|---|
| Between unrelated screen sections | 32dp |
| Between a section header and its content | 16dp |
| Between list items | 12dp |
| Between form fields | 20dp |
| Between a label and its input field | 8dp |
| Between an input field and its helper/error text | 4dp |

---

# 6. Shape Language

CropCare AI uses M3's shape scale, biased toward **rounder, softer corners** than a strict enterprise app would use — reinforcing the "calm, friendly, approachable" identity — while keeping data-dense elements (badges, chips) slightly tighter for a crisp, legible look.

## 6.1 Corner Radius Scale

| Token | Radius | Usage |
|---|---|---|
| `shape-none` | 0dp | Full-bleed images, camera viewfinder |
| `shape-xs` | 4dp | Badges, chips, tags |
| `shape-sm` | 8dp | Text fields, small buttons, snackbars |
| `shape-md` | 12dp | Standard cards, dialogs (small) |
| `shape-lg` | 16dp | Elevated cards (AI Result Card), bottom sheet top corners |
| `shape-xl` | 28dp | Large dialogs, onboarding illustration containers |
| `shape-full` | 50% (pill) | FAB, filled/outlined buttons, avatar, capture shutter button |

## 6.2 Component-Specific Shape Rules

| Component | Radius |
|---|---|
| Buttons (filled, outlined, text) | `shape-full` (pill) |
| Icon buttons | `shape-full` (circular) |
| FAB (standard & extended) | `shape-lg` default, morphs to `shape-md` when pressed (M3 FAB press-morph behavior) |
| Cards | `shape-lg` (16dp) |
| Bottom sheets | `shape-xl` top corners only (28dp), 0dp bottom |
| Dialogs | `shape-xl` (28dp) |
| Text fields (filled style) | `shape-sm` top corners only (8dp), 0dp bottom (M3 filled field convention) |
| Text fields (outlined style — used in Search) | `shape-sm` all corners |
| Images (in cards, results) | `shape-md` (12dp), or `shape-none` when full-bleed at top of a card |
| Badges (Confidence, Severity) | `shape-xs` (4dp) — deliberately crisp/tag-like to read as data, not decoration |
| Snackbars | `shape-sm` (8dp) |
| Chips | `shape-sm` (8dp) |

---

# 7. Iconography

## 7.1 Icon System

CropCare AI uses **Material Symbols** exclusively (the variable-font successor to Material Icons), in the **Rounded** grade/style — rounded terminals match the soft shape language (Section 6) and read as friendlier than Sharp or the default Outlined style at small sizes.

- **Default fill:** Outlined (fill=0) for inactive/default state.
- **Active/selected state:** Filled (fill=1) — e.g., a selected bottom nav icon fills in. This fill-on-select pattern is the app's single consistent method for showing selection state on icons, used identically everywhere (nav bar, tabs, toggles).
- **Weight:** 400 (Regular) default, 500 at small sizes (≤20dp) if legibility testing shows thinness issues.

## 7.2 Sizing

| Token | Size | Usage |
|---|---|---|
| `icon-xs` | 16dp | Inline with Label Small text (timestamps, fine print) |
| `icon-sm` | 20dp | Inline with body text, chip leading icons |
| `icon-md` | 24dp | **Default size** — buttons, list items, app bar actions |
| `icon-lg` | 32dp | Empty state icons, section headers |
| `icon-xl` | 48dp | Feature illustrations, large empty states |
| `icon-xxl` | 64dp+ | Splash screen, major empty-state moments (e.g., "No scans yet") |

## 7.3 Usage Rules

1. **No icon without a text label for any primary or destructive action.** Icon-only buttons are permitted only for well-established, universally understood actions (back arrow, close X, camera shutter, search) — and even then must carry a `contentDescription` for screen readers.
2. Icon color follows text color rules in the same context (On Surface / On Surface Variant / role colors) — never introduce a one-off icon color outside the defined palette.
3. Custom/product-specific icons (e.g., a stylized "leaf with scan lines" for the AI diagnosis feature) are permitted only where no Material Symbol adequately conveys the concept, and must be drawn in the same stroke weight and corner rounding as Material Symbols Rounded for visual consistency.
4. Status icons (success check, warning triangle, error circle) always pair the standard Material Symbol with the matching semantic color from Section 3.2 — never a custom shape for these.

---

# 8. Elevation

M3 elevation in CropCare AI is expressed primarily via **surface tonal overlay** (lighter surface = higher elevation), with shadow as a secondary, softer cue — because shadow alone is unreliable in bright outdoor light.

## 8.1 Elevation Levels

| Level | Surface Token | Shadow | Usage |
|---|---|---|---|
| Level 0 | `surface` | None | Screen background, resting cards with outline instead of shadow (used in dense lists to avoid shadow clutter) |
| Level 1 | `surface-container-low` | 1dp, 8% opacity | Resting standard cards (History Card, Recommendation Card) |
| Level 2 | `surface-container` | 3dp, 10% opacity | Slightly emphasized cards, app bar on scroll |
| Level 3 | `surface-container-high` | 6dp, 12% opacity | AI Result Card (the primary content on the results screen), FAB at rest |
| Level 4 | `surface-container-high` | 8dp, 14% opacity | FAB pressed/dragged state, dropdown menus |
| Level 5 | `surface-container-highest` | 12dp, 16% opacity | Dialogs, bottom sheets, navigation drawer |

## 8.2 Rules

1. Never use elevation shadow as the *only* signal of interactivity or hierarchy — always pair with a tonal surface change so meaning survives in bright sunlight.
2. Maximum of **3 elevation levels visible simultaneously** on one screen to preserve the calm visual hierarchy principle.
3. Elevation increases only on: layering (dialog over content), emphasis (the one card that matters most on a screen), and temporary state (press/drag). It is never used purely decoratively.
4. Elevated surfaces on dark theme use tonal elevation overlays (lighter, not shadow, since shadows are invisible on dark backgrounds) per M3 dark theme guidance.

---

# 9. Motion System

## 9.1 Principles

Motion in CropCare AI exists to **explain, not decorate.** Every animation must do one of: show spatial relationship (where did this screen come from), communicate system status (processing, success, error), or provide feedback confirming a tap registered. If an animation does none of these, it is cut.

## 9.2 Duration Tokens

| Token | Duration | Usage |
|---|---|---|
| `motion-fast` | 100ms | Icon fill toggle, ripple feedback, checkbox/switch toggle |
| `motion-short` | 200ms | Button press state, chip selection |
| `motion-medium` | 300ms | Card expand/collapse, snackbar in/out, bottom sheet peek changes |
| `motion-long` | 400ms | Full screen transitions, bottom sheet full expand |
| `motion-extra-long` | 500–700ms | Camera-to-results transition, AI processing animation loop segment |

## 9.3 Easing

| Token | Curve | Usage |
|---|---|---|
| `ease-standard` | cubic-bezier(0.2, 0, 0, 1) | Default for most UI motion — small state changes |
| `ease-emphasized` | cubic-bezier(0.05, 0.7, 0.1, 1) | Screen transitions, camera capture-to-processing, anything that should feel deliberate and important |
| `ease-emphasized-decelerate` | cubic-bezier(0.05, 0.7, 0.1, 1) | Elements entering the screen (card appearing, sheet rising) |
| `ease-emphasized-accelerate` | cubic-bezier(0.3, 0, 0.8, 0.15) | Elements exiting the screen |

## 9.4 Specific Motion Specs

| Moment | Spec |
|---|---|
| **Screen transitions** | Shared-axis transition (M3 pattern): forward navigation slides new screen in from the right with slight fade, 300ms, `ease-emphasized`. Back navigation reverses. |
| **Camera capture** | Shutter button scales down 10% on press (100ms) then a brief white flash overlay (80ms) confirms capture — critical non-visual-color feedback for outdoor glare. |
| **AI processing animation** | A calm, looping pulse on a leaf/scan icon (not a generic spinner) — 1.2s loop, `ease-standard`, paired with rotating micro-copy ("Analyzing leaf pattern…", "Comparing to known diseases…") that changes every 2s to reduce perceived wait time. Never exceeds a subtle 4% scale pulse — no spinning, no bouncing, to stay "calm." |
| **Result reveal** | AI Result Card fades and slides up 16dp over 400ms, `ease-emphasized-decelerate`, arriving *after* the processing animation completes — never a hard cut, which can feel jarring after an anxious wait. |
| **Success confirmation** | Small checkmark draws on (path-draw animation, 300ms) inside a filled circle — used for "treatment marked as applied," "scan saved," etc. |
| **Error shake** | Reserved strictly for invalid form input (e.g., empty required field on submit) — a single 2-cycle horizontal shake, 200ms total, 4dp amplitude. Never used for AI-result "bad news" (a low-confidence or severe result is not a UI error and must never be animated like one). |
| **Loading skeletons** | Shimmer sweep left-to-right, 1.5s loop, low contrast (surface-variant tones only) — see Section 10.19. |

## 9.5 Motion Reduction

When the OS-level "Remove animations" / "Reduce motion" accessibility setting is on, CropCare AI: disables all non-essential motion (shimmer becomes a static low-opacity fill, pulse animation becomes a static icon with text-only progress updates), keeps only essential state-change cross-fades at reduced duration (100ms), and never disables functional motion entirely (e.g., a progress bar still visibly fills, just without easing flourishes).

---

# 10. Components

Every component below specifies structure, states, sizing, and usage rules. Unless noted, components follow M3 baseline behavior with CropCare AI's tokens (color/shape/spacing/type/motion) applied.

## 10.1 Buttons

| Variant | Usage | Height | Shape | Color |
|---|---|---|---|---|
| Filled | Single primary action per screen (e.g., "Scan Now", "Get Diagnosis") | 48dp (56dp for the one hero CTA on Home) | `shape-full` | Primary / On Primary |
| Filled (destructive) | Irreversible actions (delete history) | 48dp | `shape-full` | Error / On Error |
| Outlined | Secondary action alongside a filled button (e.g., "Retake Photo" next to "Use This Photo") | 48dp | `shape-full` | Outline border, On Surface text |
| Text | Low-emphasis actions (e.g., "Skip" on onboarding, "Learn more") | 40dp | `shape-full` | Primary text, no fill |
| Elevated | Rare — used only when a button sits on a busy/photo background and needs to visually lift off it (e.g., "Retake" over the camera preview) | 48dp | `shape-full` | Surface fill + Level 1 shadow |

**Rules:**
- Minimum touch target 48×48dp even if visual button is smaller (achieved via padding, never via clipping the tap target).
- Never more than **one filled button** visible on screen at a time — this is the app's primary method of directing attention to the single next best action, per "minimal cognitive load."
- Button label is always a verb phrase in sentence case: "Scan another leaf," not "New Scan" or "SCAN."
- Full-width buttons on compact screens for primary CTAs; auto-width (content + 24dp horizontal padding) for secondary/tertiary buttons.

## 10.2 Icon Buttons

- 48×48dp touch target, 24dp icon, circular `shape-full` ripple/state layer.
- Standard (transparent bg), Filled (Primary Container bg — used for toggled/active icon-only actions like "Save to favorites"), and Filled Tonal (Secondary Container bg — used for less critical toggles).
- Always carry an accessible label via `contentDescription`, even though no visible text label is shown.

## 10.3 FAB (Floating Action Button)

- **Single use case app-wide: launching the camera / starting a new scan.** No other feature ever uses a FAB, to preserve its meaning as "start a new diagnosis" everywhere it appears.
- Standard FAB (56dp) on Home and History screens. Extended FAB (56dp height, pill, with "Scan crop" label + camera icon) on Home specifically, to make the primary action unmistakable to first-time/low-literacy users.
- Color: Primary Container / On Primary Container.
- Position: bottom-right, 16dp margin from screen edges, sitting 16dp above the bottom navigation bar.

## 10.4 Navigation Bar (Bottom Nav — phone default)

- 4 destinations max (Home, History, Scan [center, visually emphasized as the FAB-integrated slot], Settings) — kept to 4 to avoid cramped 48dp-minimum touch targets and decision fatigue.
- 80dp height, `surface-container` background, Level 2 elevation on scroll-up only (flat at rest).
- Active item: filled icon + Primary-colored label (Label Medium) + Secondary Container "pill" indicator behind the icon (M3 standard active-indicator pattern).
- Inactive item: outlined icon + On Surface Variant label.

## 10.5 Navigation Rail (Tablet / landscape)

- Replaces bottom nav on Expanded width class and Medium-width landscape.
- 80dp wide, left-anchored, same 4 destinations, FAB docked at top of rail.

## 10.6 Bottom Sheet

- Used for: filter/sort options (History), share options, "more info" secondary detail (e.g., full ingredient list of a recommended treatment) that doesn't warrant a full screen.
- `shape-xl` top corners (28dp), drag handle (32×4dp, Outline Variant color) centered at top, 16dp below handle to first content.
- Modal (scrim behind) for focused decisions; non-modal/draggable-persistent never used in this app — every sheet is a deliberate, dismissible layer to avoid ambiguity about what's "active."

## 10.7 Cards

| Card Type | Elevation | Notes |
|---|---|---|
| Standard Card | Level 1 | List items: History Card, Recommendation Card |
| Emphasized Card | Level 3 | AI Result Card — the one card per screen allowed to visually lead |
| Outlined Card | Level 0 + 1dp Outline Variant border | Used in dense lists where shadow-stacking would look noisy (e.g., long History list) |

All cards: `shape-lg` (16dp), 16dp internal padding, tap target covers full card when the card itself is the primary interactive element (not just an inner button).

## 10.8 Dialogs

- `shape-xl` (28dp), Level 5 elevation, scrim at 32% black.
- Structure: Icon (optional, 24dp, centered) → Title (Title Large) → Body (Body Medium, max 3 sentences) → Actions (right-aligned, text buttons; destructive action never pre-focused/default).
- Used sparingly — only for irreversible actions (delete scan, discard unsaved report) or critical permission explanations. Never used for informational content that a snackbar or inline banner could handle instead (reduces interruption, supports "calm").

## 10.9 Snackbars

- `inverse-surface` background, `shape-sm`, single-line default (two-line max), optional single text-button action (e.g., "Undo").
- Auto-dismiss after 4s (extended to 7s if it contains an action button, per accessibility timing guidance), swipeable to dismiss early.
- Positioned above the bottom nav bar / FAB with 16dp margin, never overlapping tappable elements.

## 10.10 Text Fields

- **Filled style only** app-wide (not outlined), since filled fields have a clearer touch-target boundary for users less familiar with form conventions.
- 56dp height minimum, `shape-sm` top corners, Surface Variant fill, label floats above on focus/fill (M3 standard behavior).
- Helper/error text (Body Small) sits 4dp below the field; error state swaps outline+helper text to Error color and adds an error icon (16dp) at the field's trailing edge.
- **Minimize typing principle:** text fields are used only where unavoidable (Settings/profile fields, optional notes on a scan). Wherever a fixed set of options exists, a chip group, dropdown, or stepper replaces free text.

## 10.11 Search

- Persistent search bar (not icon-triggered) at the top of the History screen — 56dp height, `shape-full`, Surface Container background, leading search icon + trailing mic icon (voice search, supporting low-literacy/low-typing users).
- Expands to full-screen search-with-suggestions on focus; recent searches and common crop/disease names shown as tappable chips before any text is typed.

## 10.12 Dropdown (Menu)

- Used for short, well-known option sets (e.g., "Sort by: Most recent / Severity / Crop type").
- Trigger is a filled-tonal button showing current selection + trailing dropdown chevron (rotates 180° on open, `motion-fast`).
- Menu surface: `surface-container-highest`, Level 5, `shape-sm`, max-height with internal scroll beyond 6 items.

## 10.13 Checkbox / Switch / Radio Button

- **Checkbox:** multi-select lists (e.g., filter by multiple crop types). 24dp box, `shape-xs`, Primary fill + white check when checked.
- **Switch:** binary settings only (e.g., "Enable offline mode," "Push notifications"). 52×32dp M3 standard switch, Primary track when on.
- **Radio button:** single-select from a visible short list (e.g., language selection in onboarding). 20dp circle, Primary fill + dot when selected.
- Rule: never use a Switch for a choice that isn't a true on/off system state — use Radio for mutually exclusive *options* even if there are only two.

## 10.14 Progress Indicators

- **Linear determinate:** upload progress (photo upload bar), 4dp height, full width, Primary fill on Surface Variant track.
- **Circular determinate:** used only inside the AI Processing screen, 120dp diameter, paired with percentage text (Headline Small) in the center for scans that take >3s, so wait time always feels measured, not indefinite.
- **Indeterminate:** used only for sub-1-second operations where showing a percentage would be meaningless (e.g., brief local cache read) — kept extremely rare per "trustworthy AI" (indefinite spinners feel evasive for anything longer).

## 10.15 Loading Indicators & Skeleton Loading

- Skeleton screens (not spinners) are the default loading pattern for content-shaped loads: History list, Diagnosis Results while server data streams in after the AI processing animation completes.
- Skeleton blocks use `surface-container-high` base with a `surface-container-highest` shimmer sweep, matching the exact shape/size of the real content (card outlines, text-line bars) to prevent layout shift.

## 10.16 Image Picker

- Two entry points always presented together, never buried in a menu: **"Take Photo"** (filled button, primary — camera is the default/expected path) and **"Choose from Gallery"** (outlined button, secondary — for pre-existing photos or spotty-connectivity scenarios where a farmer photographed earlier and returns later).
- Multi-select disabled — one photo per diagnosis keeps the flow linear and reduces cognitive load; a "scan another angle" flow (Section 11.4) is offered afterward rather than upfront multi-select.

## 10.17 Camera Capture

- Full-screen viewfinder, minimal chrome: top bar has only a close (X) and flash toggle; bottom bar has gallery-import thumbnail (left), large circular shutter button (center, 72dp, white ring + Primary fill dot), and a toggleable **framing guide** (a soft-cornered rectangle overlay reading "Center the leaf" to coach good photo composition — directly supports diagnosis accuracy and reduces retake frustration).
- On capture: freeze-frame + review screen with "Retake" (outlined) and "Use Photo" (filled) — never auto-submits without user confirmation (error prevention principle).
- Auto-detects low light / excessive blur pre-capture and shows a non-blocking inline tip ("Tip: Move closer to natural light") rather than blocking capture — a farmer may still need to submit an imperfect photo in the field.

## 10.18 AI Result Card

The signature component of the app. Structure, top to bottom:

1. **Photo** (full-bleed top, 4:3 aspect ratio, `shape-lg` top corners only)
2. **AI Highlight badge** ("AI Diagnosis," small chip, top-left overlaid on photo, AI Highlight Container color) — always present so the AI origin of the content is unmissable
3. **Disease/Pest name** (Title Large, Bold) + common local name if available (Body Medium, On Surface Variant, in parentheses)
4. **Confidence Badge** + **Severity Badge** side by side (see 10.19–10.20)
5. **Short plain-language explanation** (Body Large, max 3 sentences — "what this means")
6. **Primary action row:** "View Treatment" (filled button) + "Ask a question" (outlined button, opens expert-referral or AI chat)
7. Expandable **"How the AI reached this conclusion"** disclosure (progressive disclosure — collapsed by default, Section 12.5)

Elevation Level 3, `shape-lg`, 16dp internal padding below the photo.

## 10.19 Confidence Badge

- Pill shape (`shape-xs`, not full-pill, to read as "data tag" not "button"), Label Medium text, leading 16dp icon (check-circle for High, info for Medium, warning for Low).
- Text always states both the tier label AND the percentage: "High confidence · 92%" — never percentage alone (supports low-literacy comprehension) and never label alone (supports users who want precision).
- Colors per Section 3.6.

## 10.20 Severity Badge

- Same pill treatment as Confidence Badge, positioned adjacent (never stacked, to allow quick side-by-side scanning).
- Text: severity tier only ("Moderate"), never a raw score, since severity is a qualitative clinical-style judgment, not a probability.
- Colors per Section 3.7.

## 10.21 Treatment Card

- Standard Card, Level 1.
- Structure: Treatment type icon (24dp — organic leaf icon, chemical flask icon, or cultural-practice icon) + Treatment name (Title Medium) + one-line summary (Body Medium) + "Est. cost" and "Time to apply" as small metadata chips + expand chevron for full instructions.
- Multiple Treatment Cards on the Treatment Details screen are ordered **organic/cultural options first, chemical options last**, reflecting sustainable-practice-first sequencing, with a persistent note that order is not a ranking of effectiveness.

## 10.22 Recommendation Card

- Used for prevention/best-practice tips (distinct from active Treatment Cards). Secondary Container background (visually lighter-weight than Treatment Cards) to signal "good to know" rather than "action required now."
- Structure: tip icon + short headline (Title Small) + 1–2 sentence body.

## 10.23 History Card

- Compact card (12dp padding), horizontal layout: 56×56dp thumbnail (`shape-sm`) + crop name & disease result (Title Small + Body Small) + Severity Badge (small) + relative timestamp (Label Small, trailing, On Surface Variant).
- Swipe-to-delete affordance (reveals Error-colored delete action on swipe) with confirmation dialog before actual deletion (error prevention).

## 10.24 Offline Banner

- Persistent (not dismissible), full-width, non-modal banner pinned just below the top app bar whenever connectivity is lost. `surface-container-highest` background with a leading Warning-colored cloud-off icon.
- Text: "You're offline. New scans will run when you're back online." — always paired with the current queue count if >0 ("2 scans waiting to upload").
- Never blocks interaction with already-cached content (History, previously completed diagnoses remain fully browsable offline).

## 10.25 Notification Banner (in-app)

- Used for transient, non-error system messages (e.g., "New disease database update available"). Info Container background, dismissible (X, trailing), max 2 lines, optional single text-button action.
- Distinct from Snackbar in that it's used for persistent-until-dismissed system state, while Snackbar is used for auto-expiring feedback on a just-completed action.

---

# 11. Screen Templates

## 11.1 Splash

- Duration: max 1.5s, or until app initialization completes (whichever is longer, capped at 3s before proceeding regardless).
- Layout: Primary Container background, centered logo mark (96dp) with a subtle 4% scale-in over 400ms, `ease-emphasized-decelerate`. No tagline animation, no loading spinner (initialization should be fast enough not to need one; if it isn't, fall through to a skeleton Home screen rather than extending splash).

## 11.2 Onboarding

- 3 screens max (fourth "permissions" screen counts separately, Section 11.13): (1) what the app does — photo-to-diagnosis in one sentence, (2) how it helps — confidence/treatment/prevention framed around trust, (3) language selection.
- Full-bleed illustration (not photography) top 60% of screen, headline + 1-sentence body below, page indicator dots, "Skip" text button top-right on all but the last screen, filled "Next"/"Get Started" button bottom.
- Swipeable horizontally in addition to button navigation.

## 11.3 Home

- Top app bar: app wordmark left, profile/settings icon right (no hamburger menu — all destinations live in bottom nav).
- Primary content: large Extended FAB-style "Scan a crop" hero CTA is visually the first thing below the app bar (not buried below other content) — directly serves "fast interactions" and "core user goal."
- Below: horizontal "Recent scans" row (max 5, card = mini History Card), then a vertical "Tips for you" Recommendation Card feed (contextual — e.g., seasonal pest alerts for the user's registered region/crop).
- If zero history: hero CTA remains identical; recent-scans row is replaced by the Empty State pattern (Section 15).

## 11.4 Camera

- Per Section 10.17. Additional template rule: after "Use Photo" is confirmed, a lightweight **optional** prompt appears — "Add a second angle? (optional)" with "Skip" (filled, since skipping is the faster/default path for most users) and "Add angle" (outlined) — never mandatory, never blocking the primary flow.

## 11.5 Gallery Upload

- Native OS photo picker is used (not a custom in-app gallery grid) wherever the platform supports it, to keep permissions minimal (scoped photo access) and behavior familiar. Selected photo flows into the same Review screen as camera capture (10.17) for consistency.

## 11.6 Scanning (AI Processing)

- Full-screen, calm background (Surface), centered processing animation (Section 9.4) with rotating micro-copy, and a determinate circular progress ring once the upload completes and server-side inference begins (Section 10.14).
- A single "Cancel" text button remains available throughout — never trap a user in a wait state (error prevention / respect for spotty connections where a scan may be worth aborting and retrying).
- If processing exceeds 8s, micro-copy shifts to reassurance mode: "Still working — this can take a little longer on slower connections."

## 11.7 Diagnosis Results

- Compact/phone: single column — AI Result Card (10.18) first, then Treatment Card previews (collapsed, tap to expand to full Treatment Details), then Recommendation Cards, then a "Not sure this is right?" expert-referral footer (always present, never conditional only on low confidence — reinforces that verification is always welcome, not a fallback for failure).
- Expanded/tablet: two-pane — left pane pinned photo + badges, right pane scrollable detail content.

## 11.8 Treatment Details

- Full detail per treatment option: ingredients/materials list, step-by-step application instructions (numbered, one action per step), safety precautions (if chemical — always shown, never collapsed, per safety-first error prevention), and a "Mark as applied" action that logs to History for future reference/follow-up reminders.

## 11.9 History

- Persistent search bar (10.11) + filter chip row (Crop type / Severity / Date range) at top, then vertical list of History Cards grouped by relative date headers ("Today," "This week," "Earlier").
- Empty state (Section 15) when no scans exist yet.

## 11.10 Settings

- Grouped list (M3 list-with-headers pattern): Account, Language & Region, Accessibility (Large Text toggle, reduce motion note — deep-links to OS setting since it can't be overridden in-app, high-contrast mode), Notifications, Offline & Data (manage cached storage, Wi-Fi-only upload toggle), About & Help, Legal.
- No nested settings deeper than 2 levels (list → sub-screen) to keep navigation shallow for less tech-confident users.

## 11.11 Profile

- Minimal: name, region/location (used for localized pest alerts), primary crops grown (chip multi-select), preferred language. Positioned as *optional context that improves recommendations*, never a gated requirement to use the core scan feature (a farmer can scan and get results with zero profile setup — "minimize typing," "error prevention" via not blocking core value).

## 11.12 Offline Mode (as a screen state, not a separate screen)

- Any screen that would normally require network (new scan submission) shows the Offline Banner (10.24) plus an inline explainer state where the primary CTA changes from "Get Diagnosis" to "Save for when you're back online" (filled button, same visual weight as the online CTA — offline is a supported path, not a degraded dead end).

## 11.13 Permissions

- One permission requested per screen, each with a plain-language "why" explanation *before* the OS system dialog fires (pre-permission priming pattern) — e.g., "CropCare AI needs camera access to photograph your crops for diagnosis" with "Allow" (filled) triggering the real OS prompt, and "Not now" (text button) allowed to proceed with reduced functionality rather than blocking app use entirely.
- Denied-permission states always offer a clear path to Settings to re-enable, with instructions, rather than a dead-end error.

## 11.14 Error Screens

- Full-screen error states (as opposed to inline/banner errors) are reserved for total blockers: app fails to initialize, critical data corruption. Structure: `icon-xxl` illustrative icon (Error or Warning color depending on severity), Headline Small message, Body Large explanation in plain language, single filled "Try Again" button, optional text-button "Contact Support."
- See Section 16 for the full inline error catalogue used in normal flows.

---

# 12. AI Experience Guidelines

## 12.1 Core Principle

CropCare AI's model is a **decision-support tool, not an authority.** Every piece of AI-generated UI content must communicate this without needing to say it outright every time — through consistent visual language (the AI Highlight color and badge, Section 3.5), consistent framing language (Section 18), and structural honesty about confidence and limits.

## 12.2 Confidence Score Communication

- Always shown as **both** a tier label and a percentage (Section 10.19) — never percentage alone, never label alone.
- Confidence is calculated and displayed per-diagnosis, never as a vague "AI accuracy" marketing stat.
- Confidence Badge is **always visible above the fold** on the Diagnosis Results screen — never buried, never optional to view.

## 12.3 Low-Confidence Messaging

When confidence is Low (<50%):
- The AI Result Card's primary framing text changes from a declarative statement ("This is Early Blight") to a hedged one ("This may be Early Blight, but we're not confident enough to be sure").
- The Confidence Badge itself carries the explicit instruction "verify with an expert" (Section 3.6) rather than requiring the user to infer that a low number means "go verify."
- The "Ask a question" / expert referral action is promoted to equal visual weight with "View Treatment" (both same button style/size) rather than being the secondary action — treatment should not be presented as equally actionable as verification when confidence is low.
- Treatment guidance for low-confidence results leads with **safe, low-risk general care actions** (e.g., improve drainage, remove visibly affected leaves) before any product-specific chemical recommendation, since acting on an uncertain diagnosis with a targeted chemical treatment carries real-world risk.

## 12.4 Handling Uncertainty & Avoiding Overconfidence

- The AI **never** states a diagnosis as absolute fact. Language templates (see Section 18.5) always use epistemically-hedged framing appropriate to the confidence tier — even High confidence results use "This is most likely..." rather than "This is..." for anything above a simple visual identification.
- The product never displays a bare "100%" confidence score in the UI even if the backend returns one; the display caps and rounds in a way that avoids implying mathematical certainty (e.g., cap displayed value at 99% or reframe as "Very high confidence").
- No diagnosis screen ever omits a path to human expert verification — the "Ask a question"/referral action is a permanent, non-conditional fixture of the AI Result Card (10.18), not a low-confidence-only fallback.

## 12.5 Explanations & Progressive Disclosure

- The default result view shows a **3-sentence-max plain-language explanation.** Users who want more can expand "How the AI reached this conclusion," which reveals: key visual symptoms the model detected (e.g., "yellow halo around lesions," "leaf curling"), how those compare to the identified disease's known signature, and — where applicable — the top 1–2 alternative possibilities the model considered and why it ruled them lower.
- This progressive disclosure structure directly serves "explain AI decisions clearly" without overwhelming first-time or low-literacy users who just want the headline answer.

## 12.6 Expert Referral

- Framed positively, never as a failure state: "Want a second opinion? Connect with a local agricultural extension officer" — never "The AI could not confidently diagnose this."
- Available as a persistent action regardless of confidence tier (Section 12.3), reinforcing that expert verification is a normal, encouraged part of the workflow rather than a rare emergency escape hatch.

## 12.7 Avoiding Hallucination Risk in UI

- The UI never invents specificity the model doesn't have. If treatment-cost or timing data isn't available for a given region, the field is omitted from the Treatment Card entirely rather than showing a placeholder or generic estimate that could be mistaken for verified local data.
- Any AI-sourced claim that has real-world safety implications (chemical dosage, application frequency) is visually flagged with a small Info-colored "verify product label" note directly beneath it — every single time, not just on lower-confidence results, since real product formulations vary regionally and by brand.

## 12.8 Severity vs. Confidence — Never Conflated

- Severity (Section 3.7) reflects how serious the *identified condition* is if the diagnosis is correct. Confidence (Section 3.6) reflects how sure the *model* is that the diagnosis is correct. These are shown side-by-side (10.18–10.20) but styled and labeled distinctly enough that users cannot mistake a "Severe / Low confidence" result for a mild or certain one — this combination in particular should trigger the strongest possible push toward expert verification in the copy (Section 18.5).

---

# 13. Accessibility

CropCare AI targets **WCAG 2.2 Level AA** as a hard minimum across every screen, with several requirements exceeding AA where the target user characteristics (older users, low vision, outdoor glare, low connectivity) warrant it.

## 13.1 Contrast

| Requirement | Standard | CropCare AI target |
|---|---|---|
| Body text vs background | 4.5:1 (AA) | 4.5:1 minimum, all palette pairs in Section 3 audited to meet or exceed |
| Large text (24sp+/18sp bold+) vs background | 3:1 (AA) | 3:1 minimum |
| Icons & UI graphics vs background | 3:1 (AA) | 3:1 minimum |
| Critical status color pairs (Error, Warning, Confidence, Severity) | 4.5:1 (AA) | **4.5:1 even at large-text sizes**, since these signals must never be misread |

All new color combinations added to the system in the future must be run through a contrast checker against every surface they'll appear on before shipping.

## 13.2 Touch Targets

- **48×48dp minimum** for every interactive element, per M3/Android accessibility guidance — applied without exception, including icon buttons, chip close icons, and checkbox/radio hit areas (visual control may be smaller; hit area is not).
- 8dp minimum spacing between adjacent touch targets (Section 5.5).

## 13.3 Font Scaling

- All text uses `sp` units and layouts use flexible/wrap containers so the app supports OS font scaling up to **200%** without clipped or overlapping text (Section 4.6).
- Critical status text (Confidence/Severity badges) is tested specifically at 200% scale to confirm badges reflow to multi-line gracefully rather than truncating.

## 13.4 Screen Readers (TalkBack / VoiceOver)

- Every interactive element has a meaningful accessible label (`contentDescription` on Android, `accessibilityLabel` on iOS) — icon-only buttons are never left with generic or missing labels.
- The AI Result Card's reading order is: Photo (labeled "Photo of scanned crop"), AI badge, disease name, confidence ("High confidence, 92 percent"), severity ("Moderate severity"), explanation text, then action buttons — a logical, linear order matching visual hierarchy.
- Status changes (upload complete, scan result ready, offline banner appearing) are announced via live regions (`accessibilityLiveRegion` / ARIA-live equivalent) so screen reader users aren't left waiting silently.
- Decorative images (onboarding illustrations) are marked to be skipped by screen readers; informational images (the user's crop photo) always have a label.

## 13.5 Color Blindness

- No status or semantic meaning (confidence, severity, success/error) is ever conveyed by color alone — every instance pairs color with an icon shape (check/warning/error) and a text label (Sections 10.19–10.20).
- Palette has been checked against Protanopia, Deuteranopia, and Tritanopia simulation; the Confidence and Severity scales in particular avoid relying on a pure red/green distinction (Severe uses a red that remains distinguishable from Mild's olive-yellow-green even under deuteranopia simulation, reinforced by icon + label).

## 13.6 Landscape Support

- All screens support landscape orientation on tablets (navigation rail layout, Section 2.3/11). On phones, landscape is supported for the Camera and Diagnosis Results screens specifically (common real-world postures when photographing crops or showing results to another person), with other screens allowed to letterbox/scroll rather than requiring bespoke landscape layouts, to keep engineering scope realistic.

## 13.7 Motion Reduction

- Respects OS "Reduce motion" setting app-wide per Section 9.5.

## 13.8 Additional Considerations for the Stated User Base

- **Language clarity for non-fluent English speakers:** UI copy is written at a plain-language reading level (Section 18.2) and the app supports full localization (Section 19), not just UI-chrome translation — AI explanation templates are localized, not machine-translated at runtime, to avoid degraded clarity in the moment it matters most.
- **Outdoor/bright-sunlight legibility:** addressed structurally via the light-theme-default decision (Section 3), high body-text contrast targets, larger-than-typical default body text (17sp, Section 4.2), and avoidance of shadow-only elevation cues (Section 8.1).
- **Unreliable internet:** addressed structurally via the full Offline Experience system (Section 14), not treated as an edge case.

---

# 14. Offline Experience

Offline is treated as a **first-class, expected state**, not an edge case — a direct response to the "unreliable internet" user characteristic.

## 14.1 Detection & Signaling

- Connectivity state is monitored continuously; any loss triggers the persistent Offline Banner (10.24) within 2 seconds, and recovery triggers a brief Success-colored "Back online" snackbar plus automatic resumption of any queued actions.

## 14.2 Loading Under Poor Connectivity

- Any network call with no response after 5s shows an inline "This is taking longer than usual" message alongside the existing loading indicator, rather than leaving the user watching an indicator with no context.
- Image uploads use resumable/chunked upload where feasible so a dropped connection mid-upload doesn't force a full photo re-upload from zero.

## 14.3 Retry

- All failed network actions surface a **retry action inline**, at the point of failure (e.g., a failed scan shows "Couldn't connect. Retry" directly on the Scanning screen) rather than only via a generic global error screen.
- Automatic retry with backoff happens silently up to 2 attempts before surfacing the manual retry UI, so brief connectivity blips don't require user intervention at all.

## 14.4 Cached History

- All previously completed diagnoses (photo, result, treatment detail, badges) are cached fully on-device and remain 100% browsable with zero functionality loss while offline — History, Treatment Details, and Settings are fully offline-capable screens.

## 14.5 Pending Uploads

- A new scan taken while offline is saved locally with a **"Pending"** state (distinct badge: neutral Outline-colored "Pending upload" chip instead of a Confidence/Severity badge, since no diagnosis exists yet) and shown in History in its queued position.
- Pending scans auto-submit the moment connectivity returns; the user is notified via snackbar ("2 scans uploaded, results ready") rather than needing to manually re-trigger anything.
- A "Wi-Fi only for uploads" setting (Settings → Offline & Data) is available and **on by default**, respecting that mobile data may be limited/costly for this user base — clearly labeled so users understand why an upload might be waiting even with a cellular connection present.

---

# 15. Empty States

Every empty state follows the same structure: `icon-xxl` or lightweight illustration (Secondary/Tertiary tone, never the alarming Error color) → Title Medium headline → Body Medium supporting line → one clear filled-button action that resolves the emptiness.

| Screen | Icon/Illustration | Headline | Body | Action |
|---|---|---|---|---|
| Home (first launch / zero history) | Leaf-with-camera illustration | "Let's diagnose your first crop" | "Take a photo of any pest or disease symptoms you're seeing." | "Scan a crop" (filled, opens Camera) |
| History (no scans yet) | Empty folder / leaf icon | "No scans yet" | "Your diagnosis history will show up here." | "Scan a crop" (filled) |
| History (filtered, no matches) | Search-off icon | "No matches found" | "Try adjusting your filters." | "Clear filters" (text button) |
| Search (no query yet) | Search icon | — (shows recent/suggested chips instead of headline) | "Search by crop or disease name" | Suggested chips |
| Notifications (none) | Bell-off icon | "You're all caught up" | "We'll notify you about important updates here." | None (informational only) |

Rule: an empty state is never a dead end. It always either explains why the space is empty or offers the single next action that fills it.

---

# 16. Error States

Errors are handled **inline, at the point of failure**, using Warning or Error coloring appropriate to severity, plain-language copy (Section 18.4), and — wherever possible — a way forward rather than a dead stop (error prevention and recovery both matter, but prevention is prioritized: e.g., blur detection warns before submission, Section 10.17).

| Scenario | Presentation | Message | Recovery Action |
|---|---|---|---|
| **Camera unavailable** (permission denied or hardware error) | Full-screen state within Camera flow | "We can't access your camera. You can still upload a photo from your gallery." | "Choose from Gallery" (filled) + "Open Settings" (text, if permission-related) |
| **Image too blurry** | Inline banner on Review screen (Warning) | "This photo looks a little blurry, which may affect accuracy. Want to retake it?" | "Retake Photo" (filled) + "Use Anyway" (outlined) — never blocks submission entirely, since a blurry photo may still be all the user has access to |
| **No internet** (attempting new scan) | Inline state replacing submit button, plus Offline Banner | "You're offline. We'll run this scan as soon as you're back online." | "Save for Later" (filled) — becomes the primary action; framed as a supported path, not a failure |
| **AI unavailable** (backend/model error) | Inline error card on Scanning screen (Error) | "Something went wrong on our end. Your photo is saved — please try again." | "Retry" (filled) — photo is preserved, never lost |
| **Unknown disease/pest** (model returns no confident match) | Treated as a valid, distinct result type on Diagnosis Results — not a generic error | "We couldn't identify a specific cause from this photo." + general plant-health guidance | "Ask a question" (expert referral, filled) + "Try another photo" (outlined) |
| **Low confidence** | Handled within the normal AI Result Card per Section 12.3, not as a separate error UI | — | — |
| **Form validation error** (e.g., empty required Settings field) | Inline field-level (Section 10.10) + brief shake (Section 9.4) | Specific, field-level message (e.g., "Please enter your region") | Focus returns to the field automatically |

## 16.1 Error Copy Rules

- Never show a raw system/network error code or stack trace to the user. Log it for diagnostics; show plain language.
- Never blame the user ("Invalid photo") — frame around the situation ("This photo looks a little blurry").
- Always state what happens next, even if that's simply "please try again."

---

# 17. Design Tokens

Implementation-ready tokens, structured for direct use in a design-token pipeline (e.g., Style Dictionary) feeding Android Compose Theme, iOS SwiftUI, and/or a shared design-token JSON consumed by CI. Naming convention: `category.role.variant` in lower-kebab-case, e.g., `color.primary.default`.

## 17.1 Color Tokens (Light Theme excerpt — Dark Theme mirrors with `-dark` suffix or separate theme file)

```
color.primary.default        = #2E7D32
color.primary.on             = #FFFFFF
color.primary.container      = #B4F1AE
color.primary.on-container   = #00210A

color.secondary.default      = #54634C
color.secondary.on           = #FFFFFF
color.secondary.container    = #D7E8CB
color.secondary.on-container = #121F0E

color.tertiary.default       = #38656A
color.tertiary.on            = #FFFFFF
color.tertiary.container     = #BCEBF0
color.tertiary.on-container  = #002023

color.success.default        = #2E7D32
color.success.container      = #B4F1AE
color.warning.default        = #8A5700
color.warning.container      = #FFE0B2
color.error.default          = #BA1A1A
color.error.container        = #FFDAD6
color.info.default           = #0061A4
color.info.container         = #D1E4FF

color.surface.default            = #FBFDF8
color.surface.container-lowest   = #FFFFFF
color.surface.container-low      = #F5F7F0
color.surface.container          = #EFF2E9
color.surface.container-high     = #E9EBE4
color.surface.container-highest  = #E3E6DE
color.surface.variant            = #DEE5D8

color.outline.default        = #72796C
color.outline.variant        = #C2C9BB

color.text.on-surface         = #1A1C18
color.text.on-surface-variant = #42493E
color.text.disabled           = rgba(#1A1C18, 0.38)

color.ai-highlight.default    = #6750A4
color.ai-highlight.container  = #EADDFF

color.confidence.high    = #2E7D32
color.confidence.medium  = #8A5700
color.confidence.low     = #8C4A00

color.severity.healthy   = #2E7D32
color.severity.mild      = #7C8C00
color.severity.moderate  = #8A5700
color.severity.severe    = #BA1A1A
```

## 17.2 Spacing Tokens

```
space.2  = 2dp
space.4  = 4dp
space.8  = 8dp
space.12 = 12dp
space.16 = 16dp   // default screen margin, default card padding
space.24 = 24dp
space.32 = 32dp
space.48 = 48dp
space.64 = 64dp
```

## 17.3 Radius Tokens

```
shape.none = 0dp
shape.xs   = 4dp    // badges, chips
shape.sm   = 8dp    // text fields, snackbars, chips
shape.md   = 12dp   // dialogs (small), images
shape.lg   = 16dp   // cards, bottom sheet top
shape.xl   = 28dp   // large dialogs, bottom sheet, onboarding
shape.full = 50%    // buttons, FAB, avatar
```

## 17.4 Elevation Tokens

```
elevation.0 = { surface: surface, shadow: none }
elevation.1 = { surface: surface.container-low, shadow: 1dp/8% }
elevation.2 = { surface: surface.container, shadow: 3dp/10% }
elevation.3 = { surface: surface.container-high, shadow: 6dp/12% }
elevation.4 = { surface: surface.container-high, shadow: 8dp/14% }
elevation.5 = { surface: surface.container-highest, shadow: 12dp/16% }
```

## 17.5 Typography Tokens

```
type.headline-large   = { size: 32sp, line-height: 40sp, weight: 500, tracking: 0 }
type.headline-medium  = { size: 28sp, line-height: 36sp, weight: 500, tracking: 0 }
type.headline-small   = { size: 24sp, line-height: 32sp, weight: 500, tracking: 0 }
type.title-large      = { size: 22sp, line-height: 28sp, weight: 500, tracking: 0 }
type.title-medium     = { size: 18sp, line-height: 24sp, weight: 500, tracking: 0.15sp }
type.title-small      = { size: 16sp, line-height: 20sp, weight: 500, tracking: 0.1sp }
type.body-large       = { size: 17sp, line-height: 26sp, weight: 400, tracking: 0.15sp }  // default body
type.body-medium      = { size: 15sp, line-height: 22sp, weight: 400, tracking: 0.25sp }
type.body-small       = { size: 13sp, line-height: 18sp, weight: 400, tracking: 0.4sp }
type.label-large      = { size: 15sp, line-height: 20sp, weight: 500, tracking: 0.1sp }
type.label-medium     = { size: 13sp, line-height: 16sp, weight: 500, tracking: 0.5sp }
type.label-small      = { size: 12sp, line-height: 16sp, weight: 500, tracking: 0.5sp }

font.family.primary   = "Roboto Flex"
font.family.fallback  = "Roboto, Noto Sans, sans-serif"
```

## 17.6 Motion Tokens

```
motion.duration.fast        = 100ms
motion.duration.short       = 200ms
motion.duration.medium      = 300ms
motion.duration.long        = 400ms
motion.duration.extra-long  = 500-700ms

motion.easing.standard              = cubic-bezier(0.2, 0, 0, 1)
motion.easing.emphasized            = cubic-bezier(0.05, 0.7, 0.1, 1)
motion.easing.emphasized-decelerate = cubic-bezier(0.05, 0.7, 0.1, 1)
motion.easing.emphasized-accelerate = cubic-bezier(0.3, 0, 0.8, 0.15)
```

## 17.7 Component Size Tokens

```
size.touch-target.min       = 48dp
size.button.height           = 48dp
size.button.height-hero      = 56dp
size.button.height-text      = 40dp
size.icon.xs                 = 16dp
size.icon.sm                 = 20dp
size.icon.md                 = 24dp   // default
size.icon.lg                 = 32dp
size.icon.xl                 = 48dp
size.icon.xxl                = 64dp
size.fab.standard            = 56dp
size.nav-bar.height           = 80dp
size.nav-rail.width           = 80dp
size.text-field.height        = 56dp
size.app-bar.height           = 64dp
size.thumbnail.history-card   = 56dp
size.camera-shutter           = 72dp
```

## 17.8 Naming Convention Rules

1. All tokens are lowercase, kebab-case, dot-namespaced by category: `{category}.{role}.{variant}`.
2. Semantic tokens (e.g., `color.success.default`) are the only tokens referenced directly in component code — raw hex/dp values (Section 3–9 tables) are the *source* that generates these tokens, never hardcoded a second time in implementation.
3. Component-specific overrides, if ever needed, are named `{component}.{property}.{state}` (e.g., `fab.elevation.pressed`) and must resolve back to a base token, never an arbitrary new value.

---

# 18. UX Writing Guidelines

## 18.1 Tone of Voice

CropCare AI writes like a **knowledgeable, calm field colleague** — never like a corporate app, never like a lab report. Warm but not chatty; confident but not certain; plain but not condescending.

| Do | Don't |
|---|---|
| "This looks like it could be Early Blight." | "DIAGNOSIS COMPLETE: EARLY BLIGHT DETECTED" |
| "Let's take another look — try getting a bit closer." | "Image quality insufficient. Retry capture." |
| "You're offline. We'll run this scan as soon as you're back online." | "Network error 0x8007. Connection required." |
| "Want a second opinion? Talk to a local expert." | "Confidence too low for reliable diagnosis." |

## 18.2 Reading Level

- Target **Grade 6–7 reading level** (Flesch-Kincaid) for all in-app copy, including AI explanation templates — appropriate for a broad, multilingual, variable-literacy user base.
- Short sentences (aim ≤15 words). One idea per sentence. Avoid subordinate clauses stacked together.
- No agricultural-science jargon without a plain-language gloss: "Early Blight (a common fungal leaf disease)" on first mention within a result, not just the Latin/technical name alone.

## 18.3 Button Text

- Always a specific verb + object: "Scan a crop," "View treatment," "Retake photo" — never vague labels like "OK," "Submit," or "Continue" where a more specific label is possible.
- Sentence case always. No exclamation points on standard actions (reserved, sparingly, only for genuine positive milestones like a first completed scan).

## 18.4 Error Messages

Structure: **[What happened, plainly] + [What to do next].** Never technical codes. Never passive-voice blame. See full catalogue in Section 16.

## 18.5 AI Result Language Templates

| Confidence Tier | Template |
|---|---|
| High | "This is most likely **{disease_name}**." |
| Medium | "This could be **{disease_name}**, though we're only moderately confident." |
| Low | "We're not confident, but this may be **{disease_name}**. We'd recommend checking with a local expert." |
| Severe + any confidence below High | "This looks serious, and we're not fully certain — we strongly recommend getting an expert opinion soon." |

## 18.6 Success Messages

- Specific and calm, never celebratory-loud: "Scan saved to your history," "Treatment marked as applied," "You're back online — 2 scans uploaded."
- No more than one exclamation point per screen, ever, and only for genuinely positive user-initiated milestones (never for routine confirmations).

## 18.7 Farmer-Friendly Wording Glossary

| Avoid | Use Instead |
|---|---|
| "Inference complete" | "Here's what we found" |
| "Insufficient data" | "We need a clearer photo" |
| "Model confidence" | "How sure we are" |
| "Query" | "Search" |
| "Sync" | "Update" / "Save" |
| "Null result" | "We couldn't find a match" |
| "Timeout" | "This is taking longer than usual" |

## 18.8 General Rules

1. Every screen's most important message is the first thing a screen-reader user hears and the first thing a skimming eye lands on.
2. Never use humor around a result that could represent real crop/income loss — warmth comes from clarity and support, not jokes, on Diagnosis Results, Treatment, and Error screens. Onboarding and empty states can carry slightly more personality.
3. Numbers are always paired with words for critical data ("High confidence · 92%"), never numbers alone.

---

# 19. Internationalization

## 19.1 Text Direction

- **LTR is the current default and only shipped direction.** All layouts are built using directional-agnostic layout properties (`start`/`end` rather than `left`/`right`) from day one so that a future RTL rollout (for Arabic/Urdu-speaking farming regions) requires configuration, not re-engineering.
- Icons that carry inherent directionality (back arrow, chevrons) are flagged in the component library as "mirror in RTL" so future localization tooling can auto-mirror them.

## 19.2 Long Text Support

- No fixed-width text containers for translatable strings. Buttons, chips, and badges use intrinsic/content-based sizing with defined min-width only, never max-width clipping — since translated strings (especially into German, Sinhala, Tamil) frequently run 30–50% longer than English source text.
- Two-line wrapping is the accepted default for button labels and badges under long-text locales rather than truncation with ellipsis, since truncated critical data (confidence/severity) is unacceptable.

## 19.3 Units

- **Metric units by default** (°C, cm, hectares, kg/ha for treatment dosage) reflecting the primary target regions. An Imperial toggle is available in Settings for regions/users who need it, but metric is the baseline assumption throughout copy templates and treatment data.

## 19.4 Local Languages

- Full UI and AI-explanation-template localization (not just marketing copy) is required for each supported language at launch — partial localization (English AI content inside a localized shell) is explicitly disallowed, since inconsistent language mixing undermines trust and comprehension for the target user base.
- Disease and pest names always show **both** the localized/common regional name and the standard scientific name, e.g., "Early Blight (Alternaria solani)" — supporting both farmer recognition and extension-officer/consultant precision.
- Voice input (Section 10.11 mic icon) and, in future iterations, voice output for AI explanations are treated as core accessibility features for this user base, not nice-to-haves, given documented literacy variability.

## 19.5 Localization Process Notes

- All user-facing strings live in externalized resource files (never hardcoded in component code) from the start of implementation, keyed semantically (`diagnosis.confidence.low.label`), not by raw English text, to support clean translation handoff.
- Date/time formats, number formats (decimal comma vs. period), and currency (for treatment cost estimates) all follow device locale automatically.

---

# 20. Future Scalability

The design system is deliberately built with headroom for CropCare AI to grow from a single-purpose diagnosis tool into a broader farm-management platform, without requiring a redesign.

## 20.1 Weather Forecasting

- The existing Tertiary color role and Info semantic role are reserved partly for this future surface (weather/environmental data reads as "contextual intelligence," distinct from AI-diagnosis-purple and core-brand-green).
- Home screen's "Tips for you" Recommendation Card feed (11.3) is architected as a generic contextual-content slot, so weather-driven alerts ("Rain expected — hold off on spraying") can be injected into that same feed without new screen templates.

## 20.2 Crop Monitoring (ongoing, not single-scan)

- History (11.9) is structured around individual scans today, but its data model (crop type, location, timestamp) is compatible with future grouping into a **per-plot or per-crop timeline view** — a new tab/filter within History rather than a new IA branch.

## 20.3 Expert Chat

- The "Ask a question" action already present on every AI Result Card (10.18) and referenced throughout Section 12 is the deliberate seam for this feature — it currently can route to static contact info/resources, and can be upgraded to a live chat surface without changing any upstream screen, since the entry point and its framing language are already in place.
- Chat UI, when built, will reuse the AI Highlight vs. neutral-surface color distinction to clearly separate AI-suggested responses from human-expert responses within the same thread.

## 20.4 Marketplace

- Treatment Cards (10.21) already display "Est. cost" metadata — the natural extension point for a "Buy this product" action is an additional button slot within the existing card footer, reusing the Filled/Outlined button pair pattern rather than introducing new card types.

## 20.5 Farm Records

- Profile (11.11) is intentionally scoped as lightweight/optional today; it is the designated future home for structured farm-record data (plot size, planting dates, past yields) as an expanded, still-optional, profile section — never a blocking requirement for core scan functionality, preserving the "minimize typing / error prevention" principle as the product grows.

## 20.6 Notifications

- The Notification Banner component (10.25) and a dedicated Notifications settings group (11.10) are already in the v1 system specifically so that future notification types (weather alerts, seasonal pest warnings, expert chat replies, marketplace order updates) all have an established visual and behavioral home rather than needing bespoke treatment per feature.

## 20.7 Community Features

- The Secondary/Tertiary color roles and the existing card component family (Standard, Recommendation) are designed to be reusable for future community content (e.g., "Farmers near you are reporting...") without introducing a third visual language — community-sourced content would adopt a new, clearly-labeled badge (parallel to the AI Highlight badge pattern) rather than a whole new component set, keeping the system's total surface area small as it grows.

## 20.8 Scalability Principle

Any future feature should be evaluated against the same north star as v1 (Section 1.4): does it reduce stress and support fast, confident decisions for a farmer in the field? Features that add complexity without clearly serving that goal should extend the system's *content*, not its *visual vocabulary* — new colors, shapes, or component patterns should be proposed only when a genuinely new semantic category (not covered by AI/Success/Warning/Error/Info/Confidence/Severity) emerges.

---

*End of design.md — CropCare AI Design System v1.0*
