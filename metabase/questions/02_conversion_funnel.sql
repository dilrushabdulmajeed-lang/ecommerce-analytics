WITH funnel AS (
  SELECT
    user_id,
    windowFunnel(86400)(event_time,
      event_type = 'view_product',
      event_type = 'add_to_cart',
      event_type = 'begin_checkout',
      event_type = 'purchase') AS level
  FROM analytics.ecom_events
  WHERE 1 = 1
    [[AND {{date_range}}]]
    [[AND {{device}}]]
  GROUP BY user_id
)
SELECT
  ['1. Viewed product', '2. Added to cart', '3. Started checkout', '4. Purchased'][n] AS step,
  countIf(level >= n) AS users,
  round(users / max(users) OVER () * 100, 1) AS pct_of_visitors
FROM funnel
ARRAY JOIN [1, 2, 3, 4] AS n
GROUP BY n
ORDER BY n
