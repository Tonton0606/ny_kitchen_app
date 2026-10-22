-- Read-only diagnostic for the tables used by the Flutter Supabase sync.
-- Run in the Supabase SQL Editor. It does not read business rows or policy
-- expressions, which could contain sensitive literals.

WITH target_tables(table_name) AS (
  VALUES
    ('users'),
    ('food_categories'),
    ('food_items'),
    ('transactions'),
    ('transaction_items'),
    ('activity_logs'),
    ('login_attempts')
)
SELECT
  target.table_name,
  relation.relrowsecurity AS rls_enabled,
  relation.relforcerowsecurity AS rls_forced,
  COUNT(policy.policyname) AS policy_count,
  COALESCE(
    STRING_AGG(DISTINCT policy.policyname, ', ' ORDER BY policy.policyname),
    '(none)'
  ) AS policy_names,
  COALESCE(
    STRING_AGG(DISTINCT policy.cmd, ', ' ORDER BY policy.cmd),
    '(none)'
  ) AS policy_commands,
  COALESCE(
    STRING_AGG(DISTINCT ARRAY_TO_STRING(policy.roles, ', '), '; '),
    '(none)'
  ) AS policy_roles,
  CASE WHEN relation.oid IS NULL THEN NULL ELSE
    HAS_TABLE_PRIVILEGE('anon', relation.oid, 'SELECT') END AS anon_select_grant,
  CASE WHEN relation.oid IS NULL THEN NULL ELSE
    HAS_TABLE_PRIVILEGE('anon', relation.oid, 'INSERT') END AS anon_insert_grant,
  CASE WHEN relation.oid IS NULL THEN NULL ELSE
    HAS_TABLE_PRIVILEGE('anon', relation.oid, 'UPDATE') END AS anon_update_grant,
  CASE WHEN relation.oid IS NULL THEN NULL ELSE
    HAS_TABLE_PRIVILEGE('authenticated', relation.oid, 'SELECT') END AS authenticated_select_grant,
  CASE WHEN relation.oid IS NULL THEN NULL ELSE
    HAS_TABLE_PRIVILEGE('authenticated', relation.oid, 'INSERT') END AS authenticated_insert_grant,
  CASE WHEN relation.oid IS NULL THEN NULL ELSE
    HAS_TABLE_PRIVILEGE('authenticated', relation.oid, 'UPDATE') END AS authenticated_update_grant
FROM target_tables AS target
LEFT JOIN pg_class AS relation
  ON relation.relname = target.table_name
 AND relation.relnamespace = 'public'::regnamespace
 AND relation.relkind IN ('r', 'p')
LEFT JOIN pg_policies AS policy
  ON policy.schemaname = 'public'
 AND policy.tablename = target.table_name
GROUP BY target.table_name, relation.oid, relation.relrowsecurity, relation.relforcerowsecurity
ORDER BY target.table_name;
