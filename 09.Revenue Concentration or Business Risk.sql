


What percentage of revenue comes from the top 5 products?


with cte as (
select 
p.product_id ,
sum(tv.gross_revenue) as product_revenue
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on p.product_id = tv.product_id 
group by p.product_id
),
cte_1 as (
select 
product_id ,
product_revenue ,
sum(product_revenue ) over() as Total_revenue
from cte 
order by product_revenue  desc
limit 5
)
select 
round(sum(product_revenue ) / max(total_revenue  ) * 100 , 2 ) as Top_5_product_share
from cte_1 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

What percentage of revenue comes from the top 2 categories?

with cte as (
select 
p.category ,
sum(tv.gross_revenue ) as category_revenue
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on p.product_id = tv.product_id 
group by p.category 
),
cte_1 as (
select 
category ,
category_revenue ,
sum(category_revenue ) over() as Total_revenue
from cte 
order by category_revenue desc
limit 2
)
select 
round(sum(category_revenue ) / max(total_revenue ) * 100, 2 ) as top_2_category_share
from cte_1 


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

What percentage of revenue comes from the top 2 countries?



with cte as(
select 
c.country ,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.customers c 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on c.customer_id = tv.customer_id 
group by c.country  
),
cte_1 as (
select 
country  ,
revenue ,
sum(revenue) over() as Total_Revenue
from cte 
order by revenue desc
limit 2
)
select 
concat(
round(sum(revenue) / max(total_revenue ) * 100,2),
"%"
) as top_2_country_share
from cte_1 



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


What percentage of customers generate 80% of revenue?


with cte as (
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
sum(revenue ) over(order by revenue desc rows between unbounded preceding and current row) as cumulative_revenue
from cte 
),
eighty_percent_revenue_contributing_customers_cte as (
select
customer_id 
from cte_1 
where cumulative_revenue  <= (select 0.80 * sum(tv.gross_revenue ) from marketing_and_ecommerce_analysis.transactions_vw tv ) 
)
select 
round(count(customer_id ) / (select count(distinct tv.customer_id ) from marketing_and_ecommerce_analysis.transactions_vw tv ) * 100 ,2) as percentage_of_customers_contributing_eighty_percent_of_revenue
from eighty_percent_revenue_contributing_customers_cte 


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which categories are highly dependent on a small number of products?

-- A category is considered highly dependent on a small number of products when its top 10% of products generate at least 50% of the category's revenue.


with cte as (
select 
p.category ,
p.product_id ,
sum(tv.gross_revenue) as product_revenue
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
sum(product_revenue ) over(partition by category ) as category_revenue,
ntile(100) over(partition by category order by product_revenue desc) as ntl
from cte 
),
cte_2 as (
select 
category ,
sum(product_revenue) / max(category_revenue ) * 100 as top_10_percentage_product_share
from cte_1 
where ntl <= 10
group by category
)
select
category ,
top_10_percentage_product_share
from cte_2
where top_10_percentage_product_share >= 50


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


Which countries are highly dependent on a small number of categories?


-- A country is considered highly dependent on a small number of categories when its top 2 categories generate at least 65% of the country's revenue.


with cte as (
select 
c.country ,
p.category ,
sum(tv.gross_revenue) as category_revenue
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on p.product_id = tv.product_id 
join marketing_and_ecommerce_analysis.customers c 
on c.customer_id = tv.customer_id 
group by 
			c.country ,
			p.category 
),
cte_1 as (
select 
country ,
category ,
category_revenue ,
sum(category_revenue ) over(partition by country ) as country_revenue,
row_number() over(partition by country order by category_revenue desc) as rn
from cte 
),
cte_2 as (
select 
country  ,
sum(category_revenue) / max(country_revenue ) * 100 as top_2_percentage_category_share
from cte_1 
where rn <= 2
group by country 
)
select
country ,
top_2_percentage_category_share
from cte_2
where top_2_percentage_category_share >= 65



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Is revenue concentrated among a small group of customers?


-- Revenue is considered highly concentrated when the top 10% of customers generate at least 50% of total revenue.


with cte as (
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
sum(revenue ) over() total_revenue,
ntile(100) over(order by revenue desc) as ntl
from cte 
),
cte_2 as (
select 
sum(revenue ) / max(total_revenue ) * 100 as top_10_percent_customer_revenue_share
from cte_1 
where ntl <= 10
)
select 
case
	when top_10_percent_customer_revenue_share >= 50 then "Yes"
	else "No"
end as is_concentrated,
top_10_percent_customer_revenue_share
from cte_2 


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

