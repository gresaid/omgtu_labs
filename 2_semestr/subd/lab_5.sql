-- active: 1744030364581@@127.0.0.1@5432@db-books
-- view 1: детальная информация о книгах с авторами и издательствами
create view book_details as
select
    b.code_book,
    b.title_book,
    a.name_author,
    b.pages,
    ph.publish as publisher_name,
    ph.city as publisher_city
from
    books b
    left join authors a on b.code_author = a.code_author
    left join publishing_house ph on b.code_publish = ph.code_publish;

select
    *
from
    book_details;

-- view 2: статистика закупок по поставщикам
create view supplier_purchase_stats as
select
    d.code_delivery,
    d.name_company,
    d.name_delivery,
    count(p.code_purchase) as total_purchases,
    sum(p.amount) as total_books_ordered,
    sum(p.amount * p.cost :: numeric) as total_cost,
    avg(p.cost :: numeric) as avg_book_cost,
    min(p.date_order) as first_order_date,
    max(p.date_order) as last_order_date
from
    deliveries d
    left join purchases p on d.code_delivery = p.code_delivery
group by
    d.code_delivery,
    d.name_company,
    d.name_delivery;

select
    *
from
    supplier_purchase_stats