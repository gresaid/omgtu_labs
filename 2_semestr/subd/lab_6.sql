-- Active: 1744030364581@@127.0.0.1@5432@device_repair

-- Вывести список приборов с указанным типом
CREATE OR REPLACE PROCEDURE list_devices_by_type(device_type_param VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE r RECORD;
BEGIN
    IF device_type_param IS NULL OR TRIM(device_type_param) = '' THEN
        RAISE EXCEPTION 'Тип устройства не может быть пустым';
    END IF;

    FOR r IN (
        SELECT
            device_id,
            device_name,
            device_type,
            manufacture_date
        FROM
            devices
        WHERE
            device_type ILIKE '%' || device_type_param || '%'
        ORDER BY
            device_name
    ) LOOP
        RAISE NOTICE 'Устройство ID: %, Название: %, Тип: %, Дата производства: %',
              r.device_id, r.device_name, r.device_type, r.manufacture_date;
    END LOOP;
END;
$$;

-- Вывести статистику по ремонтам указанного мастера
CREATE OR REPLACE PROCEDURE list_master_repairs_stats(master_id_param INT)
LANGUAGE plpgsql
AS $$
DECLARE
    total_repairs BIGINT;
    total_cost NUMERIC;
    master_name VARCHAR;
    master_exists BOOLEAN;
BEGIN
    IF master_id_param IS NULL THEN
        RAISE EXCEPTION 'ID мастера не может быть NULL';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM masters WHERE master_id = master_id_param
    ) INTO master_exists;

    IF NOT master_exists THEN
        RAISE EXCEPTION 'Мастер с ID % не найден', master_id_param;
    END IF;

    SELECT last_name || ' ' || first_name || ' ' || COALESCE(middle_name, '')
    INTO master_name
    FROM masters
    WHERE master_id = master_id_param;

    SELECT
        COUNT(repair_id),
        COALESCE(SUM(repair_cost), 0)
    INTO
        total_repairs,
        total_cost
    FROM
        repairs
    WHERE
        master_id = master_id_param;

    RAISE NOTICE 'Статистика для мастера: %', master_name;
    RAISE NOTICE 'Количество ремонтов: %', total_repairs;
    RAISE NOTICE 'Общая стоимость: % руб.', total_cost;
END;
$$;

-- Вывести владельцев и количество обращений
CREATE OR REPLACE PROCEDURE list_owners_by_repairs_count()
LANGUAGE plpgsql
AS $$
DECLARE r RECORD;
BEGIN
    RAISE NOTICE 'Список владельцев по количеству обращений:';
    RAISE NOTICE '-------------------------------------------';
    RAISE NOTICE 'ФИО владельца | Количество ремонтов | Общая сумма';
    RAISE NOTICE '-------------------------------------------';

    FOR r IN (
        SELECT
            owner_full_name,
            COUNT(repair_id) AS repairs_count,
            SUM(repair_cost) AS total_spent
        FROM
            repairs
        GROUP BY
            owner_full_name
        ORDER BY
            repairs_count DESC,
            total_spent DESC
    ) LOOP
        RAISE NOTICE '% | % | % руб.',
              r.owner_full_name, r.repairs_count, r.total_spent;
    END LOOP;
END;
$$;

-- Вывести информацию о мастерах по разряду и дате
CREATE OR REPLACE PROCEDURE list_masters_by_rank_or_date(
    min_rank INT DEFAULT 1,
    max_hire_date DATE DEFAULT CURRENT_DATE
)
LANGUAGE plpgsql
AS $$
DECLARE r RECORD;

BEGIN
    IF min_rank IS NULL THEN
        min_rank := 1;
    END IF;

    IF max_hire_date IS NULL THEN
        max_hire_date := CURRENT_DATE;
    END IF;

    RAISE NOTICE 'Список мастеров (разряд > % или дата приема < %):',
          min_rank, max_hire_date;
    RAISE NOTICE '------------------------------------------------------';
    RAISE NOTICE 'ID | ФИО | Разряд | Дата приема | Стаж (лет)';
    RAISE NOTICE '------------------------------------------------------';

    FOR r IN (
        SELECT
            master_id,
            last_name || ' ' || first_name || ' ' || COALESCE(middle_name, '') AS full_name,
            qualification_rank,
            hire_date,
            EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS years_exp
        FROM
            masters
        WHERE
            qualification_rank > min_rank
            OR hire_date < max_hire_date
        ORDER BY
            qualification_rank DESC,
            hire_date ASC
    ) LOOP
        RAISE NOTICE '% | % | % | % | %',
              r.master_id, r.full_name, r.qualification_rank, r.hire_date, r.years_exp;
    END LOOP;
END;
$$;

CALL list_devices_by_type('Смартфон');
CALL list_master_repairs_stats(1);
CALL list_owners_by_repairs_count();
CALL list_masters_by_rank_or_date(3, '2021-01-01');
