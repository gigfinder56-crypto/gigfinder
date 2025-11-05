-- Pending migrations to reconcile earlier attempts

-- Remove redundant index if it was previously created
DROP INDEX IF EXISTS idx_users_email;

-- Drop updated_at triggers and function if they were created
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
DROP TRIGGER IF EXISTS update_opportunities_updated_at ON opportunities;
DROP TRIGGER IF EXISTS update_applications_updated_at ON applications;
DROP TRIGGER IF EXISTS update_experiences_updated_at ON experiences;

DROP FUNCTION IF EXISTS update_updated_at_column();
