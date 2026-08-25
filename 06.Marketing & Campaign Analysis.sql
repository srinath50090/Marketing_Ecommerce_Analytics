

Which campaign channel generates the highest revenue?


select 
c.channel ,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.campaigns c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.campaign_id = tv.campaign_id 
group by c.channel 
order by Revenue  desc

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which campaigns generate the highest revenue per customer?


select 
c.campaign_id ,
sum(tv.gross_revenue ) / count(distinct tv.customer_id ) as Revenue_per_customer
from marketing_and_ecommerce_analysis.campaigns c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.campaign_id = tv.campaign_id 
group by c.campaign_id 
order by revenue_per_customer desc

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which campaigns generate the highest number of orders?

select 
c.campaign_id  ,
count(tv.transaction_id  ) as Orders
from marketing_and_ecommerce_analysis.campaigns c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.campaign_id = tv.campaign_id 
group by c.campaign_id  
order by Orders  desc

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which campaign has the highest conversion rate?


with transactions_cte as (
select 
c.campaign_id ,
count(tv.transaction_id ) as transactions
from marketing_and_ecommerce_analysis.campaigns c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.campaign_id = tv.campaign_id 
where tv.refund_flag = 0
group by c.campaign_id
),
events_cte as (
select 
c.campaign_id ,
count(distinct ev.session_id ) as events
from marketing_and_ecommerce_analysis.campaigns c 
join marketing_and_ecommerce_analysis.events_vw ev 
on c.campaign_id = ev.campaign_id 
group by c.campaign_id 
)
select
t.campaign_id ,
round(t.transactions / e.events  * 100 , 2 ) as Campaign_conversion_rate
from transactions_cte t
join events_cte e
on t.campaign_id = e.campaign_id 
order by Campaign_conversion_rate desc

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which country has the highest conversion rate for each campaign channel?


with transactions_cte as (
select 
cu.country ,
c.channel  ,
count(tv.transaction_id ) as transactions
from marketing_and_ecommerce_analysis.campaigns c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.campaign_id = tv.campaign_id 
join marketing_and_ecommerce_analysis.customers cu
on tv.customer_id = cu.customer_id 
where tv.refund_flag = 0
group by 
			cu.country ,
			c.channel 
),
events_cte as (
select 
cu.country ,
c.channel  ,
count(distinct ev.session_id ) as events
from marketing_and_ecommerce_analysis.campaigns c 
join marketing_and_ecommerce_analysis.events_vw ev 
on c.campaign_id = ev.campaign_id 
join marketing_and_ecommerce_analysis.customers cu
on ev.customer_id = cu.customer_id 
group by 
			cu.country ,
			c.channel 
),
cte as (
select
t.country ,
t.channel  ,
round(t.transactions / e.events  * 100 , 2 ) as conversion_rate
from transactions_cte t
join events_cte e
on (t.country ,t.channel ) = (e.country ,e.channel )
),
cte_1 as (
select 
country,
channel,
conversion_rate ,
rank() over( partition by channel order by conversion_rate desc ) as rnk
from cte 
)
select 
channel,
country
from cte_1 
where rnk = 1

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which acquisition channel performs best for each category?


with transactions_cte as (
select 
p.category ,
c.acquisition_channel ,
count(tv.transaction_id ) as transactions
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id  = tv.customer_id  
join marketing_and_ecommerce_analysis.products p 
on tv.product_id  = p.product_id 
where tv.refund_flag = 0
group by 
			p.category ,
			c.acquisition_channel
),
events_cte as (
select 
p.category ,
c.acquisition_channel ,
count(distinct ev.session_id ) as events
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.events_vw ev
on c.customer_id  = ev.customer_id  
join marketing_and_ecommerce_analysis.products p 
on ev.product_id  = p.product_id 
group by 
			p.category ,
			c.acquisition_channel 
),
cte as (
select
t.category ,
t.acquisition_channel ,
round(t.transactions / e.events  * 100 , 2 ) as conversion_rate
from transactions_cte t
join events_cte e
on (t.category , t.acquisition_channel ) = (e.category ,e.acquisition_channel )
),
cte_1 as (
select 
category ,
acquisition_channel ,
rank() over( partition by category order by conversion_rate desc ) as rnk
from cte 
)
select 
category ,
acquisition_channel 
from cte_1 
where rnk = 1


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which campaigns have declining performance over time?


with cte as (
select 
c.campaign_id  ,
year(tv.`timestamp` ) as year,
month(tv.`timestamp` ) as month,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.campaigns c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.campaign_id = tv.campaign_id 
group by 
			c.campaign_id ,
			year,
			month
),
cte_1 as (
select 
campaign_id ,
year,
month,
((revenue - lag(revenue ) over(partition by campaign_id order by year, month)) / 
lag(revenue ) over(partition by campaign_id order by year, month)) as growth_or_decline
from cte
),
cte_2 as (
select 
campaign_id ,
count(*)  as comparable_months,
sum( case 
	when growth_or_decline < 0 then 1
	else 0 
end) as declining_months
from cte_1
where growth_or_decline is not null 
group by campaign_id 
)
select
campaign_id,
comparable_months,
declining_months
from cte_2
where declining_months = comparable_months;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which campaign channel contributes the largest percentage of total campaign revenue?

with cte as (
select 
distinct c.channel  ,
sum(tv.gross_revenue ) over(partition by c.channel ) as Revenue,
sum(tv.gross_revenue ) over() as Total_revenue
from marketing_and_ecommerce_analysis.campaigns c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.campaign_id = tv.campaign_id 
)
select 
channel ,
round( revenue / total_revenue * 100, 2 ) as Percentage_of_share
from cte 
order by Percentage_of_share desc


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


