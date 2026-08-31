
What is the monthly AOV trend?

select 
year(tv.`timestamp` ) as year,
month(tv.`timestamp` ) as month,
round(sum(tv.gross_revenue ) / count(tv.transaction_id ),2) as AOV
from marketing_and_ecommerce_analysis.transactions_vw tv 
group by 
			year(tv.`timestamp` ),
			month(tv.`timestamp` )

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which month had the highest revenue growth in every year?


with cte as (
select 
year(tv.`timestamp` ) as year,
month(tv.`timestamp` ) as month,
sum(tv.gross_revenue ) as Revenue 
from marketing_and_ecommerce_analysis.transactions_vw tv 
group by 
			year(tv.`timestamp` ),
			month(tv.`timestamp` )
),
cte_1 as (
select 
year,
month,
(revenue - lag(revenue ) over(partition by year)) / lag(revenue ) over(partition by year) * 100 as growth_or_decline
from cte
),
cte_2 as (
select 
year,
month,
growth_or_decline,
rank() over(partition by year order by growth_or_decline desc) as rnk
from cte_1 
)
select 
year,
ELT(month, 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' ) AS month_name
from cte_2
where rnk = 1

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


Which month had the largest revenue decline in every year?


with cte as (
select 
year(tv.`timestamp` ) as year,
month(tv.`timestamp` ) as month,
sum(tv.gross_revenue ) as Revenue 
from marketing_and_ecommerce_analysis.transactions_vw tv 
group by 
			year(tv.`timestamp` ),
			month(tv.`timestamp` )
),
cte_1 as (
select 
year,
month,
(revenue - lag(revenue ) over(partition by year)) / lag(revenue ) over(partition by year) * 100 as growth_or_decline
from cte
),
cte_2 as (
select 
year,
month,
growth_or_decline,
rank() over(partition by year order by growth_or_decline) as rnk
from cte_1 
)
select 
year,
ELT(month, 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' ) AS month_name
from cte_2
where rnk = 1


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

What is the 3-month moving average of revenue?


with cte as (
select 
year(tv.`timestamp` ) as year,
month(tv.`timestamp` ) as month,
sum(tv.gross_revenue ) as Revenue 
from marketing_and_ecommerce_analysis.transactions_vw tv 
group by 
			year(tv.`timestamp` ),
			month(tv.`timestamp` )
)
select 
year,
month,
round(avg(revenue ) over(order by year,month rows between 2 preceding and current row ),2) as moving_average_revenue
from cte


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

What is the running total of revenue throughout the year?


with cte as (
select 
year(tv.`timestamp` ) as year,
month(tv.`timestamp` ) as month,
sum(tv.gross_revenue ) as Revenue 
from marketing_and_ecommerce_analysis.transactions_vw tv 
group by 
			year(tv.`timestamp` ),
			month(tv.`timestamp` )
)
select 
year,
month,
round(sum(revenue ) over(partition by year order by month rows between unbounded preceding  and current row),2) as running_total_revenue
from cte

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which products experienced the largest month-over-month decline?


with cte as (
select 
p.product_id  ,
year(tv.`timestamp` ) as year,
month(tv.`timestamp` ) as month,
sum(tv.gross_revenue ) as Revenue
from marketing_and_ecommerce_analysis.products p 
join marketing_and_ecommerce_analysis.transactions_vw tv 
on p.product_id = tv.product_id 
group by 
			p.product_id  ,
			year(tv.`timestamp` ),
			month(tv.`timestamp` )
),
cte_1 as (
select 
product_id  ,
year,
month,
(( revenue - lag(revenue) over(partition by product_id  order by year, month) ) / lag(revenue) over(partition by product_id  order by year, month) )* 100 as growth_or_decline
from cte 
)
select 
product_id 
from cte_1
where growth_or_decline = (select min(growth_or_decline) from cte_1 )


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Which countries have consistently grown revenue month over month?


with cte as (
select
c.country ,
year(tv.`timestamp` ) as year,
month(tv.`timestamp` ) as month,
sum(tv.gross_revenue ) as current_revenue
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
round(((current_revenue - lag(current_revenue,1) over(partition by country order by `year`,`month` )) / 
lag(current_revenue,1) over(partition by country order by `year`,`month` ) )* 100,2) as growth_or_decline
from cte
),
cte_2 as (
select 
country,
count(*) as comparable_months,
sum(
		case
			when growth_or_decline > 0 then 1
			else 0
		end
) as Growing_months
from cte_1 
where growth_or_decline is not null
group by country
)
select 
country
from cte_2 
where comparable_months = growing_months 



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------