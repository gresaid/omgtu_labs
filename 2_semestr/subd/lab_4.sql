-- active: 1744030364581@@127.0.0.1@5432@db-books
--- оператор update
-- 1. изменение значения поля pages на 300 для книг с определенными параметрами
update books
set
    pages = 300
where
    code_author = 1
    and title_book = 'мемуары';

select * from books;
-- 2. увеличение цены на 20% для заказов, оформленных в течение последнего месяца
update purchases
set
    cost = cost * 1.2
where
    date_order >= (
        current_date - interval '1 month'
    );

--- оператор insert
-- 1. добавление новой записи в таблицу books с автоматическим определением кода
insert into
    books (
        code_book,
        title_book,
        code_author,
        pages,
        code_publish
    )
values (
        (
            select coalesce(max(code_book), 0) + 1
            from books
        ),
        'наука. техника. инновации',
        null,
        null,
        null
    );

-- 2. добавление новой записи в таблицу publishing_house
insert into
    publishing_house (code_publish, publish, city)
values (
        (
            select coalesce(max(code_publish), 0) + 1
            from publishing_house
        ),
        'наука',
        'москва'
    );

-- оператор delete
-- 1. удаление записей с нулевым количеством книг в заказе
delete from purchases where amount = 0;

select * from deliveries;

-- 2. удаление записей без указания инн
delete from deliveries where inn is null or trim(inn) = '';
