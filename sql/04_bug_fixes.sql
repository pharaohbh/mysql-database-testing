-- =====================================================
-- 04_bug_fixes.sql
-- Suggested fixes for the bugs found in DB-019 to DB-025.
-- Run AFTER finishing all tests and capturing evidence,
-- then re-run the failed tests to verify (retest).
-- Make sure the cleanup queries were run first, otherwise
-- ALTER TABLE ... ADD CONSTRAINT fails on leftover bad rows.
-- =====================================================

USE shop_db;

-- BUG-001 (DB-019): negative unit_price accepted
ALTER TABLE order_items
  ADD CONSTRAINT chk_unit_price CHECK (unit_price > 0);

-- BUG-002 (DB-020): negative total_amount accepted
ALTER TABLE orders
  ADD CONSTRAINT chk_total_amount CHECK (total_amount >= 0);

-- BUG-003 (DB-021): invalid email format accepted
-- (simple pattern check; catches obvious mistakes, not a full validator)
ALTER TABLE customers
  ADD CONSTRAINT chk_email_format CHECK (email LIKE '%_@_%._%');

-- BUG-004 (DB-022): non-numeric phone accepted
ALTER TABLE customers
  ADD CONSTRAINT chk_phone CHECK (phone IS NULL OR phone REGEXP '^[0-9+() -]+$');

-- BUG-005 (DB-023): orders.total_amount not updated when item inserted
-- BUG-006 (DB-024): stock not reduced when item inserted
DELIMITER $$

CREATE TRIGGER trg_order_items_after_insert
AFTER INSERT ON order_items
FOR EACH ROW
BEGIN
    UPDATE orders
       SET total_amount = (SELECT SUM(quantity * unit_price)
                           FROM order_items
                           WHERE order_id = NEW.order_id)
     WHERE order_id = NEW.order_id;

    UPDATE products
       SET stock = stock - NEW.quantity
     WHERE product_id = NEW.product_id;
END$$

DELIMITER ;

-- BUG-007 (DB-025): unit_price can differ from the product's price
-- Needs business confirmation (discounts may be intentional), so it is
-- left as an open finding. One option is a BEFORE INSERT trigger that
-- fills unit_price from products.price.
