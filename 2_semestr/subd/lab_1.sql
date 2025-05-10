-- Active: 1746819132822@@127.0.0.1@5432@db-books
-- создание таблицы авторы 
create table authors (
    code_author int primary key,
    name_author char(100) not null,
    birthday date
);

-- создание таблицы издательства
create table publishing_house (
    code_publish int primary key,
    publish char(100) not null,
    city char(50)
);

-- создание таблицы поставщики 
create table deliveries (
    code_delivery int primary key,
    name_delivery char(100) not null,
    name_company char(100) not null,
    address char(200),
    phone numeric(15),
    inn char(12)
);

-- создание таблицы книги 
create table books (
    code_book int primary key,
    title_book char(200) not null,
    code_author int references authors(code_author),
    pages int,
    code_publish int references publishing_house(code_publish)
);

-- создание таблицы покупки 
create table purchases (
    code_purchase int primary key,
    code_book int references books(code_book),
    date_order date not null,
    code_delivery int references deliveries(code_delivery),
    type_purchase boolean not null,
    -- 0 - розница, 1 - опт
    cost money not null,
    amount int not null
);

----- 1.1 заполнение данными
-- заполнение таблицы авторы (authors)
insert into
    authors (code_author, name_author, birthday)
values
    (1, 'толстой лев николаевич', '1828-09-09'),
    (2, 'достоевский федор михайлович', '1821-11-11'),
    (3, 'роулинг джоан кэтлин', '1965-07-31'),
    (4, 'кинг стивен', '1947-09-21'),
    (5, 'пелевин виктор олегович', '1962-11-22');

-- заполнение таблицы издательства (publishing_house)
insert into
    publishing_house (code_publish, publish, city)
values
    (1, 'эксмо', 'москва'),
    (2, 'аст', 'москва'),
    (3, 'росмэн', 'санкт-петербург'),
    (4, 'азбука', 'санкт-петербург'),
    (5, 'миф', 'москва');

-- заполнение таблицы поставщики (deliveries)
insert into
    deliveries (
        code_delivery,
        name_delivery,
        name_company,
        address,
        phone,
        inn
    )
values
    (
        1,
        'иванов а.а.',
        'оао книжный мир',
        'г. москва, ул. ленина, 10',
        79261234567,
        '7701234567'
    ),
    (
        2,
        'петров и.с.',
        'ооо книги оптом',
        'г. санкт-петербург, пр. невский, 30',
        78129876543,
        '7821234567'
    ),
    (
        3,
        'сидорова е.в.',
        'ип литера',
        'г. казань, ул. баумана, 15',
        78432345678,
        '1651234567'
    ),
    (
        4,
        'козлов д.д.',
        'оао буквоед',
        'г. екатеринбург, ул. ленина, 5',
        73433456789,
        '6671234567'
    ),
    (
        5,
        'смирнова о.п.',
        'ооо читай-город',
        'г. новосибирск, пр. красный, 25',
        73834567890,
        '5401234567'
    );

-- заполнение таблицы книги (books)
insert into
    books (
        code_book,
        title_book,
        code_author,
        pages,
        code_publish
    )
values
    (1, 'война и мир', 1, 1300, 1),
    (2, 'преступление и наказание', 2, 672, 4),
    (
        3,
        'гарри поттер и философский камень',
        3,
        399,
        3
    ),
    (4, 'оно', 4, 1138, 2),
    (5, 'generation п', 5, 352, 5);

-- заполнение таблицы покупки (purchases)
insert into
    purchases (
        code_purchase,
        code_book,
        date_order,
        code_delivery,
        type_purchase,
        cost,
        amount
    )
values
    (1, 1, '2023-01-15', 1, true, 550.00, 50),
    (2, 2, '2023-02-10', 2, true, 420.00, 30),
    (3, 3, '2023-03-05', 3, false, 350.00, 5),
    (4, 4, '2023-03-15', 4, true, 580.00, 40),
    (5, 5, '2023-04-01', 5, false, 420.00, 10);