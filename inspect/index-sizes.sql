select c.relname AS name,
  pg_size_pretty(sum(c.relpages::bigint * 8192)::bigint) as size
from pg_class c
left join pg_namespace n on (n.oid = c.relnamespace)
where n.nspname not in ('pg_catalog', 'information_schema')
and n.nspname !~ '^pg_toast'
and c.relkind='i'
group by c.relname
order by sum(c.relpages) desc;
