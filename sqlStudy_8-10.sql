-- =======第八章：视图==========

USE `sql_invoicing`;
-- ===创建视图===
CREATE VIEW  sales_by_client AS
SELECT
    client_id,
    name,
    SUM(invoice_total) AS total_sales
FROM clients c
JOIN invoices i USING (client_id)
GROUP BY client_id;
-- 未来很多查询可能基于该查询来写，我们就不需要每次都重写这段查询语句并在每段查询语句上都做一点修改，而是这段查询保存为视图，以供很多地方使用。
-- 视图不存储数据，它是一张虚拟出来的表，如果基础表的内容做出了改表，由其创建的视图的内容也会改变

-- ===删除视图===
DROP VIEW IF EXISTS sales_with_balance;

-- ===创建或替换视图===
CREATE OR REPLACE VIEW  sales_by_client AS
SELECT
    client_id,
    name,
    SUM(invoice_total) AS total_sales
FROM clients c
JOIN invoices i USING (client_id)
GROUP BY client_id;
-- 如果视图不存在就创建，如果视图存在就替换掉

-- ===可更新视图===
-- 如果视图中没有DISTINCT、聚合函数、GROUP　BY、HAVING、UNION等，则我们的视图是可更新的。
CREATE OR REPLACE VIEW sales_with_balance AS
SELECT *,invoice_total - payment_total AS balance
FROM invoices;
DELETE FROM sales_with_balance
WHERE payment_total = 0;
-- 有时处于安全原因，我们没有权限修改基础表，所以我们想要修改数据的话只能通过视图，但前提是我们的视图是可更新的。

-- ===WITH CHECK OPTION子句===
CREATE OR REPLACE VIEW sales_with_balance AS
SELECT *,invoice_total - payment_total AS balance
FROM invoices
WHERE (invoice_total - payment_total) > 0
WITH CHECK OPTION ;
-- 有时不想让视图的数据通过更新或删除语句删掉的话，可以加上WITH CHECK OPTION
UPDATE sales_with_balance
SET payment_total = invoice_total
WHERE invoice_id = 1;
-- 例如更新数据会使invoice_id=1的行消失，所以会报错，错误如下：
-- CHECK OPTION failed 'sql_invoicing.sales_with_balance'


-- =======第九章：存储过程==========

-- 存储过程是一个包含一堆SQL代码的数据库对象。
-- 优点：在我们的应用代码中，通过使用存储过程来存储和管理SQL代码，更快捷的执行，保证数据安全
DELIMITER $$
CREATE PROCEDURE get_invoices_with_balance()
BEGIN
    SELECT *
    FROM sales_with_balance
    WHERE balance > 0;
END $$
DELIMITER ;
-- 更改默认分隔符是为了在存储过程中使用“;”分号
-- 因为sql语句结束默认的分隔符为“;”所以为了避免SQL语法错误，需要设置$$作为新的语句结束分隔符，最后在使用DELIMITER改回来

CALL get_invoices_with_balance();
-- 调用存储过程

DROP PROCEDURE IF EXISTS get_invoices_with_balance;
-- 删除存储过程

CREATE PROCEDURE get_invoices_by_client(client_id VARCHAR(10))
BEGIN
    SELECT *
    FROM invoices i
    WHERE client_id = i.client_id;
END;
-- 带参数的存储过程，通过传入client_id来返回该客户对应的发票
CALL get_invoices_by_client('1');

-- ======默认参数=========
DROP PROCEDURE IF EXISTS get_client_by_state;
CREATE PROCEDURE get_client_by_state
(
    state varchar(10)
)
BEGIN
    IF state IS NULL THEN
        SELECT * FROM clients;
    ELSE
        SELECT * FROM clients c
        WHERE c.state = state;
    END IF;
END;
CALL get_client_by_state('CA');
-- 如果输入空值则返回所有客户，否则返回对应州的客户

DROP PROCEDURE IF EXISTS get_clients_by_state;
DELIMITER $$
CREATE PROCEDURE get_clients_by_state
    (
        state varchar(10)
    )
BEGIN
    SELECT * FROM clients c
    WHERE c.state = IFNULL(state,c.state);
END $$
DELIMITER ;
-- 优化上一个存储过程，IFNULL(state,c.state)，如果state为空，则该函数返回第二个值。

CALL get_clients_by_state(NULL);

DROP PROCEDURE IF EXISTS get_payments;
DELIMITER $$
CREATE PROCEDURE get_payments
    (
        client_id INT,
        payment_method_id TINYINT
    )
BEGIN
    SELECT * FROM  payments p
    JOIN payment_methods pm ON p.payment_method = pm.payment_method_id
    WHERE
        p.client_id = IFNULL(client_id ,p.client_id) AND
        p.payment_method = IFNULL(payment_method_id,p.payment_method);
END $$
DELIMITER ;
-- 有两个参数client_id和payment_method_id如果两个都为空值则返回全部的付款，
-- 如果client_id不为空则返回对应客户的所有付款，如果client_id为空，payment_method_id不为空则返回该付款方式对应的所有付款
-- 如果两者都不为空，则返回该客户所用的付款方式对应的所有付款
CALL get_payments(5,NULL);

-- =====参数验证====
DROP PROCEDURE IF EXISTS make_payment;
CREATE PROCEDURE make_payment
    (
        invoice_id  INT,
        payment_total DECIMAL(9,2),
        payment_date  DATE
    )
BEGIN
    IF payment_total <= 0 THEN
        SIGNAL SQLSTATE '22003'
        SET MESSAGE_TEXT = '输入的金额无效';
    END IF;
    UPDATE invoices i
    SET i.payment_total = payment_total ,
        i.payment_date = payment_date
    WHERE i.invoice_id = invoice_id ;
END ;
-- DECIMAL(9,2):9是定点精度，2是小数位数。
-- SIGNAL SQLSTATE '22003' :使用SIGNAL 语句从存储的程序（例如存储过程，存储函数，  触发器或事件）向调用者返回错误或警告条件；如果输入的是负数则引发异常，并显示SQLSTATE '22003'的错误消息：Data truncation
-- SET MESSAGE_TEXT = '输入的金额无效';  设置错误描述信息
CALL make_payment(2,-100,'2019-01-01');
-- 报该错：Data truncation: 输入的金额无效

-- ====输出参数======
DROP PROCEDURE IF EXISTS get_unpaid_invoices_for_client;
CREATE PROCEDURE get_unpaid_invoices_for_client
    (
        client_id INT,
        OUT invoices_count INT,
        OUT invoices_total DECIMAL(9,2)
    )
BEGIN
    SELECT
           COUNT(*),
           SUM(invoice_total)
    INTO invoices_count,invoices_total
    FROM invoices i
    WHERE i.client_id = client_id AND payment_total = 0;
end;
-- 调用
set @invoices_count = 0;
set @invoices_total = 0;
call get_unpaid_invoices_for_client(3,@invoices_count,@invoices_total);
select @invoices_count,@invoices_total;
-- 只要建立会话，变量就一直存在
-- 不建议使用

-- =======本地变量=========
DROP PROCEDURE IF EXISTS get_risk_factor;
CREATE PROCEDURE get_risk_factor()
BEGIN
    DECLARE risk_factor DECIMAL(9,2) DEFAULT 0;
    DECLARE invoices_total DECIMAL(9,2);
    DECLARE invoices_count INT;

    SELECT COUNT(*) ,SUM(invoices_total)
    INTO invoices_count,invoices_total
    FROM invoices;

    SET risk_factor = invoices_total / invoices_count * 5;

    SELECT risk_factor;
end;
--  DECLARE:声明变量
-- 本地变量是我们在存储过程或函数内定义的，这些变量只在在客户端会话过程中被保存，一旦存储过程完成执行任务，这些变量就会被清空
CALL get_risk_factor();

-- ======创建自己的函数======
-- 函数和存储过程较为相似，主要区别是函数只能返回单一值
DROP FUNCTION IF EXISTS get_risk_factor_for_client;
CREATE FUNCTION get_risk_factor_for_client
    (
        client_id INT
    )
RETURNS INTEGER  --明确函数返回值的类型。
-- 设置函数的属性，每个MySQL至少要具有一个属性
READS SQL DATA
BEGIN
    DECLARE risk_factor DECIMAL(9,2) DEFAULT 0;
    DECLARE invoices_total DECIMAL(9,2);
    DECLARE invoices_count INT;

    SELECT COUNT(*) ,SUM(invoices_total)
    INTO invoices_count,invoices_total
    FROM invoices i
    WHERE i.client_id = client_id;

    SET risk_factor = invoices_total / invoices_count * 5;

    RETURN  IFNULL(risk_factor,0); -- 返回我们要的值
end;
-- 函数属性：
-- DETERMINISTIC （确定性）：如果我们给予这个函数同样的一组值，则它永远返回一样的值
-- READS SQL DATA （读取SQL数据）：函数中会配置选择语句，用以读取一些数据
-- MODIFIES SQL DATA (修改SQL数据) ：函数中有插入、更新或者删除函数

-- 调用函数，和MySQL内置函数一样
SELECT
       client_id,
       name,
       get_risk_factor_for_client(client_id) AS risk_factor
FROM clients ;
-- 小提示：可以加上proc前缀来命名存储过程，加上fn前缀来表示函数


-- ===========第十章：触发器===========
DROP TRIGGER IF EXISTS payment_after_insert;
DELIMITER $$
CREATE TRIGGER payment_after_insert
    AFTER INSERT ON payments
    FOR EACH ROW
BEGIN
    UPDATE invoices
    SET payment_total = payment_total + NEW.amount
    WHERE invoice_id = NEW.invoice_id;
end $$
DELIMITER ;
-- 我们在付款表中插入数据后会触发触发器，触发器去执行我们配置的SQL代码
INSERT INTO payments
VALUES (default,3,11,CURDATE(),10,2);
-- 触发器是在插入、更新和删除语句前后自动执行的一堆SQL代码，来增强数据一致性。

DROP TRIGGER IF EXISTS payment_after_delete;
CREATE TRIGGER payment_after_delete
    AFTER DELETE ON payments
    FOR EACH ROW
BEGIN
    UPDATE invoices
    SET payment_total = payment_total - OLD.amount
    WHERE invoice_id = OLD.invoice_id;
end;
-- 练习
DELETE
FROM payments
WHERE payment_id = 10;

-- ====查看触发器======
SHOW TRIGGERS ;
-- 全部的触发器
SHOW TRIGGERS LIKE 'PAYMENTS%' ;
-- 查看返回名称中是payments开头的触发器


-- =====使用触发器进行审计======
DROP TABLE IF EXISTS payments_audit;
CREATE TABLE payments_audit
    (
        client_id INT,
        date DATE,
        amount DECIMAL(9,2),
        action_type varchar(50),
        action_date datetime
)engine = INNODB default charset = utf8;
-- 创建一个表用来记录被更改的数据

-- 在我们原来触发器的基础上加入记录数据变化的SQL
DROP TRIGGER IF EXISTS payment_after_insert;
DELIMITER $$
CREATE TRIGGER payment_after_insert
    AFTER INSERT ON payments
    FOR EACH ROW
BEGIN
    UPDATE invoices
    SET payment_total = payment_total + NEW.amount
    WHERE invoice_id = NEW.invoice_id;

    INSERT INTO payments_audit
    VALUES (NEW.client_id,NEW.date,NEW.amount,'Insert',NOW());
end $$
DELIMITER ;

DROP TRIGGER IF EXISTS payment_after_delete;
CREATE TRIGGER payment_after_delete
    AFTER DELETE ON payments
    FOR EACH ROW
BEGIN
    UPDATE invoices
    SET payment_total = payment_total - OLD.amount
    WHERE invoice_id = OLD.invoice_id;

    INSERT INTO payments_audit
    VALUES (OLD.client_id,OLD.date,OLD.amount,'Delete',NOW());
end;

-- =====事件======
SHOW VARIABLES LIKE 'EVENT%';  -- 查询MySql系统变量
SET GLOBAL EVENT_SCHEDULER = ON;  -- 开启事件调度器

DROP EVENT IF EXISTS yearly_delete_stale_audit_rows;
CREATE EVENT yearly_delete_stale_audit_rows
ON SCHEDULE
-- 接下来提供事件执行的计划，你想多久执行这个任务，执行一次还是定期执行
--    AT '2020-06-01' -- 只执行一次用AT，只在2020-06-01这天执行一次
    EVERY 1 YEAR STARTS '2019-01-01' ENDS '2025-01-01'   -- 执行多次,在该日期内每年都执行一次
DO BEGIN
    DELETE FROM payments_audit
    WHERE action_date < NOW() - INTERVAL 1 YEAR ;
end;
-- 将审计表中记录的数据超过一年的进行删除。

SHOW EVENTS;
-- 修改事件
ALTER EVENT yearly_delete_stale_audit_rows
-- DISABLE   -- 关闭该事件
ENABLE ; -- 开启该事件

