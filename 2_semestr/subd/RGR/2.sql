-- все записи на определенную дату с информацией о клиентах, мастерах и услугах
select
    a.appointment_id,
    concat(c.first_name, ' ', c.last_name) as client_name,
    concat(e.first_name, ' ', e.last_name) as employee_name,
    s.name as service_name,
    a.start_time,
    s.duration,
    s.price,
    a.status
from
    appointments a
    join clients c on a.client_id = c.client_id
    join employees e on a.employee_id = e.employee_id
    join services s on a.service_id = s.service_id
where
    a.appointment_date = '2024-11-21'
order by
    a.start_time;

-- рейтинг мастеров по среднему баллу отзывов
select
    concat(e.first_name, ' ', e.last_name) as employee_name,
    e.position,
    count(f.feedback_id) as feedback_count,
    round(avg(f.rating), 2) as average_rating
from
    employees e
    left join appointments a on e.employee_id = a.employee_id
    left join feedback f on a.appointment_id = f.appointment_id
group by
    e.employee_id,
    e.first_name,
    e.last_name,
    e.position
having
    count(f.feedback_id) > 0
order by
    average_rating desc;

--анализ популярности услуг и дохода от них
select
    s.name as service_name,
    count(a.appointment_id) as appointment_count,
    sum(s.price) as total_revenue,
    round(avg(f.rating), 2) as average_rating
from
    services s
    left join appointments a on s.service_id = a.service_id
    left join feedback f on a.appointment_id = f.appointment_id
where
    a.status = 'completed'
    and a.appointment_date between '2025-01-01'
    and '2025-05-01'
group by
    s.service_id,
    s.name
order by
    appointment_count desc,
    total_revenue desc;

--список клиентов, не посещавших салон более 6 месяцев
select
    c.client_id,
    concat(c.first_name, ' ', c.last_name) as client_name,
    c.phone,
    c.email,
    max(a.appointment_date) as last_visit_date,
    current_date - max(a.appointment_date) as days_since_last_visit
from
    clients c
    left join appointments a on c.client_id = a.client_id
where
    a.status = 'completed'
group by
    c.client_id,
    c.first_name,
    c.last_name,
    c.phone,
    c.email
having
    max(a.appointment_date) < current_date - interval '6 months'
order by
    last_visit_date asc;

-- эффективность услуг
select
    service_id,
    name as service_name,
    price,
    duration,
    round(price / nullif(duration, 0), 2) as price_per_minute,
    round(price / (nullif(duration, 0) / 60.0), 2) as price_per_hour,
    rank() over (
        order by
            price / nullif(duration, 0) desc
    ) as profitability_rank
from
    services
where
    duration > 0
order by
    price_per_minute desc,
    price desc;

-- обновление цены на услугу с учетом инфляции
update
    services
set
    price = price * 1.1
where
    service_id in (1, 2, 3) --запрос на удаление данных
delete from
    appointments
where
    status = 'cancelled'
    and appointment_date < current_date - interval '3 months';