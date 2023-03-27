\set ON_ERROR_STOP off

drop table if exists employees;

create table employees (
    id serial primary key,
    first_name varchar(50),
    last_name varchar(50),
    birth_date date check (birth_date > '1950-01-01') not null,
    created_at date check (created_at > birth_date) not null,
    salary numeric check(salary > 0) not null
);

insert into employees
    (first_name, last_name, birth_date, created_at, salary)
values
    ('gregothy', 'johnson', '1960-01-01', '1970-01-01', 1000),
    ('dorothy', 'johnson', '1965-12-01', '1970-12-01', 1200),
    ('ivan', 'karagiozov', '2001-03-09', '2023-01-01', 800);

select * from employees;

insert into employees
    (first_name, last_name, birth_date, created_at, salary)
values
    ('gregothy', 'johnson', '1930-01-01', '1970-01-01', 1000);

insert into employees
    (first_name, last_name, birth_date, created_at, salary)
values
    ('gregothy', 'johnson', '1980-01-01', '1970-01-01', 1000);

insert into employees
    (first_name, last_name, birth_date, created_at, salary)
values
    ('gregothy', 'johnson', '1980-01-01', '1990-01-01', -1000);

update employees
set
    first_name = initcap(first_name),
    last_name = initcap(last_name);

select * from employees;

drop function if exists is_cap;
create function is_cap(x text) returns boolean
    language sql
    immutable
    returns null on null input
    return ascii(left($1, 1)) between 65 and 90;

alter table employees
add constraint capital_names_check
check (
    is_cap(first_name) and is_cap(last_name)
);

insert into employees values
    (5, 'test', 'hello', '2001-12-12', '2002-12-12', 1);

alter table employees
drop constraint capital_names_check;

insert into employees values
    (5, 'test', 'hello', '2001-12-12', '2002-12-12', 1);

-- cant do this
alter table employees
add constraint dont_pay_too_much_bucks_check
check (
    salary < (select sum(salary) from employees)
);

alter table employees
alter column first_name set not null;

alter table employees
alter column last_name set not null;

insert into employees values
    (10, null, 'Gotchu m8', '2000-12-12', '2012-10-10', 100);
