-- PROJECT INSTACART ANALYSIS

/*CREATE TABLE orders (
	order_id INT,
	user_id INT,
	eval_set TEXT,
	order_number INT,
	order_dow INT,
	order_hour_of_day INT,
	days_since_prior_order FLOAT
);

CREATE TABLE order_products_prior (
	order_id INT,
	product_id INT,
	add_to_cart_order INT,
	reordered INT
);

CREATE TABLE products (
	product_id INT,
	product_name TEXT,
	aisle_id INT,
	department_id INT
);

CREATE TABLE aisles (
	aisle_id INT,
	aisle TEXT
);

CREATE TABLE departments (
	department_id INT,
	department TEXT
);*/

-- REMARKS: order_dow: 0 is Sunday, 1 is Monday, ... , 7 is Saturday

SELECT
	COUNT(*)
FROM
	ORDERS;

SELECT
	COUNT(*)
FROM
	ORDER_PRODUCTS_PRIOR;

SELECT
	COUNT(DISTINCT USER_ID)
FROM
	ORDERS;

-- Most popular day of grocery:

SELECT
	ORDER_DOW,
	COUNT(*) AS TOTAL_ORDERS
FROM
	ORDERS
GROUP BY
	ORDER_DOW
ORDER BY
	ORDER_DOW;
-- Insights: Day 0 (Sunday) has the most amount of orders, with 600K orders placed. 
-- This suggests that customers like to stock up in groceries at the start of the week.

-- Most popular time of grocery:

SELECT
	ORDER_HOUR_OF_DAY,
	COUNT(*) AS TOTAL_ORDERS
FROM
	ORDERS
GROUP BY
	ORDER_HOUR_OF_DAY
ORDER BY
	ORDER_HOUR_OF_DAY;

-- Insights: 10 am is usually the busiest time, with over 288K orders placed.
-- This suggests that customers like to stock up groceries at an early time.

-- What are the most frequently ordered grocery products?
SELECT
	P.PRODUCT_NAME,
	COUNT(*) AS TIMES_ORDERED
FROM
	ORDER_PRODUCTS_PRIOR OP
	JOIN PRODUCTS P ON OP.PRODUCT_ID = P.PRODUCT_ID
GROUP BY
	P.PRODUCT_NAME
ORDER BY
	TIMES_ORDERED DESC
LIMIT 
	10;

-- Bananas are the most frequently ordered grocery product, being a staple for the company. Could be due to low cost.

-- How many items are in the average order?
-- To break this down, we will answer this first: how many items are in each order?
SELECT
	order_id,
	COUNT(product_id) AS product_count
FROM
	order_products_prior
GROUP BY
	order_id;
-- Now we have the product count for each order ID. From here, we can look at the average of these product counts:
SELECT
	ROUND(AVG(product_count), 2) AS order_sizes
FROM
	(
		SELECT
			order_id,
			COUNT(product_id) AS product_count
		FROM
			order_products_prior
		GROUP BY
			order_id
	);
-- So, in the average order, there are about 10 products. This suggests that Instacart is for quick restock rather than full grocery hauls.


-- Next, how often are customers buying products they have purchased before?
-- 1 means product was reordered
-- 0 means its a first time purchase
SELECT
	ROUND(AVG(reordered), 2) AS reorder_rate
FROM
	order_products_prior;

-- This query says that the reorder rate is about 59%. This could be driven by repeat purchases of staple items such as Bananas.

-- Now, what grocery department drives the MOST orders?
SELECT
	d.department,
	COUNT(*) AS total_orders
FROM
	order_products_prior op
	JOIN products p ON op.product_id = p.product_id
	JOIN departments d ON p.department_id = d.department_id
GROUP BY
	d.department
ORDER BY
	total_orders DESC;

-- Based on this query, the product deparment drives the most orders by a significant amount. 
-- This is Instacart's biggest revenue generator, followed by dairy eggs.

-- Analysis Base Table:
CREATE TABLE instacart_analytics_base AS
SELECT
	O.order_id,
	O.user_id,
	O.order_dow,
	O.order_hour_of_day,
	OP.product_id,
	OP.reordered,
	P.product_name,
	D.department,
	A.aisle
FROM
	orders O
	JOIN order_products_prior OP ON O.order_id = OP.order_id
	JOIN products P ON OP.product_id = P.product_id
	JOIN departments D ON P.department_id = D.department_id
	JOIN aisles A ON P.aisle_id = A.aisle_id;


SELECT 
	COUNT(*)
FROM
	instacart_analytics_base;


-- Customer Behaviour Analysis:

-- How many orders does the average customer place on Instacart?
SELECT
	*
FROM
	instacart_analytics_base;

-- First we look at number of orders per customer, then we tackle the average (Subquery)

SELECT
	ROUND(AVG(orders), 2) AS avg_orders
FROM 
	(
		SELECT
			user_id,
			COUNT(DISTINCT order_id) AS orders
		FROM
			instacart_analytics_base
		GROUP BY
			user_id
	);
-- From this, we can see that the average orders customers place on Instacart are around 15-16 orders.
-- Combining this with a high reorder rate suggests that customers use Instacart frequently as a recurring platform.

-- Which products are most frequently reordered?
SELECT
	product_name,
	COUNT(*) AS times_reordered
FROM
	instacart_analytics_base
WHERE
	reordered = 1
GROUP BY
	product_name
ORDER BY
	times_reordered DESC
LIMIT
	10;

-- Bananas are the most frequently reordered item, with nearly 400k repeat purchases.

-- Which product categories customers return to the most?
SELECT
	department,
	COUNT(*) AS reorder_count
FROM
	instacart_analytics_base
WHERE
	reordered = 1
GROUP BY
	department
ORDER BY
	reorder_count DESC;

-- The top 3 product categories customers return to are produce, dairy eggs, and beverages.


-- Creating Datasets for Excel Analysis:
-- Dataset 1: When do customers place orders?

SELECT
	order_dow,
	order_hour_of_day,
	COUNT(DISTINCT order_id) AS total_orders
FROM
	instacart_analytics_base
GROUP BY
	order_dow,
	order_hour_of_day;

-- Dataset 2: Which departments drive the most demand?

SELECT
	department,
	COUNT(*) AS total_orders,
	SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END) AS reorder_count
FROM
	instacart_analytics_base
GROUP BY
	department
ORDER BY
	total_orders DESC;


-- Dataset 3: Which individual products drive demand?

SELECT
	product_name,
	COUNT(*) AS total_orders,
	SUM(CASE WHEN reordered = 1 THEN 1 ELSE 0 END) AS reorder_count
FROM
	instacart_analytics_base
GROUP BY
	product_name
ORDER BY
	total_orders DESC
LIMIT
	100;