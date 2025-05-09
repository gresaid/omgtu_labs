-- роль администратора базы данных
create role db_admin;

grant all privileges on database device_repair to db_admin;

grant all privileges on all tables in schema public to db_admin;

grant all privileges on all sequences in schema public to db_admin;

-- роль мастера-ремонтника
create role repair_master;

grant
select
    on masters to repair_master;

grant
select
    on devices to repair_master;

grant
select
,
insert
,
update
    on repairs to repair_master;

-- роль менеджера приемки
create role reception_manager;

grant
select
    on masters to reception_manager;

grant
select
    on devices to reception_manager;

grant
select
,
insert
    on repairs to reception_manager;

-- администратор базы данных
create user admin_ivanov with password 'secure_pass_123';

grant db_admin to admin_ivanov;

-- мастера-ремонтники
create user master_sidorov with password 'master_pass_456';

grant repair_master to master_sidorov;

-- менеджеры приемки
create user manager_petrova with password 'manager_pass_123';

grant reception_manager to manager_petrova;