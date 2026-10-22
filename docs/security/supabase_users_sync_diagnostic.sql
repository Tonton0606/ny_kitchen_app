-- Read-only diagnostic for Supabase users upload failures (for example SQLSTATE 23502).
-- Returns schema metadata only; it does not read user rows, credentials, policies, or secrets.
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'users'
  AND is_nullable = 'NO'
ORDER BY ordinal_position;
