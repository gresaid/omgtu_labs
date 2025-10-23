-- 1. Иерархия авторов (предполагая, что авторы могут быть связаны как наставники)
WITH RECURSIVE author_hierarchy AS (
    SELECT code_author, name_author, birthday, 0 AS level
    FROM authors
    WHERE code_author = 1 -- Начальный автор
    UNION ALL
    SELECT a.code_author, a.name_author, a.birthday, ah.level + 1
    FROM authors a
    JOIN author_hierarchy ah ON a.code_author = ah.code_author + 1
    WHERE ah.level < 3
)
SELECT name_author, level
FROM author_hierarchy;

-- 2. Список издательств с рекурсивным перечислением книг
WITH RECURSIVE publish_books AS (
    SELECT p.code_publish, p.publish, b.code_book, b.title_book, 1 AS book_count
    FROM publishing_house p
    LEFT JOIN books b ON p.code_publish = b.code_publish
    WHERE p.code_publish = 1 -- Начальное издательство
    UNION ALL
    SELECT p.code_publish, p.publish, b.code_book, b.title_book, pb.book_count + 1
    FROM publishing_house p
    LEFT JOIN books b ON p.code_publish = b.code_publish
    JOIN publish_books pb ON pb.code_publish = p.code_publish - 1
    WHERE pb.book_count < 3
)
SELECT publish, title_book, book_count
FROM publish_books;

-- 3. Цепочка поставок по книгам через покупки
WITH RECURSIVE delivery_chain AS (
    SELECT p.code_purchase, p.code_book, d.name_delivery, 1 AS chain_level
    FROM purchases p
    JOIN deliveries d ON p.code_delivery = d.code_delivery
    WHERE p.code_book = 1 -- Начальная книга
    UNION ALL
    SELECT p.code_purchase, p.code_book, d.name_delivery, dc.chain_level + 1
    FROM purchases p
    JOIN deliveries d ON p.code_delivery = d.code_delivery
    JOIN delivery_chain dc ON dc.code_book = p.code_book
    WHERE dc.chain_level < 3
)
SELECT name_delivery, chain_level
FROM delivery_chain;