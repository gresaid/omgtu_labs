-- Active: 1744025315676@@127.0.0.1@5432@db-books
-- 1. Выбор всех полей из таблицы Deliveries с изменением порядка столбцов
SELECT Name_delivery, INN, Phone, Address, Code_delivery
FROM Deliveries;

-- 2. Выбор названий книг, страниц и имен авторов
SELECT b.Title_book, b.Pages, a.Name_author
FROM Books b
JOIN Authors a ON b.Code_author = a.Code_author;

-- 3. Выбор компаний с названиями, начинающимися на 'ОАО'
SELECT Name_company, Phone, INN
FROM Deliveries
WHERE Name_company LIKE 'ОАО%';

-- 4. Вывод издательств не из Москвы
SELECT Publish
FROM Publishing_house
WHERE City != 'Москва';

-- 5. Вывод книг, выпущенных всеми издательствами, кроме 'Питер-Софт'(Росмэн)
SELECT b.Title_book
FROM Books b
JOIN Publishing_house p ON b.Code_publish = p.Code_publish
WHERE p.Publish != 'Росмэн';

-- 6. Вывод авторов с датой рождения в диапазоне '1821-11-11' AND '1828-09-09'
SELECT Name_author
FROM Authors
WHERE Birthday BETWEEN '1821-11-11' AND '1828-09-09';

-- 7. Вывод книг с количеством страниц от 200 до 300(300-400)
SELECT Title_book, Pages
FROM Books
WHERE Pages BETWEEN 300 AND 400;

-- 8. Вывод авторов, фамилии которых начинаются на 'В'-'Г'(Д К)
SELECT Name_author
FROM Authors
WHERE Name_author >= 'Д' AND Name_author < 'К';

-- 9. Вывод названий книг и количества, поставленных поставщиками с кодами 3, 7, 9, 11 (1, 3, 5)
SELECT b.Title_book, p.Amount
FROM Books b
JOIN Purchases p ON b.Code_book = p.Code_book
WHERE p.Code_delivery IN (1, 3, 5);

-- 10. Вывод книг, выпущенных издательствами 'Питер-Софт', 'Альфа', 'Наука' ('ЭКСМО', 'Росмэн', 'МИФ');
SELECT b.Title_book
FROM Books b
JOIN Publishing_house p ON b.Code_publish = p.Code_publish
WHERE p.Publish IN ('ЭКСМО', 'Росмэн', 'МИФ');

-- 11. Вывод авторов, фамилии которых начинаются на 'К' (Д)
SELECT Name_author
FROM Authors
WHERE Name_author LIKE 'Д%';

-- 12. Выбор компаний с названиями, оканчивающимися на 'ский' ??????????
SELECT Name_company
FROM Deliveries
WHERE Name_company LIKE '%ед';

-- 13. Вывод издательств, содержащих в названии 'софт' (мен)
SELECT Publish
FROM Publishing_house
WHERE LOWER(Publish) LIKE '%мэн%';

-- 14. Выбор кодов поставщиков, дат заказов и названий книг с условиями по количеству и цене
SELECT p.Code_delivery, p.Date_order, b.Title_book
FROM Purchases p
JOIN Books b ON p.Code_book = b.Code_book
WHERE p.Amount > 100 OR (p.Cost BETWEEN CAST(200 AS MONEY) AND CAST(500 AS MONEY));

-- 15. Вывод издательств, выпустивших книги, названия которых начинаются со слова 'Труды' в Новосибирске ('Война%' AND ph.City = 'Москва';)
SELECT ph.Publish
FROM Publishing_house ph
JOIN Books b ON ph.Code_publish = b.Code_publish
WHERE b.Title_book LIKE 'Война%' AND ph.City = 'Москва';

-- 16. Вывод компаний-поставщиков и названий книг, поставленных в период 2002-2003 ( 2023-01-01' AND '2023-03-01')
SELECT d.Name_company, b.Title_book
FROM Deliveries d
JOIN Purchases p ON d.Code_delivery = p.Code_delivery
JOIN Books b ON p.Code_book = b.Code_book
WHERE p.Date_order BETWEEN '2023-01-01' AND '2023-03-01';

-- 17. Вывод поставщиков книг издательства 'Питер'(Росмэн)
SELECT DISTINCT d.Name_company
FROM Deliveries d
JOIN Purchases p ON d.Code_delivery = p.Code_delivery
JOIN Books b ON p.Code_book = b.Code_book
JOIN Publishing_house ph ON b.Code_publish = ph.Code_publish
WHERE ph.Publish = 'Росмэн';

-- 18. Вывод стоимости одной печатной страницы каждой книги и названий книг
SELECT b.Title_book, CAST(p.Cost / b.Pages AS DECIMAL(10, 4)) AS cost_per_page
FROM Books b
JOIN Purchases p ON b.Code_book = p.Code_book;

-- 19. Вывод количества лет с момента рождения авторов и имен авторов
SELECT
    Name_author,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, Birthday)) AS age_years
FROM Authors;
