-- Jalankan SQL ini di Supabase Dashboard → SQL Editor
-- https://supabase.com/dashboard/project/rnbfzfwkxxdpixhvilnx/sql/new

-- 1. Create profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id uuid primary key default gen_random_uuid(),
  username text unique not null,
  page_data jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- 2. Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 3. Policies
-- Anyone can view public profiles
CREATE POLICY "Public profiles are viewable by everyone" ON profiles
  FOR SELECT USING (true);

-- Users can insert their own profile (id must match auth.uid())
CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Note: After registration, trigger will auto-create profile row
-- This is handled by the app code
