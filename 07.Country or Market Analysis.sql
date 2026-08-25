


Which countries have the highest revenue per customer?


select 
c.country ,
concat(
			"$ ",
			round(sum(tv.gross_revenue ) / count(distinct tv.customer_id ) ,2)
			) as Revenue_per_customer
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by c.country 
order by Revenue_per_customer desc
limit 1

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which country has the highest AOV?


select 
c.country ,
sum(tv.gross_revenue ) / count(tv.transaction_id ) as AOV
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by c.country 
order by AOV desc

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


Which country has the highest repeat purchase rate?


with cte as (
select 
c.country ,
c.customer_id ,
count(tv.transaction_id ) as Orders
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by 
			c.country ,
			c.customer_id 
order by 
			c.country ,
			Orders desc
),
Purchasing_customers as (
select 
distinct 
country, 
count(customer_id ) over(partition by country) as Purchasing_customers_by_country
from cte
),
Repeating_customers as (
select
distinct 
country, 
count(customer_id ) over(partition by country) as Repeating_customers_by_country
from cte
where orders > 1
),
cte_1 as (
select 
pc.country,
pc.purchasing_customers_by_country,
rc.repeating_customers_by_country 
from Purchasing_customers  pc
join Repeating_customers  rc
on pc.country = rc.country 
),
cte_2 as (
select 
country ,
round(repeating_customers_by_country / purchasing_customers_by_country * 100 , 2 ) as Repeat_purchase_rate
from cte_1 
)
select 
country,
repeat_purchase_rate 
from cte_2 
order by repeat_purchase_rate  desc



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which country has the highest refund rate?


with Orders as (
select 
c.country ,
count(tv.transaction_id ) as Orders
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by c.country
),
Refunded_orders as (
select 
c.country ,
count(t.transaction_id ) as Refunds
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions t
on c.customer_id = t.customer_id 
where t.refund_flag = 1
group by c.country
)
select 
o.country ,
round(r.refunds / o.orders * 100, 2 ) as Refund_rate
from orders o 
join Refunded_orders r
on o.country = r.country 
order by refund_rate  desc
limit 1


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


Which country has the fastest revenue growth?

-- Fastest revenue growth is defined as the country with the highest average month-over-month (MoM) revenue growth rate 


with cte as (
select 
c.country ,
year(tv.`timestamp` ) as year,
month(tv.`timestamp` ) as month,
sum(tv.gross_revenue ) as revenue
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by 
			c.country ,
			year(tv.`timestamp` ),
			month(tv.`timestamp` )
),
cte_1 as (
select 
country ,
year,
month,
revenue ,
lag(revenue) over(partition by country order by year, month) as previous_month_revenue
from cte 
),
cte_2 as (
select 
country ,
year,
month,
round(((revenue - previous_month_revenue )/ previous_month_revenue * 100),2) as growth_or_decline
from cte_1
)
select
distinct country,
avg(growth_or_decline ) over(partition by country) as  avg_revenue_growth
from cte_2
where growth_or_decline is not null
order by avg_revenue_growth desc


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which category dominates each country s revenue?


with cte as (
select 
c.country ,
p.category ,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
join marketing_and_ecommerce_analysis.products p 
on p.product_id = tv.product_id 
group by 
			c.country ,
			p.category 
),
cte_1 as (
select 
country ,
category ,
revenue ,
row_number() over( partition by country order by revenue desc) as rn
from cte 
)
select 
country ,
category ,
revenue 
from cte_1 
where rn =1 


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which countries have diversified revenue across categories?

-- A country is considered diversified when no single category contributes more than 40% of its total revenue.


with cte as (
select 
distinct c.country ,
p.category ,
(sum(tv.gross_revenue ) over(partition by c.country , p.category ) / sum(tv.gross_revenue ) over(partition by c.country )) * 100 as Revenue_contribution
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
join marketing_and_ecommerce_analysis.products p 
on p.product_id = tv.product_id 
)
select 
country 
from cte 
group by country 
having max(revenue_contribution ) <= 40


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which country has the strongest customer base but relatively low revenue?

-- Let us consider,
			  -- A country has a strong customer base but relatively low revenue when it has an above-average number of customers but below-average total revenue.


with cte as (
select 
c.country ,
count(distinct tv.customer_id) as Customers ,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by c.country 
)
select 
country 
from cte
where 
customers > (select avg(customers ) from cte ) and 
revenue < (select avg(revenue) from cte )


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

