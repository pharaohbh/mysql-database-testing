-- =====================================================
-- 03_test_queries.sql
-- All 25 test cases (DB-001 to DB-025).
-- IMPORTANT: run ONE statement at a time (Ctrl + Enter).
-- Tests marked [EXPECT ERROR] should fail with the given error.
-- Tests marked [CLEANUP] change data: run the cleanup afterwards.
-- =====================================================

USE shop_db;

-- ---------- A. Constraint tests (baseline) ----------

-- DB-001 [EXPECT ERROR 1062] Duplicate email
INSERT INTO customers (full_name, email) VALUES ('Test User', 'andi@mail.com');

-- DB-002 [EXPECT ERROR 1048] NULL in required field
INSERT INTO customers (full_name, email) VALUES (NULL, 'x@mail.com');

-- DB-003 [EXPECT ERROR 3819] Negative price
INSERT INTO products (product_name, price, stock) VALUES ('Bad Product', -100, 5);

-- DB-004 [EXPECT ERROR 3819] Negative stock
INSERT INTO products (product_name, price, stock) VALUES ('Bad Product', 100, -5);

-- DB-005 [EXPECT ERROR 1265] Invalid status
INSERT INTO orders (customer_id, status) VALUES (1, 'unknown');

-- DB-006 [EXPECT ERROR 3819] Zero quantity
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (1, 2, 0, 150000);

-- ---------- B. Referential integrity ----------

-- DB-007 [EXPECT ERROR 1452] Non-existent customer
INSERT INTO orders (customer_id) VALUES (999);

-- DB-008 [EXPECT ERROR 1451] Delete customer that has orders
DELETE FROM customers WHERE customer_id = 1;

-- DB-009 Cascade delete (destructive: restore order 2 afterwards)
SELECT * FROM order_items WHERE order_id = 2;   -- expect 1 row
DELETE FROM orders WHERE order_id = 2;          -- expect 1 row affected
SELECT * FROM order_items WHERE order_id = 2;   -- expect 0 rows
-- [CLEANUP] restore order 2
INSERT INTO orders (order_id, customer_id, status, total_amount) VALUES (2, 2, 'pending', 350000.00);
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (2, 3, 1, 350000.00);

-- ---------- C. Data integrity ----------

-- DB-010 Order total equals sum of items (expect 0 rows)
SELECT o.order_id, o.total_amount, SUM(oi.quantity * oi.unit_price) AS calculated
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
HAVING o.total_amount <> SUM(oi.quantity * oi.unit_price);

-- DB-011 No orphan order items (expect 0 rows)
SELECT oi.* FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- DB-012 No duplicate emails, case-insensitive (expect 0 rows)
SELECT LOWER(email), COUNT(*) FROM customers
GROUP BY LOWER(email) HAVING COUNT(*) > 1;

-- DB-013 Zero-stock products not in pending orders (expect 0 rows)
SELECT p.product_name, p.stock FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE p.stock = 0 AND o.status = 'pending';

-- ---------- D. Functional (CRUD) ----------

-- DB-014 Insert valid customer
INSERT INTO customers (full_name, email, phone) VALUES ('Dewi Lestari', 'dewi@mail.com', '081211112222');
SELECT * FROM customers WHERE email = 'dewi@mail.com';

-- DB-015 Update product price only changes price
UPDATE products SET price = 7500000.00 WHERE product_id = 1;
SELECT * FROM products WHERE product_id = 1;
-- [CLEANUP] restore original price
UPDATE products SET price = 8000000.00 WHERE product_id = 1;

-- DB-016 Select orders by customer
SELECT * FROM orders WHERE customer_id = 1;

-- DB-017 Default values on new order
INSERT INTO orders (customer_id) VALUES (3);
SELECT status, total_amount, order_date FROM orders WHERE customer_id = 3;

-- ---------- E. Transaction ----------

-- DB-018 ROLLBACK restores original stock
START TRANSACTION;
UPDATE products SET stock = stock - 1 WHERE product_id = 1;
SELECT stock FROM products WHERE product_id = 1;   -- expect 9
ROLLBACK;
SELECT stock FROM products WHERE product_id = 1;   -- expect 10

-- ---------- F. Gap-finding tests (these expose design gaps) ----------

-- DB-019 Negative unit_price should be rejected
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (1, 2, 1, -5000);
-- [CLEANUP]
DELETE FROM order_items WHERE unit_price < 0;

-- DB-020 Negative total_amount should be rejected
INSERT INTO orders (customer_id, total_amount) VALUES (1, -100000);
-- [CLEANUP]
DELETE FROM orders WHERE total_amount < 0;

-- DB-021 Invalid email format should be rejected
INSERT INTO customers (full_name, email) VALUES ('Bad Email', 'not-an-email');
-- [CLEANUP]
DELETE FROM customers WHERE email = 'not-an-email';

-- DB-022 Letters in phone number should be rejected
INSERT INTO customers (full_name, email, phone) VALUES ('Phone Test', 'p@mail.com', 'abc-xyz');
-- [CLEANUP]
DELETE FROM customers WHERE email = 'p@mail.com';

-- DB-023 Order total should stay consistent after adding an item
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (1, 3, 1, 350000.00);
SELECT o.order_id, o.total_amount, SUM(oi.quantity * oi.unit_price) AS calculated
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
HAVING o.total_amount <> SUM(oi.quantity * oi.unit_price);
-- [CLEANUP]
DELETE FROM order_items WHERE order_id = 1 AND product_id = 3;

-- DB-024 Stock should decrease when an order item is placed
SELECT stock FROM products WHERE product_id = 2;   -- note value (50)
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (1, 2, 2, 150000.00);
SELECT stock FROM products WHERE product_id = 2;
-- [CLEANUP]
DELETE FROM order_items WHERE order_id = 1 AND product_id = 2 AND quantity = 2;

-- DB-025 unit_price should match the product's price
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES (1, 2, 1, 1.00);
-- [CLEANUP]
DELETE FROM order_items WHERE unit_price = 1.00;
