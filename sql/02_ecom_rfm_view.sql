-- RFM segmentation: one row per customer, scored 1-5 on Recency, Frequency, Monetary.
-- Recency is measured from the latest order in the data, so the view stays valid as data ages.
CREATE OR REPLACE VIEW analytics.ecom_rfm AS
WITH (SELECT toDate(max(order_time)) FROM analytics.ecom_orders) AS ref_date
SELECT
    user_id,
    country,
    acquisition_channel,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    multiIf(
        r_score >= 4 AND f_score >= 4, 'Champions',
        r_score >= 3 AND f_score >= 3, 'Loyal',
        r_score >= 4,                  'New / Promising',
        r_score <= 2 AND f_score >= 3, 'At Risk',
        r_score = 1,                   'Lost',
                                       'Needs Attention') AS segment
FROM
(
    SELECT
        o.user_id,
        any(u.country)                                AS country,
        any(u.acquisition_channel)                    AS acquisition_channel,
        dateDiff('day', toDate(max(o.order_time)), ref_date) AS recency_days,
        count()                                       AS frequency,
        sum(o.revenue)                                AS monetary,
        ntile(5) OVER (ORDER BY recency_days DESC)    AS r_score,   -- 5 = most recent
        multiIf(frequency = 1, 1, frequency = 2, 2, frequency = 3, 3, frequency <= 5, 4, 5) AS f_score,
        ntile(5) OVER (ORDER BY monetary)             AS m_score    -- 5 = highest spend
    FROM analytics.ecom_orders AS o
    INNER JOIN analytics.ecom_users AS u ON u.user_id = o.user_id
    GROUP BY o.user_id
);
