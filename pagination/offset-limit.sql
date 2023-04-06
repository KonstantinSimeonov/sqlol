-- path is relative to psql pwd sadly
\i ./plv8/generate-pastes.sql

drop table if exists pastes;

create extension if not exists plv8;

create table pastes (
    id serial primary key,
    content text not null,
    language varchar(20),
    created_at timestamp default(now()),
    deleted_at timestamp default(null)
);

insert into pastes(content, language, created_at, deleted_at)
select * from generate_pastes(10000);
