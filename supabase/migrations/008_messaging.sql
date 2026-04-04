-- ============================================================
-- 008_messaging.sql — announcements, announcement_replies
-- ============================================================

CREATE TABLE announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id uuid NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  team_id uuid REFERENCES teams(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  body text NOT NULL,
  pinned boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE announcement_replies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id uuid NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  body text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_announcements_club_id ON announcements(club_id);
CREATE INDEX idx_announcements_team_id ON announcements(team_id) WHERE team_id IS NOT NULL;
CREATE INDEX idx_announcements_created ON announcements(created_at DESC);
CREATE INDEX idx_announcements_pinned ON announcements(pinned DESC, created_at DESC);
CREATE INDEX idx_replies_announcement ON announcement_replies(announcement_id);
CREATE INDEX idx_replies_created ON announcement_replies(created_at);

CREATE TRIGGER announcements_updated_at
  BEFORE UPDATE ON announcements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

ALTER TABLE notifications ALTER COLUMN event_id DROP NOT NULL;
ALTER TABLE notifications ADD COLUMN announcement_id uuid REFERENCES announcements(id) ON DELETE CASCADE;
ALTER TABLE notifications ADD CONSTRAINT notifications_source_check
  CHECK (event_id IS NOT NULL OR announcement_id IS NOT NULL);

ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
ALTER TABLE notifications ADD CONSTRAINT notifications_type_check
  CHECK (type IN (
    'event_created', 'event_updated', 'event_cancelled',
    'coverage_requested', 'coverage_accepted', 'coverage_escalated',
    'announcement_posted', 'announcement_reply'
  ));

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcement_replies ENABLE ROW LEVEL SECURITY;

CREATE POLICY announcements_doc_all ON announcements FOR ALL
  USING (club_id IN (SELECT get_doc_club_ids()))
  WITH CHECK (club_id IN (SELECT get_doc_club_ids()));

CREATE POLICY announcements_coach_insert ON announcements FOR INSERT
  WITH CHECK (
    team_id IN (SELECT get_user_team_ids())
    AND club_id NOT IN (SELECT get_doc_club_ids())
    AND author_id IN (SELECT get_user_profile_ids())
  );

CREATE POLICY announcements_coach_update ON announcements FOR UPDATE
  USING (
    author_id IN (SELECT get_user_profile_ids())
    AND club_id NOT IN (SELECT get_doc_club_ids())
  )
  WITH CHECK (
    author_id IN (SELECT get_user_profile_ids())
    AND club_id NOT IN (SELECT get_doc_club_ids())
  );

CREATE POLICY announcements_coach_delete ON announcements FOR DELETE
  USING (
    author_id IN (SELECT get_user_profile_ids())
    AND club_id NOT IN (SELECT get_doc_club_ids())
  );

CREATE POLICY announcements_member_read ON announcements FOR SELECT
  USING (
    club_id IN (SELECT get_user_club_ids())
    AND (team_id IS NULL OR team_id IN (SELECT get_user_team_ids()))
  );

CREATE POLICY replies_member_read ON announcement_replies FOR SELECT
  USING (announcement_id IN (
    SELECT id FROM announcements
    WHERE club_id IN (SELECT get_user_club_ids())
    AND (team_id IS NULL OR team_id IN (SELECT get_user_team_ids()))
  ));

CREATE POLICY replies_member_insert ON announcement_replies FOR INSERT
  WITH CHECK (
    author_id IN (SELECT get_user_profile_ids())
    AND announcement_id IN (
      SELECT id FROM announcements
      WHERE club_id IN (SELECT get_user_club_ids())
      AND (team_id IS NULL OR team_id IN (SELECT get_user_team_ids()))
    )
  );

CREATE POLICY replies_delete ON announcement_replies FOR DELETE
  USING (
    author_id IN (SELECT get_user_profile_ids())
    OR announcement_id IN (
      SELECT id FROM announcements WHERE club_id IN (SELECT get_doc_club_ids())
    )
  );
