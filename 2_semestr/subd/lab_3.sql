-- active: 1744025315676@@127.0.0.1@5432@db-books
-- 1. сортировка по названиям книг (возрастание) и страницам (убывание)
select
    code_book,
    title_book,
    pages
from
    books
order by
    title_book asc,
    pages desc;

-- 2. многотабличный запрос: компании-поставщики и названия книг за период 2002-2003
select
    d.name_company,
    b.title_book
from
    deliveries d
    join purchases p on d.code_delivery = p.code_delivery
    join books b on p.code_book = b.code_book
where
    p.date_order between '2023-01-01'
    and '2023-12-31';

-- 3. вычисление суммарной стоимости партии одноименных книг в каждой поставке
select
    b.title_book,
    (p.amount * p.cost :: numeric) as total_cost
from
    purchases p
    join books b on p.code_book = b.code_book;

-- 4. вычисление общей суммы поставок книг, выполненных 'зао оптторг'
select
    sum(p.amount * p.cost :: numeric) as total_sum
from
    purchases p
    join deliveries d on p.code_delivery = d.code_delivery
where
    d.name_company = 'оао книжный мир';

-- 5. средняя стоимость и среднее количество экземпляров книг в поставках, где автор 'акунин'
select
    avg(p.cost :: numeric) as avg_cost,
    avg(p.amount) as avg_amount
from
    purchases p
    join books b on p.code_book = b.code_book
    join authors a on b.code_author = a.code_author
where
    a.name_author like 'достоевский%';

-- 6. список книг с количеством страниц больше среднего
select
    title_book,
    pages
from
    books
where
    pages > (
        select
            avg(pages)
        from
            books
    );

-- 7. список авторов, возраст которых меньше среднего
select
    name_author,
    birthday
from
    authors
where
    (current_date - birthday) < (
        select
            avg(current_date - birthday)
        from
            authors
    );

-- 8. список книг с минимальным количеством страниц
select
    title_book,
    pages
from
    books
where
    pages = (
        select
            min(pages)
        from
            books
    );

-- 9. список книг, которые были поставлены (с использованием exists)
select
    b.title_book
from
    books b
where
    exists (
        select
            1
        from
            purchases p
        where
            p.code_book = b.code_book
    );

-- 10. список авторов, книг которых нет в таблице books (с использованием not exists)
select
    a.name_author
from
    authors a
where
    not exists (
        select
            1
        from
            books b
        where
            b.code_author = a.code_author
    );