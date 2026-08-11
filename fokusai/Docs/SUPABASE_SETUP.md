# Step 3: Supabase Integration - Complete! ✅

## What Was Built ????

### 1. **SupabaseConfig.swift**
Configuration file with placeholders for your Supabase credentials.

**Action Required:**
- Replace `YOUR_PROJECT_ID` with your actual Supabase project ID
- Replace `YOUR_ANON_PUBLIC_KEY_HERE` with your anon/public key

### 2. **DATABASE_SCHEMA.sql**
Complete SQL schema for all 6 tables + RLS policies + triggers.

**What it includes:**
- ✅ `profiles` - User profiles with XP, levels, streaks
- ✅ `tasks` - User tasks
- ✅ `microtasks` - Broken-down steps
- ✅ `feedback` - Size ratings for personalization
- ✅ `upgrades` - Cosmetic rewards (seeded with 9 upgrades)
- ✅ `user_upgrades` - Unlocked upgrades per user
- ✅ Row Level Security (RLS) on all tables
- ✅ Auto-create profile trigger on signup

### 3. **SupabaseService.swift**
Singleton service for authentication.

**Methods:**
- `checkSession()` - Restore existing session
- `signUp(email:password:)` - Create new account
- `signIn(email:password:)` - Sign in
- `signOut()` - Sign out
- `resetPassword(email:)` - Send reset link

### 4. **DatabaseService.swift**
All CRUD operations for tasks, microtasks, profiles, feedback, upgrades.

**Key Operations:**
- Profile: fetch, update, create
- Tasks: fetch, create, update, delete (with microtasks)
- Microtasks: update, complete
- Feedback: submit, fetch recent
- Upgrades: fetch available, fetch user's, unlock

### 5. **AuthView.swift**
Beautiful sign-in/sign-up screen.

**Features:**
- Email + password fields
- Toggle between sign up / sign in
- Password reset flow
- Form validation
- Error handling
- FokusAI branding with orb
- Follows design system

### 6. **Updated Models**
Added Supabase-compatible fields and CodingKeys.

**Changes:**
- `Task` - Added `userId` and snake_case CodingKeys
- `Microtask` - Added `taskId` and snake_case CodingKeys
- `AppState` - Replaced mock data with real Supabase calls

### 7. **Updated App Flow**
ContentView now handles auth state.

**Flow:**
1. Splash screen
2. Check auth session
3. If not authenticated → AuthView
4. If authenticated → HomeView
5. HomeView loads tasks from Supabase

---

## Setup Instructions

### Part 1: Create Supabase Project

1. Go to https://app.supabase.com
2. Click **"New Project"**
3. Choose a name (e.g., "fokusai")
4. Set a strong database password (save it!)
5. Choose a region close to your users
6. Click **"Create new project"**

### Part 2: Get Your Credentials

1. In your project dashboard, go to **Settings → API**
2. Copy the **Project URL** (looks like `https://abc123.supabase.co`)
3. Copy the **anon/public** key (long string starting with `eyJ...`)
4. Open `Config/SupabaseConfig.swift`
5. Replace the placeholder values:

```swift
static let supabaseURL = "https://YOUR_ACTUAL_PROJECT_ID.supabase.co"
static let supabaseAnonKey = "eyJhbGci...YOUR_ACTUAL_KEY"
```

### Part 3: Run the Database Schema

1. In your Supabase dashboard, go to **SQL Editor**
2. Click **"New query"**
3. Copy the entire contents of `DATABASE_SCHEMA.sql`
4. Paste into the SQL editor
5. Click **"Run"**
6. Verify: You should see "Success. No rows returned"

### Part 4: Add the Supabase Swift Package

1. In Xcode, go to **File → Add Packages...**
2. Enter the URL: `https://github.com/supabase/supabase-swift`
3. Choose **"Up to Next Major Version"** with `2.0.0`
4. Click **"Add Package"**
5. Select **Supabase** (the main product)
6. Click **"Add Package"** again

---

## Verification Checklist

After setup, verify everything works:

### ✅ Configuration
- [ ] `SupabaseConfig.swift` has real credentials (not placeholders)
- [ ] `SupabaseConfig.isConfigured` returns `true`

### ✅ Database
- [ ] All 6 tables exist in Supabase dashboard (Database → Tables)
- [ ] `upgrades` table has 9 rows (the seed data)
- [ ] RLS is enabled on all tables (green shield icon)

### ✅ Package
- [ ] `supabase-swift` package added successfully
- [ ] No build errors related to missing imports

### ✅ App Flow
- [ ] App builds successfully
- [ ] Splash screen appears
- [ ] Auth screen appears (not signed in)
- [ ] Can create account
- [ ] Can sign in
- [ ] HomeView loads after sign-in
- [ ] Can create tasks
- [ ] Tasks persist after app restart

---

## Testing the Integration

### 1. Test Sign Up
```
Email: test@fokusai.com
Password: test123456
```

- Should create account
- Should auto-create profile in database
- Should navigate to HomeView

### 2. Test Task Creation
- Click "+ New task"
- Enter title: "Test task"
- Click "Break it down"
- Should appear in HomeView
- Refresh Supabase dashboard → `tasks` table should have 1 row

### 3. Test Microtask Completion
- Tap the test task
- Tap "START HERE"
- Wait or tap "Done"
- Check Supabase → `microtasks` table should show `status = 'done'`
- Check `profiles` table → `xp` should be `10`

### 4. Test Sign Out (when ProfileView is built)
- Sign out
- Should return to AuthView
- Sign back in
- Tasks should still be there

---

## Architecture Notes

### Data Flow
```
View (SwiftUI)
  ↓
AppState (@Observable)
  ↓
DatabaseService
  ↓
SupabaseClient (from package)
  ↓
Supabase Cloud (Postgres + RLS)
```

### Security
- ✅ **Anon key in app** - Safe, RLS protects data
- ❌ **Secret key in app** - NEVER! Only in Edge Functions
- ✅ **RLS enabled** - Users can only see their own data
- ✅ **No API keys in git** - Add `.env` to `.gitignore` in production

### State Management
- `SupabaseService` - Singleton, handles auth state
- `DatabaseService` - Stateless, pure CRUD operations
- `AppState` - Observable, bridges database ↔ views
- Views observe `AppState`, automatically update on changes

---

## Next Steps

### Immediate (to complete Step 3):
1. Add Supabase credentials to `SupabaseConfig.swift`
2. Run `DATABASE_SCHEMA.sql` in Supabase
3. Add `supabase-swift` package in Xcode
4. Build and test sign up flow

### Future Steps (later phases):
- **Step 4:** Real AI decomposition via Edge Function
- **Step 5:** Full gamification (streak freeze, level-up animation, etc.)
- **Step 6:** Notifications
- **Step 7:** Upgrades + Onboarding

---

## Troubleshooting

### "Supabase is not configured" crash
→ Update `SupabaseConfig.swift` with real credentials

### "Invalid API key" error
→ Make sure you copied the **anon** key, not the **service_role** key

### Tasks don't load
→ Check RLS policies are enabled (run full SQL schema)

### Can't sign up
→ Check Supabase dashboard → Authentication → Users for errors

### Build errors about missing Supabase module
→ Add the `supabase-swift` package via SPM

---

## Files Created

```
Config/
  └── SupabaseConfig.swift
Services/
  ├── SupabaseService.swift
  └── DatabaseService.swift
Views/
  └── AuthView.swift
DATABASE_SCHEMA.sql
SUPABASE_SETUP.md (this file)
```

## Files Modified

```
Models/
  ├── Task.swift (added userId, CodingKeys)
  ├── Microtask.swift (added taskId, CodingKeys)
  └── AppState.swift (Supabase integration, async methods)
Views/
  ├── NewTaskView.swift (async task creation)
  └── MicrotaskFocusView.swift (async completion)
ContentView.swift (auth state management)
```

---

**Status:** Step 3 complete, pending your Supabase credentials! 🚀
