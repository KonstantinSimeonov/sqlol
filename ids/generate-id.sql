
drop function if exists generate_id;
-- TODO: figure out bytea, char(32) seems terrible compared to uuid
create function generate_id() returns char(32) as
$$
    declare ts text;
    declare rnd text;
begin
    ts := extract(epoch from current_timestamp)::int::text;
    rnd := substring(md5(random()::text), 1, 32 - length(ts) - 1);
    return (ts || '-' || rnd)::char(32);
end;
$$ language plpgsql;

drop table if exists posts;
create table posts (
    id char(32) primary key default(generate_id()),
    content text not null,
    title text not null
);

insert into posts
    (content, title)
values
    ('kekw', 'kekw'),
    ('omri', 'haha'),
    ('kiro', 'miro');

select pg_sleep(2);

insert into posts
    (content, title)
values
    ('don4o', 'kekw'),
    ('stamat', 'haha'),
    ('van4o', 'miro');

select pg_sleep(2);

insert into posts
    (content, title)
values
    ('kir4o', 'kekw'),
    ('haha', 'test'),
    ('test', 'omri');

select * from posts;

select * from posts order by id desc;

select * from posts where id > (select id from posts offset 4 limit 1) order by id;

insert into posts
    (id, content, title)
values
    ('1690021995-dde3014a94326d14d95de', 'kir4o', 'kekw'),
    ('1700031995-dd63014a94326d14d95de', 'kir4o', 'kekw');

-- 9 posts expected
select * from posts where id between '1690021996' and '1690031994';
