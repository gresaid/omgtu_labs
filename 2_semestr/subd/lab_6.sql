-- active: 1744030364581@@127.0.0.1@5432@device_repair

-- вывести список приборов с указанным типом
create or replace procedure list_devices_by_type(device_type_param varchar)
language plpgsql
as $$
declare r record;
begin
    if device_type_param is null or trim(device_type_param) = '' then
        raise exception 'тип устройства не может быть пустым';
    end if;

    for r in (
        select
            device_id,
            device_name,
            device_type,
            manufacture_date
        from
            devices
        where
            device_type ilike '%' || device_type_param || '%'
        order by
            device_name
    ) loop
        raise notice 'устройство id: %, название: %, тип: %, дата производства: %',
              r.device_id, r.device_name, r.device_type, r.manufacture_date;
    end loop;
end;
$$;

-- вывести статистику по ремонтам указанного мастера
create or replace procedure list_master_repairs_stats(master_id_param int)
language plpgsql
as $$
declare
    total_repairs bigint;
    total_cost numeric;
    master_name varchar;
    master_exists boolean;
begin
    if master_id_param is null then
        raise exception 'id мастера не может быть null';
    end if;

    select exists (
        select 1 from masters where master_id = master_id_param
    ) into master_exists;

    if not master_exists then
        raise exception 'мастер с id % не найден', master_id_param;
    end if;

    select last_name || ' ' || first_name || ' ' || coalesce(middle_name, '')
    into master_name
    from masters
    where master_id = master_id_param;

    select
        count(repair_id),
        coalesce(sum(repair_cost), 0)
    into
        total_repairs,
        total_cost
    from
        repairs
    where
        master_id = master_id_param;

    raise notice 'статистика для мастера: %', master_name;
    raise notice 'количество ремонтов: %', total_repairs;
    raise notice 'общая стоимость: % руб.', total_cost;
end;
$$;

-- вывести владельцев и количество обращений
create or replace procedure list_owners_by_repairs_count()
language plpgsql
as $$
declare r record;
begin
    raise notice 'список владельцев по количеству обращений:';
    raise notice '-------------------------------------------';
    raise notice 'фио владельца | количество ремонтов | общая сумма';
    raise notice '-------------------------------------------';

    for r in (
        select
            owner_full_name,
            count(repair_id) as repairs_count,
            sum(repair_cost) as total_spent
        from
            repairs
        group by
            owner_full_name
        order by
            repairs_count desc,
            total_spent desc
    ) loop
        raise notice '% | % | % руб.',
              r.owner_full_name, r.repairs_count, r.total_spent;
    end loop;
end;
$$;

-- вывести информацию о мастерах по разряду и дате
create or replace procedure list_masters_by_rank_or_date(
    min_rank int default 1,
    max_hire_date date default current_date
)
language plpgsql
as $$
declare r record;

begin
    if min_rank is null then
        min_rank := 1;
    end if;

    if max_hire_date is null then
        max_hire_date := current_date;
    end if;

    raise notice 'список мастеров (разряд > % или дата приема < %):',
          min_rank, max_hire_date;
    raise notice '------------------------------------------------------';
    raise notice 'id | фио | разряд | дата приема | стаж (лет)';
    raise notice '------------------------------------------------------';

    for r in (
        select
            master_id,
            last_name || ' ' || first_name || ' ' || coalesce(middle_name, '') as full_name,
            qualification_rank,
            hire_date,
            extract(year from age(current_date, hire_date)) as years_exp
        from
            masters
        where
            qualification_rank > min_rank
            or hire_date < max_hire_date
        order by
            qualification_rank desc,
            hire_date asc
    ) loop
        raise notice '% | % | % | % | %',
              r.master_id, r.full_name, r.qualification_rank, r.hire_date, r.years_exp;
    end loop;
end;
$$;

call list_devices_by_type('смартфон');
call list_master_repairs_stats(1);
call list_owners_by_repairs_count();
call list_masters_by_rank_or_date(3, '2021-01-01');
