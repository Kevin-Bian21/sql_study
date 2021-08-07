-- =========第二章：查询语句=========
use sql_store;
select *
from order_items
where order_id = 6 and quantity * unit_price > 30 ;

select *
from customers
-- where state = 'VA' or state = 'FL' or state = 'GA'
where state  in ('VA','FL','GA' ) ;  # IN运算符简化查询条件

SELECT *
FROM products
WHERE quantity_in_stock IN (49,38,72) ;

SELECT *
FROM customers
-- WHERE points >= 1000 AND points <= 3000
WHERE points BETWEEN 1000 AND 3000;  # BETWEEN 运算符

SELECT *
FROM customers
WHERE birth_date BETWEEN '1990-01-01' AND '2000-01-01';

SELECT *
FROM customers
WHERE last_name LIKE '%b%' OR '_a';
-- LIKE运算符   %b%:匹配含有b/B的last_name  %:代表该处占任意数量的字符
-- _a:只有两个字符，第一个随意，但第二个必须是字符a/A，_:表示该处只占一个字符

SELECT *
FROM customers
WHERE last_name REGEXP '^b|D$|caff|[gim]e|a[a-h]';
-- REGEXP正则表达式 ^b(以b/B开头)，d$以d/D结尾 |:或者含有caff字符串 或者[gim]e :含有ge或ie或me

SELECT *
FROM customers
WHERE phone IS NULL ;
-- IS NULL 查询customers表中电话号码为空的客户


SELECT *
FROM customers
ORDER BY first_name DESC ;
-- ORDER BY:排序 DESC:降序

SELECT * ,quantity * unit_price AS total_price
FROM order_items
WHERE order_id = 2
ORDER BY total_price DESC;
-- 查询order_items表中order_id为2的数据，且将查出的数据根据总价进行降序排序

SELECT *
FROM customers
LIMIT 6,3 ;
-- LIMIT A,B :A偏移量，B读取数据量，这里为跳过前六条数据，然后获取三条记录，即7-9


-- =========第三章：连接=========
SELECT *
FROM customers
ORDER BY points DESC
LIMIT 3 ;
-- 查询积分最多的前三个客户信息

SELECT order_id,o.customer_id,first_name,last_name
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id;
-- INNER JOIN 表 on 条件 ：通过该条件将同一个数据库中的表与表进行连接
-- 由于orders表和customers表中都有customer_id列 所以这里需要指明是哪个表里的customer_id：o.customer_id
-- 否则会报该错误 Column 'customer_id' in field list is ambiguous
-- orders o ，customers c 给表起别名简化代码


SELECT *
FROM db_bills.billtype b
JOIN customers c
    ON b.id = c.customer_id ;
-- JOIN默认为INNER JOIN
-- 不同数据库之间表连接，只需要给不再当前数据库的表加数据库前缀：db_bills.billtype

SELECT
    oi.order_id,
    oi2.order_id,
    oi.product_id,
    oi2.unit_price
FROM order_items oi
JOIN order_items oi2 ON oi.order_id = oi2.order_id;
-- 自连接：同一张表进行连接，需要起不同别名

SELECT  *
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_statuses os
    ON o.status = os.order_status_id ;
-- 多表连接

SELECT *
FROM order_items oi
JOIN order_item_notes oin
    ON oi.order_id = oin.order_Id
    AND oi.product_id = oin.product_id;
-- 复合连接，通过复合主键来唯一表示一条记录
-- 复合主键：表中有超过一个主键

SELECT *
FROM orders o
JOIN customers c on c.customer_id = o.customer_id ;
-- 这两条sql相等，上面是显示连接，下面是隐式连接语法
SELECT *
FROM orders o ,customers c
WHERE o.customer_id = c.customer_id;

SELECT c.customer_id,c.first_name,o.order_id
FROM  customers c
LEFT OUTER JOIN orders o
    ON c.customer_id = o.customer_id ;
-- 外连接，LEFT/RIGHT OUTER JOIN 左外连接返回第一张表即customers表和查询条件所得到的结果，RIGHT返回第二张表和查询条件返回的结果，OUTER可以省略

USE `sql_hr` ;
SELECT e.employee_id,e.first_name,m.first_name AS manager
FROM employees e
LEFT JOIN employees m
    ON e.reports_to = m.employee_id ;
-- 外自连接

use sql_store;
SELECT p.product_id,name,quantity
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id ;

SELECT c.customer_id,o.order_id,c.first_name,s.name AS shipper
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
LEFT JOIN shippers s
    ON o.shipper_id = s.shipper_id
ORDER BY  c.customer_id ;
-- 多表外连接

-- 该条sql与上面的sql功能完全相同
SELECT c.customer_id,o.order_id,c.first_name,s.name AS shipper
FROM customers c
LEFT JOIN orders o
    USING (customer_id)  -- ON c.customer_id = o.customer_id
LEFT JOIN shippers s
    USING (shipper_id)   -- ON o.shipper_id = s.shipper_id
ORDER BY  c.customer_id ;
-- USING 关键字只能用在不同表中列名完全一样的场景中，简化代码

SELECT *
FROM orders o
NATURAL JOIN customers c ;
-- 自然连接，让数据库引擎自己看着办，基于共同的列（有相同名称的列），不推荐使用

SELECT *
FROM customers c
CROSS JOIN  products p;
-- 交叉连接，笛卡尔积的形式，基本不会用到
SELECT *
FROM customers c,products p;
-- 交叉连接隐式语法

SELECT *,'Active' AS status
FROM orders
WHERE order_date >= '2019-01-01'
UNION
SELECT *,'Archived'
FROM orders
WHERE order_date < '2019-01-01';
-- UNION合并多段sql查询记录，列名基于第一段sql，这里各个sql语句查询出的列的数量需要相同，否则会报如下错误
-- The used SELECT statements have a different number of columns


-- =======第四章：列属性=========
use sql_store;
INSERT INTO customers
VALUES (DEFAULT,'Kevin','Bian','1999-09-09',DEFAULT,'Address','XI\'AN','SX',DEFAULT);
-- 插入一行数据，第一种写法，未指明对应的列名，所以在填值的时候要和表列的数量和列的顺序保持一致。
INSERT INTO customers(FIRST_NAME, LAST_NAME, BIRTH_DATE, ADDRESS, CITY, STATE)
VALUES ('Smith','John','1990-01-01','address','city','CA') ;
-- 这种插入方式我们可以调换插入列的顺序，只需要值和上面列的列顺序对应即可，还可以省略一些列，MySQL会自动添上默认值

INSERT INTO products
VALUES (DEFAULT,'test',66,3.36),
       (DEFAULT,'test',33,3.26),
       (DEFAULT,'test',11,3.16) ;
-- 插入多行数据

INSERT INTO orders(customer_id,order_date,status)
values (1,'2021-05-23',3);
INSERT INTO order_items
VALUES (LAST_INSERT_ID(),1,2,3.33),
       (LAST_INSERT_ID(),3,2,3.33);
-- SELECT LAST_INSERT_ID()
-- 多表插入，通过LAST_INSERT_ID来获取最后一次插入的id值，从而用该id值往对应的表中插入相应数据
-- 这里是往订单表中插入记录，通过LAST_INSERT_ID获取最后一次插入的id值，即我们插入的order_id主键值，通过该order_id值在对应的order_items表中添加该order_id的具体信息
-- orders表中有order_id，customer_id等等，每个order_id在order_items表中都有对应的具体信息：产品id，数量，和单价

CREATE TABLE order_archived AS
    SELECT *FROM orders;
-- 创建一张和orders具有相同数据的表，即表的复制，注：这样的copy出的表将不会具有原表的一些列的属性，如主键，自增等等。

use `sql_store`;
INSERT INTO order_archived
SELECT *
FROM orders
WHERE order_date < '2019-01-01';
-- Truncate截断表（将数据删除），然后这里我们想往order_archived复制 orders表中order_date < '2019-01-01'的数据
-- 使用SELECT语句作为INSERT语句的子查询

USE `sql_invoicing` ;
CREATE TABLE   invoices_archived AS
    SELECT invoice_id,number,name AS client ,invoice_total,invoice_date,due_date,payment_date,phone
    FROM invoices i
    JOIN clients c ON i.client_id = c.client_id
    WHERE payment_date IS NOT NULL ;
-- 创建一张表，表的数据来源来自invoice表和clients表，且创建出的表中不想要客户id而将其替换为客户姓名，并且只要支付完成的订单。

UPDATE invoices
SET payment_total=8.88 , payment_date='2021-05-23'
WHERE invoice_id = 1 ;
-- 更新一行数据

USE `sql_store`;
UPDATE customers
SET points=points+50
WHERE birth_date <'1990-01-01';
-- 更新一堆符合条件的数据

use `sql_invoicing`;
UPDATE invoices
SET payment_total=8.88 , payment_date='2021-05-23'
WHERE client_id = (SELECT client_id
                   FROM clients
                   WHERE name = 'Vinte') ;
-- 更新子查询，假设我们只知道客户名字，为了在invoices表中更新相应数据，我们首先要到clients表中查找这个客户名字对应的id，所以我们需要进行子查询
UPDATE invoices
SET payment_total=8.88 , payment_date='2021-05-23'
WHERE client_id IN (SELECT client_id
                   FROM clients
                   WHERE state IN ('CA','NY')) ;
-- 当需要更改子查询出来的多条记录时，就不能在使用=，而是要用IN关键字。

use sql_store;
UPDATE orders
SET comments = 'gold'
WHERE customer_id IN (
    SELECT customer_id
    FROM customers
    WHERE points > 3000
    );
-- 练习，将顾客积分超过3000且下过订单的备注改为gold，查询出来符合条件的顾客有多位，所以使用IN关键字

DELETE FROM customers
WHERE customer_id = 13;
-- 删除customer_id = 13的客户

