create table public.dm_kladr (
    kladr_id    bigint,
    level       int,
    type        text,
    code        char(13),
    name        text,
    city_id     bigint,
    city_code   char(13),
    dist_id     bigint,
    dist_code   char(13),
    region_id   bigint,
    region_code char(13),
    start_dt    date,
    end_dt      date
)
distributed by (kladr_id);


create table public.stg_kladr (
    name text,
    code char(13)
);

insert into public.stg_kladr (name, code)
select "NAME", code
from kladr;   -- ваша таблица

create sequence public.sqn_main;
CREATE OR REPLACE FUNCTION public.fn_dm_kladr_load (
    p_update_dt date default current_date
)
RETURNS int4
LANGUAGE plpgsql
AS $$
DECLARE
    p_step      int4;
    p_row_count int4;
    p_end_dt    date := date '4000-12-31';
BEGIN
    p_step := 1;
    RAISE NOTICE '%. Step %. Start', clock_timestamp(), p_step;

    -------------------------------------------------------------------------
    -- 1. Удаление "новых" записей с start_dt >= p_update_dt (перезапуск)
    -------------------------------------------------------------------------
    p_step := 2;
    RAISE NOTICE '%. Step %. Cleaning future records', clock_timestamp(), p_step;

    DELETE FROM public.dm_kladr
    WHERE start_dt >= p_update_dt;

    GET DIAGNOSTICS p_row_count = ROW_COUNT;
    RAISE NOTICE 'dm_kladr deleted: %', p_row_count;

    -------------------------------------------------------------------------
    -- 2. Откат ранее закрытых записей (если перезапуск)
    -------------------------------------------------------------------------
    p_step := 3;
    RAISE NOTICE '%. Step %. Re-open previous records', clock_timestamp(), p_step;

    UPDATE public.dm_kladr
    SET end_dt = p_end_dt
    WHERE p_update_dt - 1 BETWEEN start_dt AND end_dt
      AND end_dt <> p_end_dt;

    GET DIAGNOSTICS p_row_count = ROW_COUNT;
    RAISE NOTICE 'dm_kladr reopened: %', p_row_count;

    -------------------------------------------------------------------------
    -- 3. Берём старые kladr_id, чтобы не создавать новые
    -------------------------------------------------------------------------
    DROP TABLE IF EXISTS tmp_kladr_id;

    CREATE TEMP TABLE tmp_kladr_id AS
    SELECT DISTINCT code, kladr_id
    FROM public.dm_kladr
    DISTRIBUTED BY (code);

    ANALYZE tmp_kladr_id;

    -------------------------------------------------------------------------
    -- 4. Формируем новый срез КЛАДР
    -------------------------------------------------------------------------
    DROP TABLE IF EXISTS tmp_kladr_new;

    CREATE TEMP TABLE tmp_kladr_new AS
    WITH base AS (
        SELECT 
            name,
            code,
            CASE
                WHEN right(code, 11) = '00000000000' THEN 1
                WHEN right(code, 8) = '0000000' THEN 2
                WHEN right(code, 5) = '00000' THEN 3
                ELSE 4
            END AS level
        FROM public.stg_kladr
    )
    SELECT
        COALESCE(ids.kladr_id, nextval('public.sqn_main')) AS kladr_id,
        CASE
            WHEN right(k.code, 11) = '00000000000' THEN 1
            WHEN right(k.code, 8)  = '0000000' THEN 2
            WHEN right(k.code, 5)  = '00000' THEN 3
            ELSE 4
        END AS level,
        CASE
            WHEN right(k.code, 11) = '00000000000' THEN 'region'
            WHEN right(k.code, 8)  = '0000000' THEN 'district'
            WHEN right(k.code, 5)  = '00000' THEN 'city'
            ELSE 'settlement'
        END AS type,
        k.name,
        k.code,
        r.code AS region_code,
        d.code AS dist_code,
        c.code AS city_code
    FROM public.stg_kladr k
    LEFT JOIN tmp_kladr_id ids ON ids.code = k.code
    LEFT JOIN base r ON r.level = 1 AND r.code = rpad(substr(k.code, 1, 2), 13, '0')
    LEFT JOIN base d ON d.level = 2 AND d.code = rpad(substr(k.code, 1, 5), 13, '0')
    LEFT JOIN base c ON c.level = 3 AND c.code = rpad(substr(k.code, 1, 8), 13, '0')
    DISTRIBUTED BY (kladr_id);

    ANALYZE tmp_kladr_new;

    -------------------------------------------------------------------------
    -- 5. Формируем ссылки на родителей
    -------------------------------------------------------------------------
    DROP TABLE IF EXISTS tmp_kladr_result;

    CREATE TEMP TABLE tmp_kladr_result AS
    SELECT
        k.kladr_id,
        k.level,
        k.type,
        k.code,
        k.name,
        COALESCE(city.kladr_id, -1) AS city_id,
        k.city_code,
        COALESCE(dist.kladr_id, -1) AS dist_id,
        k.dist_code,
        COALESCE(reg.kladr_id, -1) AS region_id,
        k.region_code
    FROM tmp_kladr_new k
    LEFT JOIN tmp_kladr_new reg  ON reg.code  = k.region_code
    LEFT JOIN tmp_kladr_new dist ON dist.code = k.dist_code
    LEFT JOIN tmp_kladr_new city ON city.code = k.city_code
    DISTRIBUTED BY (kladr_id);

    ANALYZE tmp_kladr_result;

    -------------------------------------------------------------------------
    -- 6. Находим различия (новые и устаревшие записи)
    -------------------------------------------------------------------------
    DROP TABLE IF EXISTS tmp_kladr_diff;

    CREATE TEMP TABLE tmp_kladr_diff AS
    SELECT
        kladr_id,
        level,
        type,
        code,
        name,
        city_id,
        city_code,
        dist_id,
        dist_code,
        region_id,
        region_code,
        MIN(is_new) AS is_new
    FROM (
        -- старые актуальные
        SELECT
            kladr_id, level, type, code, name,
            city_id, city_code,
            dist_id, dist_code,
            region_id, region_code,
            0 AS is_new
        FROM public.dm_kladr
        WHERE p_update_dt BETWEEN start_dt AND end_dt
        
        UNION ALL
        
        -- новые
        SELECT
            kladr_id, level, type, code, name,
            city_id, city_code,
            dist_id, dist_code,
            region_id, region_code,
            1 AS is_new
        FROM tmp_kladr_result
    ) t
    GROUP BY
        kladr_id, level, type, code, name,
        city_id, city_code,
        dist_id, dist_code,
        region_id, region_code
    HAVING COUNT(*) = 1
    DISTRIBUTED BY (kladr_id);

    ANALYZE tmp_kladr_diff;

    -------------------------------------------------------------------------
    -- 7. Закрываем старые версии
    -------------------------------------------------------------------------
    UPDATE public.dm_kladr k
    SET end_dt = p_update_dt - 1
    WHERE EXISTS (
        SELECT 1 FROM tmp_kladr_diff d
        WHERE d.is_new = 0
          AND d.kladr_id = k.kladr_id
    )
    AND p_update_dt BETWEEN k.start_dt AND k.end_dt;

    -------------------------------------------------------------------------
    -- 8. Вставляем новые версии (ТО ЧЕГО НЕ ХВАТАЛО)
    -------------------------------------------------------------------------
    INSERT INTO public.dm_kladr (
        kladr_id, level, type, code, name,
        city_id, city_code,
        dist_id, dist_code,
        region_id, region_code,
        start_dt, end_dt
    )
    SELECT
        kladr_id,
        level,
        type,
        code,
        name,
        city_id,
        city_code,
        dist_id,
        dist_code,
        region_id,
        region_code,
        p_update_dt,
        p_end_dt
    FROM tmp_kladr_diff
    WHERE is_new = 1;

    -------------------------------------------------------------------------
    RAISE NOTICE 'DONE';
    RETURN 1;

EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error at step %, %', p_step, SQLERRM;
    RETURN -1;
END;
$$;


select * from fn_dm_kladr_load();



select * from fn_dm_kladr_load();

UPDATE public.stg_kladr
SET name = name || ' TEST11'
WHERE code = '1802200700099';

SELECT public.fn_dm_kladr_load('2025-12-10');

SELECT kladr_id, name, start_dt, end_dt
FROM public.dm_kladr
WHERE code = '1802200700099'
ORDER BY start_dt;
