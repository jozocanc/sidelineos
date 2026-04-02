-- Fix RLS recursion using SECURITY DEFINER functions
-- These functions bypass RLS internally, breaking the circular dependency

-- Helper: get club_ids for current user (bypasses RLS on profiles)
CREATE OR REPLACE FUNCTION get_user_club_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT club_id FROM profiles WHERE user_id = auth.uid() AND club_id IS NOT NULL;
$$;

-- Helper: get profile_ids for current user (bypasses RLS on profiles)
CREATE OR REPLACE FUNCTION get_user_profile_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM profiles WHERE user_id = auth.uid();
$$;

-- Helper: get club_ids where user is DOC (bypasses RLS on clubs)
CREATE OR REPLACE FUNCTION get_doc_club_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM clubs WHERE created_by = auth.uid();
$$;

-- Drop ALL existing policies
DROP POLICY IF EXISTS clubs_doc_all ON clubs;
DROP POLICY IF EXISTS clubs_members_read ON clubs;
DROP POLICY IF EXISTS teams_doc_all ON teams;
DROP POLICY IF EXISTS teams_members_read ON teams;
DROP POLICY IF EXISTS profiles_own_read ON profiles;
DROP POLICY IF EXISTS profiles_own_update ON profiles;
DROP POLICY IF EXISTS profiles_own_insert ON profiles;
DROP POLICY IF EXISTS profiles_doc_read ON profiles;
DROP POLICY IF EXISTS team_members_doc_all ON team_members;
DROP POLICY IF EXISTS team_members_own_read ON team_members;
DROP POLICY IF EXISTS invites_doc_all ON invites;

-- === CLUBS ===
CREATE POLICY clubs_doc_all ON clubs
  FOR ALL
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

CREATE POLICY clubs_members_read ON clubs
  FOR SELECT
  USING (id IN (SELECT get_user_club_ids()));

-- === PROFILES ===
CREATE POLICY profiles_own_read ON profiles
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY profiles_own_update ON profiles
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY profiles_own_insert ON profiles
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY profiles_doc_read ON profiles
  FOR SELECT
  USING (club_id IN (SELECT get_doc_club_ids()));

-- === TEAMS ===
CREATE POLICY teams_doc_all ON teams
  FOR ALL
  USING (club_id IN (SELECT get_doc_club_ids()))
  WITH CHECK (club_id IN (SELECT get_doc_club_ids()));

CREATE POLICY teams_members_read ON teams
  FOR SELECT
  USING (
    id IN (
      SELECT team_id FROM team_members
      WHERE profile_id IN (SELECT get_user_profile_ids())
    )
  );

-- === TEAM_MEMBERS ===
CREATE POLICY team_members_doc_all ON team_members
  FOR ALL
  USING (
    team_id IN (SELECT id FROM teams WHERE club_id IN (SELECT get_doc_club_ids()))
  )
  WITH CHECK (
    team_id IN (SELECT id FROM teams WHERE club_id IN (SELECT get_doc_club_ids()))
  );

CREATE POLICY team_members_own_read ON team_members
  FOR SELECT
  USING (profile_id IN (SELECT get_user_profile_ids()));

-- === INVITES ===
CREATE POLICY invites_doc_all ON invites
  FOR ALL
  USING (club_id IN (SELECT get_doc_club_ids()))
  WITH CHECK (club_id IN (SELECT get_doc_club_ids()));
