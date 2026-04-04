-- ============================================================
-- 007_coach_coverage.sql — club_settings, coverage_requests, coverage_responses
-- ============================================================

CREATE TABLE club_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id uuid NOT NULL UNIQUE REFERENCES clubs(id) ON DELETE CASCADE,
  coverage_timeout_minutes integer NOT NULL DEFAULT 120,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE coverage_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  club_id uuid NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  unavailable_coach_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  covering_coach_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'escalated', 'resolved')),
  created_by uuid NOT NULL REFERENCES auth.users(id),
  timeout_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE coverage_responses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coverage_request_id uuid NOT NULL REFERENCES coverage_requests(id) ON DELETE CASCADE,
  coach_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  response text NOT NULL CHECK (response IN ('accepted', 'declined')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(coverage_request_id, coach_id)
);

CREATE INDEX idx_coverage_requests_event_id ON coverage_requests(event_id);
CREATE INDEX idx_coverage_requests_club_id ON coverage_requests(club_id);
CREATE INDEX idx_coverage_requests_active ON coverage_requests(status) WHERE status IN ('pending', 'escalated');
CREATE INDEX idx_coverage_requests_timeout ON coverage_requests(timeout_at) WHERE status = 'pending';
CREATE INDEX idx_coverage_responses_request ON coverage_responses(coverage_request_id);
CREATE INDEX idx_coverage_responses_coach ON coverage_responses(coach_id);

CREATE UNIQUE INDEX idx_coverage_requests_no_dup
  ON coverage_requests(event_id, unavailable_coach_id)
  WHERE status IN ('pending', 'escalated');

CREATE TRIGGER club_settings_updated_at
  BEFORE UPDATE ON club_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER coverage_requests_updated_at
  BEFORE UPDATE ON coverage_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

ALTER TABLE notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type IN (
    'event_created', 'event_updated', 'event_cancelled',
    'coverage_requested', 'coverage_accepted', 'coverage_escalated'
  ));

ALTER TABLE club_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE coverage_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE coverage_responses ENABLE ROW LEVEL SECURITY;

CREATE POLICY club_settings_doc_all ON club_settings FOR ALL
  USING (club_id IN (SELECT get_doc_club_ids()))
  WITH CHECK (club_id IN (SELECT get_doc_club_ids()));

CREATE POLICY club_settings_member_read ON club_settings FOR SELECT
  USING (club_id IN (SELECT get_user_club_ids()));

CREATE POLICY coverage_requests_doc_all ON coverage_requests FOR ALL
  USING (club_id IN (SELECT get_doc_club_ids()))
  WITH CHECK (club_id IN (SELECT get_doc_club_ids()));

CREATE POLICY coverage_requests_coach_read ON coverage_requests FOR SELECT
  USING (club_id IN (SELECT get_user_club_ids()));

CREATE POLICY coverage_requests_coach_insert ON coverage_requests FOR INSERT
  WITH CHECK (
    club_id IN (SELECT get_user_club_ids())
    AND unavailable_coach_id IN (SELECT get_user_profile_ids())
  );

CREATE POLICY coverage_responses_doc_read ON coverage_responses FOR SELECT
  USING (coverage_request_id IN (
    SELECT id FROM coverage_requests WHERE club_id IN (SELECT get_doc_club_ids())
  ));

CREATE POLICY coverage_responses_coach_read ON coverage_responses FOR SELECT
  USING (coverage_request_id IN (
    SELECT id FROM coverage_requests WHERE club_id IN (SELECT get_user_club_ids())
  ));

CREATE POLICY coverage_responses_coach_insert ON coverage_responses FOR INSERT
  WITH CHECK (
    coach_id IN (SELECT get_user_profile_ids())
    AND coverage_request_id IN (
      SELECT id FROM coverage_requests WHERE club_id IN (SELECT get_user_club_ids())
    )
  );
