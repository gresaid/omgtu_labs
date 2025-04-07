-- Active: 1744030364581@@127.0.0.1@5432@db-books
-- Создание таблицы Авторы (Authors)
CREATE TABLE Authors (
    Code_author INT PRIMARY KEY,
    Name_author CHAR(100) NOT NULL,
    Birthday DATE
);

-- Создание таблицы Издательства (Publishing_house)
CREATE TABLE Publishing_house (
    Code_publish INT PRIMARY KEY,
    Publish CHAR(100) NOT NULL,
    City CHAR(50)
);

-- Создание таблицы Поставщики (Deliveries)
CREATE TABLE Deliveries (
    Code_delivery INT PRIMARY KEY,
    Name_delivery CHAR(100) NOT NULL,
    Name_company CHAR(100) NOT NULL,
    Address CHAR(200),
    Phone NUMERIC(15),
    INN CHAR(12)
);

-- Создание таблицы Книги (Books)
CREATE TABLE Books (
    Code_book INT PRIMARY KEY,
    Title_book CHAR(200) NOT NULL,
    Code_author INT REFERENCES Authors(Code_author),
    Pages INT,
    Code_publish INT REFERENCES Publishing_house(Code_publish)
);

-- Создание таблицы Покупки (Purchases)
CREATE TABLE Purchases (
    Code_purchase INT PRIMARY KEY,
    Code_book INT REFERENCES Books(Code_book),
    Date_order DATE NOT NULL,
    Code_delivery INT REFERENCES Deliveries(Code_delivery),
    Type_purchase BOOLEAN NOT NULL, -- 0 - розница, 1 - опт
    Cost MONEY NOT NULL,
    Amount INT NOT NULL
);
----- 1.1 Заполнение данными
-- Заполнение таблицы Авторы (Authors)
INSERT INTO Authors (Code_author, Name_author, Birthday) VALUES
(1, 'Толстой Лев Николаевич', '1828-09-09'),
(2, 'Достоевский Федор Михайлович', '1821-11-11'),
(3, 'Роулинг Джоан Кэтлин', '1965-07-31'),
(4, 'Кинг Стивен', '1947-09-21'),
(5, 'Пелевин Виктор Олегович', '1962-11-22');

-- Заполнение таблицы Издательства (Publishing_house)
INSERT INTO Publishing_house (Code_publish, Publish, City) VALUES
(1, 'ЭКСМО', 'Москва'),
(2, 'АСТ', 'Москва'),
(3, 'Росмэн', 'Санкт-Петербург'),
(4, 'Азбука', 'Санкт-Петербург'),
(5, 'МИФ', 'Москва');

-- Заполнение таблицы Поставщики (Deliveries)
INSERT INTO Deliveries (Code_delivery, Name_delivery, Name_company, Address, Phone, INN) VALUES
(1, 'Иванов А.А.', 'ОАО Книжный мир', 'г. Москва, ул. Ленина, 10', 79261234567, '7701234567'),
(2, 'Петров И.С.', 'ООО Книги оптом', 'г. Санкт-Петербург, пр. Невский, 30', 78129876543, '7821234567'),
(3, 'Сидорова Е.В.', 'ИП Литера', 'г. Казань, ул. Баумана, 15', 78432345678, '1651234567'),
(4, 'Козлов Д.Д.', 'ОАО Буквоед', 'г. Екатеринбург, ул. Ленина, 5', 73433456789, '6671234567'),
(5, 'Смирнова О.П.', 'ООО Читай-город', 'г. Новосибирск, пр. Красный, 25', 73834567890, '5401234567');

-- Заполнение таблицы Книги (Books)
INSERT INTO Books (Code_book, Title_book, Code_author, Pages, Code_publish) VALUES
(1, 'Война и мир', 1, 1300, 1),
(2, 'Преступление и наказание', 2, 672, 4),
(3, 'Гарри Поттер и философский камень', 3, 399, 3),
(4, 'Оно', 4, 1138, 2),
(5, 'Generation П', 5, 352, 5);

-- Заполнение таблицы Покупки (Purchases)
INSERT INTO Purchases (Code_purchase, Code_book, Date_order, Code_delivery, Type_purchase, Cost, Amount) VALUES
(1, 1, '2023-01-15', 1, TRUE, 550.00, 50),
(2, 2, '2023-02-10', 2, TRUE, 420.00, 30),
(3, 3, '2023-03-05', 3, FALSE, 350.00, 5),
(4, 4, '2023-03-15', 4, TRUE, 580.00, 40),
(5, 5, '2023-04-01', 5, FALSE, 420.00, 10);
