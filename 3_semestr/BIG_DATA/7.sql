drop table if exists public.kladr_part;

create table public.kladr_part (
    "NAME"   varchar,
    socr     varchar,
    code     varchar,
    "INDEX"  varchar,
    gninmb   varchar,
    uno      varchar,
    ocatd    varchar,
    status   varchar
)
distributed by (code)
partition by list (socr)
(
    partition region values ('респ', 'край', 'обл'),
    partition district values ('р-н'),
    partition city values ('г'),
    partition settlement values ('п', 'с', 'д'),
    default partition other
);


---

insert into public.kladr_part
select *
from public.kladr;

