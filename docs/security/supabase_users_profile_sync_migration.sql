-- Prepare public.users for profile-only synchronization.
-- The Flutter app keeps password hashes local and uploads this column as NULL/omitted.
-- This changes nullability only; it does not remove existing cloud hash values.
-- Apply to a development project first and review old cloud hash cleanup separately.
ALTER TABLE public.users
  ALTER COLUMN password_hash DROP NOT NULL;
