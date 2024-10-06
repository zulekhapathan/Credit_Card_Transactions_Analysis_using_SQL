select * from credit_card_transcations;


--1.query to display top 5 cities with highest spends and their percentage contribution of total credit card spends 

with highest_spends as (
select city,sum(amount) as total_spend from credit_card_transcations
group by city)
,total_spent as (select sum(cast (amount as bigint)) as total_amount from credit_card_transcations)
select top 5 highest_spends.*, round(total_spend*1.0/total_amount * 100,2) as percentage_contribution from highest_spends
inner join total_spent on 1=1
order by total_spend desc;

----------------------------------------------------------------------------------------------------------------------------

--2.query to display highest spend month and amount spent in that month for each card type

with highest_spending_month as (
select card_type, datepart(year,transaction_date) as yt,
datepart(month,transaction_date) as mn,sum(amount) as total_spent from credit_card_transcations
group by card_type,datepart(year,transaction_date),
datepart(month,transaction_date))
select * from (select *,rank() over(partition by card_type order by total_spent desc) as rn 
from highest_spending_month) a
where rn=1;

----------------------------------------------------------------------------------------------------------------------------

--3.query to display the transaction details for each card type when
--it reaches a cumulative of 1000000 total spends

with transaction_details as 
(
select *,sum(amount) over(partition by card_type order by transaction_id,transaction_date) as total_spend
from credit_card_transcations)
select * from (select *,rank() over(partition by card_type order by total_spend) as rn
from transaction_details
where total_spend >= 1000000) a 
where rn=1;

----------------------------------------------------------------------------------------------------------------------------

--4.query to find city which had lowest percentage spend for gold card type

with total_spent as(
select top 1 city,card_type,sum(amount) as total_amount,
sum(case when card_type='Gold' then amount end) as gold_amount 
from credit_card_transcations
group by city,card_type)
select city,sum(gold_amount)*1.0/sum(total_amount) as lowest_percentage from total_spent 
group by city
--having count(gold_amount)>0 and sum(gold_amount)>0
order by lowest_percentage;


with amounts as (
select top 1 city,card_type,sum(amount) as total_amount,
sum(case when card_type='Gold' then amount end) as gold_amount from credit_card_transcations
group by city,card_type)
select city,card_type,sum(total_amount)*1.0/sum(gold_amount) as gold_ratio
from amounts 
group by city,card_type; 

----------------------------------------------------------------------------------------------------------------------------

--5.query to display city with highest_expense_type , lowest_expense_type 

with expenses as (
select city,exp_type,
sum(amount) as amount from credit_card_transcations
group by city,exp_type)
select city,
max(case when rn_desc=1 then exp_type end) as highest_exp_type ,
min( case when rn_asc=1 then exp_type end ) as lowest_exp_type
from(
select *, rank() over(partition by city order by amount desc) as rn_desc,
rank() over(partition by city order by amount asc) as rn_asc from expenses) A 
group by city;

----------------------------------------------------------------------------------------------------------------------------

--6.query to find percentage contribution of spends by females for each expense type

select exp_type,
sum(case when gender='F' then amount else 0 end) * 1.0/sum(amount) as percentage_contribution
from credit_card_transcations
group by exp_type
order by percentage_contribution desc;

----------------------------------------------------------------------------------------------------------------------------

--7.card and expense type combination saw highest month over month growth in Jan-2014

with combination as (
select card_type,exp_type,datepart(year,transaction_date) as yt,
datepart(month,transaction_date) as mt,
sum(amount) as total_spend from credit_card_transcations
group by card_type,exp_type,datepart(year,transaction_date),
datepart(month,transaction_date))
select top 1*, (total_spend-prev_month_spend) as month_growth
from(
select *, lag(total_spend,1) over(partition by card_type,exp_type order by yt,mt) as prev_month_spend from combination) A
where prev_month_spend is not null and yt=2014 and mt=1
order by month_growth desc;

----------------------------------------------------------------------------------------------------------------------------

--8.city with highest total spend to total no of transcations ratio during weekends

select top 1 city,sum(amount)*1.0/count(1) as transaction_ratio
from credit_card_transcations
where datepart(weekday,transaction_date) in (1,7)
group by city
order by transaction_ratio desc;

----------------------------------------------------------------------------------------------------------------------------

--9.city that took least number of days to reach its 500th transaction after the first transaction in that city

with least_days as (
select *, ROW_NUMBER() over(partition by city order by transaction_date,transaction_id) as row_no
from credit_card_transcations)
select top 1 city, DATEDIFF(day,min(transaction_date),max(transaction_date)) as datedif
from least_days 
where row_no=1 or row_no=500
group by city
having count(1)=2
order by datedif;

--10.query to find the percentage contribution of spends by females for each expense type.
select exp_type, 
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount) as percentage_female_spents from credit_card_transcations
group by exp_type
order by percentage_female_spents desc;
