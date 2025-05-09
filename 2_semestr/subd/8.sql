-- Роль администратора базы данных
CREATE ROLE db_admin;
GRANT ALL PRIVILEGES ON DATABASE device_repair TO db_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO db_admin;

-- Роль мастера-ремонтника
CREATE ROLE repair_master;
GRANT SELECT ON masters TO repair_master;
GRANT SELECT ON devices TO repair_master;
GRANT SELECT, INSERT, UPDATE ON repairs TO repair_master;

-- Роль менеджера приемки
CREATE ROLE reception_manager;
GRANT SELECT ON masters TO reception_manager;
GRANT SELECT ON devices TO reception_manager;
GRANT SELECT, INSERT ON repairs TO reception_manager;


-- Администратор базы данных
CREATE USER admin_ivanov WITH PASSWORD 'secure_pass_123';
GRANT db_admin TO admin_ivanov;

-- Мастера-ремонтники
CREATE USER master_sidorov WITH PASSWORD 'master_pass_456';
GRANT repair_master TO master_sidorov;


-- Менеджеры приемки
CREATE USER manager_petrova WITH PASSWORD 'manager_pass_123';
GRANT reception_manager TO manager_petrova;