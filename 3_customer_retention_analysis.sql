with customer_last_purchase as (
	select
		customerkey,
		cleaned_name,
		orderdate,
		row_number() over(partition by customerkey order by orderdate DESC) as rn,
		first_order_date,
		cohort_yr 
	FROM 
		cohort_analysis
), churned_customers as (
	select
		cohort_yr,
		customerkey,
		cleaned_name,
		orderdate as last_purchase_date,
		case 
			when orderdate::date < (select MAX(orderdate) from sales) then 'Churned'
			else 'Active'
		end as customer_status
	from customer_last_purchase 
	where rn =1
	 and first_order_date::date < (select MAX(orderdate) from sales) 
)
select
	cohort_yr,
	customer_status,
	count(distinct customerkey) as number_of_customer,
	sum(count(distinct customerkey)) OVER(partition by cohort_yr) as total_customers,
	Round(count(distinct customerkey) / sum(count(distinct customerkey)) over(partition by cohort_yr),3) as status_percentage
from churned_customers 
group by cohort_yr, customer_status ;


	