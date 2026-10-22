-- Read-only schema check before deploying device-scoped sale IDs.
-- Confirms that cloud transaction and line-item IDs accept signed 64-bit values.
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('transactions', 'transaction_items')
  AND column_name IN ('id', 'transaction_id')
ORDER BY table_name, ordinal_position;
