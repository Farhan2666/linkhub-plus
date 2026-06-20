-- Jalankan SQL ini di Supabase Dashboard → SQL Editor
-- https://supabase.com/dashboard/project/rnbfzfwkxxdpixhvilnx/sql/new

-- =========================================================
-- 1. Create profiles table (id matches auth.users id)
-- =========================================================
CREATE TABLE IF NOT EXISTS profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique not null,
  page_data jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- =========================================================
-- 2. Index for fast username lookup
-- =========================================================
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles (username);

-- =========================================================
-- 3. Enable Row Level Security
-- =========================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- =========================================================
-- 4. RLS Policies
-- =========================================================
-- Anyone can view public profiles
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

-- Users can insert their own profile (id must match auth.uid())
CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- =========================================================
-- 5. Auto-create profile on signup (safety net — app also does this)
-- =========================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = ''
AS $$
BEGIN
  INSERT INTO public.profiles (id, username, page_data)
  VALUES (
    NEW.id,
    LOWER(REGEXP_REPLACE(SPLIT_PART(NEW.email, '@', 1), '[^a-z0-9_]', '', 'g')),
    '{"profile":{"avatar":"","name":"Your Name","bio":"Digital creator & content maker","status":"open to work","statusEmoji":"✨"},"links":[{"id":"1","title":"E-Commerce App","url":"https://example.com","icon":"🛍️","description":"Full-stack marketplace","category":"Web Apps","color":""},{"id":"2","title":"Weather Dashboard","url":"https://example.com","icon":"🌦️","description":"Real-time weather","category":"Web Apps","color":""},{"id":"3","title":"Fitness Tracker","url":"https://example.com","icon":"🏃","description":"Mobile workout tracker","category":"Mobile Apps","color":""}],"socials":[{"platform":"Instagram","url":"https://instagram.com","icon":"instagram"},{"platform":"Twitter","url":"https://twitter.com","icon":"twitter"},{"platform":"GitHub","url":"https://github.com","icon":"github"}],"theme":{"bgType":"gradient","primaryColor":"#5D34D0","secondaryColor":"#FF006E","accentColor":"#00F0FF","cardOpacity":0.06,"cardBlur":12,"glowIntensity":1,"solidColor":"#0a0014","particleColor":"#FF006E","particleCount":50}}'::jsonb
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =========================================================
-- 6. ⚠️ IMPORTANT: Supabase Auth Settings
--    Di Supabase Dashboard → Authentication → Settings:
--    - Site URL: https://linkhub-plus.vercel.app
--    - Redirect URLs: https://linkhub-plus.vercel.app
--    - JWT expiry: 3600 (default, refresh token otomatis)
-- =========================================================
