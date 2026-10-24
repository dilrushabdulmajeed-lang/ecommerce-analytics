-- Project 2: E-commerce behavioural data (synthetic)
-- GCC electronics store, 15 Oct 2025 – 14 Oct 2026.
-- Planted patterns: weak mobile checkout, low-retention White Friday promo cohort,
-- Pareto revenue concentration with some high-value customers drifting away.

-- ---------- Public tables ----------
CREATE TABLE IF NOT EXISTS analytics.ecom_products
(
    product_id   UInt16,
    product_name String,
    category     LowCardinality(String),
    price        Decimal(10, 2)
)
ENGINE = MergeTree
ORDER BY product_id;

CREATE TABLE IF NOT EXISTS analytics.ecom_users
(
    user_id             UInt32,
    first_visit         Date,
    acquisition_channel LowCardinality(String),
    country             LowCardinality(String),
    preferred_device    LowCardinality(String)
)
ENGINE = MergeTree
ORDER BY user_id;

CREATE TABLE IF NOT EXISTS analytics.ecom_events
(
    event_time  DateTime,
    session_id  UInt64,
    user_id     UInt32,
    event_type  LowCardinality(String),   -- view_product, add_to_cart, begin_checkout, purchase
    device      LowCardinality(String),
    channel     LowCardinality(String),
    country     LowCardinality(String),
    product_id  UInt16,
    category    LowCardinality(String),
    price       Decimal(10, 2),
    quantity    UInt8,
    revenue     Decimal(12, 2)
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(event_time)
ORDER BY (user_id, event_time);

CREATE TABLE IF NOT EXISTS analytics.ecom_orders
(
    order_id     UInt64,
    user_id      UInt32,
    order_time   DateTime,
    device       LowCardinality(String),
    channel      LowCardinality(String),
    country      LowCardinality(String),
    product_id   UInt16,
    category     LowCardinality(String),
    quantity     UInt8,
    discount_pct UInt8,
    revenue      Decimal(12, 2)
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(order_time)
ORDER BY (user_id, order_time);

TRUNCATE TABLE analytics.ecom_products;
TRUNCATE TABLE analytics.ecom_users;
TRUNCATE TABLE analytics.ecom_events;
TRUNCATE TABLE analytics.ecom_orders;

-- ---------- Products: 200 SKUs across 6 categories ----------
INSERT INTO analytics.ecom_products
SELECT
    toUInt16(number + 1) AS product_id,
    concat(category, ' #', toString(product_id)) AS product_name,
    ['Phones', 'Laptops', 'Audio', 'Accessories', 'Wearables', 'Gaming'][1 + number % 6] AS category,
    round([2400, 4200, 450, 120, 900, 1800][1 + number % 6]
          * (0.6 + (cityHash64(number, 'price') % 1000) / 1250.0), 2) AS price
FROM numbers(200);

-- ---------- Hidden per-user behaviour (dropped at the end) ----------
DROP TABLE IF EXISTS analytics._ecom_user_seed;
CREATE TABLE analytics._ecom_user_seed ENGINE = MergeTree ORDER BY user_id AS
SELECT
    toUInt32(number + 1) AS user_id,
    (cityHash64(number, 'promo')  % 10007) / 10007.0 AS r_promo,
    (cityHash64(number, 'date')   % 10007) / 10007.0 AS r_date,
    (cityHash64(number, 'chan')   % 10007) / 10007.0 AS r_chan,
    (cityHash64(number, 'ctry')   % 10007) / 10007.0 AS r_ctry,
    (cityHash64(number, 'dev')    % 10007) / 10007.0 AS r_dev,
    (cityHash64(number, 'loyal')  % 10007) / 10007.0 AS r_loyal,
    (cityHash64(number, 'life')   % 10007) / 10007.0 AS r_life,
    (cityHash64(number, 'nsess')  % 10007) / 10007.0 AS r_nsess,
    r_promo < 0.12 AS is_promo,
    if(is_promo,
       toDate('2025-11-20') + toUInt16(r_date * 11),                 -- White Friday window
       toDate('2025-10-15') + toUInt16(pow(r_date, 0.85) * 364)) AS first_visit,
    if(is_promo, 'White Friday Promo',
       multiIf(r_chan < 0.30, 'Organic', r_chan < 0.60, 'Google Ads', r_chan < 0.80, 'Meta Ads',
               r_chan < 0.90, 'Email', 'Referral')) AS acquisition_channel,
    multiIf(r_ctry < 0.55, 'UAE', r_ctry < 0.85, 'KSA', r_ctry < 0.93, 'Qatar', 'Kuwait') AS country,
    multiIf(r_dev < 0.65, 'Mobile', r_dev < 0.95, 'Desktop', 'Tablet') AS preferred_device,
    pow(r_loyal, 3) * if(is_promo, 0.3, 1.0) AS loyalty,              -- skewed: few very loyal users
    toUInt16(if(is_promo, 10 + loyalty * 120, 25 + loyalty * 420) * (0.5 + r_life)) AS lifetime_days,
    toUInt16(1 + floor(loyalty * 35 + r_nsess * 3)) AS n_sessions
FROM numbers(60000);

INSERT INTO analytics.ecom_users
SELECT user_id, first_visit, acquisition_channel, country, preferred_device
FROM analytics._ecom_user_seed;

-- ---------- Sessions with funnel outcome ----------
DROP TABLE IF EXISTS analytics._ecom_session_seed;
CREATE TABLE analytics._ecom_session_seed ENGINE = MergeTree ORDER BY session_id AS
SELECT
    cityHash64(user_id, k) AS session_id,
    user_id,
    k = 0 AS is_first_session,
    is_promo,
    (cityHash64(user_id, k, 'off')  % 10007) / 10007.0 AS r_off,
    (cityHash64(user_id, k, 'hr')   % 10007) / 10007.0 AS r_hr,
    (cityHash64(user_id, k, 'sec')  % 10007) / 10007.0 AS r_sec,
    (cityHash64(user_id, k, 'dev')  % 10007) / 10007.0 AS r_dev2,
    (cityHash64(user_id, k, 'ch')   % 10007) / 10007.0 AS r_ch,
    (cityHash64(user_id, k, 'cart') % 10007) / 10007.0 AS r_cart,
    (cityHash64(user_id, k, 'co')   % 10007) / 10007.0 AS r_co,
    (cityHash64(user_id, k, 'buy')  % 10007) / 10007.0 AS r_buy,
    (cityHash64(user_id, k, 'v')    % 10007) / 10007.0 AS r_views,
    (cityHash64(user_id, k, 'q')    % 10007) / 10007.0 AS r_qty,
    (cityHash64(user_id, k, 'disc') % 10007) / 10007.0 AS r_disc,
    first_visit + if(k = 0, 0, toUInt16(lifetime_days * pow(r_off, 1.3))) AS session_date,
    addSeconds(toDateTime(session_date),
               toUInt32(((8 + toUInt8(pow(r_hr, 0.7) * 16)) % 24) * 3600 + r_sec * 3599)) AS session_start,
    if(r_dev2 < 0.85, preferred_device, ['Mobile', 'Desktop', 'Tablet'][1 + cityHash64(user_id, k) % 3]) AS device,
    if(k = 0, acquisition_channel,
       multiIf(r_ch < 0.40, 'Direct', r_ch < 0.60, 'Email', r_ch < 0.80, 'Organic', 'Google Ads')) AS channel,
    country,
    -- funnel probabilities
    least(0.85, 0.035 + loyalty * 0.30 + if(k = 0 AND is_promo, 0.30, 0)) AS p_cart,
    0.55 + if(k = 0 AND is_promo, 0.15, 0) AS p_checkout,
    multiIf(device = 'Mobile', 0.46, device = 'Tablet', 0.72, 0.78) + if(k = 0 AND is_promo, 0.10, 0) AS p_buy,
    toUInt8(1 + (r_cart < p_cart)
              + (r_cart < p_cart AND r_co < p_checkout)
              + (r_cart < p_cart AND r_co < p_checkout AND r_buy < p_buy)) AS depth,   -- 1..4
    toUInt8(1 + floor(r_views * 4)) AS views,
    toUInt16(1 + cityHash64(user_id, k, 'prod') % 200) AS product_id,
    toUInt8(1 + (r_qty < 0.2)) AS quantity,
    toUInt8(if(k = 0 AND is_promo, 30, if(r_disc < 0.10, 10, 0))) AS discount_pct
FROM analytics._ecom_user_seed
ARRAY JOIN range(n_sessions) AS k
WHERE session_date <= toDate('2026-10-14');

-- ---------- Events: one row per step ----------
INSERT INTO analytics.ecom_events
SELECT
    addSeconds(s.session_start, toUInt32(idx * (30 + cityHash64(s.session_id, idx) % 150))) AS event_time,
    s.session_id,
    s.user_id,
    step AS event_type,
    s.device,
    s.channel,
    s.country,
    s.product_id,
    p.category,
    p.price,
    if(step = 'view_product', 0, s.quantity) AS quantity,
    if(step = 'purchase', round(p.price * s.quantity * (100 - s.discount_pct) / 100, 2), 0) AS revenue
FROM analytics._ecom_session_seed AS s
INNER JOIN analytics.ecom_products AS p ON p.product_id = s.product_id
ARRAY JOIN
    arrayConcat(arrayResize(['view_product'], s.views, 'view_product'),
                arraySlice(['add_to_cart', 'begin_checkout', 'purchase'], 1, s.depth - 1)) AS step,
    arrayEnumerate(arrayConcat(arrayResize(['view_product'], s.views, 'view_product'),
                               arraySlice(['add_to_cart', 'begin_checkout', 'purchase'], 1, s.depth - 1))) AS idx;

-- ---------- Orders: one row per purchase ----------
INSERT INTO analytics.ecom_orders
SELECT
    cityHash64(e.session_id, 'order') AS order_id,
    e.user_id, e.event_time, e.device, e.channel, e.country,
    e.product_id, e.category, e.quantity, s.discount_pct, e.revenue
FROM analytics.ecom_events AS e
INNER JOIN analytics._ecom_session_seed AS s ON s.session_id = e.session_id
WHERE e.event_type = 'purchase';

DROP TABLE analytics._ecom_session_seed;
DROP TABLE analytics._ecom_user_seed;
