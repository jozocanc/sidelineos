-- Fix infinite recursion in RLS policies
-- Problem: clubs_members_read checks profiles.club_id, profiles checks clubs.created_by

-- Drop the problematic policies
DROP POLICY IF EXISTS clubs_members_read ON clubs;
DROP POLICY IF EXISTS profiles_doc_read ON profiles;

-- Recreate clubs_members_read using auth.uid() directly against profiles
-- Use a direct join to avoid recursion
CREATE POLICY clubs_members_read ON clubs
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.club_id = clubs.id
        AND profiles.user_id = auth.uid()
    )
  );

-- Recreate profiles_doc_read to avoid recursion through clubs
-- Check created_by directly on clubs table without going through profiles
CREATE POLICY profiles_doc_read ON profiles
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM clubs
      WHERE clubs.id = profiles.club_id
        AND clubs.created_by = auth.uid()
    )
  );
