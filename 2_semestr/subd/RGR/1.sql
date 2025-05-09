-- Active: 1744025315676@@127.0.0.1@5432@beauty_salon
-- Создание таблицы клиентов
CREATE TABLE clients (
    client_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    registration_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Создание таблицы сотрудников
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position VARCHAR(50) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    hire_date DATE NOT NULL
);

-- Создание таблицы услуг
CREATE TABLE services (
    service_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    duration INT NOT NULL, -- продолжительность в минутах
    price DECIMAL(10, 2) NOT NULL
);

-- Создание таблицы записей
CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    client_id INT NOT NULL,
    employee_id INT NOT NULL,
    service_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    start_time TIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled', -- scheduled, completed, cancelled
    CONSTRAINT fk_client FOREIGN KEY (client_id) REFERENCES clients(client_id),
    CONSTRAINT fk_employee FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    CONSTRAINT fk_service FOREIGN KEY (service_id) REFERENCES services(service_id)
);

-- Создание таблицы отзывов
CREATE TABLE feedback (
    feedback_id SERIAL PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT,
    feedback_date DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT fk_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);
