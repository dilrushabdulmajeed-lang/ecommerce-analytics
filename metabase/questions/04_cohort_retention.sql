WITH
  (SELECT toStartOfMonth(max(order_time)) FROM analytics.ecom_orders) AS last_month,
  first_orders AS (
    SELECT user_id, toStartOfMonth(min(order_time)) AS cohort
    FROM analytics.ecom_orders
    GROUP BY user_id
  ),
  per_user AS (
    SELECT
      f.cohort,
      retention(
        dateDiff('month', f.cohort, toStartOfMonth(o.order_time)) = 0,
        dateDiff('month', f.cohort, toStartOfMonth(o.order_time)) = 1,
        dateDiff('month', f.cohort, toStartOfMonth(o.order_time)) = 2,
        dateDiff('month', f.cohort, toStartOfMonth(o.order_time)) = 3,
        dateDiff('month', f.cohort, toStartOfMonth(o.order_time)) = 6
      ) AS r
    FROM analytics.ecom_orders AS o
    INNER JOIN first_orders AS f ON f.user_id = o.user_id
    GROUP BY o.user_id, f.cohort
  )
SELECT
  formatDateTime(cohort, '%Y-%m') AS cohort_month,
  count() AS customers,
  if(addMonths(cohort, 1) < last_month, round(sum(r[2]) / count() * 100, 1), NULL) AS m1_pct,
  if(addMonths(cohort, 2) < last_month, round(sum(r[3]) / count() * 100, 1), NULL) AS m2_pct,
  if(addMonths(cohort, 3) < last_month, round(sum(r[4]) / count() * 100, 1), NULL) AS m3_pct,
  if(addMonths(cohort, 6) < last_month, round(sum(r[5]) / count() * 100, 1), NULL) AS m6_pct
FROM per_user
GROUP BY cohort
ORDER BY cohort
