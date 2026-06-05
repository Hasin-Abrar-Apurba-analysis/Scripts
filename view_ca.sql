
WITH customer_revenue AS (
         SELECT s.customerkey,
            s.orderdate,
            sum(s.quantity::double precision * s.netprice * s.exchangerate) AS total_net_revenue,
            count(s.orderkey) AS num_orders,
            max(c.countryfull::text) AS countryfull,
            max(c.age) AS age,
            max(c.givenname::text) AS givenname,
            max(c.surname::text) AS surname
           FROM sales s
             LEFT JOIN customer c ON s.customerkey = c.customerkey
          GROUP BY s.customerkey, s.orderdate
        )
 SELECT customerkey,
    orderdate,
    total_net_revenue,
    num_orders,
    countryfull,
    age,
    concat(givenname, ' ', surname) AS cleaned_name,
    min(orderdate) OVER (PARTITION BY customerkey) AS first_order_date,
    EXTRACT(year FROM min(orderdate) OVER (PARTITION BY customerkey)) AS cohort_yr
   FROM customer_revenue cr;                                                                                     