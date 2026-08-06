-- FokusAI Database Schema
-- Run this SQL in your Supabase SQL Editor
-- https://app.supabase.com/project/YOUR_PROJECT/sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- PROFILES TABLE
-- ============================================================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    estimate_multiplier DOUBLE PRECISION DEFAULT 1.0,
    xp INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    streak_count INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    last_active_date DATE,
    freezes_available INTEGER DEFAULT 2,
    procrastination_type TEXT,
    selected_theme TEXT DEFAULT 'deep_focus'
);

-- ============================================================================
-- TASKS TABLE
-- ============================================================================
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    task_type TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'done', 'abandoned'))
);

-- ============================================================================
-- MICROTASKS TABLE
-- ============================================================================
CREATE TABLE microtasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    order_index INTEGER NOT NULL,
    text TEXT NOT NULL,
    estimated_minutes INTEGER NOT NULL,
    actual_minutes INTEGER,
    status TEXT DEFAULT 'todo' CHECK (status IN ('todo', 'done', 'skipped')),
    completed_at TIMESTAMPTZ
);

-- ============================================================================
-- FEEDBACK TABLE
-- ============================================================================
CREATE TABLE feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    microtask_id UUID NOT NULL REFERENCES microtasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    size_rating TEXT CHECK (size_rating IN ('too_big', 'just_right', 'too_small')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- UPGRADES TABLE (seed data)
-- ============================================================================
CREATE TABLE upgrades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('theme', 'orb', 'sound', 'flair')),
    unlock_level INTEGER NOT NULL,
    description TEXT
);

-- ============================================================================
-- USER_UPGRADES TABLE
-- ============================================================================
CREATE TABLE user_upgrades (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    upgrade_id UUID NOT NULL REFERENCES upgrades(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, upgrade_id)
);

-- ============================================================================
-- INDEXES for performance
-- ============================================================================
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_microtasks_task_id ON microtasks(task_id);
CREATE INDEX idx_microtasks_status ON microtasks(status);
CREATE INDEX idx_feedback_user_id ON feedback(user_id);

-- ============================================================================
-- SEED UPGRADES DATA
-- ============================================================================
INSERT INTO upgrades (key, name, category, unlock_level, description) VALUES
    ('deep_focus', 'Deep Focus', 'theme', 1, 'Default deep blue theme'),
    ('orb_classic', 'Classic Orb', 'orb', 1, 'Original gradient orb'),
    ('flair_ember', 'Ember', 'flair', 2, 'Warm ember streak flame'),
    ('orb_nebula', 'Nebula Orb', 'orb', 3, 'Violet-blue gradient'),
    ('theme_midnight', 'Midnight', 'theme', 4, 'Near-black with brand blue'),
    ('sound_chime', 'Soft Chime', 'sound', 5, 'Completion sound effect'),
    ('orb_aurora', 'Aurora Orb', 'orb', 6, 'Teal-green shift'),
    ('theme_dawn', 'Dawn', 'theme', 8, 'Warm light mode'),
    ('flair_gold', 'Gold Flame', 'flair', 10, 'Gold streak icon');

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE microtasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_upgrades ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can only read/update their own profile
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Tasks: Users can only access their own tasks
CREATE POLICY "Users can view own tasks"
    ON tasks FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tasks"
    ON tasks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tasks"
    ON tasks FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tasks"
    ON tasks FOR DELETE
    USING (auth.uid() = user_id);

-- Microtasks: Users can only access microtasks for their own tasks
CREATE POLICY "Users can view own microtasks"
    ON microtasks FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM tasks
            WHERE tasks.id = microtasks.task_id
            AND tasks.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert own microtasks"
    ON microtasks FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM tasks
            WHERE tasks.id = microtasks.task_id
            AND tasks.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update own microtasks"
    ON microtasks FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM tasks
            WHERE tasks.id = microtasks.task_id
            AND tasks.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete own microtasks"
    ON microtasks FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM tasks
            WHERE tasks.id = microtasks.task_id
            AND tasks.user_id = auth.uid()
        )
    );

-- Feedback: Users can only access their own feedback
CREATE POLICY "Users can view own feedback"
    ON feedback FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own feedback"
    ON feedback FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Upgrades: Public read (all users can see available upgrades)
CREATE POLICY "Anyone can view upgrades"
    ON upgrades FOR SELECT
    USING (true);

-- User Upgrades: Users can only access their own unlocked upgrades
CREATE POLICY "Users can view own upgrades"
    ON user_upgrades FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can unlock upgrades"
    ON user_upgrades FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- TRIGGER: Auto-create profile on user signup
-- ============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id)
    VALUES (NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- COMPLETE! Your database is ready for FokusAI
-- ============================================================================
