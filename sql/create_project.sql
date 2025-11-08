-- ==============================================
-- Создание PostgreSQL роли
-- ==============================================
DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${DB_USER}') THEN
      CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASSWORD}';
   END IF;
END
$$;

-- ==============================================
-- Привилегии будут выданы после создания базы
-- ==============================================
-- GRANT ALL PRIVILEGES ON DATABASE ${DB_DATABASE} TO ${DB_USER};
-- Создание базы выполняется в bash-скрипте, чтобы избежать ошибок при существующей базе
