-- 模拟并发
USE `sql_store`;
START TRANSACTION;
UPDATE customers
SET points = points + 10
WHERE customer_id = 1;
COMMIT;

-- ===读未提交===
START TRANSACTION;
UPDATE customers
SET points = 20
WHERE customer_id = 1;
ROLLBACK;
COMMIT;

-- ===读已提交===
START TRANSACTION;
UPDATE customers
SET points = 30
WHERE customer_id = 1;
COMMIT;

-- ===可重复读===
START TRANSACTION;
UPDATE customers
SET points = 40
WHERE customer_id = 1;
COMMIT;

-- ===序列化===
START TRANSACTION;
UPDATE customers
SET state = 'VA'
WHERE customer_id = 1;
COMMIT;

-- ===死锁===
START TRANSACTION;
UPDATE orders SET status = 1 WHERE order_id = 5;
UPDATE customers SET state = 'VA' WHERE customer_id = '1';
COMMIT;