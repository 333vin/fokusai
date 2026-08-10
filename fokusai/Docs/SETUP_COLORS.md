# Asset Catalog Color Setup Instructions

## Required Action: Add Color Sets to Assets.xcassets

The app references 10 color tokens via the `Color` extension in `Theme.swift`. You need to add these color sets to your `Assets.xcassets` catalog with light and dark mode variants.

### How to Add Each Color:

1. Open `Assets.xcassets` in Xcode
2. Right-click in the left sidebar → **New Color Set**
3. Name the color set exactly as shown below (case-sensitive)
4. In the Attributes Inspector (right sidebar), set **Appearances** to "Any, Dark"
5. Set the hex values for **Any Appearance** (light mode) and **Dark Appearance** (dark mode)

---

## Color Definitions

### 1. bg
- **Dark (default):** `#0B1A2F`
- **Light:** `#F4F7FC`
- **Use:** App background (deep navy)

### 2. surface
- **Dark:** `#16273D`
- **Light:** `#FFFFFF`
- **Use:** Cards, sheets

### 3. surfaceRaised
- **Dark:** `#1E3350`
- **Light:** `#E9EFF8`
- **Use:** Elevated / pressed states

### 4. brand
- **Dark:** `#4C8DFF`
- **Light:** `#2D6CDF`
- **Use:** Primary interactive blue, focus ring, progress

### 5. accent
- **Dark:** `#FFC857`
- **Light:** `#E8A317`
- **Use:** **Reserved**: start buttons, XP, streak flame, rewards

### 6. success
- **Dark:** `#4FD1A5`
- **Light:** `#2FA37E`
- **Use:** Completion checks

### 7. textPrimary
- **Dark:** `#F2F5FA`
- **Light:** `#0B1A2F`
- **Use:** Headlines, body text

### 8. textSecondary
- **Dark:** `#9AAFC7`
- **Light:** `#5B7189`
- **Use:** Captions, hints

### 9. stroke
- **Dark:** `#FFFFFF14` (white at 14/255 ≈ 5.5% opacity = `rgba(255, 255, 255, 0.078)`)
- **Light:** `#0B1A2F14` (navy at 14/255 ≈ 5.5% opacity = `rgba(11, 26, 47, 0.078)`)
- **Use:** Hairline borders

**Note on stroke:** The `14` suffix in hex is an alpha channel. In Xcode's color picker:
- Dark: RGB (255, 255, 255) with Opacity ~8%
- Light: RGB (11, 26, 47) with Opacity ~8%

---

## Quick Reference Table

| Name | Dark Hex | Light Hex |
|------|----------|-----------|
| bg | #0B1A2F | #F4F7FC |
| surface | #16273D | #FFFFFF |
| surfaceRaised | #1E3350 | #E9EFF8 |
| brand | #4C8DFF | #2D6CDF |
| accent | #FFC857 | #E8A317 |
| success | #4FD1A5 | #2FA37E |
| textPrimary | #F2F5FA | #0B1A2F |
| textSecondary | #9AAFC7 | #5B7189 |
| stroke | #FFFFFF (8% opacity) | #0B1A2F (8% opacity) |

---

## Verification

After adding all colors, build the project. If any color is missing, you'll see a runtime warning in the console. The app should display:

- **Dark mode (default):** Deep navy background with blue accents
- **Light mode:** Light gray background with darker blue accents
- **Accent discipline:** Amber/gold only appears on the "+ New task" button, streak flame, and "Done" buttons

---

## Design System Rules (from spec)

1. **Never hardcode hex values in views** — always use `Color.tokenName`
2. **Accent discipline:** Amber `accent` appears ONLY on:
   - Primary "Start" / "Done" buttons
   - XP/streak indicators
   - Reward moments
3. **Dark mode is primary** — light mode must work but is secondary
4. **Support Dynamic Type** throughout (already handled by using system fonts)
