-- 1) витрина (wide table)
DROP TABLE IF EXISTS dm.dm_transactions_denorm;
CREATE TABLE dm.dm_transactions_denorm (
  transaction_id   text NOT NULL,
  dt               date,
  card             bigint,
  client_id        text,
  full_name        text,
  phone            text,
  passport         text,
  address_code     bpchar(13),

  region_id        bigint,
  region_code      bpchar(13),
  region_name      text,

  dist_id          bigint,
  dist_code        bpchar(13),
  dist_name        text,

  city_id          bigint,
  city_code        bpchar(13),
  city_name        text,

  street_id        bigint,
  street_code      bpchar(13),
  street_name      text,

  operation_type   text,
  amount           float8,
  operation_result text,
  terminal_id      text,

  load_dt          timestamp NOT NULL DEFAULT now()
)
DISTRIBUTED BY (transaction_id);


-- 2) функция загрузки (полная/инкремент)
CREATE OR REPLACE FUNCTION dm.fn_dm_transactions_denorm_load(p_update_dt date DEFAULT current_date)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
  p_step int4 := 0;
  p_row_count int4 := 0;
  p_end_dt date := date '4000-12-31';
BEGIN
  p_step := 1;
  RAISE NOTICE '%. Step %: start', clock_timestamp(), p_step;

  -- 1) delete period
  p_step := 2;
  DELETE FROM dm.dm_transactions_denorm
  WHERE dt >= p_update_dt;

  GET DIAGNOSTICS p_row_count = ROW_COUNT;
  RAISE NOTICE 'deleted: %', p_row_count;

  -- 2) tmp_kladr unique by code (для k)
  p_step := 3;
  DROP TABLE IF EXISTS tmp_kladr_code;
  CREATE TEMP TABLE tmp_kladr_code AS
  SELECT DISTINCT ON (code) *
  FROM public.dm_kladr
  WHERE p_end_dt BETWEEN start_dt AND end_dt
  ORDER BY code, start_dt DESC
  DISTRIBUTED BY (code);
  ANALYZE tmp_kladr_code;

  -- 3) tmp_kladr unique by kladr_id (для r/d/c)
  p_step := 4;
  DROP TABLE IF EXISTS tmp_kladr_id;
  CREATE TEMP TABLE tmp_kladr_id AS
  SELECT DISTINCT ON (kladr_id) *
  FROM public.dm_kladr
  WHERE p_end_dt BETWEEN start_dt AND end_dt
  ORDER BY kladr_id, start_dt DESC
  DISTRIBUTED BY (kladr_id);
  ANALYZE tmp_kladr_id;

  -- 4) tmp_street unique by street_code
  p_step := 5;
  DROP TABLE IF EXISTS tmp_street;
  CREATE TEMP TABLE tmp_street AS
  SELECT DISTINCT ON (street_code) *
  FROM public.dm_street
  WHERE p_end_dt BETWEEN start_dt AND end_dt
  ORDER BY street_code, start_dt DESC
  DISTRIBUTED BY (street_code);
  ANALYZE tmp_street;

  -- 5) insert denorm
  p_step := 6;
  INSERT INTO dm.dm_transactions_denorm (
    transaction_id, dt, card, client_id, full_name, phone, passport, address_code,
    region_id, region_code, region_name,
    dist_id, dist_code, dist_name,
    city_id, city_code, city_name,
    street_id, street_code, street_name,
    operation_type, amount, operation_result, terminal_id
  )
  WITH src AS (
    SELECT
      t.transaction_id::text AS transaction_id,

      CASE
        WHEN t."date" ~ '^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\.\d+' THEN
          to_timestamp(substr(t."date", 1, 26), 'YYYY-MM-DD HH24:MI:SS.US')::date
        WHEN t."date" ~ '^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}$' THEN
          to_timestamp(t."date", 'YYYY-MM-DD HH24:MI:SS')::date
        WHEN t."date" ~ '^\d{4}-\d{2}-\d{2}' THEN
          to_date(substr(t."date",1,10), 'YYYY-MM-DD')
        ELSE NULL
      END AS dt,

      NULLIF(regexp_replace(t.card, '\D','','g'),'')::bigint AS card,
      t.client_id::text AS client_id,
      t.full_name::text AS full_name,
      t.phone::text     AS phone,
      t.passport::text  AS passport,

      rpad(regexp_replace(coalesce(t.address_code,''), '\D','','g'), 13, '0')::bpchar(13) AS address_code,

      t.operation_type::text   AS operation_type,
      NULLIF(replace(t.amount, ',', '.'), '')::float8 AS amount,
      t.operation_result::text AS operation_result,
      t.terminal_id::text      AS terminal_id
    FROM trans_sch.transactions t
  )
  SELECT
    s.transaction_id, s.dt, s.card, s.client_id, s.full_name, s.phone, s.passport, s.address_code,

    k.region_id, k.region_code, r.name AS region_name,
    k.dist_id,   k.dist_code,   d.name AS dist_name,
    k.city_id,   k.city_code,   c.name AS city_name,

    st.street_id, st.street_code, st.street_name,

    s.operation_type, s.amount, s.operation_result, s.terminal_id
  FROM src s
  LEFT JOIN tmp_kladr_code k ON k.code = s.address_code
  LEFT JOIN tmp_kladr_id   r ON r.kladr_id = k.region_id
  LEFT JOIN tmp_kladr_id   d ON d.kladr_id = k.dist_id
  LEFT JOIN tmp_kladr_id   c ON c.kladr_id = k.city_id
  LEFT JOIN tmp_street     st ON st.street_code = s.address_code
  WHERE s.dt >= p_update_dt;

  GET DIAGNOSTICS p_row_count = ROW_COUNT;
  RAISE NOTICE 'inserted: %', p_row_count;

  RETURN 1;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error step %: %', p_step, SQLERRM;
    RETURN -1;
END;
$$;



-- 3) запуск
SELECT dm.fn_load_transactions_denorm(date '1900-01-01');

-- 4) проверки
SELECT count(*) FROM trans_sch.transactions;
SELECT count(*) FROM dm.dm_transactions_denorm;

-- сколько строк обогатилось адресом
SELECT
  sum((region_name is not null)::int) as with_region,
  sum((city_name   is not null)::int) as with_city,
  sum((street_name is not null)::int) as with_street
FROM dm.dm_transactions_denorm;



Нормализация кода (убрать всё кроме цифр + добить нулями до 13)
ALTER TABLE trans_sch.transactions
  ALTER COLUMN address_code TYPE bpchar(13)
  USING rpad(regexp_replace(address_code, '\D', '', 'g'), 13, '0')::bpchar(13);
