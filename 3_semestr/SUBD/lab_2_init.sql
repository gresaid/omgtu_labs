create database db_books;

-- создание таблицы авторы
create table authors (
    code_author int primary key,
    name_author char(100) not null,
    birthday date
);

-- создание таблицы издательства
create table publishing_house (
    code_publish int primary key,
    publish char(100) not null,
    city char(50)
);

-- создание таблицы поставщики
create table deliveries (
    code_delivery int primary key,
    name_delivery char(100) not null,
    name_company char(100) not null,
    address char(200),
    phone numeric(15),
    inn char(12)
);

-- создание таблицы книги
create table books (
    code_book int primary key,
    title_book char(200) not null,
    code_author int references authors(code_author),
    pages int,
    code_publish int references publishing_house(code_publish)
);

-- создание таблицы покупки
create table purchases (
    code_purchase int primary key,
    code_book int references books(code_book),
    date_order date not null,
    code_delivery int references deliveries(code_delivery),
    type_purchase boolean not null,
    -- 0 - розница, 1 - опт
    cost money not null,
    amount int not null
);



--- Данные

-- ======== АВТОРЫ ========
INSERT INTO authors (code_author, name_author, birthday) VALUES
(1, 'Лев Толстой', '1828-09-09'),
(2, 'Фёдор Достоевский', '1821-11-11'),
(3, 'Александр Пушкин', '1799-06-06'),
(4, 'Антон Чехов', '1860-01-29'),
(5, 'Михаил Булгаков', '1891-05-15');

-- ======== ИЗДАТЕЛЬСТВА ========
INSERT INTO publishing_house (code_publish, publish, city) VALUES
(1, 'Азбука', 'Санкт-Петербург'),
(2, 'Эксмо', 'Москва'),
(3, 'АСТ', 'Москва'),
(4, 'Молодая гвардия', 'Казань');

-- ======== ПОСТАВЩИКИ ========
INSERT INTO deliveries (code_delivery, name_delivery, name_company, address, phone, inn) VALUES
(1, 'ИП Иванов', 'Книжный Мир', 'Москва, ул. Лесная, д.10', 79161234567, '770123456789'),
(2, 'ООО АльфаТрейд', 'АльфаТрейд', 'Санкт-Петербург, Невский пр., д.45', 79219876543, '781234567890'),
(3, 'ИП Петров', 'ПетровBooks', 'Казань, ул. Баумана, д.3', 79035554422, '160987654321');

-- ======== КНИГИ ========
INSERT INTO books (code_book, title_book, code_author, pages, code_publish) VALUES
(1, 'Война и мир', 1, 1225, 1),
(2, 'Анна Каренина', 1, 864, 2),
(3, 'Преступление и наказание', 2, 672, 2),
(4, 'Идиот', 2, 640, 3),
(5, 'Евгений Онегин', 3, 400, 1),
(6, 'Капитанская дочка', 3, 256, 3),
(7, 'Вишнёвый сад', 4, 180, 4),
(8, 'Мастер и Маргарита', 5, 480, 2),
(9, 'Собачье сердце', 5, 320, 1);

-- ======== ПОКУПКИ ========
INSERT INTO purchases (code_purchase, code_book, date_order, code_delivery, type_purchase, cost, amount) VALUES
(1, 1, '2024-01-05', 1, TRUE, 5500.00, 10),
(2, 2, '2024-01-10', 1, FALSE, 800.00, 2),
(3, 3, '2024-01-12', 2, TRUE, 4200.00, 8),
(4, 4, '2024-01-14', 3, FALSE, 950.00, 1),
(5, 5, '2024-02-01', 1, FALSE, 600.00, 3),
(6, 6, '2024-02-05', 2, TRUE, 2500.00, 6),
(7, 7, '2024-02-10', 3, FALSE, 500.00, 1),
(8, 8, '2024-02-15', 1, TRUE, 3800.00, 5),
(9, 9, '2024-02-18', 2, FALSE, 750.00, 2),
(10, 3, '2024-03-01', 1, FALSE, 700.00, 1),
(11, 5, '2024-03-05', 3, TRUE, 1800.00, 4),
(12, 8, '2024-03-08', 2, FALSE, 900.00, 2),
(13, 1, '2024-03-10', 3, TRUE, 5000.00, 9),
(14, 6, '2024-03-15', 1, FALSE, 650.00, 1),
(15, 9, '2024-03-20', 2, TRUE, 2100.00, 4);
