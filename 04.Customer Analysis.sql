
How many customers have never made a purchase?


select 
count(c.customer_id )
from marketing_and_ecommerce_analysis.customers c 
where c.customer_id not in (
select 
tv.customer_id 
from marketing_and_ecommerce_analysis.transactions_vw tv 
)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which two countries have the highest number of purchasing customers?

select 
c.country ,
count(distinct tv.customer_id ) as Purchasing_customers
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by c.country 
order by Purchasing_customers desc
limit 2

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

Which age group has the highest average order value?

with age_group_cte as (
select
c.customer_id ,
case
	when c.age < 25 then "18-24"
	when c.age < 35 then "25-34"
	when c.age < 45 then "35-44"
	when c.age < 55 then "45-54"
	else "55+"
end as Age_Group
from marketing_and_ecommerce_analysis.customers c 
)
select 
ag.age_group ,
sum(tv.gross_revenue) / count(tv.transaction_id) AOV
from age_group_cte ag
join marketing_and_ecommerce_analysis.transactions_vw tv 
on ag .customer_id = tv.customer_id 
group  by ag.age_group
order by AOV  desc
limit 1

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which age group places the most orders?


with age_group_cte as (
select
c.customer_id ,
case
	when c.age < 25 then "18-24"
	when c.age < 35 then "25-34"
	when c.age < 45 then "35-44"
	when c.age < 55 then "45-54"
	else "55+"
end as Age_Group
from marketing_and_ecommerce_analysis.customers c 
)
select 
ag.age_group ,
count(tv.transaction_id) as Orders
from age_group_cte ag
join marketing_and_ecommerce_analysis.transactions_vw tv 
on ag .customer_id = tv.customer_id 
group  by ag.age_group
order by Orders  desc
limit 1

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Who are the top 10 customers by total revenue?


select 
c.customer_id ,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by c.customer_id 
order by revenue desc 
limit 10

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

What percentage of total revenue comes from the top 10 customers?


with cte as(
select 
c.customer_id ,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by c.customer_id 
),
cte_1 as (
select 
customer_id ,
revenue ,
sum(revenue) over() as Total_Revenue
from cte 
order by revenue desc
limit 10
)
select 
concat(
round(sum(revenue) / max(total_revenue ) * 100,2),
"%"
) as Top_10_customer_share
from cte_1 

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which customers have made only one purchase?

select 
c.customer_id ,
count(tv.transaction_id ) as Orders
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by c.customer_id 
having count(tv.transaction_id ) = 1

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

What percentage of customers are repeat customers?


with cte as (
select 
c.customer_id ,
count(tv.transaction_id ) as Orders
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by c.customer_id 
order by Orders desc
),
cte_1 as (
select
distinct
(select count(orders) from cte) as Purchasing_customers,
(select count(orders) from cte  where orders > 1) as Repeated_customers
from cte 
)
select 
concat(
		round(repeated_customers / purchasing_customers * 100 , 2 ),
		"%"
		) as Repeated_customer_percentage
from cte_1 

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which country have the highest repeat purchase rate?


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
country
from cte_2 
where repeat_purchase_rate = (select max(repeat_purchase_rate ) from cte_2)


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which age groups have the highest repeat purchase rate?


with customer_cte as(
select 
c.customer_id ,
c.age ,
case
	when c.age < 25 then "18-24"
	when c.age < 35 then "25-34"
	when c.age < 45 then "35-44"
	when c.age < 55 then "45-54"
	else "55+"
end as Age_Group
from marketing_and_ecommerce_analysis.customers c 
),
cte as (
select 
c.age_group ,
c.customer_id ,
count(tv.transaction_id ) as Orders
from customer_cte  c
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by 
			c.age_group ,
			c.customer_id 
order by 
			c.age_group ,
			orders desc
),
Purchasing_customers as (
select 
distinct 
age_group , 
count(customer_id ) over(partition by age_group) as Purchasing_customers_by_age_group
from cte
),
Repeating_customers as (
select
distinct 
age_group, 
count(customer_id ) over(partition by age_group) as Repeating_customers_by_age_group
from cte
where orders > 1
),
cte_1 as (
select 
pc.age_group,
pc.Purchasing_customers_by_age_group,
rc.Repeating_customers_by_age_group 
from Purchasing_customers  pc
join Repeating_customers  rc
on pc.age_group = rc.age_group 
),
cte_2 as (
select 
age_group ,
round(Repeating_customers_by_age_group / Purchasing_customers_by_age_group * 100 , 2 ) as Repeat_purchase_rate
from cte_1 
)
select 
age_group
from cte_2 
where repeat_purchase_rate = (select max(repeat_purchase_rate ) from cte_2)


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which customers have not purchased recently?


-- I am finding customers who have not purchased in the last 30 days

with purchasing_customers_cte as (
select 
c.customer_id 
from marketing_and_ecommerce_analysis.customers c 
where c.customer_id in ( select tv2.customer_id from marketing_and_ecommerce_analysis.transactions_vw tv2  )
),
transaction_cte as (
select 
tv.customer_id,
date(tv.`timestamp`) as date_of_purchase
from marketing_and_ecommerce_analysis.transactions_vw tv
),
last_purchase_cte as (
select
customer_id,
max(date_of_purchase) as last_purchase_date
from transaction_cte
group by customer_id
)
select 
p.customer_id
from purchasing_customers_cte p
join last_purchase_cte lp
on p.customer_id = lp.customer_id
where lp.last_purchase_date < (select date_sub(max(date_of_purchase),interval 30 day )from transaction_cte)


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


What is the average number of days between a customers purchases?


with cte as (
select 
c.customer_id ,
date(tv.`timestamp` ) as Purchase_date,
count(tv.transaction_id ) over(partition by c.customer_id ) as Orders
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
order by 
			c.customer_id , 
			purchase_date 
),
cte_1 as (
select 
customer_id ,
purchase_date  as current_purchase_date,
lag(purchase_date ) over(partition by customer_id order by purchase_date ) as previous_purchase_date
from cte 
)
select 
avg(datediff(current_purchase_date ,previous_purchase_date )) as days_between_purchases
from cte_1 

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which customers have the highest lifetime revenue?


select 
tv.customer_id ,
sum(tv.gross_revenue ) as Lifetime_revenue
from marketing_and_ecommerce_analysis.transactions_vw tv 
group by tv.customer_id 
order by  Lifetime_revenue desc
limit 1

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which customers have high purchase frequency but low revenue?

with cte as (
select 
tv.customer_id ,
sum(tv.gross_revenue ) as Revenue,
count(tv.transaction_id ) as Orders
from marketing_and_ecommerce_analysis.transactions_vw tv 
group by tv.customer_id 
)
select 
customer_id ,
revenue ,
orders ,
round(revenue / orders , 2) as AOV
from cte 
where 
		orders > (select avg(orders) from cte ) and 
		revenue <  (select avg(revenue) from cte )
order by orders desc, revenue 
limit 20

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which customers have low purchase frequency but high revenue?


with cte as (
select 
tv.customer_id ,
sum(tv.gross_revenue ) as Revenue,
count(tv.transaction_id ) as Orders
from marketing_and_ecommerce_analysis.transactions_vw tv 
group by tv.customer_id 
)
select 
customer_id ,
revenue ,
orders ,
round(revenue / orders , 2) as AOV
from cte 
where 
		revenue >  (select avg(revenue) from cte ) and
		orders < (select avg(orders) from cte )
order by revenue desc ,orders
limit 20

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which products are purchased most frequently by repeat customers?

with cte as (
select 
c.customer_id ,
count(tv.transaction_id ) as Orders
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by c.customer_id 
),
Repeated_customers as (
select 
distinct customer_id 
from cte
where orders > 1
)
select 
tv.product_id,
count(tv.transaction_id ) as Orders
from marketing_and_ecommerce_analysis.transactions_vw tv 
where tv.customer_id in (select r.customer_id  from Repeated_customers r)
group by tv.product_id 
order by Orders desc
limit 10



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

