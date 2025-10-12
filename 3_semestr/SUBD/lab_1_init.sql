-- ================================
-- Таблица: сотрудники
-- ================================
DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    full_name   VARCHAR(50) NOT NULL,
    department  VARCHAR(30) NOT NULL,
    hire_date   DATE NOT NULL
);

-- ================================
-- Таблица: продажи
-- ================================
DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
    sale_id     SERIAL PRIMARY KEY,
    employee_id INT NOT NULL REFERENCES employees(employee_id),
    sale_date   DATE NOT NULL,
    amount      DECIMAL(10,2) NOT NULL
);




-- ================================
-- Данные: сотрудники
-- ================================
INSERT INTO employees (full_name, department, hire_date) VALUES
('Alice Brown',   'Electronics', '2021-03-12'),
('Bob Smith',     'Electronics', '2020-08-05'),
('Carol Johnson', 'Clothing',    '2022-01-18'),
('David Wilson',  'Grocery',     '2019-10-20'),
('Emily Davis',   'Clothing',    '2023-06-10');

-- ================================
-- Данные: продажи
-- ================================
INSERT INTO sales (employee_id, sale_date, amount) VALUES
(1, '2024-01-01', 120.00),
(1, '2024-01-03', 300.00),
(2, '2024-01-02', 200.00),
(2, '2024-01-05', 180.00),
(3, '2024-01-01', 90.00),
(3, '2024-01-04', 150.00),
(4, '2024-01-02', 400.00),
(5, '2024-01-03', 70.00),
(5, '2024-01-04', 130.00);

-- ================================
-- Проверка данных
-- ================================
SELECT * FROM employees;
SELECT * FROM sales;