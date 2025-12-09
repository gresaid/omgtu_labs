-- Версия GreenPlum
select version();

-- Сегменты кластера
select * from gp_segment_configuration;

-- Создадим таблицу с распределением данных по id
drop table if exists public.random_data;
create table public.random_data (
	id int,
	random_num decimal,
	random_text text
) distributed by (id);

-- Наполним таблицу суррогатными данными
insert into public.random_data(id, random_num, random_text)
select
	t,
	random() * 100,
	md5(random()::text)
from generate_series(1,1000) as t;

select * from public.random_data;

-- Посмотрим, как данные распределены по сегментам кластера
-- В этом случае данные распределены равномерно между всеми сегментами. Перекосов нет.
select gp_segment_id, count(*) from public.random_data group by gp_segment_id
order by 1;

-- Давайте искуственно создадим перекос
-- Создадим другую таблицу, данные в которой будут распределяться по полю с низкой селективностью
-- Например, по полю заполненному константой
create table public.random_data2 (
	id int,
	const_num int4,
	random_num decimal,
	random_text text
) distributed by (const_num);

insert into public.random_data2(id, const_num, random_num, random_text)
select
	t,
	0,
	random() * 100,
	md5(random()::text)
from generate_series(1,1000) as t;

-- Видим, что все данные попали на один из сегментов кластера
-- Таких перекосов нужно избегать
select gp_segment_id, count(*) from public.random_data2 group by gp_segment_id
order by 1;

