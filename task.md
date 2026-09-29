```
Завдання 3. DML та DDL команди. Складні SQL-вирази
Вітаємо у домашньому завданні до Теми 4!

У цій темі ви працювали з DML-командами INSERT, UPDATE, DELETE, можливостями PostgreSQL RETURNING та ON CONFLICT, DDL-командами CREATE TABLE і ALTER TABLE, обмеженнями цілісності, різними типами JOIN, агрегуванням через GROUP BY і HAVING, множинними операціями та базовим прикладом window functions.



У домашньому завданні ви застосуєте ці інструменти на багатотабличному e-commerce-датасеті. Головна мета роботи — не просто написати багато SQL-запитів, а показати, що ви вмієте безпечно змінювати дані, будувати схему з constraints, обирати правильний тип JOIN, агрегувати бізнес-метрики й пояснювати результат запиту бізнес-мовою.



У результаті виконання завдання ви навчитеся:

завантажувати кілька пов’язаних CSV-таблиць у PostgreSQL і створювати поверх них контрольовану typed-схему;
використовувати INSERT ... RETURNING, INSERT ... ON CONFLICT, UPDATE ... FROM і DELETE ... RETURNING;
створювати таблиці з PRIMARY KEY, FOREIGN KEY, UNIQUE, CHECK, NOT NULL, DEFAULT та identity-ключами;
реалізовувати idempotent seed / upsert-логіку для повторюваних ETL-запусків;
контролювати грануляність даних перед агрегуванням, щоб не множити метрики через зайві JOIN;
писати INNER, LEFT, FULL OUTER, SELF і anti-join запити на реальній схемі;
обчислювати бізнес-метрики через GROUP BY, HAVING, COUNT, SUM, AVG, STRING_AGG або ARRAY_AGG;
використовувати UNION, UNION ALL, INTERSECT або EXCEPT для порівняння наборів;
застосовувати один підзапит / CTE або базову window function для складнішого аналітичного сценарію.


 ☝Основне правило цього ДЗ: запити мають бути відтворюваними. Notebook повинен запускатися після Restart & Run All без ручного виправлення таблиць, шляхів або constraints.


Що потрібно знати перед виконанням

Із Огляду дисципліни вам знадобляться: запуск pgserver у Google Colab, робота з notebook, структура репозиторію, базове завантаження даних.
Із Теми 3 вам знадобляться: SELECT, WHERE, ORDER BY, LIMIT, DISTINCT, NULLhandling, базові EDA-запити.
Із Теми 4 вам знадобляться: DML, DDL, constraints, JOIN, GROUP BY, HAVING, set operations, підзапити, базовий синтаксис OVER (...).


Хід роботи

У цьому домашньому завданні ви пройдете повний цикл роботи з багатотабличним e-commerce-датасетом:

Завантажите Olist-датасет і створите raw- та typed-рівні даних.
Побудуєте схему з ключами та обмеженнями цілісності.
Реалізуєте DML-операції PostgreSQL для оновлення та підтримки даних.
Створите customer-level сегментацію.
Побудуєте ознаки та бізнес-метрики через JOIN-запити.
Виконаєте агрегування, set operations і window functions.
Підготуєте Reflection щодо проєктних рішень і якості даних.


Опис домашнього завдання

Уявіть, що ви працюєте Data Engineer або Data Analyst у компанії електронної комерції.

Вам потрібно підготувати багатотабличний dataset до подальшої аналітикита ML-моделювання: забезпечити цілісність даних, побудувати коректні зв’язки між таблицями, сформувати ознаки на рівні клієнтів і продавці та підготувати бізнес-метрики для прийняття рішень.

Саме такі задачі ви виконаєте в межах цього домашнього завдання.



Усі наступні завдання виконуються на одному датасеті — Olist Brazilian E-commerce Dataset. Він містить кілька пов’язаних таблиць, тому дозволяє відпрацювати не лише окремі SQL-запити, а й роботу з повноцінною реляційною схемою.


Для домашнього завдання використовується Olist Brazilian E-commerce Public Dataset — багатотабличний набір даних про приблизно 100 тис. замовлень на бразильській e-commerce-платформі Olist за 2016–2018 роки. Він містить пов’язані таблиці про клієнтів, замовлення, товари, продавців, позиції замовлень і відгуки.



Таблиця	Призначення	Ключ у typed-схемі
olist_customers	Клієнти: customer_id, customer_unique_id, city/state/zip	customer_id
olist_orders	Замовлення: статус і часові мітки	order_id
olist_order_items	Позиції замовлення: товар, продавець, ціна, freight	(order_id, order_item_id)
olist_products	Товари й категорії	product_id
olist_sellers	Продавці: city/state/zip	seller_id
olist_order_reviews	Відгуки до замовлень	технічний review_row_id;
review_id лишається джерельним ID


Важливо. У Olist customer_id пов’язаний із конкретним замовленням або доставкою, а customer_unique_id краще використовувати як ідентифікатор реального покупця для customer-level ML-фіч, повторних покупок і RFM-сегментації.



Не робіть review_id безумовним primary key. У реальних копіях Olist можуть траплятися повтори або кілька review-записів, тому для стабільного ДЗ безпечніше створити технічний review_row_id і зберегти review_id як джерельний атрибут.



Важливо. Таблиці Olist мають різну грануляність (позиція замовлення, замовлення, відгук, покупець). Перед обчисленням метрик перевіряйте, чи не множить JOIN кількість рядків і значення агрегатів.


Перед здачею переконайтеся, що:

Notebook виконується після Restart & Run All без помилок.
Дані Olist завантажені, а raw- та typed-рівні створені.
customer_segments, seller_score і DML-запити працюють коректно.
JOIN, агреговані запити, set operation і window function / CTE виконані.
Reflection відповідає на всі запитання.


Підготовка та завантаження домашнього завдання

Створіть публічний репозиторій goit-rdb-hw-04.
Виконайте роботу в Google Colab notebook.
Додайте README.md з джерелом датасету, способом отримання файлів, списком використаних таблиць і короткою інструкцією запуску.
Переконайтеся, що notebook виконується від початку до кінця після Restart & Run All.
Збережіть notebook разом із output клітинок.
Створіть архів ДЗ4_ПІБ.zip і завантажте його в LMS.
Додайте в LMS посилання на репозиторій та архів.


Якщо в курсовому репозиторії є notebooks/hw_t4_template.ipynb, використайте його як основу.

Для власних таблиць використовуйте префікс hw4_ для службових таблиць і префікс olist_ для typed-таблиць Olist.



Формат здачі

публічний репозиторій goit-rdb-hw-04;
notebook у форматі .ipynb з output клітинок;
README.md з джерелом датасету, способом отримання файлів і sample-розміром;
архів ДЗ4_ПІБ.zip у LMS;
CSV-файли у папці data/, якщо вони вкладаються у ліміт репозиторію;
якщо CSV не вкладаються у ліміт репозиторію — стабільне посилання або інструкція отримання через Kaggle / course archive.


Формат оцінювання

Загальна оцінка за домашнє завдання — 100 балів.

Етап	Що оцінюється	Бали
1. Setup і typed-schema Olist	Працююче підключення доpgserver; 6 таблиць Olist завантажено; створено typed-таблиці з PK/FK/CHECK	0–15
2. DML-запити PostgreSQL	INSERT ... RETURNING, ON CONFLICT, UPDATE ... FROM, DELETE ... RETURNING; пояснення idempotency	0–15
3.customer_segments	DDL з identity PK, FK, UNIQUE, CHECK, NOT NULL, DEFAULT; сегментація на рівні customer_unique_id; наповнення через INSERT ... SELECT і upsert	0–15
4. JOIN-запити	Щонайменше 5 запитів: INNER, LEFT, FULL OUTER, SELF, anti-join; формат business-question / SQL / interpretation	0–25
5. GROUP BY, HAVING, агрегати	Щонайменше 3 бізнес-метрики; HAVING у мінімум 2 запитах; один PG-агрегат STRING_AGG / ARRAY_AGG / JSONB_AGG	0–20
6. Set operations, підзапит/window, Reflection	Один set-operation запит; один підзапит / CTE або window function; Reflection 200–250 слів	0–10


Бали зменшуються пропорційно до помилок або відсутніх артефактів відповідно до критеріїв прийняття нижче.



Критерії прийняття

Робота відповідає вимогам, якщо виконано всі наведені нижче умови.

У LMS додано посилання на публічний репозиторій goit-rdb-hw-04 та архів ДЗ4_ПІБ.zip.
Notebook виконується після Restart & Run All без ручного виправлення шляхів або SQL.
Перша секція запускає pgserver і показує версію PostgreSQL.
Olist-дані отримано з Kaggle або курсового архіву відтворюваним способом.
Завантажено raw-таблиці та створено окремі typed-таблиці.
Typed-схема містить ключі й обмеження: PK, FK, CHECK, NOT NULL там, де це доречно.
olist_order_reviews не використовує review_id як безумовний єдиний primary key; є технічний PK або інше безпечне рішення.
Є щонайменше чотири DML-запити з RETURNING, ON CONFLICT, UPDATE ... FROM і DELETE ... RETURNING.
seller_score не множить review score через item-level join; перед агрегацією використано грануляність seller_id × order_id.
Є таблиця olist_customer_dim із customer_unique_id як primary key.
Є таблиця customer_segments з identity PK, FK, UNIQUE, CHECK, NOT NULL і DEFAULT.
customer_segments рахується на рівні customer_unique_id, а не на рівні customer_id.
Є щонайменше 5 JOIN-запитів із покриттям INNER, LEFT, FULL OUTER, SELF і anti-join.
Кожен JOIN-запит оформлено як business-question / SQL / interpretation.
JOIN-запити, які працюють із review score, не множать review через order_items.
Є щонайменше 3 агреговані запити з GROUP BY; у мінімум 2 є HAVING.
Є щонайменше один PostgreSQL-агрегат STRING_AGG, ARRAY_AGG або JSONB_AGG.
Є щонайменше один set-operation запит.
Є один підзапит / CTE або базова window function.
Reflection відповідає на питання про JOIN, DML/DDL-фічі, window functions, data quality, грануляність customer_unique_id і ризик множення review score.


Зверніть увагу. Це завдання побудоване як єдиний наскрізний сценарій роботи з PostgreSQL. Тому для успішного виконання важливо не лише написати окремі SQL-запити, а й побудувати цілісну схему даних, реалізувати DML-операції та сформувати сегментацію покупців.


Робота приймається, якщо загальна оцінка становить не менше 60 балів зі 100 і одночасно наявні:

працездатне підключення до pgserver;
typed-схема Olist із constraints;
коректний seller_score без множення review через item-level join;
customer_segments на рівні customer_unique_id;
DML-запити з PostgreSQL-синтаксисом RETURNING та ON CONFLICT;
JOIN-запити з коректним FULL OUTER JOIN і anti-join.
```