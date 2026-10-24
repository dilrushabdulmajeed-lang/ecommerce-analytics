SELECT
  sum(revenue)                 AS total_revenue,
  count()                      AS orders,
  round(avg(revenue))          AS aov,
  uniqExact(user_id)           AS customers
FROM analytics.ecom_orders
WHERE 1 = 1
  [[AND {{date_range}}]]
  [[AND {{device}}]]
