with customer_ltv as (
	select
		customerkey,
		cleaned_name,
		sum(total_net_revenue) as total_ltv
	from cohort_analysis ca 
	group by customerkey,cleaned_name
),customer_segments as (
select 
	PERCENTILE_CONT(.25) within group (order by total_ltv) as ltv_25th_percentile,
	PERCENTILE_CONT(.75) within group (order by total_ltv) as ltv_75th_percentile,
	PERCENTILE_CONT(.5) within group (order by total_ltv) as ltv_median
from customer_ltv
), segment_value as(
select 
	c.*,
	case 
		when c.total_ltv < cs.ltv_25th_percentile then '1-low-value'
		when c.total_ltv >= cs.ltv_75th_percentile then '3-high-value'
		when c.total_ltv = cs.ltv_median then 'median'
		else '2-mid-value'
	end as customer_segment
from
	customer_ltv c, customer_segments cs
)
select 
	customer_segment,
	Round(sum(total_ltv)) as total_ltv,
	ROUND(count(customerkey)) as customer_count,
	ROUND(sum(total_ltv)  /count(customerkey)) as avg_ltv
from 
	segment_value
group by 
	customer_segment
order by 
	customer_segment;
