-- active: 1744025315676@@127.0.0.1@5432@db-books
-- 1. выбор всех полей из таблицы deliveries с изменением порядка столбцов
select
    name_delivery,
    inn,
    phone,
    address,
    code_delivery
from
    deliveries;

-- 2. выбор названий книг, страниц и имен авторов
select
    b.title_book,
    b.pages,
    a.name_author
from
    books b
    join authors a on b.code_author = a.code_author;

-- 3. выбор компаний с названиями, начинающимися на 'оао'
select
    name_company,
    phone,
    inn
from
    deliveries
where
    name_company like 'оао%';

-- 4. вывод издательств не из москвы
select
    publish
from
    publishing_house
where
    city != 'москва';

-- 5. вывод книг, выпущенных всеми издательствами, кроме 'питер-софт'(росмэн)
select
    b.title_book
from
    books b
    join publishing_house p on b.code_publish = p.code_publish
where
    p.publish != 'росмэн';

-- 6. вывод авторов с датой рождения в диапазоне '1821-11-11' and '1828-09-09'
select
    name_author
from
    authors
where
    birthday between '1821-11-11'
    and '1828-09-09';

-- 7. вывод книг с количеством страниц от 200 до 300(300-400)
select
    title_book,
    pages
from
    books
where
    pages between 300
    and 400;

-- 8. вывод авторов, фамилии которых начинаются на 'в'-'г'(д к)
select
    name_author
from
    authors
where
    name_author >= 'д'
    and name_author < 'к';

-- 9. вывод названий книг и количества, поставленных поставщиками с кодами 3, 7, 9, 11 (1, 3, 5)
select
    b.title_book,
    p.amount
from
    books b
    join purchases p on b.code_book = p.code_book
where
    p.code_delivery in (1, 3, 5);

-- 10. вывод книг, выпущенных издательствами 'питер-софт', 'альфа', 'наука' ('эксмо', 'росмэн', 'миф');
select
    b.title_book
from
    books b
    join publishing_house p on b.code_publish = p.code_publish
where
    p.publish in ('эксмо', 'росмэн', 'миф');

-- 11. вывод авторов, фамилии которых начинаются на 'к' (д)
select
    name_author
from
    authors
where
    name_author like 'д%';

-- 12. выбор компаний с названиями, оканчивающимися на 'ский' ??????????
select
    name_company
from
    deliveries
where
    name_company like '%ед';

-- 13. вывод издательств, содержащих в названии 'софт' (мен)
select
    publish
from
    publishing_house
where
    lower(publish) like '%мэн%';

-- 14. выбор кодов поставщиков, дат заказов и названий книг с условиями по количеству и цене
select
    p.code_delivery,
    p.date_order,
    b.title_book
from
    purchases p
    join books b on p.code_book = b.code_book
where
    p.amount > 100
    or (
        p.cost between cast(200 as money)
        and cast(500 as money)
    );

-- 15. вывод издательств, выпустивших книги, названия которых начинаются со слова 'труды' в новосибирске ('война%' and ph.city = 'москва';)
select
    ph.publish
from
    publishing_house ph
    join books b on ph.code_publish = b.code_publish
where
    b.title_book like 'война%'
    and ph.city = 'москва';

-- 16. вывод компаний-поставщиков и названий книг, поставленных в период 2002-2003 ( 2023-01-01' and '2023-03-01')
select
    d.name_company,
    b.title_book
from
    deliveries d
    join purchases p on d.code_delivery = p.code_delivery
    join books b on p.code_book = b.code_book
where
    p.date_order between '2023-01-01'
    and '2023-03-01';

-- 17. вывод поставщиков книг издательства 'питер'(росмэн)
select
    distinct d.name_company
from
    deliveries d
    join purchases p on d.code_delivery = p.code_delivery
    join books b on p.code_book = b.code_book
    join publishing_house ph on b.code_publish = ph.code_publish
where
    ph.publish = 'росмэн';

-- 18. вывод стоимости одной печатной страницы каждой книги и названий книг
select
    b.title_book,
    cast(p.cost / b.pages as decimal(10, 4)) as cost_per_page
from
    books b
    join purchases p on b.code_book = p.code_book;

-- 19. вывод количества лет с момента рождения авторов и имен авторов
select
    name_author,
    extract(
        year
        from
            age(current_date, birthday)
    ) as age_years
from
    authors;