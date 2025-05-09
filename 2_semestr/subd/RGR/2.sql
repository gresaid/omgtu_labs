-- все записи на определенную дату с информацией о клиентах, мастерах и услугах

SELECT
    a.appointment_id,
    CONCAT(c.first_name, ' ', c.last_name) AS client_name,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    s.name AS service_name,
    a.start_time,
    s.duration,
    s.price,
    a.status
FROM
    appointments a
JOIN
    clients c ON a.client_id = c.client_id
JOIN
    employees e ON a.employee_id = e.employee_id
JOIN
    services s ON a.service_id = s.service_id
WHERE
    a.appointment_date = '2024-11-21'
ORDER BY
    a.start_time;


-- Рейтинг мастеров по среднему баллу отзывов
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.position,
    COUNT(f.feedback_id) AS feedback_count,
    ROUND(AVG(f.rating), 2) AS average_rating
FROM
    employees e
LEFT JOIN
    appointments a ON e.employee_id = a.employee_id
LEFT JOIN
    feedback f ON a.appointment_id = f.appointment_id
GROUP BY
    e.employee_id, e.first_name, e.last_name, e.position
HAVING
    COUNT(f.feedback_id) > 0
ORDER BY
    average_rating DESC;

--Анализ популярности услуг и дохода от них
SELECT
    s.name AS service_name,
    COUNT(a.appointment_id) AS appointment_count,
    SUM(s.price) AS total_revenue,
    ROUND(AVG(f.rating), 2) AS average_rating
FROM
    services s
LEFT JOIN
    appointments a ON s.service_id = a.service_id
LEFT JOIN
    feedback f ON a.appointment_id = f.appointment_id
WHERE
    a.status = 'completed'
    AND a.appointment_date BETWEEN '2025-01-01' AND '2025-05-01'
GROUP BY
    s.service_id, s.name
ORDER BY
    appointment_count DESC, total_revenue DESC;


--Список клиентов, не посещавших салон более 6 месяцев
SELECT
    c.client_id,
    CONCAT(c.first_name, ' ', c.last_name) AS client_name,
    c.phone,
    c.email,
    MAX(a.appointment_date) AS last_visit_date,
    CURRENT_DATE - MAX(a.appointment_date) AS days_since_last_visit
FROM
    clients c
LEFT JOIN
    appointments a ON c.client_id = a.client_id
WHERE
    a.status = 'completed'
GROUP BY
    c.client_id, c.first_name, c.last_name, c.phone, c.email
HAVING
    MAX(a.appointment_date) < CURRENT_DATE - INTERVAL '6 months'
ORDER BY
    last_visit_date ASC;


-- Эффективность услуг
SELECT
    service_id,
    name AS service_name,
    price,
    duration,
    ROUND(price / NULLIF(duration, 0), 2) AS price_per_minute,
    ROUND(price / (NULLIF(duration, 0) / 60.0), 2) AS price_per_hour,
    RANK() OVER (ORDER BY price / NULLIF(duration, 0) DESC) AS profitability_rank
FROM
    services
WHERE
    duration > 0
ORDER BY
    price_per_minute DESC,
    price DESC;











-- Обновление цены на услугу с учетом инфляции
UPDATE services
SET price = price * 1.1
WHERE service_id IN (1, 2, 3)


--Запрос на удаление данных
DELETE FROM appointments
WHERE status = 'cancelled'
AND appointment_date < CURRENT_DATE - INTERVAL '3 months';
