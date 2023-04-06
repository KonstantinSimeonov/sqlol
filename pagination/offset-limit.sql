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
