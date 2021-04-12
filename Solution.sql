--	Assumption:
--	If user does not have positive date for covid then he is asummed to have never contracted covid and filtered from possible covid contraction dates

-- -- --------------------------------------------------------------------
--	Events with Covid person
-- -----------------------------------------------------------------------
create table events_with_covid as select distinct location, presence_date from (
select a.user,a.location , b.positive_date, a.presence_date::timestamp::date , 
a.report_date::timestamp::date , case when b.positive_date <= a.presence_date then 1 else 0 end as covid_flag
from public.attendance a left outer join public.positives b  on a.user=b.user
) a
where covid_flag=1
order by location,presence_date



-- -- --------------------------------------------------------------------
--	Last Date where user may contracted covid
-- -----------------------------------------------------------------------
create table Covid_interacted_date_byUser as
select c.user, 
max(case when c.positive_date is not null then c.presence_date else null end) as covid_interacted from (
select a.user,a.location,
a.presence_date::timestamp::date , 
a.report_date::timestamp::date , b.positive_date ,
case when b.positive_date <= a.presence_date then 1 else 0 end as covid_flag
from public.attendance a left outer join public.positives b  on a.user=b.user
	where case when b.positive_date <= a.presence_date then 1 else 0 end = 0
)c inner join events_with_covid d on c.location = d.location and c.presence_date = d.presence_date

group by c.user
order by c.user

-- -- --------------------------------------------------------------------
--	Possible events where user may have contracted covid
-- -----------------------------------------------------------------------

create table possible_events_for_covid_interaction
as
select c.user, c.location, c.presence_date from (
select a.user,a.location,
a.presence_date::timestamp::date , 
a.report_date::timestamp::date , b.positive_date ,
case when b.positive_date <= a.presence_date then 1 else 0 end as covid_flag
from public.attendance a left outer join public.positives b  on a.user=b.user
	where case when b.positive_date <= a.presence_date then 1 else 0 end = 0
)c inner join events_with_covid d on c.location = d.location and c.presence_date = d.presence_date

where c.positive_date is not null
order by c.user, c.presence_date


---------------------------------------------------------------------------

--	Base table creation for all sqls
---------------------------------------------------------------------------

drop table base_table_data;
create table base_table_data as 

select c.user as user_id, c.location, c.presence_date, c.positive_date, case when d.presence_date is not null then 1 else 0 end as covid_presence_flag,
case when c.positive_date is not null and c.presence_date <= c.positive_date and d.presence_date is not null then c.presence_date else null end as covid_contracted_date from (
select distinct a.user,a.location,
a.presence_date::timestamp::date , 
a.report_date::timestamp::date , b.positive_date ,
case when b.positive_date <= a.presence_date then 1 else 0 end as covid_flag
from public.attendance a left outer join public.positives b  on a.user=b.user
	
)c left outer join (select distinct location, presence_date from (
select a.user,a.location , b.positive_date, a.presence_date::timestamp::date , 
a.report_date::timestamp::date , case when b.positive_date <= a.presence_date then 1 else 0 end as covid_flag
from public.attendance a left outer join public.positives b  on a.user=b.user
) a
where covid_flag=1) d on c.location = d.location and c.presence_date = d.presence_date


order by c.user, c.presence_date


---------------------------------------------------------------------------

--List of users which may have contracted covid and need to be contacted
---------------------------------------------------------------------------
select distinct user_id  from base_table_data
where covid_presence_flag =1
and positive_date is null
order by user_id


---------------------------------------------------------------------------
-- What is the effect of late reporting or logging of attendance (e.g. what if all reports were same day)
---------------------------------------------------------------------------

--This  will help in containing covid and prevent from spreading at events

