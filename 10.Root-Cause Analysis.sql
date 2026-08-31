

Revenue declined last month — which countries contributed most to the decline?

-- Countries that contributed most to last month's revenue decline are the countries with the largest negative month-over-month change in revenue.


with cte as (
select 
c.country ,
year(tv.`timestamp` ) as year,
month(tv.`timestamp` ) as month,
sum(tv.gross_revenue ) as Revenue
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
country,
year,
month,
revenue - lag(revenue ) over(partition by country order by year ,month)  as revenue_change
from cte 
),
cte_2 as (
select 
country ,
revenue_change 
from cte_1 
where (year, month) = (select year, month from cte_1 order by year desc, month desc limit 1)
)
select 
country ,
revenue_change 
from cte_2 
where revenue_change = (select min(revenue_change) from cte_2)


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Revenue declined — which categories are responsible for the decrease?


-- Category that contributed most to last month's revenue decline are the category  with the largest negative month-over-month change in revenue.


with cte as (
select 
p.category ,
year(tv.`timestamp` ) as year,
month(tv.`timestamp` ) as month,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on p.product_id  = tv.product_id  
group by 
			p.category  ,
			year(tv.`timestamp` ),
			month(tv.`timestamp` )
),
cte_1 as (
select 
category ,
year,
month,
revenue - lag(revenue ) over(partition by category order by year ,month)  as revenue_change
from cte 
),
cte_2 as (
select 
category  ,
revenue_change 
from cte_1 
where (year, month) = (select year, month from cte_1 order by year desc, month desc limit 1)
)
select 
category  ,
revenue_change 
from cte_2 
where revenue_change = (select min(revenue_change) from cte_2)




----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Orders increased but revenue decreased — which categories or products, explain the gap?

-- A category or product is considered to explain the revenue gap when its order volume increases while its revenue decreases compared with the previous month


with cte as (
select 
p.category ,
p.product_id ,
year(tv.`timestamp` ) as year,
month(tv.`timestamp` ) as month,
sum(tv.gross_revenue ) as Revenue,
count(tv.transaction_id  ) as Orders
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on p.product_id  = tv.product_id  
group by 
			p.category ,
			p.product_id ,
			year(tv.`timestamp` ),
			month(tv.`timestamp` )
),
cte_1 as (
select 
category ,
product_id ,
year,
month,
revenue - lag(revenue ) over(partition by category,product_id  order by year ,month)  as revenue_change,
Orders - lag(Orders ) over(partition by category,product_id  order by year ,month)  as orders_change
from cte 
),
cte_2 as (
select 
category  ,
product_id ,
revenue_change,
orders_change 
from cte_1 
where (year, month) = (select year, month from cte_1 order by year desc, month desc limit 1)
)
select 
category  ,
product_id ,
revenue_change,
orders_change 
from cte_2 
where 
orders_change > 0 and
revenue_change < 0
order by revenue_change


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

A country s revenue dropped — which products caused the decline?

-- A product is considered responsible for a country's revenue decline when its revenue decreases month-over-month. 
-- The product with the largest negative revenue change is considered the biggest contributor to the decline in that country.


with cte as (
 select
c.country,
p.product_id,
year(tv.`timestamp`) as year,
month(tv.`timestamp`) as month,
sum(tv.gross_revenue) as revenue
from marketing_and_ecommerce_analysis.customers c
join marketing_and_ecommerce_analysis.transactions_vw tv
on c.customer_id = tv.customer_id
join marketing_and_ecommerce_analysis.products p
on p.product_id = tv.product_id
group by
        c.country,
        p.product_id,
        year(tv.`timestamp`),
        month(tv.`timestamp`)
),
cte_1 as (
select
country,
product_id,
year,
month,
revenue - lag(revenue) over (partition by country, product_id order by year, month ) as revenue_change
from cte
),
cte_2 as (
select
country,
product_id,
revenue_change
from cte_1
where (year, month) = (select year, month from cte_1 order by year desc, month desc limit 1)
),
cte_3 as (
select
country,
product_id,
revenue_change,
row_number() over(partition by country order by revenue_change) as rn
from cte_2
where revenue_change < 0
)
select 
country,
product_id,
revenue_change
from cte_3 
where rn =1



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

A category s revenue dropped — which brands contributed most to the decline?


-- A brand is considered a major contributor to a category's revenue decline when its revenue decreases month-over-month. 
-- The brand with the largest negative revenue change is considered the biggest contributor to the decline within that category.


with cte as (
 select
p.category ,
p.brand ,
year(tv.`timestamp`) as year,
month(tv.`timestamp`) as month,
sum(tv.gross_revenue) as revenue
from marketing_and_ecommerce_analysis.products p
join  marketing_and_ecommerce_analysis.transactions_vw tv  
on p.product_id = tv.product_id
group by
        p.category,
        p.brand,
        year(tv.`timestamp`),
        month(tv.`timestamp`)
),
cte_1 as (
select
category,
brand,
year,
month,
revenue - lag(revenue) over ( partition by category, brand order by year, month ) as revenue_change
from cte
),
cte_2 as (
select
category,
brand,
revenue_change
from cte_1
where (year, month) = (select year, month from cte_1 order by year desc, month desc limit 1)
),
cte_3 as (
select
category,
brand,
revenue_change,
row_number() over(partition by category order by revenue_change) as rn
from cte_2
where revenue_change < 0
)
select 
category,
brand,
revenue_change
from cte_3 
where rn =1


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

A campaign generated high revenue but few orders — what does this indicate?


with cte as (
select
tv.campaign_id,
count(tv.transaction_id) as orders,
sum(tv.gross_revenue) as revenue
from marketing_and_ecommerce_analysis.transactions_vw tv
group by tv.campaign_id
)
select
campaign_id,
orders,
revenue,
round( revenue / orders,2) as AOV
from cte
where
orders < (select avg(orders) from cte)
and revenue > (select avg(revenue) from cte)
order by AOV desc


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Customer numbers last month increased but revenue per customer decreased — which segments caused the change?


with age_group_cte as (
select
customer_id,
case
		when age < 25 then '18-24'
		when age < 35 then '25-34'
		when age < 45 then '35-44'
		when age < 55 then '45-54'
		else '55+'
end as age_group
from marketing_and_ecommerce_analysis.customers
),
cte as (
select
ag.age_group,
year(tv.`timestamp`) as year,
month(tv.`timestamp`) as month,
count(distinct tv.customer_id) as customers,
sum(tv.gross_revenue) as revenue
from age_group_cte ag
join marketing_and_ecommerce_analysis.transactions_vw tv
on ag.customer_id = tv.customer_id
group by
ag.age_group,
year(tv.`timestamp`),
month(tv.`timestamp`)
),
cte_1 as (
select
age_group,
year,
month,
customers,
revenue / customers as revenue_per_customer,
lag(customers) over (partition by age_group order by year, month) as previous_customers,
lag(revenue / customers) over (partition by age_group order by year, month ) as previous_revenue_per_customer
from cte
)
select
age_group,
customers,
previous_customers,
revenue_per_customer,
previous_revenue_per_customer,
revenue_per_customer - previous_revenue_per_customer
as rpc_change
from cte_1
where (year, month) = (
select year, month
from cte_1
order by year desc, month desc
limit 1
)
and customers > previous_customers
and revenue_per_customer < previous_revenue_per_customer
order by rpc_change;



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

One category dominates revenue — is the business overly dependent on that category?

-- A business is considered highly dependent on a category when its largest category generates at least 50% of total revenue.


with cte as (
select
p.category,
sum(tv.gross_revenue) as category_revenue
from marketing_and_ecommerce_analysis.products p
join marketing_and_ecommerce_analysis.transactions_vw tv
on p.product_id = tv.product_id
group by p.category
),
cte_1 as (
select
category,
category_revenue,
sum(category_revenue) over () as total_revenue,
row_number() over (order by category_revenue desc ) as rn
from cte
)
select
category,
round(category_revenue / total_revenue * 100, 2) as revenue_share,
case
		when category_revenue / total_revenue * 100 >= 50 then 'Yes'
		else 'No'
end as Is_highly_dependent
from cte_1
where rn = 1;


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Refunds increased last month— which categories are responsible?


with cte as (
select 
p.category,
year(t.`timestamp`) as year,
month(t.`timestamp`) as month,
count(t.transaction_id) as refunds
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions t 
on p.product_id = t.product_id 
where t.refund_flag = 1
group by 
			p.category,
			year(t.`timestamp`),
			month(t.`timestamp`)
),
cte_1 as (
select
category,
year,
month,
refunds,
refunds - lag(refunds) over (partition by category order by year, month) as refund_change
from cte
)
select
category,
refunds,
refund_change
from cte_1
where (year, month) = (select year, month from cte_1 order by year desc, month desc limit 1)
and refund_change > 0
order by refund_change desc
limit 2;

 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
