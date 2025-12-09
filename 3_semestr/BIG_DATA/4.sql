with city as (
	select 
		code, 
		"NAME",
		substring(code,1,8) || rtrim(substring(code,9),'0') as city_code_mask
	from public.kladr
	where socr = 'г'
)
select k.*, city.* from public.kladr k
left join city on 1=1
and k.code like city.city_code_mask||'%';
select count(1) from public.kladr;


with city as (
	select 
		code, 
		"NAME",
		substring(code,1,8) || rtrim(substring(code,9),'0') as city_code_mask
	from public.kladr
	where socr = 'г'
)
select count(1) from public.kladr k
left join city on 1=1
and k.code like city.city_code_mask||'%';