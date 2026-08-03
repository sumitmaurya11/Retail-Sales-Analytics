CREATE DATABASE retail_sales;

USE retail_sales;

CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20)
);

ALTER TABLE customers
ADD COLUMN region VARCHAR(30);

CREATE TABLE products (
    product_id VARCHAR(30) PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category VARCHAR(50),
    sub_category VARCHAR(50)
);

CREATE TABLE orders (
    order_id VARCHAR(30) PRIMARY KEY,
    customer_id VARCHAR(20),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),

    CONSTRAINT fk_customer
    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
);

CREATE TABLE payments (
    payment_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(30),
    payment_method VARCHAR(50),
    payment_status VARCHAR(30),

    CONSTRAINT fk_payment_order
    FOREIGN KEY (order_id)
    REFERENCES orders(order_id)
);

CREATE TABLE shipments (
    shipment_id VARCHAR(20) PRIMARY KEY,
    order_id VARCHAR(30),
    delivery_status VARCHAR(50),
    delivery_partner VARCHAR(50),

    CONSTRAINT fk_shipment_order
    FOREIGN KEY (order_id)
    REFERENCES orders(order_id)
);


CREATE TABLE order_items (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(30),
    product_id VARCHAR(30),
    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(4,2),
    profit DECIMAL(10,2),

    CONSTRAINT fk_order
    FOREIGN KEY (order_id)
    REFERENCES orders(order_id),

    CONSTRAINT fk_product
    FOREIGN KEY (product_id)
    REFERENCES products(product_id)
);


SHOW TABLES;

-- Basic SQL Queries

-- Show all customers
SELECT *
FROM customers;

-- Show all products
SELECT *
FROM products;

-- Show all orders
SELECT *
FROM orders;

-- Show all order_items
SELECT *
FROM order_items;


-- Count total customers
SELECT COUNT(*) AS total_customers
FROM customers;

-- Count total products
SELECT COUNT(*) AS total_products
FROM products;

-- Count total orders
SELECT COUNT(*) AS total_orders
FROM orders;

-- Find all customers from Houston
SELECT *
FROM customers
WHERE city = 'Houston';

-- Show all Furniture products
SELECT *
FROM products
WHERE category = 'Furniture';

-- Find order_items sales more than ₹1000
SELECT *
FROM order_items
WHERE sales > 1000;

-- Display unique cities
SELECT DISTINCT city
FROM customers;

-- Find the highest sale
SELECT MAX(sales) AS highest_sale
FROM order_items;

-- Find the lowest sale
SELECT MIN(sales) AS lowest_sale
FROM order_items;

-- Average sale and round of 2 decimal point
SELECT ROUND(AVG(sales),2) AS average_sale
FROM order_items;

-- Total Revenue and round of 2 decimal point
SELECT ROUND(SUM(sales),2) AS total_revenue
FROM order_items;


-- Total Profit
SELECT ROUND(SUM(profit),2) AS total_profit
FROM order_items;


-- Intermediate Business Questions

-- Revenue by Category
SELECT p.category, ROUND(SUM(oi.sales),2) AS revenue
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Profit by Category
SELECT p.category, ROUND(SUM(oi.profit),2) AS profit
FROM order_items oi
JOIN products p
ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY profit DESC;

-- Top 10 Customers by Revenue
SELECT c.customer_name, ROUND(SUM(oi.sales),2) AS revenue
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY c.customer_name
ORDER BY revenue DESC
LIMIT 10;

-- Top 10 Products by Revenue
SELECT p.product_name, ROUND(SUM(oi.sales),2) AS revenue
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 10;

-- Revenue by Region
SELECT c.region, SUM(oi.sales) AS revenue
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY c.region
ORDER BY revenue DESC;

-- Revenue by State
SELECT c.state, SUM(sales) AS revenue
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY c.state
ORDER BY revenue DESC;

-- Revenue by Ship Mode
SELECT ship_mode, ROUND(SUM(oi.sales),2) AS revenue
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY ship_mode;


-- Revenue by Payment Method
SELECT payment_method, ROUND(SUM(oi.sales),2) AS revenue
FROM payments p
JOIN order_items oi
ON p.order_id = oi.order_id
GROUP BY payment_method;

-- Completed vs Pending Payments
SELECT payment_status, COUNT(*) AS total_orders
FROM payments
GROUP BY payment_status;

-- Delivery Performance
SELECT delivery_partner, COUNT(*) AS deliveries
FROM shipments
GROUP BY delivery_partner
ORDER BY deliveries DESC;


-- Rank customers based on the revenue they generated.
SELECT c.customer_id,c.customer_name, SUM(sales) as revenue,
RANK() OVER (ORDER BY SUM(sales) DESC) AS customer_rank
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY c.customer_id,c.customer_name;

-- Top 3 Customers by Revenue
SELECT c.customer_name, SUM(oi.sales) AS revenue
FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
JOIN order_items oi
ON o.order_id=oi.order_id
GROUP BY c.customer_name
ORDER BY revenue DESC
LIMIT 3;

-- Find the Second Highest Revenue Customer

WITH customer_rank as
(
SELECT c.customer_name, SUM(oi.sales) AS revenue,
DENSE_RANK() OVER (ORDER BY SUM(oi.sales) DESC) rnk
FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
JOIN order_items oi
ON o.order_id=oi.order_id
GROUP BY c.customer_name
)
    
SELECT *
FROM customer_rank
WHERE rnk=2;

-- Revenue Contribution (%) of Each Category
SELECT p.category, SUM(oi.sales) revenue,
(SUM(oi.sales)*100/ (SELECT SUM(sales) FROM order_items)) contribution_percentage
FROM products p
JOIN order_items oi
ON p.product_id=oi.product_id
GROUP BY p.category
ORDER BY revenue DESC;

-- Running Total of Sales
WITH running_sales as 
(
SELECT o.order_date, SUM(oi.sales) as daily_sales
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY order_date
)
SELECT order_date, daily_sales, 
SUM(daily_sales) OVER(ORDER BY order_date) AS running_total
FROM running_sales;

-- Monthly Sales Trend
SELECT YEAR (order_date) year, MONTH (order_date) month, SUM(oi.sales) as revenue
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY YEAR (order_date), MONTH (order_date)
ORDER BY year,month;


-- Best Month of Every Year
WITH monthly_sales AS
(
SELECT YEAR (order_date) year, MONTH (order_date) month, SUM(oi.sales) as revenue
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
GROUP BY YEAR (order_date), MONTH (order_date)
ORDER BY year,month
),
ranking as
(
SELECT *,
RANK() OVER (PARTITION BY year ORDER BY revenue DESC) rnk
FROM monthly_sales
)

SELECT *
FROM ranking
WHERE rnk = 1;

-- Most Profitable Product in Each Category
WITH product_profit AS
(
SELECT product_name, category, SUM(oi.profit) AS profit,
RANK() OVER (PARTITION BY category ORDER BY SUM(oi.profit) DESC) rnk
FROM products p
JOIN order_items oi
ON p.product_id= oi.product_id
GROUP BY p.product_name,p.category
)

SELECT *
FROM product_profit
WHERE rnk = 1;

-- Find Customers Who Have Placed More Than Average Number of Orders

WITH customer_orders AS
(
SELECT customer_id, COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer_id
)
SELECT customer_id, total_orders
FROM customer_orders
WHERE total_orders >
(
SELECT AVG(total_orders)
FROM customer_orders
)
ORDER BY total_orders DESC;


-- Revenue by Shipping Mode
SELECT ship_mode, SUM(sales) AS revenue
FROM orders o
JOIN order_items oi
ON o.order_id=oi.order_id
GROUP BY ship_mode
ORDER BY revenue DESC;

-- Payment Success Rate
SELECT payment_status, COUNT(*) total_transaction, COUNT(*)*100/ (SELECT COUNT(*) FROM payments) transaction_prcnt
FROM payments
GROUP BY payment_status;

-- Top 5 Cities by Revenue
SELECT city, SUM(sales) AS total_sales
FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
JOIN order_items oi
ON oi.order_id=o.order_id
GROUP BY city
ORDER BY total_sales DESC
LIMIT 5;

-- Customer Lifetime Value (CLV)
SELECT c.customer_name, SUM(sales) AS lifetime_value
FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
JOIN order_items oi
ON oi.order_id=o.order_id
GROUP BY customer_name
ORDER BY lifetime_value DESC;

-- Products with Negative Profit
SELECT product_name, SUM(profit) AS total_profit
FROM order_items oi
JOIN products p
ON oi.product_id=p.product_id
GROUP BY product_name
HAVING SUM(oi.profit)<0
ORDER BY total_profit ASC;


-- Top 5 States by Profit
SELECT state, SUM(profit) AS total_profit
FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
JOIN order_items oi
ON oi.order_id=o.order_id
GROUP BY state
ORDER BY total_profit DESC
LIMIT 5;

-- Top Product in Every Category
WITH products_sales AS 
(
SELECT category, product_name, SUM(oi.sales) AS total_sales,
ROW_NUMBER() OVER (PARTITION BY p.category ORDER BY SUM(oi.sales) DESC) rnk
FROM products p
JOIN order_items oi
ON p.product_id=oi.product_id
GROUP BY p.category,p.product_name
)

SELECT *
FROM products_sales
WHERE rnk=1;

-- Find Duplicate Customer Names
SELECT customer_name, COUNT(*) AS customr_count
FROM customers
GROUP BY customer_name
HAVING COUNT(*)>1;

-- Orders with Multiple Products
SELECT order_id, COUNT(product_id) AS total_products
FROM order_items
GROUP BY order_id
HAVING COUNT(product_id) > 1
ORDER BY total_products DESC;

-- Highest Discount by Category
SELECT category, MAX(oi.discount) AS max_discount
FROM products p
JOIN order_items oi
ON p.product_id=oi.product_id
GROUP BY category
ORDER BY max_discount DESC;

-- Average Profit Margin by Category

SELECT category, ((SUM(oi.profit)/SUM(oi.sales))*100) AS profit_margin_percentage
FROM products p
JOIN order_items oi
ON P.product_id=oi.product_id
GROUP BY p.category;

-- Top 10 Orders by Revenue
SELECT order_id, SUM(sales) AS revenue
FROM order_items
GROUP BY order_id
ORDER BY revenue DESC
LIMIT 10;

-- Monthly Profit Trend
SELECT YEAR(order_date) AS year, MONTH (order_date) AS month, SUM(oi.profit) AS total_profit
FROM orders o
JOIN order_items oi
ON o.order_id=oi.order_id
GROUP BY YEAR(order_date), MONTH (order_date)
ORDER BY year, month;


-- Top 3 Products in Each Category
WITH ranked_products AS
(
SELECT category,product_name, SUM(oi.sales) AS Total_sales,
DENSE_RANK() OVER (PARTITION BY p.category 	ORDER BY SUM(oi.sales) DESC ) rnk
FROM products p
JOIN order_items oi
ON p.product_id=oi.product_id
GROUP BY category, product_name
ORDER BY Total_sales
)

SELECT *
FROM ranked_products
WHERE rnk<=3
ORDER BY rnk ASC;


-- Executive Sales Dashboard Dataset
SELECT c.region, c.segment, p.category, p.sub_category, o.ship_mode, SUM(oi.sales) revenue, SUM(oi.profit) profit, SUM(oi.quantity) quantity
FROM customers c
JOIN orders o
ON c.customer_id=o.customer_id
JOIN order_items oi
ON o.order_id=oi.order_id
JOIN products p
ON oi.product_id=p.product_id
GROUP BY c.region, c.segment, p.category, p.sub_category, o.ship_mode
ORDER BY c.region, c.segment;







