-- ══════════════════════════════════════════════════════════════
-- Habit Tracker — Complete Database Schema
-- Run once in: Supabase Dashboard → SQL Editor → New query
-- ══════════════════════════════════════════════════════════════


-- ── 1. habits ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS habits (
  id          TEXT PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL CHECK (char_length(name) <= 60),
  time_start  TEXT,
  time_end    TEXT,
  sort_order  INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE habits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "habits: user owns rows"
  ON habits FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- ── 2. check_ins ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS check_ins (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  habit_id    TEXT NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  check_date  DATE NOT NULL,
  UNIQUE (habit_id, check_date)
);

ALTER TABLE check_ins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "check_ins: user owns rows"
  ON check_ins FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- ── 3. user_meta ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_meta (
  user_id       UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  xp            INTEGER DEFAULT 0 CHECK (xp >= 0),
  perfect_days  DATE[]  DEFAULT '{}',
  freeze_tokens INTEGER DEFAULT 0 CHECK (freeze_tokens >= 0),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_meta ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_meta: user owns row"
  ON user_meta FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- ── 4. profiles ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name  TEXT,
  avatar_url    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 所有已登录用户可读取他人 profile（社交层需要）
CREATE POLICY "profiles: authenticated users can read"
  ON profiles FOR SELECT
  USING (auth.role() = 'authenticated');

-- 只能写自己的 profile
CREATE POLICY "profiles: user owns row (insert)"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles: user owns row (update)"
  ON profiles FOR UPDATE
  USING  (auth.uid() = id)
  WITH CHECK (auth.uid() = id);


-- ── 5. Auto-create profile on signup ─────────────────────────
-- 新用户注册/Google 登录后自动写入 profiles 表
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1)
    ),
    NEW.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
