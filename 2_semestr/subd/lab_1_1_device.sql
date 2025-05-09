-- active: 1744030364581@@127.0.0.1@5432@device_repair
create database device_repair;


--- 1. инициализация
-- таблица мастеров
create table masters (
    master_id serial primary key,          -- код мастера
    last_name varchar(100) not null,       
    first_name varchar(100) not null,     
    middle_name varchar(100),             
    qualification_rank integer not null,   -- разряд мастера
    hire_date date not null                -- дата приема на работу
);

-- таблица приборов
create table devices (
    device_id serial primary key,          -- код прибора
    device_name varchar(200) not null,    
    device_type varchar(100) not null,    
    manufacture_date date                  -- дата производства
);

-- таблица ремонтов
create table repairs (
    repair_id serial primary key,           -- код ремонта
    device_in_repair_id varchar(50) not null, -- код прибора в ремонте
    device_id integer references devices(device_id), -- код прибора (внешний ключ)
    master_id integer references masters(master_id), -- код мастера (внешний ключ)
    owner_full_name varchar(255) not null, 
    receipt_date date not null,             -- дата приема в ремонт
    malfunction_type varchar(200) not null, -- вид поломки
    repair_cost decimal(10, 2) not null     -- стоимость ремонта
);
--- 2. заполнение данных
-- заполнение таблицы masters
insert into masters (master_id, last_name, first_name, middle_name, qualification_rank, hire_date) values
(1, 'иванов', 'александр', 'петрович', 5, '2020-03-15'),
(2, 'петрова', 'елена', 'сергеевна', 4, '2021-06-22'),
(3, 'сидоров', 'николай', 'иванович', 5, '2019-11-10'),
(4, 'козлова', 'мария', 'андреевна', 3, '2022-02-01'),
(5, 'соколов', 'дмитрий', 'алексеевич', 4, '2020-08-17');


-- заполнение таблицы devices
insert into devices (device_id, device_name, device_type, manufacture_date) values
(1, 'samsung galaxy s21', 'смартфон', '2021-02-10'),
(2, 'lg 55nano866', 'телевизор', '2020-11-05'),
(3, 'bosch serie 6', 'стиральная машина', '2019-08-15'),
(4, 'sony playstation 5', 'игровая приставка', '2021-01-20'),
(5, 'apple macbook pro', 'ноутбук', '2020-07-12');

-- заполнение таблицы repairs
insert into repairs (repair_id, device_in_repair_id, device_id, master_id, owner_full_name, receipt_date, malfunction_type, repair_cost) values
(1, 'rep-2023-001', 1, 3, 'кузнецов иван васильевич', '2023-01-10', 'разбитый экран', 8500.00),
(2, 'rep-2023-002', 2, 1, 'смирнова ольга петровна', '2023-02-15', 'неисправен блок питания', 3200.00),
(3, 'rep-2023-003', 3, 5, 'новиков андрей михайлович', '2023-01-25', 'не сливает воду', 4600.00),
(4, 'rep-2023-004', 4, 2, 'морозов сергей дмитриевич', '2023-03-05', 'перегрев системы', 5100.00),
(5, 'rep-2023-005', 5, 4, 'волкова наталья игоревна', '2023-02-20', 'не включается', 7200.00);
