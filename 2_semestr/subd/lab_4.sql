-- Active: 1744030364581@@127.0.0.1@5432@db-books


--- Оператор UPDATE

-- 1. Изменение значения поля Pages на 300 для книг с определенными параметрами
UPDATE Books
SET Pages = 300
WHERE Code_author = 56 AND Title_book = 'Мемуары';

-- 2. Увеличение цены на 20% для заказов, оформленных в течение последнего месяца
UPDATE Purchases
SET Cost = Cost * 1.2
WHERE Date_order >= (CURRENT_DATE - INTERVAL '1 month');

--- Оператор INSERT

-- 1. Добавление новой записи в таблицу Books с автоматическим определением кода
INSERT INTO Books (Code_book, Title_book, Code_author, Pages, Code_publish)
VALUES (
    (SELECT COALESCE(MAX(Code_book), 0) + 1 FROM Books),
    'Наука. Техника. Инновации',
    NULL,
    NULL,
    NULL
);

-- 2. Добавление новой записи в таблицу Publishing_house
INSERT INTO Publishing_house (Code_publish, Publish, City)
VALUES (
    (SELECT COALESCE(MAX(Code_publish), 0) + 1 FROM Publishing_house),
    'Наука',
    'Москва'
);

-- Оператор DELETE

-- 1. Удаление записей с нулевым количеством книг в заказе
DELETE FROM Purchases
WHERE Amount = 0;

-- 2. Удаление записей без указания ИНН
DELETE FROM Deliveries
WHERE INN IS NULL OR TRIM(INN) = '';
