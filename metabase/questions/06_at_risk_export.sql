-- Used by the n8n "Weekly At-Risk customers export" workflow
SELECT
  user_id,
  country,
  acquisition_channel,
  recency_days                AS days_since_last_order,
  frequency                   AS orders,
  round(monetary)             AS lifetime_spend_aed,
  if(monetary >= 10000, 'VIP: personal call + exclusive offer', '15% win-back code') AS suggested_action
FROM analytics.ecom_rfm
WHERE segment = 'At Risk'
ORDER BY monetary DESC
