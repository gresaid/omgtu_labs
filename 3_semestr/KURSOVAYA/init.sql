-- 1. Филиалы
CREATE TABLE branches (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  address TEXT
);

-- 2. Продукты
CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  form TEXT,          -- форма: табл., сироп и т.п.
  price NUMERIC(10,2) NOT NULL,
  is_prescription BOOLEAN DEFAULT FALSE
);

-- 3. Партии
CREATE TABLE batches (
  id SERIAL PRIMARY KEY,
  product_id INT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  branch_id INT NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  lot_number TEXT,
  expiry_date DATE,
  quantity INT NOT NULL CHECK (quantity >= 0)
);

-- 4. Пациенты
CREATE TABLE patients (
  id SERIAL PRIMARY KEY,
  full_name TEXT NOT NULL,
  phone TEXT
);

-- 5. Продажи (чек)
CREATE TABLE sales_invoices (
  id SERIAL PRIMARY KEY,
  branch_id INT REFERENCES branches(id),
  patient_id INT REFERENCES patients(id),
  sale_date TIMESTAMP DEFAULT now(),
  total_amount NUMERIC(10,2)
);

-- 6. Позиции продаж
CREATE TABLE sales_items (
  id SERIAL PRIMARY KEY,
  sales_invoice_id INT REFERENCES sales_invoices(id) ON DELETE CASCADE,
  product_id INT REFERENCES products(id),
  batch_id INT REFERENCES batches(id),
  quantity INT NOT NULL CHECK (quantity > 0),
  unit_price NUMERIC(10,2) NOT NULL
);


INSERT INTO branches (id, name, address) VALUES
(1, 'Аптека №1 "Здоровье"', 'г. Москва, ул. Тверская, 15'),
(2, 'Аптека №2 "ФармПлюс"', 'г. Санкт-Петербург, Невский пр., 120'),
(3, 'Аптека №3 "Будь здоров"', 'г. Казань, ул. Баумана, 50'),
(4, 'Аптека №4 "ФармЛайф"', 'г. Новосибирск, Красный пр., 18'),
(5, 'Аптека №5 "Панацея"', 'г. Екатеринбург, ул. Ленина, 33'),
(6, 'Аптека №6 "ДоброФарм"', 'г. Самара, Московское ш., 60'),
(7, 'Аптека №7 "ФармДом"', 'г. Нижний Новгород, ул. Белинского, 12'),
(8, 'Аптека №8 "Аптечный мир"', 'г. Ростов-на-Дону, пр. Ворошиловский, 72'),
(9, 'Аптека №9 "ФармМед"', 'г. Челябинск, ул. Кирова, 45'),
(10, 'Аптека №10 "Здоровая жизнь"', 'г. Воронеж, пр. Революции, 9');


INSERT INTO products (id, name, form, price, is_prescription) VALUES
(1, 'Парацетамол', 'таблетки', 85.00, FALSE),
(2, 'Ибупрофен', 'таблетки', 120.00, FALSE),
(3, 'Амоксициллин', 'капсулы', 230.00, TRUE),
(4, 'Лоратадин', 'таблетки', 150.00, FALSE),
(5, 'Мирамистин', 'спрей', 340.00, FALSE),
(6, 'Кеторол', 'ампулы', 420.00, TRUE),
(7, 'Смекта', 'порошок', 210.00, FALSE),
(8, 'Но-шпа', 'таблетки', 160.00, FALSE),
(9, 'Цитрамон', 'таблетки', 90.00, FALSE),
(10, 'Амброксол', 'сироп', 250.00, FALSE);
INSERT INTO batches (id, product_id, branch_id, lot_number, expiry_date, quantity) VALUES
(1, 1, 1, 'P001-24', '2026-05-30', 300),
(2, 2, 2, 'I012-24', '2026-11-20', 250),
(3, 3, 3, 'A045-24', '2025-12-15', 180),
(4, 4, 4, 'L007-24', '2027-01-01', 400),
(5, 5, 5, 'M023-24', '2026-08-08', 120),
(6, 6, 6, 'K009-24', '2025-05-05', 90),
(7, 7, 7, 'S017-24', '2026-03-10', 220),
(8, 8, 8, 'N033-24', '2027-04-22', 310),
(9, 9, 9, 'C055-24', '2025-10-01', 270),
(10, 10, 10, 'AMB060-24', '2026-09-15', 190);
INSERT INTO patients (id, full_name, phone) VALUES
(1, 'Иванов Иван Сергеевич', '+7-901-123-45-67'),
(2, 'Петрова Анна Владимировна', '+7-902-234-56-78'),
(3, 'Сидоров Алексей Павлович', '+7-903-345-67-89'),
(4, 'Кузнецова Мария Андреевна', '+7-904-456-78-90'),
(5, 'Смирнов Николай Олегович', '+7-905-567-89-01'),
(6, 'Васильева Елена Петровна', '+7-906-678-90-12'),
(7, 'Морозов Андрей Иванович', '+7-907-789-01-23'),
(8, 'Федорова Ольга Сергеевна', '+7-908-890-12-34'),
(9, 'Егоров Павел Николаевич', '+7-909-901-23-45'),
(10, 'Козлова Татьяна Викторовна', '+7-910-012-34-56');
INSERT INTO sales_invoices (id, branch_id, patient_id, sale_date, total_amount) VALUES
(1, 1, 1, '2025-10-20 10:15:00', 340.00),
(2, 2, 2, '2025-10-20 11:40:00', 480.00),
(3, 3, 3, '2025-10-21 12:05:00', 230.00),
(4, 4, 4, '2025-10-21 13:22:00', 150.00),
(5, 5, 5, '2025-10-22 09:50:00', 760.00),
(6, 6, 6, '2025-10-22 15:30:00', 420.00),
(7, 7, 7, '2025-10-23 17:40:00', 370.00),
(8, 8, 8, '2025-10-24 10:10:00', 480.00),
(9, 9, 9, '2025-10-25 18:00:00', 180.00),
(10, 10, 10, '2025-10-26 09:15:00', 500.00);
INSERT INTO sales_items (id, sales_invoice_id, product_id, batch_id, quantity, unit_price) VALUES
(1, 1, 1, 1, 2, 85.00),
(2, 1, 5, 5, 1, 170.00),
(3, 2, 2, 2, 2, 120.00),
(4, 2, 9, 9, 2, 120.00),
(5, 3, 3, 3, 1, 230.00),
(6, 4, 4, 4, 1, 150.00),
(7, 5, 5, 5, 2, 340.00),
(8, 5, 8, 8, 1, 80.00),
(9, 6, 6, 6, 1, 420.00),
(10, 7, 7, 7, 2, 185.00),
(11, 8, 8, 8, 3, 160.00),
(12, 9, 9, 9, 2, 90.00),
(13, 10, 10, 10, 2, 250.00);
