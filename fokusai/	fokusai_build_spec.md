# FokusAI — Build Spec (iOS / SwiftUI)

This is a build specification for an AI coding agent. Build the Phase 1 MVP described below. Work incrementally in the build order in Section 11, keeping the app compiling and runnable on the iOS Simulator after every step.

---

## 1. Product summary

**FokusAI** is a native iOS app that helps teenagers beat procrastination.

The core loop: the user enters a task they're avoiding → AI breaks it into 2–5 minute microtasks that are trivially easy to start → the user completes steps and earns XP, streaks, and upgrades.

The design thesis: procrastination is driven by *task-initiation friction* and anxiety, not laziness. So the app lowers the activation energy of starting, converts vague work into concrete actions, and rewards showing up. The tone is calm and encouraging, never shaming. Audience is teenagers, so collect the absolute minimum personal data.

## 2. Platform & stack

- **Language / UI:** Swift + SwiftUI, targeting iOS 26, built in Xcode 26.
- **Architecture:** lightweight MVVM — SwiftUI `View`s backed by `@Observable` service/model classes.
- **Backend:** Supabase — Postgres (data), Supabase Auth (accounts), Edge Functions (server-side AI proxy).
- **AI:** Anthropic Claude Haiku 4.5, called **only** from a Supabase Edge Function, never from the app.
- **Notifications:** Apple `UserNotifications` (local only).
- **Packages:** `supabase-swift` via Swift Package Manager (`https://github.com/supabase/supabase-swift`). No other dependencies without asking.

## 3. Architecture (three tiers — do not violate)

```
SwiftUI app  ──>  Supabase (Auth + Postgres)
     │
     └────────>  Supabase Edge Function "decompose"  ──>  Anthropic API
```

- The app holds the Supabase **publishable** key only. That is safe because Row Level Security is enabled on every table.
- The Anthropic API key and any Supabase **secret** key live ONLY in Edge Function secrets. Never in the app binary, never in source control.
- The app calls the `decompose` Edge Function; the function calls Anthropic and returns microtask JSON.

## 4. Brand & design system

**Name:** FokusAI. **Concept:** deep blue for calm and focus — the app should feel like a quiet room, with one warm accent that lights up only for action and reward.

### Color tokens

Define these once in a `Theme.swift` as a `Color` extension backed by an Asset Catalog color set with light/dark variants. Never hardcode hex values in views.

| Token | Dark (default) | Light | Use |
|---|---|---|---|
| `bg` | `#0B1A2F` | `#F4F7FC` | App background (deep navy) |
| `surface` | `#16273D` | `#FFFFFF` | Cards, sheets |
| `surfaceRaised` | `#1E3350` | `#E9EFF8` | Elevated / pressed states |
| `brand` | `#4C8DFF` | `#2D6CDF` | Primary interactive blue, focus ring, progress |
| `accent` | `#FFC857` | `#E8A317` | **Reserved**: start buttons, XP, streak flame, rewards |
| `success` | `#4FD1A5` | `#2FA37E` | Completion checks |
| `textPrimary` | `#F2F5FA` | `#0B1A2F` | Headlines, body |
| `textSecondary` | `#9AAFC7` | `#5B7189` | Captions, hints |
| `stroke` | `#FFFFFF14` | `#0B1A2F14` | Hairline borders |

**Accent discipline is the most important rule here:** amber `accent` appears ONLY on the primary action ("Start"), the XP/streak indicators, and reward moments. Everything else is blue and quiet. That contrast is what makes starting a task feel like the obvious next move.

### Type & shape

- System font (SF Pro), Dynamic Type supported throughout. Titles `.largeTitle`/`.title2` semibold; body `.body`; captions `.footnote` in `textSecondary`.
- Corner radius 16 on cards, 12 on buttons, 999 (capsule) on pills and the primary Start button.
- Generous spacing: 16pt screen padding, 12pt between cards.
- Dark mode is the **default and primary** design; light mode must work but is secondary.
- Motion: gentle spring animations (`.spring(response: 0.35, dampingFraction: 0.8)`). Rewards are quick and satisfying — under 1 second, never blocking.

### The Focus Orb

FokusAI's mascot is not a creature — it's a **glowing orb** that represents the user's focus. It's a simple SwiftUI shape: a circle with a radial gradient from `brand` to `accent`, with a soft outer glow. Its state maps to progress:

- **Dim** (low opacity, small glow) when there are no active tasks.
- **Pulsing slowly** while a microtask timer is running.
- **Flares bright** on a microtask completion.
- Its glow radius grows subtly with the user's current level.

The orb appears on `HomeView` and `MicrotaskFocusView`. Keep it pure SwiftUI — no image assets required.

## 5. Data model

Six Postgres tables. `profiles` is keyed to Supabase's built-in `auth.users`. Row Level Security is enabled on all of them so a user can only touch their own rows. Mirror each as a `Codable` Swift struct.

- **profiles** — `id` (uuid, = auth.users.id), `created_at`, `estimate_multiplier` (double, default 1.0), `xp` (int, default 0), `level` (int, default 1), `streak_count` (int, default 0), `longest_streak` (int, default 0), `last_active_date` (date), `freezes_available` (int, default 2), `procrastination_type` (text), `selected_theme` (text, default 'deep_focus')
- **tasks** — `id`, `user_id`, `title`, `task_type` (text), `created_at`, `status` (active | done | abandoned)
- **microtasks** — `id`, `task_id`, `order_index` (int), `text`, `estimated_minutes` (int), `actual_minutes` (int, nullable), `status` (todo | done | skipped), `completed_at` (nullable)
- **feedback** — `id`, `microtask_id`, `user_id`, `size_rating` (too_big | just_right | too_small, nullable), `created_at`
- **upgrades** — `id`, `key`, `name`, `category` (theme | orb | sound | flair), `unlock_level` (int), `description`
- **user_upgrades** — `user_id`, `upgrade_id`, `unlocked_at`

## 6. The decompose Edge Function (contract the app codes against)

The agent does NOT implement this function (it's TypeScript, deployed separately). The Swift app must call it with this request and decode this response.

**Request (app → function):**
```json
{
  "task": {
    "title": "string (required)",
    "context": {
      "deadline": "YYYY-MM-DD (optional)",
      "format": "essay | problem_set | reading | test | project | chore (optional)",
      "scope": "string (optional)",
      "rubric": "string (optional)",
      "source_material": "string (optional)",
      "time_available_now_minutes": 30
    }
  },
  "personalization": {
    "estimate_multiplier": 1.4,
    "recent_size_feedback": "string (optional)"
  }
}
```

**Response (function → app):**
```json
{
  "task_type": "structured_deliverable | problem_set | reading_review | test_study | open_project | admin",
  "microtasks": [
    { "order": 1, "text": "string", "estimated_minutes": 3 }
  ]
}
```

Handle these states explicitly in the UI: loading, network failure, malformed response, and empty result. Never crash on a bad payload — show a friendly retry.

## 7. Screens

- **OnboardingView** — 3 short screens. Captures exactly one thing: a tap choosing `procrastination_type` (homework | studying | chores | other). Shown once. Ends by introducing the Focus Orb.
- **AuthView** — email + password via Supabase Auth. No real name required.
- **HomeView** — the Focus Orb at top; a compact stat bar showing streak (amber flame + count) and level/XP progress ring; a list of active task cards; a prominent capsule "+ New task" button in `accent`. Empty state is warm and invites the first task.
- **NewTaskView** — a single large text field ("What are you putting off?"). Below it, a collapsed **"Add details"** disclosure exposing optional context (deadline, format, scope, rubric, time available now) and an "attach a photo of the assignment" button. The point is that only the title is required — never gate the user behind a form.
- **DecompositionLoadingView** — the Focus Orb pulsing with a calm line like "Breaking this into small pieces…".
- **TaskDetailView** — returned microtasks as an ordered checklist of cards. Step 1 is visually emphasized ("Start here"). Shows overall progress.
- **MicrotaskFocusView** — one microtask, large and centered; the Focus Orb pulsing; a countdown timer; copy like "Just start — only 3 minutes." Two buttons: **"Done"** (`accent`) and **"Ran out of time"** (quiet, `textSecondary`). Both are treated as showing up.
- **RewardOverlay** — a brief XP-gain animation over the orb flare. Non-blocking, dismisses itself.
- **ProfileView** — streak and longest streak, level and XP progress, the upgrades grid, daily reminder time picker, sign-out.
- **UpgradesView** — grid of upgrade cards; locked ones show the unlock level, not a paywall. Tapping an unlocked theme/orb applies it immediately.

## 8. Services (Swift, `@Observable`)

- **SupabaseService** — client init; auth; CRUD for all tables.
- **DecompositionService** — assembles the request (pulling `estimate_multiplier` and recent feedback from the profile), invokes the `decompose` function, decodes, writes microtasks to Postgres.
- **GamificationService** — XP, levels, streaks, freezes, upgrade unlocks. Rules in Section 9.
- **PersonalizationService** — recomputes `estimate_multiplier` from actual-vs-estimated minutes and size ratings.
- **NotificationService** — schedules the daily reminder and optional per-task reminders. Encouraging tone only.
- **ThemeService** — applies the user's `selected_theme` to the token set.

## 9. Gamification system

The design constraint that overrides everything: **this audience overlaps heavily with anxiety and ADHD, so every mechanic must be forgiving.** Streak-loss shame backfires in exactly the users we're trying to help. Rewards motivate; punishment produces avoidance, which is the thing the app exists to fix.

### XP and levels

- **+10 XP** per microtask completed.
- **+5 XP** for "Ran out of time" — showing up still counts. This is deliberate and non-negotiable.
- **+25 XP** bonus for completing a whole task.
- **Occasional random +5–15 XP** "focus bonus" on roughly 1 in 5 completions, with a small orb flare. Unpredictable rewards sustain motivation better than perfectly predictable ones (variable-ratio schedule) — this is the healthy version of the dopamine loop the app is replacing.
- **Levels** use a gentle curve: level *n* requires `50 * n * (n + 1) / 2` cumulative XP (L2 at 50, L3 at 150, L4 at 300, L5 at 500…). Level-up shows a full orb bloom.

### Streaks (forgiving by design)

- A streak day = at least **one** microtask completed (not a whole task). The bar is intentionally low.
- **Freezes:** `freezes_available` starts at 2, caps at 3, and refills +1 for each week with 4+ active days. If a day is missed and a freeze is available, consume it and preserve the streak. Tell the user warmly afterward ("We used a streak freeze — you're still going").
- **On a genuine break:** never shame. Copy is "Streaks restart, progress doesn't. Your XP and upgrades are safe." Offer a one-tap tiny task to restart immediately.
- **Notifications** are never guilt-based. Never "You're about to lose your streak!" Instead: "One 2-minute step keeps it alive."
- Track `longest_streak` separately so a break never erases the user's best achievement.

### Upgrades (the reward store)

Unlocked by **level**, never purchased. Seed these rows:

| key | category | name | unlock_level |
|---|---|---|---|
| `deep_focus` | theme | Deep Focus (default deep blue) | 1 |
| `orb_classic` | orb | Classic Orb | 1 |
| `flair_ember` | flair | Ember streak flame | 2 |
| `orb_nebula` | orb | Nebula Orb (violet-blue gradient) | 3 |
| `theme_midnight` | theme | Midnight (near-black + brand blue) | 4 |
| `sound_chime` | sound | Soft chime on completion | 5 |
| `orb_aurora` | orb | Aurora Orb (teal-green shift) | 6 |
| `theme_dawn` | theme | Dawn (warm light mode) | 8 |
| `flair_gold` | flair | Gold streak flame | 10 |

Themes re-skin the token set; orbs change the orb's gradient; flair changes the streak icon; sounds add a completion chime. All cosmetic — never gate functionality behind an upgrade.

## 10. Copy & tone rules

- Encouraging, plain, teen-appropriate, never childish, never corporate.
- Never use "should," "failed," "missed," or "behind."
- Stopping early is framed as a win. Every session ends on a positive note.
- Microtask language stays concrete and physical.

## 11. Build order (keep it runnable at every step)

1. **Scaffold + design system.** Project structure, `Theme.swift` with the token set, Asset Catalog colors, the Focus Orb component. Static `HomeView` and `NewTaskView` with mock in-memory data. Runs on the Simulator.
2. **Task flow on mock data.** `TaskDetailView` and `MicrotaskFocusView` with a working countdown timer and both completion buttons. Tappable end-to-end.
3. **Supabase.** Add `supabase-swift` via SPM, implement `SupabaseService`, Auth, the six tables with Row Level Security; replace mock data with real persistence.
4. **AI decomposition.** Implement `DecompositionService` against the Section 6 contract; wire `NewTaskView` to produce real microtasks with full loading/error handling.
5. **Gamification.** `GamificationService` + `PersonalizationService`: XP, levels, forgiving streaks, the stat bar, `RewardOverlay`, and the feedback-driven multiplier.
6. **Notifications.** `NotificationService` + reminder settings in `ProfileView`.
7. **Upgrades + onboarding.** `UpgradesView`, `ThemeService`, and the 3-screen onboarding.

## 12. Guardrails for the agent

- **Never** embed the Anthropic key or a Supabase secret key in the app. The app only calls the Edge Function and uses the publishable key.
- Enable Row Level Security on every table before any real data goes in.
- Modern SwiftUI only: `@Observable`, `@State`, `NavigationStack`. Avoid UIKit unless genuinely unavoidable.
- Use the design tokens — no hardcoded hex in views. Respect the accent-discipline rule.
- Stay strictly in MVP scope. Do **NOT** build app-blocking, screen-time overlays, or social features — those are a later phase with an Apple entitlement dependency.
- This app is used by minors: collect the minimum data, and keep every mechanic forgiving and non-shaming.
- Ask before adding any dependency or exceeding the current build-order step.
