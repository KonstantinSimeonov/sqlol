drop table if exists follows;
drop table if exists users;

create table users (
    id serial primary key,
    name varchar(50) not null
);

create table follows (
    left_id serial not null references users(id),
    right_id serial not null references users(id),
    primary key (left_id, right_id)
);

do $$

declare
    X integer := 1;

begin
    for i in 1..1000 loop
        insert into users (name) values ('user_' || i);
    end loop;

    for i in 1..1000 loop
        for _ in 1..((random() * 5)::int) loop
            select (random() * 999 + 1)::int into X;
            if not exists (select from follows where left_id = i and right_id = X) then
                insert into follows values (i, X);
            end if;
        end loop;
    end loop;
end;
$$;

with recursive followed(n) as (
    select 0, * from users where id = 1
    union
    select
    distinct on (u.id)
        n + 1,
        u.id,
        u.name from followed
    join follows f on followed.id = f.left_id
    join users u on f.right_id = u.id
    where n < 3
) select * from followed;
