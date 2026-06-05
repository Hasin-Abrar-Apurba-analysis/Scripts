# Intermediate SQL – Sales Analysis

## Overview
This project analyzes the Contoso dataset using SQL techniques
to uncover customer behavior patterns and revenue trends.

The analysis covers three key areas: customer segmentation by lifetime value,
cohort-based revenue tracking, and retention/churn analysis.

The goal is to identify high-value customers, diagnose declining revenue per
customer, and flag at-risk customers before they lapse.

## Business Questions

1. Who are our most valuable customers?

2. How do different customer groups generate revenue?

3. Who hasn't purchase recently?

### 1. **Customer Segmentation Analysis:** Who are our most valuable customers?

## Analysis Approach

- Categorized customer based on total life time value (LTV)

- Assigned customers to High, Mid & Low value segments.

- Calculated key metrics: Total Revenue

- Here we also calculated the median value of the total revenue. We can also consider it as a Mid-value segment.

Query: [1_customer_segmentation.sql](/1_customer_segmentation.sql)

```sql
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
```

**📊 Visualization:**

![Customer Segmentation Analysis](/images/1_Customer_segment_analysis.png)

**🔑 Key Findings:**

- High-value segment (25% of customers) drive 66% of the revenue ($135.4M)

- Mid-value segment (50% of customers) generate 32% of revenue ($66.6M)

- Low_value segment (25% of customers) accounts for 2% of revenue ($4.3M)

## Business Insights

**High-Value (66% revenue):** Offer premium membership program to 12,372 VIP customers, as losing one customer significantly impacts revenue

**Mid-Value (32% revenue):** Create upgrade paths through personalized promotions, with potential $66.6M → $135.4M revenue opportunity

**Low-Value (2% revenue):** Design re-engagement campaigns and price-sensitive promotions to increase purchase frequency


### 2.**Cohort Analysis:** How do different customer groups generate revenue?

## Analysis Approach

- Tracked revenue and customer count per cohort.
- Cohorts were grouped by year and customer purchase.
- Analyzed customer retention at a cohort level.

Query: [2_cohort_analysis.sql](/2_cohort_analysis.sql)

```sql
select 
	cohort_yr,
	sum(total_net_revenue) as total_revenue,
	count(distinct customerkey) as total_customer,
	sum(total_net_revenue)/count(distinct customerkey) as customer_revenue
from cohort_analysis 
where orderdate = first_order_date 
group by order_month, cohort_yr  
order by order_month, cohort_yr;
```

 

**📊 Visualization:**

![Cohort Analysis](/images/2_cohort_analysis.png)

**🔑 Key Findings:**
- Revenue per customer shows an alarming decreasing trend over time.
- 2022-2024 cohorts are consistently performing worsen than earlier cohort.
- NOTE: Although net revenue is increasing, this is likely due to large customer base, which is reflective to customer value.

**💡 Business Insights**

- Value extracted from customers is decreasing over time and needs further investigation.
- In 2023 we saw a drop in number of customers acquired, which is concerning.
- With both lowering LTV and decreasing customer acquisition, the company is facing a potential revenue decline.

{Repeat for each analysis approach}

### 3.**Retention Analysis:** Who hasn't purchase recently?

## Analysis Approach


### Query: [3_Customer_retention_analysis.sql](/3_customer_retention_analysis.sql)

```sql
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
```


- Identified customers at risk of churning
- Analyzed last purchase patterns
- Calculated customer-specific metrics


**📊 Visualization:**

![3_customer_retention_analysis.png](/3_customer_retention_analysis.png)

**🔑 Key Findings:**

- Cohort churn stabilizes at ~90% after 2-3 years, indicating a predictable long-term retention pattern.
- Retention rates are consistently low (8-10%) across all cohorts, suggesting retention issues are systemic rather than specific to certain cohorts.

- Newer cohorts (2022-2023) show similar churn trajectories, signaling that without intervention, future cohorts will follow the same pattern.

**💡 Business Insights**

- Strengthen early engagement strategies to target the first 1-2 years with onboarding
  incentives, loyalty rewards, and personalized offers to improve long-term retention.
- Re-engage high-value churned customers by focusing on targeted win-back campaigns
  rather than broad retention efforts, as reactivating valuable users may yield higher ROI.
- Predict & preempt churn risk and use customer-specific warning indicators to
  proactively intervene with at-risk users before they lapse.


## Strategic Recommendations

## Strategic Recommendations

> **Core Problem:** Declining revenue per customer + slowing acquisition = compounding
> revenue risk. The following strategies address both sides.

1. **Customer Value Optimization** (Customer Segmentation)
   - Launch VIP program for 12,372 high-value customers (66% revenue)
   - Create personalized upgrade paths for mid-value segment ($66.6M → $135.4M opportunity)
   - Design price-sensitive promotions for low-value segment to increase purchase frequency

2. **Cohort Performance Strategy** (Customer Revenue by Cohort)
   - Target 2022-2024 cohorts with personalized re-engagement offers
   - Implement loyalty/subscription programs to stabilize revenue fluctuations
   - Apply successful strategies from high-spending 2016-2018 cohorts to newer customers

3. **Retention & Churn Prevention** (Customer Retention)
   - Strengthen first 1-2 year engagement with onboarding incentives and loyalty rewards
   - Focus on targeted win-back campaigns for high-value churned customers
   - Implement proactive intervention system for at-risk customers before they lapse

4. **Data-Driven Decision Making** (Ongoing)
   - Build a customer health score combining LTV, cohort age, and last purchase date
   - Set churn alert thresholds per cohort year to trigger automated campaigns
   - Track retention rate quarterly as a core KPI alongside total revenue

## Technical Details
- **Database:** PostgreSQL
- **Analysis Tools:** PostgreSQL, DBeaver
- **Visualization:** Claude
