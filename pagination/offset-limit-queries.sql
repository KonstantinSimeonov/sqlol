\qecho page count
explain (analyze, settings on)
select count(1) / 20 as page_count
from pastes
where
    language = 'js'
    and created_at > '01/01/2002'
    and deleted_at is null;

\qecho get page 0
explain analyze
select * from pastes
where
    language = 'js'
    and created_at > '01/01/2002'
    and deleted_at is null
order by created_at desc
limit 20;

\qecho get page 10
explain analyze
select * from pastes
where
    language = 'js'
    and created_at > '01/01/2002'
    and deleted_at is null
order by created_at desc
offset 180
limit 20;

\qecho just give me recent pastes
explain analyze
select * from pastes
where
    created_at > '01/01/2002'
    and deleted_at is null
order by created_at desc
offset 180
limit 20;

\qecho just give me js
explain analyze
select * from pastes
where
    language = 'js'
offset 180
limit 20;
