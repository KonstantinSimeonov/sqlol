drop table if exists salesmen;
create table salesmen (
    id serial primary key,
    fname varchar(30) not null,
    lname varchar(30) not null,
    cars_sold int not null default(0),
    email varchar(30) default(null)
);

insert into salesmen (fname, lname, cars_sold, email) values
('Clarabelle', 'Hanmer', 77, 'ch@mail.com'),
('Christiano', 'Overstall', 51, 'co@mail.com'),
('Pesho', 'Overstall', 51, null),
('Wilhelm', 'Kopec', 38, null),
('Rubie', 'Ding', 72, 'rd@mail.com'),
('Artemus', 'Woolward', 100, 'aw@mail.com'),
('Emilee', 'Nanetti', 84, 'en@proton.me'),
('Raina', 'Bedinn', 57, 'kiro@proton.me'),
('Glendon', 'Knowlys', 116, 'gkk@lol.com'),
('Carlotta', 'Dytham', 106, 'ca@mail.com'),
('Joly', 'Tschierasche', 114, 'jt@jt.mail');

-- seed
do $$

begin
    for i in 1..300000 loop
        insert into salesmen (fname, lname, cars_sold) values
            ('John' || i, 'Doe' || i, (random() * 999 + 1)::int);
    end loop;
end;
$$;

-- disable seq scan because pg sometimes goes overzealous with that
SET enable_seqscan TO off;

explain (analyze, buffers) select rank() over(order by cars_sold desc) as rank_sales, * from salesmen where cars_sold > 60;
-- without indexing, this becomes an external merge sort
explain (analyze, buffers) select * from salesmen where cars_sold > 300 order by cars_sold desc;
create index sold_idx on salesmen (cars_sold desc);
-- indexing doesn't seem to offer much perf gains for window funcs like rank
explain (analyze, buffers) select rank() over(order by cars_sold desc) as rank_sales, * from salesmen where cars_sold > 60;
-- with indexing, pg uses a bitmap index scan, noice!
-- ~3x faster on this dataset on my machine
explain (analyze, buffers) select fname from salesmen where cars_sold > 300;

drop index sold_idx;

create index sold_idx_300 on salesmen (fname) where cars_sold > 300;
-- contraintuitively, a predicated index doesn't seem to improve this query,
-- it actually makes it slower on this data set
-- TODO: understand why
explain (analyze, buffers) select fname from salesmen where cars_sold > 300;

drop index sold_idx_300;

-- seq scan, duh
explain (analyze, buffers) select id, fname from salesmen where lower(fname) = 'clarabelle';
create index fname_lower_idx on salesmen(lower(fname));
-- bitmap index scan
explain (analyze, buffers) select id, fname from salesmen where lower(fname) = 'clarabelle';
-- still a seq scan, because the index is not directly on the column,
-- but rather on a function of it
explain (analyze, buffers) select id, fname from salesmen where fname = 'Clarabelle';

drop index fname_lower_idx;

-- get all the John8's lol
explain (analyze, buffers) select * from salesmen where fname like '%n8';
create extension if not exists btree_gin;
create extension if not exists pg_trgm;
-- gin is slower to update than btrees, so maybe
-- not ideal for a high write volume to the indexed column
create index fname_gin_idx on salesmen using gin (fname gin_trgm_ops);
-- ~1000x faster on my machine with this dataset
-- for edge cases like '%8' execution time is twice as slow! tricky
explain (analyze, buffers) select * from salesmen where fname like '%n8';

drop index fname_gin_idx;

-- no index, seq scan
explain analyze select * from salesmen order by email desc nulls last limit 10;
create index email_idx on salesmen (email);
-- quick index backward scan, no in-memory sort
explain analyze select * from salesmen order by email desc limit 10;
-- in-memory sort, yikes, marginally better perf than no index
-- can also be remedied by adding "nulls last" to the index
-- but this makes the index somewhat specific to this particular query
explain analyze select * from salesmen order by email desc nulls last limit 10;
-- avoid the in-memory sort by union-ing not nulls with nulls in two simpler queries
-- seems to be much faster
explain analyze
    with sorted_by_email as (
        (select * from salesmen where email is not null order by email desc limit 10)
        union
        (select * from salesmen where email is null limit 10)
    )
    select * from sorted_by_email limit 10;

\i ./inspect/index-sizes.sql

drop index email_idx;
-- smaller index, 16KB instead of 2056KB
create index email_idx on salesmen(email) where email is not null;
-- performance degrades due to the second query requiring a seq scan
explain analyze
    with sorted_by_email as (
        (select * from salesmen where email is not null order by email desc limit 10)
        union
        (select * from salesmen where email is null limit 10)
    )
    select * from sorted_by_email limit 10;

-- same perf, maybe even better
explain analyze select * from salesmen where email is not null order by email desc limit 10;
-- requires sequential scan now
explain analyze select * from salesmen where email is null limit 10;

\i ./inspect/index-sizes.sql
