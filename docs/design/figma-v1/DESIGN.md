---
name: Warm Pastel Social Connection
colors:
  surface: '#fcf9f4'
  surface-dim: '#dcdad5'
  surface-bright: '#fcf9f4'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3ee'
  surface-container: '#f0ede9'
  surface-container-high: '#ebe8e3'
  surface-container-highest: '#e5e2dd'
  on-surface: '#1c1c19'
  on-surface-variant: '#444748'
  inverse-surface: '#31302d'
  inverse-on-surface: '#f3f0eb'
  outline: '#747878'
  outline-variant: '#c4c7c7'
  surface-tint: '#5f5e5e'
  primary: '#010101'
  on-primary: '#ffffff'
  primary-container: '#1c1c1c'
  on-primary-container: '#858484'
  inverse-primary: '#c8c6c5'
  secondary: '#445b9f'
  on-secondary: '#ffffff'
  secondary-container: '#9db4fd'
  on-secondary-container: '#2b4486'
  tertiary: '#6d5e16'
  on-tertiary: '#ffffff'
  tertiary-container: '#bdab5c'
  on-tertiary-container: '#4b3f00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e5e2e1'
  primary-fixed-dim: '#c8c6c5'
  on-primary-fixed: '#1b1b1b'
  on-primary-fixed-variant: '#474746'
  secondary-fixed: '#dbe1ff'
  secondary-fixed-dim: '#b4c5ff'
  on-secondary-fixed: '#00174b'
  on-secondary-fixed-variant: '#2b4385'
  tertiary-fixed: '#f7e28d'
  tertiary-fixed-dim: '#dac674'
  on-tertiary-fixed: '#221b00'
  on-tertiary-fixed-variant: '#534600'
  background: '#fcf9f4'
  on-background: '#1c1c19'
  surface-variant: '#e5e2dd'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.03em
  display-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.03em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system is crafted for playful in-person networking, gamified icebreakers, and event interactions (such as chit-chat challenges and QR-based social discovery). It breaks down traditional corporate awkwardness into warm, joyful micro-moments. The emotional target is approachable, serene, cheerful, and unpretentious—giving participants the psychological safety to connect naturally.

The visual style merges contemporary soft minimalism with tactile, rounded neo-editorial aesthetics:
- **Warm, Canvas-like Surfaces:** Tactile cream and almond backdrops that prevent screen fatigue and evoke warm stationery.
- **Card-Centric Bento Layouts:** Playful pastel blocks that segment challenges, avatars, questions, and participant profiles into distinct, tangible pods.
- **High-Contrast Anchors:** Bold charcoal/obsidian floating pill navigations and crisp line icons to keep the gentle pastel interface grounded and modern.

## Colors

The palette relies on a warm off-white foundation paired with muted confectionery pastels and obsidian anchors:

- **Base Canvas & Cards:**
  - Background Neutral: `#FAF7F2` (Soft warm canvas)
  - Surface Neutral / Card Base: `#FFFFFF` (Crisp white cards) and `#F6F1EB` (Subtle container cream)
- **Primary Contrast:**
  - Charcoal Primary: `#1C1C1C` (Primary floating CTA pills, active tab anchors, deep contrast headlines)
  - Secondary Slate: `#4A4844` (Subtle body copy, secondary metadata)
- **Pastel Palette (Functional & Gamification Tones):**
  - **Periwinkle / Blue:** `#B8C5F2` (Base) & `#9EB5FF` (Active / Accent) – Used for icebreaker prompts and connection counts.
  - **Buttermilk / Honey Yellow:** `#F8E38E` & `#FCE881` – Used for challenges, spark alerts, and highlighted badges.
  - **Sage / Mint Green:** `#B8DBC9` & `#88B89E` – Used for successful matches, unlocked perks, and online/active statuses.
  - **Soft Terracotta / Coral:** `#F3A592` – Used for urgent discovery cues, conversation topics, and dynamic tags.
- **Borders & Dividers:**
  - Soft Border: `#EFE8DE` (Barely-there warmth preserving clean separation).

## Typography

The typography uses `Plus Jakarta Sans` across all roles to achieve a soft-geometric, modern, and friendly presence. Headings feature snug letter-spacing with selective inline bolding to create expressive conversational titles (e.g., "Exercises based on **your needs**"). Small uppercase or title-case category trackers sit cleanly above bold headings to ground the information architecture without visual clutter.

## Layout & Spacing

Layouts follow an asymmetrical, playful bento grid structure suited for fast-scannable mobile interfaces:
- **Columns & Canvases:** Mobile layouts utilize a 4-column fluid framework with `1.25rem` outer margins. Desktop/tablet companions adapt into centered fixed containers (`max-w-md` to `max-w-lg` for mobile-first companion experiences).
- **Rhythm & Padding:** Cards and interactive tiles use internal padding of `1.25rem` (`20px`) to `1.5rem` (`24px`). Content blocks breathe with `1rem` inter-card gaps.
- **Floating Safe Area:** Bottom views reserve a dedicated clearance buffer of `5rem` (`80px`) to accommodate the signature floating obsidian pill navigation.

## Elevation & Depth

Visual hierarchy relies on chromatic contrast and soft pill stacking rather than heavy dropshadows:
- **Flat Pastel Tonal Blocks:** Level-0 surfaces sit directly on `#FAF7F2` or `#F6F1EB`. Card blocks use flat pastel fills (`#B8C5F2`, `#F8E38E`, `#B8DBC9`, `#F3A592`) with no shadows, allowing colors to articulate spatial hierarchy.
- **Frosted Translucent Pods:** Bottom navigation docks and circular quick-action controls utilize soft frosted glass (`rgba(255, 255, 255, 0.85)` with `16px` backdrop blur and `1px` subtle border `#FFFFFF60`).
- **Floating Action Elevation:** Floating primary charcoal buttons and dark floating tabs feature an ambient, tinted low-opacity shadow: `0 12px 28px -6px rgba(28, 28, 28, 0.16)`.

## Shapes

The shape vocabulary emphasizes ultra-rounded, friendly, pebble-like curves:
- **Tiles and Bento Cards:** Radii range from `1.5rem` (`24px`) to `1.75rem` (`28px`), giving large blocks a soft, organic feel.
- **Buttons, Badges, and Chips:** Full pill geometry (`rounded-full` / `9999px`).
- **Circular Micro-Interactions:** Action triggers, arrow shortcuts, and circular avatar indicators use true 1:1 circle aspect ratios with centered micro-glyphs.

## Components

### Buttons & Quick Triggers
- **Primary Charcoal Pill:** `#1C1C1C` background with pure white text, fully rounded (`rounded-full`), `h-12` or `h-14`, semi-bold body.
- **Micro Arrow Discs:** Embedded within pastel tiles (bottom-right aligned), these are subtle circular buttons (`w-8 h-8` or `w-10 h-10`) filled with translucent black (`rgba(0,0,0,0.06)`) and a sleek diagonal directional arrow (`↗`).

### Interactive Chips & Tags
- Pill-shaped tags using soft-tinted pastels with charcoal text (`#1C1C1C`). Used for user interests, networking icebreaker tags (e.g., "Tech & Design", "Coffee Lover"), and game statuses.

### Networking Cards & Bento Blocks
- **Pastel Category Tiles:** Distinct tinted blocks (`#B8C5F2`, `#F8E38E`, `#B8DBC9`, `#F3A592`) containing concise title copy, minimalistic line illustrations, and micro arrow triggers.
- **High-Contrast QR Identification Card:** A pure white rounded card (`rounded-[28px]`) with generous padding, embedding an obsidian-on-cream QR code, participant profile avatar, and instant scan badge.

### Floating Bottom Navigation Bar
- A centered floating capsule dock (`rounded-full`) resting above the viewport bottom. Houses an active dark pill block (`#1C1C1C` background with white icon) alongside minimalist outline icons for social discovery, quest logs, and profile settings.

### Input Fields
- Ultra-rounded container inputs (`rounded-2xl` to `rounded-full`) with `#F6F1EB` or warm white background, subtle border, placeholder text in `#7A7874`, and an inline action button on the trailing edge.