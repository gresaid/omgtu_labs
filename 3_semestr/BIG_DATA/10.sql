CREATE TABLE IF NOT EXISTS public.dm_street (
	street_id bigint NOT NULL,
	start_dt date NOT NULL,
	end_dt date NOT NULL,
	street_name text NULL,
	street_code bpchar(13) NULL,
	socr text NULL,
	index text NULL,
	gninmb text NULL,
	uno text NULL,
	ocatd text NULL,
	kladr_id bigint NULL,
	city_id bigint NULL,
	dist_id bigint NULL,
	region_id bigint NULL
) DISTRIBUTED BY (street_id);

CREATE TABLE IF NOT EXISTS public.stg_street (
	street_name text NULL,
	code bpchar(13) NULL,
	socr text NULL,
	index text NULL,
	gninmb text NULL,
	uno text NULL,
	ocatd text NULL
) DISTRIBUTED BY (code);

CREATE
OR REPLACE FUNCTION public.fn_dm_street_load(p_update_dt date DEFAULT CURRENT_DATE) RETURNS integer LANGUAGE plpgsql AS $ function $ declare p_step int4;

-- шаг исполнения функции
p_row_count int4;

-- кол-во обработанных записей
p_end_dt date = date '4000-12-31';

-- дата окончания действия (4000-12-31)
p_pos int;

-- кол-во символов для определения кода в КЛАДР
begin p_step := 1;

raise notice '%. Step: %. Starting function',
current_timestamp,
p_step;

-- АКТУАЛИЗАЦИЯ ВИТРИНЫ НА ДАТУ ЗАГРУЗКИ
p_step := 2;

raise notice '%. Step: %. удаляем записи, добавленные на дату загрузки и после',
current_timestamp,
p_step;

--PERFORM dm_data.fn_set_actual_period ('public.dm_street', p_update_dt);
-- удаляем записи, добавленные на дату загрузки и после
delete from
	public.dm_street
where
	start_dt >= p_update_dt;

GET DIAGNOSTICS p_row_count = ROW_COUNT;

RAISE NOTICE 'dpublic.dm_street rows deleted: %',
p_row_count;

p_step := 3;

raise notice '%. Step: %. обновляем дату актуальности у ранее удаленных записей',
current_timestamp,
p_step;

-- обновляем дату актуальности у ранее удаленных записей (
UPDATE
	public.dm_street
SET
	end_dt = p_end_dt
WHERE
	p_update_dt - 1 between start_dt
	and end_dt
	AND end_dt <> p_end_dt;

GET DIAGNOSTICS p_row_count = ROW_COUNT;

RAISE NOTICE 'public.dm_street rows updated: %',
p_row_count;

-- временная таблица с актуальным КЛАДР
DROP TABLE IF EXISTS tmp_kladr;

p_step := 4;

raise notice '%. Step: %. create  tmp_kladr',
current_timestamp,
p_step;

CREATE TEMPORARY TABLE tmp_kladr AS
SELECT
	*
FROM
	public.dm_kladr
WHERE
	p_end_dt between start_dt
	and end_dt -- current_date заменить на дату загрузки
	distributed BY (code);

GET DIAGNOSTICS p_row_count = ROW_COUNT;

RAISE NOTICE 'tmp_kladr rows inserted: %',
p_row_count;

ANALYZE tmp_kladr;

p_step := 5;

raise notice '%. Step: %. create  tmp_street_id',
current_timestamp,
p_step;

DROP TABLE IF EXISTS tmp_street_id;

create temp table tmp_street_id as
select
	distinct street_code,
	street_id
from
	public.dm_street distributed by (street_code);

GET DIAGNOSTICS p_row_count = ROW_COUNT;

RAISE NOTICE 'tmp_street_id rows inserted: %',
p_row_count;

p_step := 6;

raise notice '%. Step: %. create  tmp_street',
current_timestamp,
p_step;

DROP TABLE IF EXISTS tmp_street;

CREATE TEMP TABLE tmp_street (LIKE public.dm_street);

FOR p_pos IN
SELECT
	unnest(ARRAY [13,11,8,5,2]) LOOP
INSERT INTO
	tmp_street
SELECT
	coalesce(ids.street_id, nextval('public.sqn_main')) as street_id,
	p_update_dt,
	p_end_dt,
	s.*,
	k.kladr_id,
	k.city_id,
	k.dist_id,
	k.region_id
FROM
	public.stg_street s
	left join tmp_street_id ids on (ids.street_code = s.code)
	JOIN tmp_kladr k ON (k.code = rpad(substr(s.code, 1, p_pos), 13, '0'))
	AND NOT EXISTS (
		SELECT
			1
		FROM
			tmp_street s1
		WHERE
			s1.street_code = s.code
	);

GET DIAGNOSTICS p_row_count = ROW_COUNT;

RAISE NOTICE 'Processing tmp_street. Substep:  % ;rows inserted: %',
p_pos,
p_row_count;

ANALYZE tmp_kladr;

END LOOP;

p_step := 7;

raise notice '%. Step: %. create  tmp_street_diff',
current_timestamp,
p_step;

DROP TABLE IF EXISTS tmp_street_diff;

create temp table tmp_street_diff as
select
	street_id,
	MIN(start_dt) as start_dt,
	MIN(end_dt) as end_dt,
	street_name,
	street_code,
	socr,
	INDEX,
	gninmb,
	uno,
	ocatd,
	kladr_id,
	city_id,
	dist_id,
	region_id,
	MIN(is_new) as is_new
from
	(
		select
			street_id,
			start_dt,
			end_dt,
			street_name,
			street_code,
			socr,
			INDEX,
			gninmb,
			uno,
			ocatd,
			kladr_id,
			city_id,
			dist_id,
			region_id,
			0 as is_new
		from
			public.dm_street
		where
			p_update_dt between start_dt
			and end_dt
		union
		all
		select
			street_id,
			start_dt,
			end_dt,
			street_name,
			street_code,
			socr,
			INDEX,
			gninmb,
			uno,
			ocatd,
			kladr_id,
			city_id,
			dist_id,
			region_id,
			1 as is_new
		from
			tmp_street
	) q
group by
	street_id,
	street_name,
	street_code,
	socr,
	INDEX,
	gninmb,
	uno,
	ocatd,
	kladr_id,
	city_id,
	dist_id,
	region_id
having
	count(is_new) = 1 distributed by (street_id);

GET DIAGNOSTICS p_row_count = ROW_COUNT;

RAISE NOTICE 'tmp_street_diff rows inserted: %',
p_row_count;

analyze tmp_street_diff;

p_step := 9;

raise notice '%. Step: %. Updating old recods in dm_street',
current_timestamp,
p_step;

update
	public.dm_street s
set
	end_dt = p_update_dt - 1
where
	exists (
		select
			1
		from
			tmp_street_diff d
		where
			is_new = 0
			and s.street_id = d.street_id
	)
	and p_update_dt between s.start_dt
	and s.end_dt;

GET DIAGNOSTICS p_row_count = ROW_COUNT;

RAISE NOTICE 'public.dm_street rows updated: %',
p_row_count;

p_step := 10;

raise notice '%. Step: %. insertiing new recods into dm_kladr',
current_timestamp,
p_step;

insert into
	public.dm_street (
		street_id,
		start_dt,
		end_dt,
		street_name,
		street_code,
		socr,
		INDEX,
		gninmb,
		uno,
		ocatd,
		kladr_id,
		city_id,
		dist_id,
		region_id
	)
select
	street_id,
	start_dt,
	end_dt,
	street_name,
	street_code,
	socr,
	INDEX,
	gninmb,
	uno,
	ocatd,
	kladr_id,
	city_id,
	dist_id,
	region_id
from
	tmp_street_diff
where
	is_new = 1;

GET DIAGNOSTICS p_row_count = ROW_COUNT;

RAISE NOTICE 'public.dm_street New rows inserted. Inserted: % rows',
p_row_count;

analyze public.dm_kladr;

raise notice 'DONE';

return 1;

exception
when others then raise notice 'Error: on step:%,  %',
p_step,
SQLERRM;

return -1;

end;

$ function $;

TRUNCATE TABLE public.stg_street;

INSERT INTO
	public.stg_street (
		street_name,
		code,
		socr,
		index,
		gninmb,
		uno,
		ocatd
	)
SELECT
	"NAME" :: text,
	rpad(code :: text, 13, '0') :: bpchar(13),
	"SOCR" :: text,
	"index" :: text,
	"GNINMB" :: text,
	"UNO" :: text,
	"OCATD" :: text
FROM
	public.street
WHERE
	code IS NOT NULL;

---
select
	public.fn_dm_street_load();