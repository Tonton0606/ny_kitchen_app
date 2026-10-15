-- =============================================================================
-- DRAFT: SUPABASE DEVICE SECRET ROTATION
-- =============================================================================
-- IMPORTANT INSTRUCTIONS FOR THE OPERATOR:
-- 1. DO NOT paste real secret values into this file, git repository, or chat.
-- 2. Open your Supabase Dashboard -> SQL Editor (https://supabase.com/dashboard).
-- 3. Replace the placeholder <NEW_SECRET> with your freshly generated random secret
--    directly in the Supabase SQL Editor interface.
-- 4. Execute the query corresponding to how your server-side validation is set up.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PATTERN A: Secret checked via PostgreSQL Function (Most Common in Supabase)
-- -----------------------------------------------------------------------------
-- If your RLS policies use a function like `check_device_secret()`:
-- Look in Supabase Dashboard: Database -> Functions -> check_device_secret
--
-- This function inspects the custom `x-device-secret` header passed by PostgREST
-- from request headers (stored in request.headers JSON in Postgres transaction).

CREATE OR REPLACE FUNCTION public.check_device_secret()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  headers json;
  client_secret text;
BEGIN
  -- Extract request headers populated by PostgREST
  headers := coalesce(current_setting('request.headers', true)::json, '{}'::json);
  client_secret := headers->>'x-device-secret';

  -- Replace <NEW_SECRET> in the Supabase SQL Editor before running:
  RETURN client_secret = '<NEW_SECRET>';
END;
$$;

-- Grant execution permissions to public and authenticated/anon roles
GRANT EXECUTE ON FUNCTION public.check_device_secret() TO anon, authenticated, service_role;


-- -----------------------------------------------------------------------------
-- PATTERN B: Secret stored in an Internal Config / Settings Table
-- -----------------------------------------------------------------------------
-- If you maintain an internal configuration table (e.g. `app_settings` or `vault`):
-- Look in Supabase Dashboard: Table Editor -> app_settings / secrets

-- UPDATE public.app_settings
-- SET value = '<NEW_SECRET>',
--     updated_at = NOW()
-- WHERE key = 'SUPABASE_DEVICE_SECRET';


-- -----------------------------------------------------------------------------
-- PATTERN C: Secret stored via PostgreSQL Database Setting / GUC
-- -----------------------------------------------------------------------------
-- If configured via postgres configuration parameter:
-- ALTER DATABASE postgres SET "app.settings.device_secret" = '<NEW_SECRET>';


-- -----------------------------------------------------------------------------
-- VERIFICATION QUERY (Run in SQL Editor to test function logic)
-- -----------------------------------------------------------------------------
-- SELECT public.check_device_secret(); 
-- (Should return false in the SQL Editor because no HTTP header is present)
