--STEP 1: SETUP DATA

DROP TABLE IF EXISTS superstore_raw;
CREATE TABLE superstore_raw (
    row_id          INTEGER,
    order_id        TEXT,
    order_date      TEXT,
    ship_date       TEXT,
    ship_mode       TEXT,
    customer_id     TEXT,
    customer_name   TEXT,
    segment         TEXT,
    country         TEXT,
    city            TEXT,
    state           TEXT,
    postal_code     TEXT,
    region          TEXT,
    product_id      TEXT,
    category        TEXT,
    sub_category    TEXT,
    product_name    TEXT,
    sales           REAL,
    quantity        INTEGER,
    discount        REAL,
    profit          REAL
);

-- 1.2 Normalized tables built OUT of the raw staging table

DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id     TEXT PRIMARY KEY,
    customer_name   TEXT,
    segment         TEXT
);

DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id      TEXT PRIMARY KEY,
    product_name    TEXT,
    category        TEXT,
    sub_category    TEXT
);

DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    row_id          INTEGER PRIMARY KEY,
    order_id        TEXT,
    order_date      TEXT,
    ship_date       TEXT,
    ship_mode       TEXT,
    customer_id     TEXT,
    product_id      TEXT,
    country         TEXT,
    city            TEXT,
    state           TEXT,
    postal_code     TEXT,
    region          TEXT,
    sales           REAL,
    quantity        INTEGER,
    discount        REAL,
    profit          REAL
);


-- 1.3 Populate the normalized tables using SELECT DISTINCT

INSERT INTO customers (customer_id, customer_name, segment)
SELECT DISTINCT
    customer_id, customer_name, segment
FROM superstore_raw;

INSERT INTO products (product_id, product_name, category, sub_category)
SELECT DISTINCT
    product_id, product_name, category, sub_category
FROM superstore_raw;

INSERT INTO orders (row_id, order_id, order_date, ship_date, ship_mode,
                     customer_id, product_id, country, city, state,
                     postal_code, region, sales, quantity, discount, profit)
SELECT DISTINCT
    row_id, order_id, order_date, ship_date, ship_mode,
    customer_id, product_id, country, city, state, postal_code, region,
    sales, quantity, discount, profit
FROM superstore_raw;


--STEP 2: REQUIRED QUERIES


-- 2.1 Orders where sales > average sales  (SUBQUERY)
SELECT order_id, customer_id, product_id, sales
FROM orders
WHERE sales > (SELECT AVG(sales) FROM orders)
ORDER BY sales DESC;


-- 2.2 Highest sales order for EACH customer  (SUBQUERY)
SELECT o.customer_id, o.order_id, o.sales
FROM orders o
WHERE o.sales = (
    SELECT MAX(o2.sales)
    FROM orders o2
    WHERE o2.customer_id = o.customer_id
)
ORDER BY o.sales DESC;


-- 2.3 Total sales for each customer  (CTE)
WITH customer_totals AS (
    SELECT customer_id, SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT c.customer_name, ct.total_sales
FROM customer_totals ct
JOIN customers c ON c.customer_id = ct.customer_id
ORDER BY ct.total_sales DESC;


-- 2.4 Customers whose total sales are ABOVE AVERAGE  (CTE + SUBQUERY)
WITH customer_totals AS (
    SELECT customer_id, SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT c.customer_name, ct.total_sales
FROM customer_totals ct
JOIN customers c ON c.customer_id = ct.customer_id
WHERE ct.total_sales > (SELECT AVG(total_sales) FROM customer_totals)
ORDER BY ct.total_sales DESC;


-- 2.5 Rank ALL customers by total sales  (WINDOW FUNCTION)
WITH customer_totals AS (
    SELECT customer_id, SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.customer_name,
    ct.total_sales,
    RANK() OVER (ORDER BY ct.total_sales DESC) AS sales_rank
FROM customer_totals ct
JOIN customers c ON c.customer_id = ct.customer_id
ORDER BY sales_rank;


-- 2.6 Row number for each order WITHIN a customer  (WINDOW FUNCTION + PARTITION BY)
SELECT
    customer_id,
    order_id,
    sales,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY sales DESC) AS order_rank_for_customer
FROM orders
ORDER BY customer_id, order_rank_for_customer;


-- 2.7 Top 3 customers by total sales  (WINDOW FUNCTION)
WITH customer_totals AS (
    SELECT customer_id, SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
),
ranked AS (
    SELECT
        c.customer_name,
        ct.total_sales,
        RANK() OVER (ORDER BY ct.total_sales DESC) AS sales_rank
    FROM customer_totals ct
    JOIN customers c ON c.customer_id = ct.customer_id
)
SELECT customer_name, total_sales, sales_rank
FROM ranked
WHERE sales_rank <= 3
ORDER BY sales_rank;


--STEP 3: FINAL COMBINED QUERY
--Customer Name + Total Sales + Rank   (JOIN + CTE + WINDOW FUNCTION)
  

WITH customer_sales AS (
    SELECT
        o.customer_id,
        SUM(o.sales) AS total_sales
    FROM orders o
    GROUP BY o.customer_id
)
SELECT
    c.customer_name                                            AS customer_name,
    ROUND(cs.total_sales, 2)                                   AS total_sales,
    RANK() OVER (ORDER BY cs.total_sales DESC)                 AS rank
FROM customer_sales cs
JOIN customers c ON c.customer_id = cs.customer_id
ORDER BY rank;

--MINI PROJECT: CUSTOMER SALES INSIGHTS

-- 1. Top 5 customers
WITH customer_totals AS (
    SELECT customer_id, SUM(sales) AS total_sales
    FROM orders GROUP BY customer_id
)
SELECT c.customer_name, ct.total_sales
FROM customer_totals ct
JOIN customers c ON c.customer_id = ct.customer_id
ORDER BY ct.total_sales DESC
LIMIT 5;

-- 2. Bottom 5 customers
WITH customer_totals AS (
    SELECT customer_id, SUM(sales) AS total_sales
    FROM orders GROUP BY customer_id
)
SELECT c.customer_name, ct.total_sales
FROM customer_totals ct
JOIN customers c ON c.customer_id = ct.customer_id
ORDER BY ct.total_sales ASC
LIMIT 5;

-- 3. Customers who made only ONE order (one distinct order_id)
SELECT c.customer_name, COUNT(DISTINCT o.order_id) AS order_count
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT o.order_id) = 1;

-- 4. Customers with above-average total sales
WITH customer_totals AS (
    SELECT customer_id, SUM(sales) AS total_sales
    FROM orders GROUP BY customer_id
)
SELECT c.customer_name, ct.total_sales
FROM customer_totals ct
JOIN customers c ON c.customer_id = ct.customer_id
WHERE ct.total_sales > (SELECT AVG(total_sales) FROM customer_totals)
ORDER BY ct.total_sales DESC;

-- 5. Highest order value per customer
SELECT c.customer_name, MAX(o.sales) AS highest_order_value
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY highest_order_value DESC;
