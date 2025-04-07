-- Active: 1744030364581@@127.0.0.1@5432@device_repair
CREATE DATABASE device_repair;


--- 1. Инициализация
-- Таблица мастеров
CREATE TABLE masters (
    master_id SERIAL PRIMARY KEY,          -- Код мастера
    last_name VARCHAR(100) NOT NULL,       -- Фамилия мастера
    first_name VARCHAR(100) NOT NULL,      -- Имя мастера
    middle_name VARCHAR(100),              -- Отчество мастера
    qualification_rank INTEGER NOT NULL,   -- Разряд мастера
    hire_date DATE NOT NULL                -- Дата приема на работу
);

-- Таблица приборов
CREATE TABLE devices (
    device_id SERIAL PRIMARY KEY,          -- Код прибора
    device_name VARCHAR(200) NOT NULL,     -- Название прибора
    device_type VARCHAR(100) NOT NULL,     -- Тип прибора
    manufacture_date DATE                  -- Дата производства
);

-- Таблица ремонтов
CREATE TABLE repairs (
    repair_id SERIAL PRIMARY KEY,           -- Код ремонта
    device_in_repair_id VARCHAR(50) NOT NULL, -- Код прибора в ремонте
    device_id INTEGER REFERENCES devices(device_id), -- Код прибора (внешний ключ)
    master_id INTEGER REFERENCES masters(master_id), -- Код мастера (внешний ключ)
    owner_full_name VARCHAR(255) NOT NULL,  -- ФИО владельца прибора
    receipt_date DATE NOT NULL,             -- Дата приема в ремонт
    malfunction_type VARCHAR(200) NOT NULL, -- Вид поломки
    repair_cost DECIMAL(10, 2) NOT NULL     -- Стоимость ремонта
);
--- 2. Заполнение данных
-- Заполнение таблицы masters (мастера)
INSERT INTO masters (master_id, last_name, first_name, middle_name, qualification_rank, hire_date) VALUES
(1, 'Иванов', 'Александр', 'Петрович', 5, '2020-03-15'),
(2, 'Петрова', 'Елена', 'Сергеевна', 4, '2021-06-22'),
(3, 'Сидоров', 'Николай', 'Иванович', 5, '2019-11-10'),
(4, 'Козлова', 'Мария', 'Андреевна', 3, '2022-02-01'),
(5, 'Соколов', 'Дмитрий', 'Алексеевич', 4, '2020-08-17');


-- Заполнение таблицы devices (приборы)
INSERT INTO devices (device_id, device_name, device_type, manufacture_date) VALUES
(1, 'Samsung Galaxy S21', 'Смартфон', '2021-02-10'),
(2, 'LG 55NANO866', 'Телевизор', '2020-11-05'),
(3, 'Bosch Serie 6', 'Стиральная машина', '2019-08-15'),
(4, 'Sony PlayStation 5', 'Игровая приставка', '2021-01-20'),
(5, 'Apple MacBook Pro', 'Ноутбук', '2020-07-12');

-- Заполнение таблицы repairs (ремонты)
INSERT INTO repairs (repair_id, device_in_repair_id, device_id, master_id, owner_full_name, receipt_date, malfunction_type, repair_cost) VALUES
(1, 'REP-2023-001', 1, 3, 'Кузнецов Иван Васильевич', '2023-01-10', 'Разбитый экран', 8500.00),
(2, 'REP-2023-002', 2, 1, 'Смирнова Ольга Петровна', '2023-02-15', 'Неисправен блок питания', 3200.00),
(3, 'REP-2023-003', 3, 5, 'Новиков Андрей Михайлович', '2023-01-25', 'Не сливает воду', 4600.00),
(4, 'REP-2023-004', 4, 2, 'Морозов Сергей Дмитриевич', '2023-03-05', 'Перегрев системы', 5100.00),
(5, 'REP-2023-005', 5, 4, 'Волкова Наталья Игоревна', '2023-02-20', 'Не включается', 7200.00);
