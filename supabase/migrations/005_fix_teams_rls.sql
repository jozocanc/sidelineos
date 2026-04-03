-- Fix teams RLS recursion
-- The issue: teams_members_read references team_members which references profiles
-- Solution: use SECURITY DEFINER functions for all cross-table lookups

-- Helper: get team_ids for current user (bypasses RLS on team_members and profiles)
CREATE OR REPLACE FUNCTION get_user_team_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT tm.team_id FROM team_members tm
  INNER JOIN profiles p ON tm.profile_id = p.id
  WHERE p.user_id = auth.uid();
$$;

-- Helper: get team_ids for DOC's clubs (bypasses RLS)
CREATE OR REPLACE FUNCTION get_doc_team_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT t.id FROM teams t
  WHERE t.club_id IN (SELECT id FROM clubs WHERE created_by = auth.uid());
$$;

-- Drop and recreate teams policies
DROP POLICY IF EXISTS teams_doc_all ON teams;
DROP POLICY IF EXISTS teams_members_read ON teams;

CREATE POLICY teams_doc_all ON teams
  FOR ALL
  USING (id IN (SELECT get_doc_team_ids()))
  WITH CHECK (club_id IN (SELECT get_doc_club_ids()));

CREATE POLICY teams_members_read ON teams
  FOR SELECT
  USING (id IN (SELECT get_user_team_ids()));

-- Also fix team_members policies
DROP POLICY IF EXISTS team_members_doc_all ON team_members;
DROP POLICY IF EXISTS team_members_own_read ON team_members;

CREATE POLICY team_members_doc_all ON team_members
  FOR ALL
  USING (team_id IN (SELECT get_doc_team_ids()))
  WITH CHECK (team_id IN (SELECT get_doc_team_ids()));

CREATE POLICY team_members_own_read ON team_members
  FOR SELECT
  USING (profile_id IN (SELECT get_user_profile_ids()));
