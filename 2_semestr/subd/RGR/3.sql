create or replace procedure calculate_salon_revenue(
    start_date date,
    end_date date
)
language plpgsql
as $$
declare
    total_revenue decimal(12,2) := 0;
    master_rec record;
    service_rec record;
begin
    if start_date > end_date then
        raise exception 'начальная дата не может быть позже конечной даты';
    end if;

    select coalesce(sum(s.price), 0)
    into total_revenue
    from appointments a
    join services s on a.service_id = s.service_id
    where a.appointment_date between start_date and end_date
    and a.status = 'completed';

    raise notice 'период анализа: с % по %', start_date, end_date;
    raise notice 'общая выручка за период: % руб.', total_revenue;

    raise notice '--------------------------------------------------------';
    raise notice 'выручка по мастерам:';
    raise notice '--------------------------------------------------------';

    for master_rec in
        select
            e.employee_id,
            concat(e.first_name, ' ', e.last_name) as employee_name,
            count(a.appointment_id) as appointment_count,
            sum(s.price) as revenue,
            round(avg(coalesce(f.rating, 0)), 1) as avg_rating
        from employees e
        left join appointments a on e.employee_id = a.employee_id
        left join services s on a.service_id = s.service_id
        left join feedback f on a.appointment_id = f.appointment_id
        where (a.appointment_date between start_date and end_date or a.appointment_date is null)
        and (a.status = 'completed' or a.status is null)
        group by e.employee_id, e.first_name, e.last_name
        order by sum(coalesce(s.price, 0)) desc nulls last
    loop
        raise notice 'мастер: %, кол-во услуг: %, выручка: % руб., ср. рейтинг: %',
            master_rec.employee_name,
            master_rec.appointment_count,
            coalesce(master_rec.revenue, 0),
            master_rec.avg_rating;
    end loop;

    raise notice '--------------------------------------------------------';
    raise notice 'популярность услуг:';
    raise notice '--------------------------------------------------------';

    for service_rec in
        select
            s.name as service_name,
            count(a.appointment_id) as appointment_count,
            sum(s.price) as revenue,
            round(avg(coalesce(f.rating, 0)), 1) as avg_rating
        from services s
        left join appointments a on s.service_id = a.service_id
        left join feedback f on a.appointment_id = f.appointment_id
        where (a.appointment_date between start_date and end_date or a.appointment_date is null)
        and (a.status = 'completed' or a.status is null)
        group by s.service_id, s.name
        order by count(a.appointment_id) desc nulls last
    loop
        raise notice 'услуга: %, кол-во: %, выручка: % руб., ср. рейтинг: %',
            service_rec.service_name,
            service_rec.appointment_count,
            coalesce(service_rec.revenue, 0),
            service_rec.avg_rating;
    end loop;

    raise notice '--------------------------------------------------------';
    raise notice 'анализ завершен.';
end;
$$;
call calculate_salon_revenue('2025-01-01', '2025-05-01');



-- функция триггера для обновления даты последнего изменения
create or replace function update_last_modified()
returns trigger as $$
begin
    new.last_modified = current_timestamp;
    return new;
end;
$$ language plpgsql;

alter table appointments
add column if not exists last_modified timestamp default current_timestamp;

create trigger update_appointment_timestamp
before update on appointments
for each row
execute function update_last_modified();


-- обновление статуса записи
update appointments
set status = 'completed'
where appointment_id = 1;

-- проверка результата (last_modified должен обновиться автоматически)
select appointment_id, status, last_modified
from appointments
where appointment_id = 1;
