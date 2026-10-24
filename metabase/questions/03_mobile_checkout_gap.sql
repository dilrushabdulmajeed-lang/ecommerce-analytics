SELECT
  device,
  round(uniqExactIf(session_id, event_type = 'add_to_cart')
      / uniqExact(session_id) * 100, 1)                        AS add_to_cart_pct,
  round(uniqExactIf(session_id, event_type = 'purchase')
      / uniqExactIf(session_id, event_type = 'begin_checkout') * 100, 1) AS checkout_completion_pct
FROM analytics.ecom_events
WHERE 1 = 1
  [[AND {{date_range}}]]
GROUP BY device
ORDER BY device
