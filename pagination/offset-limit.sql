-- path is relative to psql pwd sadly
\i ./plv8/generate-pastes.sql

drop function if exists setup(force boolean);
create function setup(force boolean) returns bigint as
$$
declare
    paste_count bigint;
begin
    if force then
        drop table if exists pastes;

        create table pastes (
            id serial primary key,
            content text not null,
            language varchar(20),
            created_at timestamp default(now()) not null,
            deleted_at timestamp default(null)
        );

        for i in 1..10 loop
            insert into pastes(content, language, created_at, deleted_at)
            select * from generate_pastes(100000);
            raise notice 'inserted some stuff %', i;
        end loop;
    end if;

    select into paste_count count(1) from pastes;
    return paste_count;
end;
$$ language plpgsql;

select setup(false) as pastes_count;

\qecho running without indexing
\i ./pagination/offset-limit-queries.sql

\qecho running with lang index
drop index if exists lang_idx;
-- negligably slower/faster for some queries
create index lang_idx on pastes(language);

drop index if exists lang_idx;

\qecho running with btree index on language
\i ./pagination/offset-limit-queries.sql

drop index if exists pagination_idx;
create index pagination_idx on pastes(language, created_at);

\qecho running with btree compound index on (language, created_at)
-- first page is faster, rest is still slow
\i ./pagination/offset-limit-queries.sql

drop index if exists pagination_idx;
create index pagination_idx on pastes(created_at, language);

\qecho running with btree compound index on (created_at, language)
-- first page is okayish, rest is still slow
\i ./pagination/offset-limit-queries.sql

drop index if exists pagination_idx;
create index language_idx on pastes(language);
create index created_at_idx on pastes(created_at);

\qecho running with 2 indexes: one on language, one on created_at
-- doesn't help much
-- performs well only on queries that only one of the indexed columns
\i ./pagination/offset-limit-queries.sql

drop index if exists language_idx;
drop index if exists created_at_idx;

-- desc on created_at doesn't make much difference
create index pagination_idx on pastes(created_at, language) where deleted_at is not null;

\qecho running with btree compound index on (created_at, language)
\qecho with where condition on deleted_at
-- much faster for all queries,
-- seems like the index predicate prevents
-- the need to sort/filter
\i ./pagination/offset-limit-queries.sql

drop index if exists pagination_idx;
