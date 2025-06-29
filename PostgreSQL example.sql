CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id int,
    order_date date
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    price int
);

CREATE TABLE order_items (
    order_id INT REFERENCES orders(id) ON DELETE CASCADE,
    product_id INT REFERENCES products(id),
    quantity INT NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_id, product_id)
);

insert into customers values 
('1', 'alice_roberts', 'alice@example.com'),
('2', 'brian_martin', 'brianm@example.com'),
('3', 'carla_hernandez', 'carla_h@domain.com'),
('4', 'daniel_smith', 'daniels@gmail.com'),
('5', 'emma_jones', 'emma.jones@outlook.com'),
('6', 'fred_wilson', 'fwilson@yahoo.com'),
('7', 'gina_lee', 'gina.lee@mail.com'),
('8', 'harry_clark', 'hclark@gmail.com');

insert into orders values
(1, 1, '2023-04-15'),
(2, 1, '2024-01-09'),
(3, 2, '2022-11-20'),
(4, 3, '2025-05-02'),
(5, 4, '2025-06-15'),
(6, 5, '2024-12-12'),
(7, 6, '2023-07-19'),
(8, 7, '2024-02-28'),
(9, 8, '2025-06-10');

insert into products values 
(1, 'Basic 100Mb Fibre', 1000),
(2, '500Mb Radio', 400),
(3, '1G Business Fibre', 2500),
(4, '10G Data Link', 4000),
(5, 'Managed Router', 800),
(6, 'VoIP Seat', 150),
(7, 'Cloud Backup', 200),
(8, 'Firewall Service', 1200);

INSERT INTO order_items (order_id, product_id, quantity) VALUES
(1, 2, 1),
(1, 6, 2),
(2, 3, 1),
(2, 7, 3),
(3, 1, 1),
(3, 5, 1),
(4, 4, 2),
(4, 8, 1),
(5, 3, 1),
(6, 1, 2),
(6, 6, 5),
(7, 2, 3),
(7, 7, 2),
(8, 4, 1),
(8, 5, 2),
(8, 8, 1);

-- Addding foreign keys

ALTER TABLE orders
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id)
REFERENCES customers(id)
ON DELETE CASCADE;


-- Customer order summary

CREATE OR REPLACE VIEW customer_order_summary AS
SELECT 
    c.id AS customer_id,
    c.name AS customer_name,
    COUNT(DISTINCT o.id) AS total_orders,
    COALESCE(SUM(oi.quantity * p.price), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
LEFT JOIN order_items oi ON o.id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.id
GROUP BY c.id, c.name;

select * from customer_order_summary;

-- Top customers by amount spent

WITH customer_totals AS (
    SELECT 
        c.id, 
        c.name, 
        SUM(oi.quantity * p.price) AS total_spent
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    JOIN order_items oi ON o.id = oi.order_id
    JOIN products p ON oi.product_id = p.id
    GROUP BY c.id
)
SELECT 
    id, 
    name, 
    total_spent,
    RANK() OVER (ORDER BY total_spent DESC) AS rank
FROM customer_totals;

-- update product price and show price change history

CREATE TABLE product_price_history (
    product_id INT,
    old_price INT,
    new_price INT,
    changed_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION log_price_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.price <> OLD.price THEN
        INSERT INTO product_price_history (product_id, old_price, new_price)
        VALUES (OLD.id, OLD.price, NEW.price);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_price_update
AFTER UPDATE ON products
FOR EACH ROW
WHEN (OLD.price IS DISTINCT FROM NEW.price)
EXECUTE FUNCTION log_price_change();

-- Price increases (RPI)

update products
    set price = price * 1.1;

select * from product_price_history;

-- indexes

CREATE INDEX idx_orders_customer_date
ON orders(customer_id, order_date);

CREATE INDEX idx_order_items_product
ON order_items(product_id);


--JSON for generating invoices 

CREATE OR REPLACE FUNCTION get_order_invoice(orderid INT)
RETURNS JSON AS $$
BEGIN
    RETURN (
        SELECT json_build_object(
            'order_id', o.id,
            'order_date', o.order_date,
            'customer', json_build_object(
                'id', c.id,
                'name', c.name,
                'email', c.email
            ),
            'items', json_agg(
                json_build_object(
                    'product_id', p.id,
                    'product_name', p.product_name,
                    'unit_price', p.price,
                    'quantity', oi.quantity,
                    'line_total', oi.quantity * p.price
                )
            )
        )
        FROM orders o
        JOIN customers c ON o.customer_id = c.id
        LEFT JOIN order_items oi ON o.id = oi.order_id
        LEFT JOIN products p ON oi.product_id = p.id
        WHERE o.id = orderid
        GROUP BY o.id, o.order_date, c.id, c.name, c.email
    );
END;
$$ LANGUAGE plpgsql;

SELECT get_order_invoice(1);

--Select and drop statements

select * from customers;

select * from orders;

select * from products;

select * from order_items;

drop table customers cascade;

drop table orders cascade;

drop table order_items cascade;

drop table products cascade;


