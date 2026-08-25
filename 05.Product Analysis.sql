
What are the top 5 revenue-generating products in each country?


with cte as (
select 
c.country ,
p.product_id ,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
join marketing_and_ecommerce_analysis.products p 
on p.product_id = tv.product_id 
group by  
			c.country ,
			p.product_id 
),
cte_1 as (
select 
country,
product_id ,
Revenue,
rank() over(partition by country order by Revenue desc) as rnk
from cte 
)
select 
country,
product_id ,
Revenue
from cte_1 
where rnk <= 5
order by Revenue desc


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which products are most popular among each age group?

-- Popularity is measured by the number of transactions for each product within each age group.


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
),
cte_1 as (
select 
ag.age_group ,
p.product_id ,
count(tv.transaction_id )  as Orders
from age_group_cte ag
join marketing_and_ecommerce_analysis.transactions_vw tv 
on ag .customer_id = tv.customer_id 
join marketing_and_ecommerce_analysis.products p 
on tv.product_id = p.product_id 
group  by 
		ag.age_group,
		p.product_id 
),
cte_2 as (
select 
age_group ,
product_id ,
Orders ,
row_number() over( partition by age_group order by Orders desc ) as rn
from cte_1 
)
select 
age_group ,
product_id as Popular_product_id
from cte_2
where rn = 1


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which are the top 3 revenue-generating brands in each category?


with cte as (
select 
p.category,
p.brand,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.transactions_vw tv 
join marketing_and_ecommerce_analysis.products p 
on p.product_id = tv.product_id 
group by  
			p.category,
			p.brand 
),
cte_1 as (
select 
category,
brand ,
Revenue,
rank() over(partition by category order by Revenue desc) as rnk
from cte 
)
select 
category,
brand ,
Revenue
from cte_1 
where rnk <= 3
order by Revenue desc


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which products are popular across multiple countries?

-- A product is considered popular if it ranks in the top 10 by revenue in a country and appears in more than 2 countries.


with cte as (
select 
c.country ,
p.product_id ,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
join marketing_and_ecommerce_analysis.products p 
on p.product_id = tv.product_id 
group by  
			c.country ,
			p.product_id 
),
cte_1 as (
select 
country,
product_id ,
Revenue,
rank() over(partition by country order by Revenue desc) as rnk
from cte 
)
select 
product_id ,
count(distinct country) as Popular_countries
from cte_1
where rnk <= 10
group by product_id 
having count(distinct country) > 2
order by  Popular_countries desc


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which category has the highest number of products?


select 
p.category ,
count(p.product_id ) as No_of_Products
from marketing_and_ecommerce_analysis.products p 
group by p.category 
order by No_of_Products desc
limit 1

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which products generate the highest revenue per order?


select 
p.product_id ,
sum(tv.gross_revenue ) / count(tv.transaction_id  ) as Revenue_per_order
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on p.product_id = tv.product_id 
group by p.product_id 
order by Revenue_per_order desc


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which products have high order volume but relatively low revenue?


with cte as (
select 
p.product_id ,
count(tv.transaction_id ) as Orders,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on p.product_id = tv.product_id 
group by p.product_id 
)
select 
product_id ,
Orders,
Revenue
from cte 
where 
		Orders > ( select avg(orders) from cte  ) and 
		Revenue < ( select avg(Revenue) from cte  )


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which products contribute the largest percentage of category revenue?


with cte as (
select 
p.category ,
p.product_id ,
sum(tv.gross_revenue ) as product_revenue
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on p.product_id = tv.product_id 
group by 
			p.category ,
			p.product_id
),
cte_1 as (
select 
category ,
product_id ,
product_revenue ,
sum(product_revenue) over(partition by category) as category_revenue
from cte 
),
cte_2 as (
select 
category ,
product_id ,
round( product_revenue  / category_revenue * 100 , 2 ) as percentage_of_category_revenue
from cte_1 
),
cte_3 as (
select
category ,
product_id ,
percentage_of_category_revenue,
row_number() over(partition by category order by percentage_of_category_revenue desc) as rn
from cte_2 
)
select 
category,
product_id,
percentage_of_category_revenue
from cte_3 
where rn = 1


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which products have the highest number of refunded transactions?

select 
p.product_id ,
count(t.transaction_id ) as Refunds
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions t
on p.product_id  = t.product_id 
where t.refund_flag = 1
group by p.product_id 
order by refunds desc
limit 1

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which categories have the highest refund rate?


with Orders_cte as (
select 
p.category  ,
count(t.transaction_id ) as Orders
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions t
on p.product_id  = t.product_id 
group by p.category  
),
Refunds_cte as (
select 
p.category  ,
count(t.transaction_id ) as Refunds
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions t
on p.product_id  = t.product_id 
where t.refund_flag = 1
group by p.category  
)
select 
o.category ,
round((r.refunds / o.orders ) * 100 , 2 ) as Refund_rate
from Orders_cte  o
join Refunds_cte  r
on o.category = r.category 
order by refund_rate desc

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which brands have the highest refund rate?


with Orders_cte as (
select 
p.brand   ,
count(t.transaction_id ) as Orders
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions t
on p.product_id  = t.product_id 
group by p.brand  
),
Refunds_cte as (
select 
p.brand  ,
count(t.transaction_id ) as Refunds
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions t
on p.product_id  = t.product_id 
where t.refund_flag = 1
group by p.brand  
)
select 
o.brand ,
round((r.refunds / o.orders ) * 100 , 2 ) as Refund_rate
from Orders_cte  o
join Refunds_cte  r
on o.brand = r.brand 
order by refund_rate desc


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
