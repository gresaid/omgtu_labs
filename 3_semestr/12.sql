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
CREATE OR REPLACE FUNCTION dm.fn_load_transactions_denorm(p_update_dt date DEFAULT date '1900-01-01')
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  -- удаляем витрину за период перезагрузки
  DELETE FROM dm.dm_transactions_denorm
  WHERE dt >= p_update_dt;

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
      t.transaction_id::text                       AS transaction_id,
      t.date::date                                 AS dt,
      t.card::bigint                               AS card,
      t.client_id::text                            AS client_id,
      t.full_name::text                            AS full_name,
      t.phone::text                                AS phone,
      t.passport::text                             AS passport,
      -- нормализация address_code -> 13 символов
      rpad(regexp_replace(t.address_code::text, '\D', '', 'g'), 13, '0')::bpchar(13) AS address_code,
      t.operation_type::text                       AS operation_type,
      t.amount::float8                             AS amount,
      t.operation_result::text                     AS operation_result,
      t.terminal_id::text                          AS terminal_id
    FROM trans_sch.transactions t
    WHERE t.date::date >= p_update_dt
  )
  SELECT
    s.transaction_id, s.dt, s.card, s.client_id, s.full_name, s.phone, s.passport, s.address_code,

    k.region_id, k.region_code, r.name AS region_name,
    k.dist_id,   k.dist_code,   d.name AS dist_name,
    k.city_id,   k.city_code,   c.name AS city_name,

    st.street_id, st.street_code, st.street_name,

    s.operation_type, s.amount, s.operation_result, s.terminal_id
  FROM src s
  LEFT JOIN public.dm_kladr k
    ON k.code = s.address_code
   AND date '4000-12-31' BETWEEN k.start_dt AND k.end_dt
  LEFT JOIN public.dm_kladr r
    ON r.kladr_id = k.region_id
   AND date '4000-12-31' BETWEEN r.start_dt AND r.end_dt
  LEFT JOIN public.dm_kladr d
    ON d.kladr_id = k.dist_id
   AND date '4000-12-31' BETWEEN d.start_dt AND d.end_dt
  LEFT JOIN public.dm_kladr c
    ON c.kladr_id = k.city_id
   AND date '4000-12-31' BETWEEN c.start_dt AND c.end_dt
  LEFT JOIN public.dm_street st
    ON st.street_code = s.address_code
   AND date '4000-12-31' BETWEEN st.start_dt AND st.end_dt;

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
