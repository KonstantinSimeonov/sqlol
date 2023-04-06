-- path is relative to psql pwd sadly
\i ./plv8/generate-pastes.sql

drop table if exists pastes;

create table pastes (
    id serial primary key,
    content text not null,
    language varchar(20),
    created_at timestamp default(now()) not null,
    deleted_at timestamp default(null)
);

do $$
begin
    for i in 1..10 loop
        insert into pastes(content, language, created_at, deleted_at)
        select * from generate_pastes(100000);
    end loop;
end;
$$;
