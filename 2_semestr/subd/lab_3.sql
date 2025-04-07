-- Active: 1744025315676@@127.0.0.1@5432@db-books
-- 1. Сортировка по названиям книг (возрастание) и страницам (убывание)
SELECT Code_book, Title_book, Pages
FROM Books
ORDER BY Title_book ASC, Pages DESC;

-- 2. Многотабличный запрос: компании-поставщики и названия книг за период 2002-2003
SELECT d.Name_company, b.Title_book
FROM Deliveries d
JOIN Purchases p ON d.Code_delivery = p.Code_delivery
JOIN Books b ON p.Code_book = b.Code_book
WHERE p.Date_order BETWEEN '2023-01-01' AND '2023-12-31';

-- 3. Вычисление суммарной стоимости партии одноименных книг в каждой поставке
SELECT b.Title_book, (p.Amount * p.Cost::numeric) AS total_cost
FROM Purchases p
JOIN Books b ON p.Code_book = b.Code_book;

-- 4. Вычисление общей суммы поставок книг, выполненных 'ЗАО Оптторг'
SELECT SUM(p.Amount * p.Cost::numeric) AS total_sum
FROM Purchases p
JOIN Deliveries d ON p.Code_delivery = d.Code_delivery
WHERE d.Name_company = 'ОАО Книжный мир';

-- 5. Средняя стоимость и среднее количество экземпляров книг в поставках, где автор 'Акунин'
SELECT AVG(p.Cost::numeric) AS avg_cost, AVG(p.Amount) AS avg_amount
FROM Purchases p
JOIN Books b ON p.Code_book = b.Code_book
JOIN Authors a ON b.Code_author = a.Code_author
WHERE a.Name_author LIKE 'Достоевский%';

-- 6. Список книг с количеством страниц больше среднего
SELECT Title_book, Pages
FROM Books
WHERE Pages > (SELECT AVG(Pages) FROM Books);

-- 7. Список авторов, возраст которых меньше среднего
SELECT Name_author, Birthday
FROM Authors
WHERE
    (CURRENT_DATE - Birthday) <
    (SELECT AVG(CURRENT_DATE - Birthday) FROM Authors);

-- 8. Список книг с минимальным количеством страниц
SELECT Title_book, Pages
FROM Books
WHERE Pages = (SELECT MIN(Pages) FROM Books);

-- 9. Список книг, которые были поставлены (с использованием EXISTS)
SELECT b.Title_book
FROM Books b
WHERE EXISTS (
    SELECT 1
    FROM Purchases p
    WHERE p.Code_book = b.Code_book
);

-- 10. Список авторов, книг которых нет в таблице Books (с использованием NOT EXISTS)
SELECT a.Name_author
FROM Authors a
WHERE NOT EXISTS (
    SELECT 1
    FROM Books b
    WHERE b.Code_author = a.Code_author
);
