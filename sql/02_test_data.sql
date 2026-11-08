-- =====================================================
-- 02_test_data.sql
-- Inserts the baseline sample data used by the tests.
-- Run after 01_schema.sql.
-- =====================================================

USE shop_db;

INSERT INTO customers (full_name, email, phone) VALUES
('Andi Pratama', 'andi@mail.com', '081234567890'),
('Siti Rahma',   'siti@mail.com', '081298765432'),
('Budi Santoso', 'budi@mail.com', NULL);

INSERT INTO products (product_name, price, stock) VALUES
('Laptop',   8000000.00, 10),
('Mouse',     150000.00, 50),
('Keyboard',  350000.00, 30),
('Monitor',  2000000.00,  0);

INSERT INTO orders (customer_id, status, total_amount) VALUES
(1, 'paid',    8150000.00),
(2, 'pending',  350000.00);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 8000000.00),
(1, 2, 1,  150000.00),
(2, 3, 1,  350000.00);

-- Sanity check: expect 3 customers, 4 products, 2 orders, 3 order items
SELECT
  (SELECT COUNT(*) FROM customers)   AS customers,
  (SELECT COUNT(*) FROM products)    AS products,
  (SELECT COUNT(*) FROM orders)      AS orders,
  (SELECT COUNT(*) FROM order_items) AS order_items;
