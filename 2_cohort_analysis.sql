select 
	cohort_yr,
	sum(total_net_revenue) as total_revenue,
	count(distinct customerkey) as total_customer,
	sum(total_net_revenue)/count(distinct customerkey) as customer_revenue
from cohort_analysis 
where orderdate = first_order_date 
group by order_month, cohort_yr  
order by order_month, cohort_yr;