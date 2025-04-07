-- Active: 1744030364581@@127.0.0.1@5432@db-books
-- VIEW 1: Детальная информация о книгах с авторами и издательствами
CREATE VIEW book_details AS
SELECT
    b.Code_book,
    b.Title_book,
    a.Name_author,
    b.Pages,
    ph.Publish AS publisher_name,
    ph.City AS publisher_city
FROM
    Books b
LEFT JOIN
    Authors a ON b.Code_author = a.Code_author
LEFT JOIN
    Publishing_house ph ON b.Code_publish = ph.Code_publish;
SELECT * from book_details

-- VIEW 2: Статистика закупок по поставщикам
CREATE VIEW supplier_purchase_stats AS
SELECT
    d.Code_delivery,
    d.Name_company,
    d.Name_delivery,
    COUNT(p.Code_purchase) AS total_purchases,
    SUM(p.Amount) AS total_books_ordered,
    SUM(p.Amount * p.Cost::numeric) AS total_cost,
    AVG(p.Cost::numeric) AS avg_book_cost,
    MIN(p.Date_order) AS first_order_date,
    MAX(p.Date_order) AS last_order_date
FROM
    Deliveries d
LEFT JOIN
    Purchases p ON d.Code_delivery = p.Code_delivery
GROUP BY
    d.Code_delivery, d.Name_company, d.Name_delivery;

SELECT * from supplier_purchase_stats
