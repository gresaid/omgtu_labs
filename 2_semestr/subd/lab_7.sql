-- active: 1744030364581@@127.0.0.1@5432@device_repair
-- 1.  ведение журнала изменений стоимости ремонта

create table if not exists repair_cost_history (
    history_id serial primary key,
    repair_id int not null,
    old_cost decimal(10, 2),
    new_cost decimal(10, 2),
    change_date timestamp default current_timestamp,
    change_user varchar(100) default current_user,
    change_reason varchar(255)
);

create or replace function log_repair_cost_changes()
returns trigger as $$
begin
    if (old.repair_cost is distinct from new.repair_cost) then
        insert into repair_cost_history (
            repair_id,
            old_cost,
            new_cost,
            change_reason
        ) values (
            new.repair_id,
            old.repair_cost,
            new.repair_cost,
            'изменение стоимости ремонта'
        );

        raise notice 'стоимость ремонта id % изменена с % на %',
            new.repair_id, old.repair_cost, new.repair_cost;
    end if;
    return new;
end;
$$ language plpgsql;

create or replace trigger track_repair_cost_changes
before update on repairs
for each row
execute function log_repair_cost_changes();

-- 2.  автоматическое обновление разряда мастера при выполнении определенного количества ремонтов

create table if not exists rank_upgrade_conditions (
    rank_id serial primary key,
    from_rank int not null,
    to_rank int not null,
    min_repairs_required int not null,
    min_experience_years decimal(5, 2) not null,
    unique (from_rank, to_rank)
);

insert into rank_upgrade_conditions (from_rank, to_rank, min_repairs_required, min_experience_years)
values
    (1, 2, 3, 0.5),
    (2, 3, 30, 1.0),
    (3, 4, 50, 2.0),
    (4, 5, 100, 3.0)
on conflict (from_rank, to_rank) do nothing;

create or replace function check_master_rank_upgrade()
returns trigger as $$
declare
    master_repair_count int;
    master_experience decimal(5, 2);
    current_rank int;
    upgrade_condition record;
    should_upgrade boolean := false;
    master_name varchar;
begin
    -- получаем данные о мастере
    select
        qualification_rank,
        extract(year from age(current_date, hire_date)),
        last_name || ' ' || first_name || ' ' || coalesce(middle_name, '')
    into
        current_rank,
        master_experience,
        master_name
    from masters
    where master_id = new.master_id;

    -- выводим отладочную информацию
    raise notice 'триггер активирован для мастера id: %, фио: %, текущий разряд: %, стаж: % лет',
        new.master_id, master_name, current_rank, master_experience;

    -- подсчитываем общее количество ремонтов, включая только что добавленный
    select count(*)
    into master_repair_count
    from repairs
    where master_id = new.master_id;

    raise notice 'общее количество ремонтов у мастера: %', master_repair_count;

    -- проверяем условия для повышения разряда
    select * into upgrade_condition
    from rank_upgrade_conditions
    where from_rank = current_rank
    and min_repairs_required <= master_repair_count
    and min_experience_years <= master_experience;

    -- если есть подходящее условие - повышаем разряд
    if found then
        should_upgrade := true;

        -- обновляем разряд мастера
        update masters
        set qualification_rank = upgrade_condition.to_rank
        where master_id = new.master_id;

        -- выводим уведомление о повышении
        raise notice 'мастер % повышен с разряда % до разряда %',
            master_name, current_rank, upgrade_condition.to_rank;
    else
        raise notice 'условия для повышения не выполнены';

        -- проверяем, есть ли вообще правило для текущего разряда
        select * into upgrade_condition
        from rank_upgrade_conditions
        where from_rank = current_rank;
    end if;

    -- возвращаем new, чтобы разрешить операцию insert
    return new;
end;
$$ language plpgsql;

drop trigger if exists update_master_rank_on_repair on repairs;

create or replace trigger update_master_rank_on_repair
after insert on repairs
for each row
execute function check_master_rank_upgrade();

-- обновления стоимости ремонта для проверки первого триггера:
update repairs set repair_cost = 9000.00 where repair_id = 1;
select * from repair_cost_history;
-- добавления нового ремонта для проверки второго триггера:

select * from masters;
select * from repairs;

delete from masters where master_id = 6;
insert into masters (master_id, last_name, first_name, middle_name, qualification_rank, hire_date) values
(8, 'Вовчик', 'тест', 'тестович', 1, '2020-03-15')

delete from repairs where master_id = 17;

insert into repairs (repair_id, device_in_repair_id, device_id, master_id, owner_full_name, receipt_date, malfunction_type, repair_cost)
values
(21, 'rep-2023-007', 1, 8, 'тестовый клиент2', current_date, 'тестовая поломка2', 5000.00),
(22, 'rep-2023-007', 1, 8, 'тестовый клиент2', current_date, 'тестовая поломка2', 5000.00),
(23, 'rep-2023-007', 1, 8, 'тестовый клиент2', current_date, 'тестовая поломка2', 5000.00);
