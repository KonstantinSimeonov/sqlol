drop table if exists vertices;
drop table if exists locations;

create table locations (
    id serial primary key,
    name varchar(50) not null,
    type varchar(50) not null
);

create table vertices (
    "from" serial not null references locations(id),
    "to" serial not null references locations(id),
    type varchar(50) not null,
    primary key ("from", "to", type)
);

insert into locations values
    (1, 'Europe', 'continent'),
    (2, 'Asia', 'continent'),
    (3, 'Athens', 'city'),
    (4, 'Greece', 'country'),
    (5, 'Russia', 'country'),
    (6, 'Mackva', 'city'),
    (7, 'Red Square', 'square'),
    (8, 'Japan', 'country'),
    (9, 'Tokyo', 'metropolis'),
    (10, 'Nagoya', 'city'),
    (11, 'Bulgaria', 'country'),
    (12, 'Chirpan', 'city'),
    (13, 'Mikre', 'village');

insert into vertices values
    (3, 4, 'in'),
    (4, 1, 'in'),
    (2, 1, 'borders'),
    (1, 2, 'borders'),
    (5, 1, 'in'),
    (5, 2, 'in'),
    (6, 5, 'in'),
    (7, 6, 'in'),
    (8, 2, 'in'),
    (9, 8, 'in'),
    (10, 9, 'in'),
    (6, 2, 'in'),
    (11, 1, 'in'),
    (11, 4, 'borders'),
    (12, 11, 'in'),
    (13, 11, 'in');

-- gimme them eu cities
with recursive eu_cities as (
    select * from locations where id = 1 -- Europe
    union
    select l.* from eu_cities ec
    join vertices v on v.to = ec.id
    join locations l on v.from = l.id
    where v.type = 'in' and not exists (
        -- without this we get Mackva as well
        select from vertices v1
        join locations l1 on v1.to = l1.id
        where v1.from = v.from and l1.id != 1 and l1.type = 'continent' and v1.type = 'in'
    )
) select * from eu_cities where type = 'city';

-- gimme which locations contain Nagoya
with recursive part_of as (
    select * from locations where id = 10 -- Nagoya, Japan
    union
    select l.* from part_of po
    join vertices v on po.id = v.from
    join locations l on l.id = v.to
    where v.type = 'in'
) select * from part_of;
