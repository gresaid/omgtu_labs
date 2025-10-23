-- 1. Конкатенация имени автора и названия книги
SELECT CONCAT(trim(a.name_author), ' - ', trim(b.title_book)) AS author_book
FROM authors a
JOIN books b ON a.code_author = b.code_author;

-- 2. Извлечение первых 50 символов названия книги в верхнем регистре
SELECT UPPER(LEFT(b.title_book, 50)) AS short_title
FROM books b;

-- 3. Замена пробелов в названии компании поставщика на подчеркивания
SELECT REPLACE(d.name_company, ' ', '_') AS company_name
FROM deliveries d;

-- 4. Получение длины строки адреса поставщика
SELECT d.name_delivery, LENGTH(d.address) AS address_length
FROM deliveries d;

-- 5. Извлечение подстроки города издательства до первого пробела
SELECT p.publish, SUBSTRING(p.city FROM 1 FOR POSITION('-' IN p.city) - 1) AS city_part
FROM publishing_house p
WHERE POSITION('-' IN p.city) > 0;

select * from publishing_house;