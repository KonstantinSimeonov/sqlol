-- assume only one flag per notification

drop table if exists notifications;

create table notifications (
    id serial primary key,
    content text not null,
    flagged boolean not null default(false)
);

do $$

begin
    for i in 1..50000 loop
        insert into notifications (content, flagged) values
            -- let's say 1% of notifications are flagged
            ('zdr kpr ' || i, mod((random() * 1000)::int, 100) = 0);
    end loop;
end;
$$;

SET enable_seqscan TO on;

select count(1) as flagged_count from notifications where flagged;
select count(1) as total_count from notifications;

explain analyze
select count(1) as flagged_count from notifications where flagged;

explain analyze
select id from notifications where flagged limit 100;

-- tiny index due to where condition
create index flagged_idx on notifications(id) where flagged;

SET enable_seqscan TO off;

-- much faster due to indexing on the small number of records
explain analyze
select count(1) as flagged_count from notifications where flagged;

explain analyze
select id from notifications where flagged limit 100;

-- also fast, even when fetching columns not in the index
explain analyze
select id, content from notifications where flagged limit 100;

-- two tables instead of boolean field

drop table if exists flags2;
drop table if exists nots2;
create table nots2 (
    id serial primary key,
    content text not null
);

create table flags2 (
    id serial primary key,
    reason text,
    notification_id serial references nots2(id) not null
);

insert into nots2
select id, content from notifications;

insert into flags2 (reason, notification_id)
select 'i do not like you', id from notifications where flagged;

-- querying for count is somewhat meaningless here, since the count
-- can be obtained like so:
SET enable_seqscan TO on;

explain analyze
select count(1) from flags2;
-- the flagged ids like so:
explain analyze
select notification_id from flags2;

SET enable_seqscan TO off;

\qecho fetching flagged content with a join
explain analyze
select content from nots2 n join flags2 f on n.id = f.notification_id;

\qecho fetching flagged content with a where-in
explain analyze
select content from nots2 where id in (select notification_id from flags2);

-- without a unique constraint, the queries below use
-- a HashAggregate, resulting in somewhat lower perf (~20%)
create unique index notid_idx on flags2(notification_id);

\qecho join and where-in flagged content fetching with indexing
-- the index speeds up those queries like ~100x times for this data set
-- but they are still ~10x slower than the single table queries
explain analyze
select content from nots2 n join flags2 f on n.id = f.notification_id;

explain analyze
select content from nots2 where id in (select notification_id from flags2);
