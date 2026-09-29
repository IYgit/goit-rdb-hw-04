```
Завдання 1. Setup і typed-схема Olist

У першій секції notebook встановіть залежності, запустіть pgserver, перевірте підключення та отримайте файли Olist з Kaggle або з курсового архіву.

%pip install -q pgserver psycopg2-binary sqlalchemy pandas kagglehub

import os
import pandas as pd
import pgserver
from sqlalchemy import create_engine, text

pg = pgserver.get_server('/tmp/hw4_pg', cleanup_mode='stop')
engine = create_engine(pg.get_uri(), future=True)

with engine.connect() as conn:
    print(conn.execute(text('SELECT version()')).scalar_one())



Якщо використовується KaggleHub, у Colab має бути налаштований доступ до Kaggle. Якщо курс надає архів із CSV, розпакуйте його у data/olist/ і вкажіть це у README.

# Варіант A: якщо Kaggle credentials налаштовані
import kagglehub

dataset_dir = kagglehub.dataset_download('olistbr/brazilian-ecommerce')
print(dataset_dir)

# Варіант B: якщо CSV вже лежать у репозиторії або course archive
# dataset_dir = '/content/goit-rdb-hw-04/data/olist'



Завантажте CSV у raw-таблиці. Raw-таблиці потрібні лише як проміжний шар: вони відображають вихідні CSV і не замінюють typed-схему з constraints.

files = {
    'olist_customers_raw': 'olist_customers_dataset.csv',
    'olist_orders_raw': 'olist_orders_dataset.csv',
    'olist_order_items_raw': 'olist_order_items_dataset.csv',
    'olist_products_raw': 'olist_products_dataset.csv',
    'olist_sellers_raw': 'olist_sellers_dataset.csv',
    'olist_order_reviews_raw': 'olist_order_reviews_dataset.csv',
}

for table_name, file_name in files.items():
    path = os.path.join(dataset_dir, file_name)
    df = pd.read_csv(path)
    df.to_sql(table_name, engine, if_exists='replace', index=False, chunksize=10_000)
    print(table_name, df.shape)



Після raw-завантаження створіть typed-таблиці. Саме typed-таблиці використовуються у всіх наступних завданнях.

DROP TABLE IF EXISTS customer_segments    CASCADE;
DROP TABLE IF EXISTS seller_score         CASCADE;
DROP TABLE IF EXISTS seller_alerts        CASCADE;
DROP TABLE IF EXISTS olist_customer_dim   CASCADE;
DROP TABLE IF EXISTS olist_order_reviews  CASCADE;
DROP TABLE IF EXISTS olist_order_items    CASCADE;
DROP TABLE IF EXISTS olist_orders         CASCADE;
DROP TABLE IF EXISTS olist_customers      CASCADE;
DROP TABLE IF EXISTS olist_products       CASCADE;
DROP TABLE IF EXISTS olist_sellers        CASCADE;

CREATE TABLE olist_customers (
    customer_id              TEXT PRIMARY KEY,
    customer_unique_id       TEXT NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city            TEXT,
    customer_state           CHAR(2) NOT NULL
);

CREATE INDEX idx_olist_customers_unique_id
    ON olist_customers (customer_unique_id);

CREATE TABLE olist_orders (
    order_id                      TEXT PRIMARY KEY,
    customer_id                   TEXT NOT NULL REFERENCES olist_customers(customer_id),
    order_status                  TEXT NOT NULL,
    order_purchase_timestamp      TIMESTAMP NOT NULL,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    CHECK (order_status IN (
        'created', 'approved', 'invoiced', 'processing',
        'shipped', 'delivered', 'unavailable', 'canceled'
    ))
);

CREATE TABLE olist_products (
    product_id                 TEXT PRIMARY KEY,
    product_category_name      TEXT,
    product_name_length        INTEGER CHECK (product_name_length IS NULL OR product_name_length >= 0),
    product_description_length INTEGER CHECK (product_description_length IS NULL OR product_description_length >= 0),
    product_photos_qty         INTEGER CHECK (product_photos_qty IS NULL OR product_photos_qty >= 0),
    product_weight_g           INTEGER CHECK (product_weight_g IS NULL OR product_weight_g >= 0),
    product_length_cm          INTEGER CHECK (product_length_cm IS NULL OR product_length_cm >= 0),
    product_height_cm          INTEGER CHECK (product_height_cm IS NULL OR product_height_cm >= 0),
    product_width_cm           INTEGER CHECK (product_width_cm IS NULL OR product_width_cm >= 0)
);

CREATE TABLE olist_sellers (
    seller_id              TEXT PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city            TEXT,
    seller_state           CHAR(2) NOT NULL
);

CREATE TABLE olist_order_items (
    order_id            TEXT NOT NULL REFERENCES olist_orders(order_id),
    order_item_id       INTEGER NOT NULL,
    product_id          TEXT REFERENCES olist_products(product_id),
    seller_id           TEXT REFERENCES olist_sellers(seller_id),
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(12, 2) CHECK (price IS NULL OR price >= 0),
    freight_value       NUMERIC(12, 2) CHECK (freight_value IS NULL OR freight_value >= 0),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE INDEX idx_olist_order_items_seller_order
    ON olist_order_items (seller_id, order_id);

CREATE TABLE olist_order_reviews (
    review_row_id            BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    review_id                TEXT,
    order_id                 TEXT NOT NULL REFERENCES olist_orders(order_id),
    review_score             SMALLINT CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title     TEXT,
    review_comment_message   TEXT,
    review_creation_date     TIMESTAMP,
    review_answer_timestamp  TIMESTAMP
);

CREATE INDEX idx_olist_order_reviews_order_id
    ON olist_order_reviews (order_id);



Перенесіть дані з raw-таблиць у typed-таблиці через INSERT ... SELECT. Нижче наведено шаблон; адаптуйте лише якщо ваша копія CSV має інші назви колонок.

Не змінюйте структуру typed-таблиць, якщо ваша копія датасету відповідає структурі Olist, наведеній у завданні.

INSERT INTO olist_customers
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix::INTEGER,
    customer_city,
    customer_state::CHAR(2)
FROM olist_customers_raw;

INSERT INTO olist_orders
SELECT
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp::TIMESTAMP,
    order_approved_at::TIMESTAMP,
    order_delivered_carrier_date::TIMESTAMP,
    order_delivered_customer_date::TIMESTAMP,
    order_estimated_delivery_date::TIMESTAMP
FROM olist_orders_raw;

INSERT INTO olist_products
SELECT
    product_id,
    product_category_name,
    product_name_lenght::INTEGER,
    product_description_lenght::INTEGER,
    product_photos_qty::INTEGER,
    product_weight_g::INTEGER,
    product_length_cm::INTEGER,
    product_height_cm::INTEGER,
    product_width_cm::INTEGER
FROM olist_products_raw;

INSERT INTO olist_sellers
SELECT
    seller_id,
    seller_zip_code_prefix::INTEGER,
    seller_city,
    seller_state::CHAR(2)
FROM olist_sellers_raw;

INSERT INTO olist_order_items
SELECT
    order_id,
    order_item_id::INTEGER,
    product_id,
    seller_id,
    shipping_limit_date::TIMESTAMP,
    price::NUMERIC(12, 2),
    freight_value::NUMERIC(12, 2)
FROM olist_order_items_raw;

INSERT INTO olist_order_reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
SELECT
    review_id,
    order_id,
    review_score::SMALLINT,
    review_comment_title,
    review_comment_message,
    review_creation_date::TIMESTAMP,
    review_answer_timestamp::TIMESTAMP
FROM olist_order_reviews_raw;



Зверніть увагу. У вихідному Olist CSV назви product_name_lenght і product_description_lenght написані саме з помилкою lenght. У typed-схемі використовуйте нормалізовані назви product_name_length і product_description_length, але в SELECT із raw-таблиці звертайтеся до фактичних назв із CSV.



Додайте smoke-test кількості рядків. Якщо typed-таблиця має менше рядків, ніж raw-таблиця, поясніть причину.

SELECT 'customers' AS table_name, COUNT(*) AS n_rows FROM olist_customers
UNION ALL SELECT 'orders', COUNT(*) FROM olist_orders
UNION ALL SELECT 'order_items', COUNT(*) FROM olist_order_items
UNION ALL SELECT 'products', COUNT(*) FROM olist_products
UNION ALL SELECT 'sellers', COUNT(*) FROM olist_sellers
UNION ALL SELECT 'reviews', COUNT(*) FROM olist_order_reviews
ORDER BY table_name;





Завдання 2. DML-запити з PostgreSQL-фічами

Напишіть щонайменше чотири DML-запити. Кожен запит має мати коротке пояснення: що він змінює, чому він безпечний для повторного запуску або як RETURNING допомагає audit-логіці.



2.1. INSERT ... RETURNING: створення alert для продавця з найбільшою кількістю запізнень

DROP TABLE IF EXISTS seller_alerts CASCADE;

CREATE TABLE seller_alerts (
    alert_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seller_id  TEXT NOT NULL REFERENCES olist_sellers(seller_id),
    alert_type TEXT NOT NULL CHECK (alert_type IN ('late_delivery', 'low_rating', 'data_quality')),
    severity   SMALLINT NOT NULL CHECK (severity BETWEEN 1 AND 5),
    details    TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

WITH seller_orders AS (
    SELECT DISTINCT
        oi.seller_id,
        oi.order_id
    FROM olist_order_items AS oi
),
late_sellers AS (
    SELECT
        so.seller_id,
        COUNT(DISTINCT o.order_id) AS late_orders
    FROM seller_orders AS so
    JOIN olist_orders AS o
        ON o.order_id = so.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
      AND o.order_delivered_customer_date::DATE > o.order_estimated_delivery_date::DATE
    GROUP BY so.seller_id
    ORDER BY late_orders DESC, so.seller_id
    LIMIT 1
)
INSERT INTO seller_alerts (seller_id, alert_type, severity, details)
SELECT
    seller_id,
    'late_delivery',
    4,
    'Seller has ' || late_orders || ' late delivered orders in the loaded dataset'
FROM late_sellers
RETURNING alert_id, seller_id, alert_type, severity, created_at;



Поясніть у Markdown, що RETURNING дозволяє одразу побачити створений alert і використати цей результат як audit-log у notebook.



2.2. INSERT ... ON CONFLICT DO UPDATE: idempotent upsert агрегованих seller-score

У цьому завданні важливо не множити review score через order_items.



Неправильний підхід:

FROM olist_order_items AS oi
LEFT JOIN olist_order_reviews AS rv
    ON rv.order_id = oi.order_id
GROUP BY oi.seller_id



Такий join має грануляність seller × order_item, тому один відгук до замовлення може бути врахований кілька разів, якщо в замовленні кілька позицій.

Коректний підхід: спочатку привести дані до грануляності seller_id × order_id, окремо агрегувати review до рівня order_id, а вже потім рахувати seller-level метрики.

DROP TABLE IF EXISTS seller_score CASCADE;

CREATE TABLE seller_score (
    seller_id   TEXT PRIMARY KEY REFERENCES olist_sellers(seller_id),
    avg_rating  NUMERIC(3, 2),
    n_reviews   INTEGER NOT NULL DEFAULT 0 CHECK (n_reviews >= 0),
    tier        TEXT CHECK (tier IN ('gold', 'silver', 'bronze')),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

WITH seller_orders AS (
    SELECT DISTINCT
        oi.seller_id,
        oi.order_id
    FROM olist_order_items AS oi
),
review_per_order AS (
    SELECT
        rv.order_id,
        AVG(rv.review_score)::NUMERIC(3, 2) AS order_review_score
    FROM olist_order_reviews AS rv
    WHERE rv.review_score IS NOT NULL
    GROUP BY rv.order_id
),
seller_rating AS (
    SELECT
        so.seller_id,
        AVG(rpo.order_review_score)::NUMERIC(3, 2) AS avg_rating,
        COUNT(rpo.order_id) AS n_reviews
    FROM seller_orders AS so
    LEFT JOIN review_per_order AS rpo
        ON rpo.order_id = so.order_id
    GROUP BY so.seller_id
)
INSERT INTO seller_score (seller_id, avg_rating, n_reviews, tier)
SELECT
    seller_id,
    avg_rating,
    n_reviews,
    CASE
        WHEN avg_rating IS NULL THEN NULL
        WHEN avg_rating >= 4.5 THEN 'gold'
        WHEN avg_rating >= 3.5 THEN 'silver'
        ELSE 'bronze'
    END AS tier
FROM seller_rating
ON CONFLICT (seller_id) DO UPDATE
SET avg_rating = EXCLUDED.avg_rating,
    n_reviews  = EXCLUDED.n_reviews,
    tier       = EXCLUDED.tier,
    updated_at = NOW()
RETURNING seller_id, avg_rating, n_reviews, tier, updated_at;



Поясніть у Markdown:

чому seller_orders використовує SELECT DISTINCT;
чому review потрібно спочатку агрегувати на рівні order_id;
чому ON CONFLICT (seller_id) DO UPDATE робить запуск повторюваним без дублювання рядків;
чому sellers без review можуть мати avg_rating = NULL, n_reviews = 0, tier = NULL.
Обмеження датасету: review в Olist прив’язаний до замовлення, а не до окремого продавця. Якщо одне замовлення містить товари кількох продавців, order-level review буде пов’язаний із кожним seller у цьому замовленні. Це прийнятне навчальне спрощення, але його потрібно назвати в інтерпретації.



2.3. UPDATE ... FROM: оновлення прапорця запізнення в olist_orders

ALTER TABLE olist_orders
    ADD COLUMN IF NOT EXISTS is_late BOOLEAN NOT NULL DEFAULT FALSE;

WITH delivery_flags AS (
    SELECT
        order_id,
        (
            order_delivered_customer_date IS NOT NULL
            AND order_estimated_delivery_date IS NOT NULL
            AND order_delivered_customer_date::DATE > order_estimated_delivery_date::DATE
        ) AS is_late_calc
    FROM olist_orders
)
UPDATE olist_orders AS o
SET is_late = f.is_late_calc
FROM delivery_flags AS f
WHERE f.order_id = o.order_id
RETURNING o.order_id, o.customer_id, o.is_late;

Цей варіант ідемпотентний: якщо запустити клітинку повторно, is_late буде знову встановлено відповідно до поточного стану дат доставки, а не просто “дописано TRUE” для частини рядків.



2.4. DELETE ... RETURNING: контрольоване видалення застарілих alert-ів

Якщо результат порожній — це допустимо, але поясніть чому.

DELETE FROM seller_alerts
WHERE created_at < NOW() - INTERVAL '30 days'
RETURNING alert_id, seller_id, alert_type, created_at;





Завдання 3. CREATE TABLE customer_segments

Створіть таблицю для зберігання поточної сегментації покупців. У цьому завданні сегментація має рахуватися на рівні customer_unique_id, а не customer_id.



Причина: у Olist customer_id відповідає конкретному замовленню / доставці, а customer_unique_id краще відповідає реальному покупцю. Якщо рахувати RFM за customer_id, повторні покупки одного покупця можуть бути розбиті на різні рядки, а frequency майже завжди вироджується до 1.



Спочатку створіть дедуплікований customer dimension.

DROP TABLE IF EXISTS customer_segments CASCADE;
DROP TABLE IF EXISTS olist_customer_dim CASCADE;

CREATE TABLE olist_customer_dim (
    customer_unique_id TEXT PRIMARY KEY,
    latest_customer_id TEXT REFERENCES olist_customers(customer_id),
    customer_state     CHAR(2),
    customer_city      TEXT
);

INSERT INTO olist_customer_dim (
    customer_unique_id,
    latest_customer_id,
    customer_state,
    customer_city
)
SELECT DISTINCT ON (c.customer_unique_id)
    c.customer_unique_id,
    c.customer_id AS latest_customer_id,
    c.customer_state,
    c.customer_city
FROM olist_customers AS c
LEFT JOIN olist_orders AS o
    ON o.customer_id = c.customer_id
ORDER BY
    c.customer_unique_id,
    o.order_purchase_timestamp DESC NULLS LAST,
    c.customer_id;

Тепер створіть customer_segments з production-подібним DDL: identity PK, FK, UNIQUE, CHECK, NOT NULL, DEFAULT і idempotent-наповнення через INSERT ... SELECT ... ON CONFLICT.

CREATE TABLE customer_segments (
    segment_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    customer_unique_id  TEXT NOT NULL,
    segment_name        TEXT NOT NULL
        CHECK (segment_name IN ('VIP', 'regular', 'new', 'inactive')),

    rfm_score           SMALLINT NOT NULL
        CHECK (rfm_score BETWEEN 1 AND 5),

    recency_days        INTEGER
        CHECK (recency_days IS NULL OR recency_days >= 0),

    monetary_value      NUMERIC(12, 2) NOT NULL DEFAULT 0
        CHECK (monetary_value >= 0),

    n_orders            INTEGER NOT NULL DEFAULT 0
        CHECK (n_orders >= 0),

    assigned_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    UNIQUE (customer_unique_id)
);

ALTER TABLE customer_segments
    ADD CONSTRAINT fk_customer_segments_customer_unique
    FOREIGN KEY (customer_unique_id)
    REFERENCES olist_customer_dim(customer_unique_id)
    ON DELETE CASCADE;

Наповніть таблицю через INSERT ... SELECT ... ON CONFLICT. Для стабільності історичного датасету використайте reference_date, обчислену з самого Olist, а не CURRENT_DATE.

WITH reference_date AS (
    SELECT (MAX(order_purchase_timestamp)::DATE + 1) AS as_of_date
    FROM olist_orders
),
order_totals AS (
    SELECT
        o.order_id,
        o.customer_id,
        o.order_purchase_timestamp::DATE AS order_date,
        COALESCE(SUM(oi.price + oi.freight_value), 0)::NUMERIC(12, 2) AS order_total
    FROM olist_orders AS o
    LEFT JOIN olist_order_items AS oi
        ON oi.order_id = o.order_id
    GROUP BY
        o.order_id,
        o.customer_id,
        o.order_purchase_timestamp
),
customer_stats AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT ot.order_id) AS n_orders,
        COALESCE(SUM(ot.order_total), 0)::NUMERIC(12, 2) AS monetary_value,
        MAX(ot.order_date) AS last_order_date
    FROM olist_customer_dim AS cd
    JOIN olist_customers AS c
        ON c.customer_unique_id = cd.customer_unique_id
    LEFT JOIN order_totals AS ot
        ON ot.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),
segmented AS (
    SELECT
        cs.customer_unique_id,
        cs.n_orders,
        cs.monetary_value,
        CASE
            WHEN cs.last_order_date IS NULL THEN NULL
            ELSE (rd.as_of_date - cs.last_order_date)::INTEGER
        END AS recency_days,
        CASE
            WHEN cs.monetary_value >= 1000 THEN 'VIP'
            WHEN cs.last_order_date IS NOT NULL
                 AND (rd.as_of_date - cs.last_order_date)::INTEGER <= 90
                 AND cs.n_orders = 1 THEN 'new'
            WHEN cs.n_orders >= 2 OR cs.monetary_value >= 100 THEN 'regular'
            ELSE 'inactive'
        END AS segment_name,
        CASE
            WHEN cs.monetary_value >= 1000 THEN 5
            WHEN cs.monetary_value >= 500  THEN 4
            WHEN cs.n_orders >= 2          THEN 3
            WHEN cs.n_orders = 1           THEN 2
            ELSE 1
        END::SMALLINT AS rfm_score
    FROM customer_stats AS cs
    CROSS JOIN reference_date AS rd
)
INSERT INTO customer_segments (
    customer_unique_id,
    segment_name,
    rfm_score,
    recency_days,
    monetary_value,
    n_orders
)
SELECT
    customer_unique_id,
    segment_name,
    rfm_score,
    recency_days,
    monetary_value,
    n_orders
FROM segmented
ON CONFLICT (customer_unique_id) DO UPDATE
SET segment_name   = EXCLUDED.segment_name,
    rfm_score      = EXCLUDED.rfm_score,
    recency_days   = EXCLUDED.recency_days,
    monetary_value = EXCLUDED.monetary_value,
    n_orders       = EXCLUDED.n_orders,
    assigned_at    = NOW()
RETURNING
    customer_unique_id,
    segment_name,
    rfm_score,
    recency_days,
    monetary_value,
    n_orders;



Перевірте constraints:

SELECT
    conname,
    contype,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'customer_segments'::regclass
ORDER BY conname;



Додайте коротке пояснення:

чому customer_segments використовує customer_unique_id;
чому olist_customer_dim потрібна для FK;
чому reference_date краще брати з датасету, а не з CURRENT_DATE;
як ON CONFLICT робить сегментацію повторюваною.




Завдання 4. JOIN-запити з business-interpretation

Сформулюйте й виконайте щонайменше 5 JOIN-запитів. Кожен блок має містити: business-question, SQL і interpretation на основі фактичного output.

Обов’язкове покриття:

INNER JOIN на щонайменше трьох таблицях;
LEFT JOIN із COALESCE для feature engineering;
FULL OUTER JOIN для порівняння двох наборів;
SELF JOIN;
anti-join через LEFT JOIN ... IS NULL або NOT EXISTS.


Приклад 4.1. INNER JOIN: топ категорій за revenue і seller-state

Business-question: які категорії товарів і штати продавців дають найбільший revenue у delivered-замовленнях?

SELECT
    p.product_category_name,
    s.seller_state,
    COUNT(DISTINCT oi.order_id) AS n_orders,
    SUM(oi.price + oi.freight_value)::NUMERIC(12, 2) AS revenue
FROM olist_order_items AS oi
JOIN olist_orders AS o
    ON o.order_id = oi.order_id
JOIN olist_products AS p
    ON p.product_id = oi.product_id
JOIN olist_sellers AS s
    ON s.seller_id = oi.seller_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name, s.seller_state
ORDER BY revenue DESC NULLS LAST
LIMIT 10;



Приклад 4.2. LEFT JOIN + COALESCE: customer-level features без множення review

Business-question: які customer-level features можна побудувати для реального покупця на рівні customer_unique_id?

WITH order_totals AS (
    SELECT
        o.order_id,
        c.customer_unique_id,
        SUM(oi.price + oi.freight_value)::NUMERIC(12, 2) AS order_total
    FROM olist_orders AS o
    JOIN olist_customers AS c
        ON c.customer_id = o.customer_id
    LEFT JOIN olist_order_items AS oi
        ON oi.order_id = o.order_id
    GROUP BY
        o.order_id,
        c.customer_unique_id
),
review_per_order AS (
    SELECT
        rv.order_id,
        AVG(rv.review_score)::NUMERIC(3, 2) AS order_review_score
    FROM olist_order_reviews AS rv
    WHERE rv.review_score IS NOT NULL
    GROUP BY rv.order_id
),
customer_stats AS (
    SELECT
        ot.customer_unique_id,
        COUNT(DISTINCT ot.order_id) AS n_orders,
        COALESCE(SUM(ot.order_total), 0)::NUMERIC(12, 2) AS total_spend,
        AVG(rpo.order_review_score)::NUMERIC(3, 2) AS avg_review_score
    FROM order_totals AS ot
    LEFT JOIN review_per_order AS rpo
        ON rpo.order_id = ot.order_id
    GROUP BY ot.customer_unique_id
)
SELECT
    cd.customer_unique_id,
    cd.customer_state,
    COALESCE(cs.n_orders, 0) AS n_orders,
    COALESCE(cs.total_spend, 0)::NUMERIC(12, 2) AS total_spend,
    COALESCE(cs.avg_review_score, 0)::NUMERIC(3, 2) AS avg_review_score
FROM olist_customer_dim AS cd
LEFT JOIN customer_stats AS cs
    ON cs.customer_unique_id = cd.customer_unique_id
ORDER BY total_spend DESC NULLS LAST
LIMIT 20;



У поясненні зазначте, що review_per_order захищає від множення review score через позиції замовлення.



Приклад 4.3. FULL OUTER JOIN: які штати присутні серед клієнтів і продавців

Business-question: які штати представлені тільки серед клієнтів, тільки серед продавців або в обох групах?

WITH customer_states AS (
    SELECT customer_state AS state, COUNT(*) AS n_customers
    FROM olist_customers
    GROUP BY customer_state
), seller_states AS (
    SELECT seller_state AS state, COUNT(*) AS n_sellers
    FROM olist_sellers
    GROUP BY seller_state
)
SELECT
    COALESCE(c.state, s.state) AS state,
    c.n_customers,
    s.n_sellers,
    CASE
        WHEN c.state IS NOT NULL AND s.state IS NOT NULL THEN 'both'
        WHEN c.state IS NOT NULL THEN 'customers_only'
        ELSE 'sellers_only'
    END AS state_presence
FROM customer_states AS c
FULL OUTER JOIN seller_states AS s
    ON s.state = c.state
ORDER BY state;



Приклад 4.4. SELF JOIN: пари продавців з одного штату, але з різних міст

Business-question: які seller-пари можуть бути кандидатами для регіонального порівняння в межах одного штату?

SELECT
    s1.seller_id AS seller_a,
    s2.seller_id AS seller_b,
    s1.seller_state,
    s1.seller_city AS city_a,
    s2.seller_city AS city_b
FROM olist_sellers AS s1
JOIN olist_sellers AS s2
    ON s1.seller_state = s2.seller_state
   AND s1.seller_id < s2.seller_id
   AND s1.seller_city IS DISTINCT FROM s2.seller_city
ORDER BY s1.seller_state, seller_a, seller_b
LIMIT 20;



Приклад 4.5. Anti-join: замовлення без відгуку

Business-question: які замовлення не мають жодного review-запису?

SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp
FROM olist_orders AS o
LEFT JOIN olist_order_reviews AS rv
    ON rv.order_id = o.order_id
WHERE rv.review_row_id IS NULL
ORDER BY o.order_purchase_timestamp
LIMIT 20;



Типова помилка. Не підміняйте FULL OUTER JOIN звичайним JOIN або self-join. Якщо завдання вимагає FULL OUTER JOIN, у SQL має прямо бути FULL OUTER JOIN, а запит має порівнювати лівий і правий набори з можливими “тільки зліва” / “тільки справа” результатами.





Завдання 5. GROUP BY, HAVING і агрегати

Виконайте щонайменше 3 агреговані запити з осмисленими бізнес-метриками. У мінімум 2 із 3 запитів використайте HAVING. У щонайменше одному запиті використайте STRING_AGG, ARRAY_AGG або JSONB_AGG.



Приклад 5.1. Revenue per product category з фільтром по revenue

SELECT
    p.product_category_name,
    COUNT(DISTINCT oi.order_id) AS n_orders,
    SUM(oi.price)::NUMERIC(12, 2) AS gross_revenue,
    SUM(oi.freight_value)::NUMERIC(12, 2) AS freight,
    AVG(oi.price)::NUMERIC(8, 2) AS avg_item_price
FROM olist_order_items AS oi
JOIN olist_products AS p
    ON p.product_id = oi.product_id
GROUP BY p.product_category_name
HAVING SUM(oi.price) > 10000
ORDER BY gross_revenue DESC NULLS LAST;



Приклад 5.2. AOV per customer-state тільки для штатів із достатньою кількістю замовлень

WITH order_totals AS (
    SELECT
        o.order_id,
        c.customer_state,
        SUM(oi.price + oi.freight_value)::NUMERIC(12, 2) AS order_total
    FROM olist_orders AS o
    JOIN olist_customers AS c
        ON c.customer_id = o.customer_id
    JOIN olist_order_items AS oi
        ON oi.order_id = o.order_id
    GROUP BY
        o.order_id,
        c.customer_state
)
SELECT
    customer_state,
    COUNT(*) AS n_orders,
    SUM(order_total)::NUMERIC(12, 2) AS gmv,
    (SUM(order_total) / NULLIF(COUNT(*), 0))::NUMERIC(8, 2) AS aov
FROM order_totals
GROUP BY customer_state
HAVING COUNT(*) >= 100
ORDER BY aov DESC NULLS LAST;



Приклад 5.3. Категорії, які купував реальний покупець, через STRING_AGG

SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS n_orders,
    SUM(oi.price)::NUMERIC(12, 2) AS total_spend,
    STRING_AGG(
        DISTINCT COALESCE(p.product_category_name, '(unknown)'),
        ', ' ORDER BY COALESCE(p.product_category_name, '(unknown)')
    ) AS categories
FROM olist_customers AS c
JOIN olist_orders AS o
    ON o.customer_id = c.customer_id
JOIN olist_order_items AS oi
    ON oi.order_id = o.order_id
LEFT JOIN olist_products AS p
    ON p.product_id = oi.product_id
GROUP BY c.customer_unique_id
HAVING COUNT(DISTINCT o.order_id) >= 1
ORDER BY total_spend DESC NULLS LAST
LIMIT 20;



Поясніть у Markdown різницю між WHERE і HAVING на одному з ваших запитів: WHERE фільтрує рядки до агрегації, а HAVING фільтрує групи після агрегації.





Завдання 6. Set operations, підзапит/window і Reflection

Виконайте щонайменше один set-operation запит. Можна використати UNION, UNION ALL, INTERSECT або EXCEPT, але поясніть, чому обрали саме цей оператор.



Приклад 6.1. Усі state-коди, що є у клієнтів або продавців

SELECT customer_state AS state, 'customer' AS role
FROM olist_customers

UNION

SELECT seller_state AS state, 'seller' AS role
FROM olist_sellers
ORDER BY state, role;



Приклад 6.2. Штати, у яких є і клієнти, і продавці

SELECT customer_state AS state
FROM olist_customers

INTERSECT

SELECT seller_state AS state
FROM olist_sellers
ORDER BY state;



Додатково виконайте один підзапит / CTE або один базовий window-function запит. Window function тут не потрібно ускладнювати: достатньо ROW_NUMBER() або RANK() із OVER (...).



Приклад 6.3. Найновіше замовлення кожного реального покупця через ROW_NUMBER()

WITH ranked_orders AS (
    SELECT
        c.customer_unique_id,
        o.customer_id,
        o.order_id,
        o.order_purchase_timestamp,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp DESC, o.order_id DESC
        ) AS rn
    FROM olist_orders AS o
    JOIN olist_customers AS c
        ON c.customer_id = o.customer_id
)
SELECT
    customer_unique_id,
    customer_id,
    order_id,
    order_purchase_timestamp
FROM ranked_orders
WHERE rn = 1
ORDER BY customer_unique_id
LIMIT 20;



Reflection

Reflection має бути обсягом приблизно 200–250 слів.

Дайте відповіді на запитання:

Який тип JOIN був найскладнішим і чому?
Який запит найскладніше було сформулювати як business-question?
Яка PostgreSQL-фіча з Теми 4 здається найбільш корисною для production-ETL: RETURNING, ON CONFLICT, identity-ключі, constraints або window functions?
У яких місцях такого e-commerce pipeline ви б використали window functions у реальному ML-проєкті?
Які data-quality проблеми ви помітили в Olist-таблицях: відсутні reviews, пропущені категорії, дивні статуси, дублікати або порожні тексти?
Чому для customer-level ML-фіч у цьому ДЗ використано customer_unique_id, а не customer_id?
Чому перед обчисленням seller_score потрібно було привести дані до грануляності seller_id × order_id?

```