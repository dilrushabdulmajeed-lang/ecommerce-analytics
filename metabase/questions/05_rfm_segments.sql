SELECT
  segment,
  count()                                             AS customers,
  round(customers / sum(customers) OVER () * 100, 1)  AS pct_customers,
  round(sum(monetary))                                AS revenue,
  round(revenue / sum(revenue) OVER () * 100, 1)      AS pct_revenue,
  round(avg(recency_days))                            AS avg_days_since_order,
  round(avg(frequency), 1)                            AS avg_orders,
  round(avg(monetary))                                AS avg_spend
FROM analytics.ecom_rfm
WHERE 1 = 1
  [[AND {{country}}]]
GROUP BY segment
ORDER BY revenue DESC
