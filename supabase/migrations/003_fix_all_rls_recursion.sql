-- Fix ALL recursive RLS policies
-- The core issue: policies on table A reference table B, whose policies reference table A

-- Drop ALL existing policies and recreate without recursion
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
-- DOC can do everything with their own club (no subquery needed)
CREATE POLICY clubs_doc_all ON clubs
  FOR ALL
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

-- Members can read their club (uses profiles but profiles doesn't reference clubs in its policies)
CREATE POLICY clubs_members_read ON clubs
  FOR SELECT
  USING (
    id IN (SELECT club_id FROM profiles WHERE user_id = auth.uid())
  );

-- === PROFILES ===
-- Own profile (no subquery, no recursion possible)
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

-- DOC reads all profiles in their club
-- Uses clubs.created_by directly, clubs policies don't reference profiles
CREATE POLICY profiles_doc_read ON profiles
  FOR SELECT
  USING (
    club_id IN (SELECT id FROM clubs WHERE created_by = auth.uid())
  );

-- === TEAMS ===
-- DOC can CRUD teams (references clubs, but clubs policies don't reference teams)
CREATE POLICY teams_doc_all ON teams
  FOR ALL
  USING (
    club_id IN (SELECT id FROM clubs WHERE created_by = auth.uid())
  )
  WITH CHECK (
    club_id IN (SELECT id FROM clubs WHERE created_by = auth.uid())
  );

-- Members can read their teams (references team_members and profiles, no circular dependency)
CREATE POLICY teams_members_read ON teams
  FOR SELECT
  USING (
    id IN (
      SELECT tm.team_id FROM team_members tm
      INNER JOIN profiles p ON tm.profile_id = p.id
      WHERE p.user_id = auth.uid()
    )
  );

-- === TEAM_MEMBERS ===
-- DOC can manage (references clubs via teams, no circular)
CREATE POLICY team_members_doc_all ON team_members
  FOR ALL
  USING (
    team_id IN (
      SELECT t.id FROM teams t
      WHERE t.club_id IN (SELECT id FROM clubs WHERE created_by = auth.uid())
    )
  )
  WITH CHECK (
    team_id IN (
      SELECT t.id FROM teams t
      WHERE t.club_id IN (SELECT id FROM clubs WHERE created_by = auth.uid())
    )
  );

-- Members read own memberships (references profiles, no circular)
CREATE POLICY team_members_own_read ON team_members
  FOR SELECT
  USING (
    profile_id IN (SELECT id FROM profiles WHERE user_id = auth.uid())
  );

-- === INVITES ===
-- DOC manages invites (references clubs, no circular)
CREATE POLICY invites_doc_all ON invites
  FOR ALL
  USING (
    club_id IN (SELECT id FROM clubs WHERE created_by = auth.uid())
  )
  WITH CHECK (
    club_id IN (SELECT id FROM clubs WHERE created_by = auth.uid())
  );
