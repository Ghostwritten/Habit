-- ============================================================
-- Habit Tracker — Supabase Database Schema
-- 在 Supabase Dashboard → SQL Editor 中粘贴并执行
-- ============================================================

-- ── 用户档案 ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  display_name  TEXT,
  avatar_emoji  TEXT    DEFAULT '😊',
  motto         TEXT    DEFAULT '',
  lang          TEXT    DEFAULT 'en',
  theme         TEXT    DEFAULT 'dark',
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── 习惯列表 ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.habits (
  id          TEXT PRIMARY KEY,                  -- "habit_<timestamp>" or UUID
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name        TEXT    NOT NULL,
  time_start  TEXT,                              -- "HH:MM" 24-hour, nullable
  time_end    TEXT,                              -- "HH:MM" 24-hour, nullable
  sort_order  INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 每日打卡记录 ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.check_ins (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  habit_id    TEXT REFERENCES public.habits(id) ON DELETE CASCADE NOT NULL,
  check_date  DATE NOT NULL,                     -- YYYY-MM-DD
  UNIQUE (habit_id, check_date)
);

-- ── 用户元数据（XP、完美天、护盾）────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_meta (
  user_id        UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  xp             INTEGER  DEFAULT 0,
  perfect_days   TEXT[]   DEFAULT '{}',          -- ISO date strings
  freeze_tokens  INTEGER  DEFAULT 0,
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ── 行级安全策略（RLS）────────────────────────────────────────
ALTER TABLE public.profiles  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.habits    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.check_ins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_meta ENABLE ROW LEVEL SECURITY;

-- profiles: 仅本人可读写
CREATE POLICY "profiles_self" ON public.profiles
  FOR ALL USING (auth.uid() = id);

-- habits: 仅本人可读写
CREATE POLICY "habits_self" ON public.habits
  FOR ALL USING (auth.uid() = user_id);

-- check_ins: 仅本人可读写
CREATE POLICY "checkins_self" ON public.check_ins
  FOR ALL USING (auth.uid() = user_id);

-- user_meta: 仅本人可读写
CREATE POLICY "meta_self" ON public.user_meta
  FOR ALL USING (auth.uid() = user_id);

-- ── 新用户注册时自动创建 profile & meta ───────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1)
    )
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.user_meta (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
