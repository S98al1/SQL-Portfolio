-- table creation and data input

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id VARCHAR(100),
    product_id VARCHAR(100),
    quantity int
);

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id VARCHAR(100),
    order_date date
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    price int
);

insert into customers values ('1', 'betty_smith', 'bettys@gmail.com'),
('2', 'matthew_johnson', 'matthewj@gmail.com'),
('3', 'olly_davidson', 'ollyd@gmail.com'),
('4', 'joanna_parker', 'joannap@outlook.com');

insert into order_items values ('1', 000001, 12121, 5000),
('2', 000002, 12122, 500),
('3', 000003, 12123, 1000),
('4', 000004, 12124, 4000);

insert into orders values ('1', '001', '2022-03-07'),
('2', '002', '2023-06-22'),
('3', '003', '2024-12-11'),
('4', '004', '2020-03-25');

insert into products values ('1', '500Mb Radio', 400),
('2', '500/1000 Fibre', '2000'),
('3', '1G Fibre', '2500'),
('4', '10G Fibre', '4000');

Select* from customers;

Select* from order_items;

Select* from orders;

Select* from products;
 
 -- churn analysis
 
SELECT
	id,
    customer_id,
    order_date,
CASE 
        WHEN order_date < '2022-05-05'
        THEN 'Churned'
        ELSE 'Active'
    END AS status
    from orders;

-- Total Revenue by Month

SELECT 
	date_format(sale_date, '%M') AS month,
	round(SUM(quantity_sold * unit_price), 2) AS monthly_revenue
FROM sales_data
GROUP BY month
order by monthly_revenue desc;

-- Top 5 Products by Revenue

SELECT 
    product_ID,
    ROUND(SUM(quantity_sold * unit_price), 2) AS total_revenue
FROM sales_data
GROUP BY product_ID
ORDER BY total_revenue DESC
LIMIT 5;