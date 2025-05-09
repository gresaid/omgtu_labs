-- active: 1744025315676@@127.0.0.1@5432@beauty_salon
-- создание таблицы клиентов
create table clients (
    client_id serial primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    phone varchar(20) not null,
    email varchar(100),
    registration_date date not null default current_date
);

-- создание таблицы сотрудников
create table employees (
    employee_id serial primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    position varchar(50) not null,
    phone varchar(20) not null,
    hire_date date not null
);

-- создание таблицы услуг
create table services (
    service_id serial primary key,
    name varchar(100) not null,
    description text,
    duration int not null,
    -- продолжительность в минутах
    price decimal(10, 2) not null
);

-- создание таблицы записей
create table appointments (
    appointment_id serial primary key,
    client_id int not null,
    employee_id int not null,
    service_id int not null,
    appointment_date date not null,
    start_time time not null,
    status varchar(20) not null default 'scheduled',
    -- scheduled, completed, cancelled
    constraint fk_client foreign key (client_id) references clients(client_id),
    constraint fk_employee foreign key (employee_id) references employees(employee_id),
    constraint fk_service foreign key (service_id) references services(service_id)
);

-- создание таблицы отзывов
create table feedback (
    feedback_id serial primary key,
    appointment_id int not null unique,
    rating int not null check (
        rating between 1
        and 5
    ),
    comment text,
    feedback_date date not null default current_date,
    constraint fk_appointment foreign key (appointment_id) references appointments(appointment_id)
);