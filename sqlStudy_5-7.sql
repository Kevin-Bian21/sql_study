-- ======第五章：聚合函数=======
USE `sql_invoicing`;
SELECT
       MAX(invoice_total) AS highest,
       MIN(invoice_total) AS lowest,
       AVG(invoice_total) AS average,
       SUM(invoice_total) AS total,
       COUNT(invoice_total) AS numbers_of_invoices,
       COUNT(payment_date) AS count_of_payments,
       COUNT(DISTINCT  client_id) AS total_records,
       COUNT(*)  AS total_records
FROM invoices;
-- 聚合函数只运行非空值,要统计所有情况（包括空值），使用*号,DISTINCT去重

SELECT
       'First half of 2019' AS date_range,
       SUM(invoice_total) AS total_sales,
       SUM(payment_total) AS total_payments,
       SUM(invoice_total)-SUM(payment_total) AS what_we_expect
FROM invoices
WHERE invoice_date BETWEEN '2019-01-01' AND '2019-06-30'
UNION
SELECT
       'Second half of 2019',
       SUM(invoice_total),
       SUM(payment_total),
       SUM(invoice_total)-SUM(payment_total)
FROM invoices
WHERE invoice_date BETWEEN '2019-07-01' AND '2019-12-31'
UNION
SELECT
       'Total',
       SUM(invoice_total),
       SUM(payment_total),
       SUM(invoice_total)-SUM(payment_total)
FROM invoices ;
-- 练习题

SELECT
    client_id,
    SUM(invoice_total) AS total_sales
FROM invoices
GROUP BY client_id
ORDER BY total_sales DESC;
-- 根据用户进行分组

SELECT
    date,pm.name AS payment_menthod,SUM(amount) AS total_payments
FROM payments p
JOIN payment_methods pm
    ON p.payment_method = pm.payment_method_id
GROUP BY date ,payment_menthod
ORDER BY date;

SELECT
    client_id,
    SUM(invoice_total) AS total_sales
FROM invoices
GROUP BY client_id
HAVING total_sales > 500 ;
-- HAVING字句，在分组之后筛选数据，而WHERE则是在分组之前筛选数据。
-- 但HAVING子句的条件中用到的列必须是SELECT中选择的的，否则报如下错误
-- Unknown column '列名' in 'having clause'

USE `sql_store`;
SELECT state,first_name,SUM(oi.quantity*oi.unit_price) AS total_cost
FROM customers c
JOIN orders o
    USING (customer_id)
JOIN order_items oi
    USING (order_id)
WHERE state = 'VA'
GROUP BY state
HAVING total_cost > 100 ;
-- 练习:从customers表中获取地处Virginia并且消费超过$100的客户

USE `sql_invoicing`;
SELECT name AS payment_method,SUM(amount) AS total
FROM payments p
JOIN payment_methods pm
    ON p.payment_method = pm.payment_method_id
GROUP BY name WITH ROLLUP;
-- ROLLUP 进行数据汇总，只汇总有意义的数据
-- 使用ROLLUP运算符时，不能在GROUP BY子句中使用列的别名,只在极个别情况下不能


-- ========第六章：编写复杂查询=========
USE `sql_hr`;
SELECT employee_id,first_name,last_name,salary
FROM employees
WHERE salary > (
    SELECT
        AVG(salary)
    FROM employees
    );
-- 复杂查询，从员工表中查询薪水超过平均薪水的员工

USE `sql_invoicing`;
SELECT client_id,name
FROM clients
WHERE client_id  NOT IN (
    SELECT DISTINCT client_id
    FROM invoices
    ) ;
--  查询没有发票的客户， IN运算符

USE `sql_store`;
-- 子查询VS连接查询
SELECT customer_id,first_name,last_name
FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id
    FROM orders
    WHERE order_id IN (
        SELECT order_id
        FROM order_items
        WHERE product_id = 3)
    );
SELECT DISTINCT c.customer_id,first_name,last_name
FROM customers c
JOIN orders o USING (customer_id)
JOIN order_items oi USING (order_id)
WHERE product_id = 3
ORDER BY customer_id ;
-- 查询点了lettuce（product_id=3）菜品的客户,使用嵌套查询和连表查询两种方式实现
-- 比较代码的易读性和书写难度综合考量使用那种

USE `sql_invoicing`;
SELECT *
FROM invoices
WHERE invoice_total > (
    SELECT MAX(invoice_total)
    FROM invoices
    WHERE client_id = 3
    );
SELECT *
FROM invoices
WHERE invoice_total > ALL (
    SELECT invoice_total
    FROM invoices
    WHERE client_id = 3
);
-- 查询大于三号客户账单的所有账单，ALL和MAX都可以实现上述问题
-- ALL 关键字，当子查询返回的值有多个时，就可以使用ALL关键字，
-- num > All(10,15,23):即num大于ALL中的各个数才能返回TRUE

SELECT  *
FROM clients
WHERE client_id = ANY (
    SELECT client_id
    FROM invoices
    GROUP BY client_id
    HAVING COUNT(*) >= 2
);
-- ANY关键字，WHERE client_id IN()和WHERE client_id = ANY()等价

USE `sql_hr`;
SELECT *
FROM employees e
WHERE salary > (
    SELECT AVG(salary)
    FROM employees em
    WHERE e.office_id = em.office_id
    );
-- 相关子查询，数据越多，查询越费时间。
-- 选出薪水超过他所在部门平均薪水的员工,这里子查询只面向的是同一个部门的员工

USE `sql_invoicing`;
SELECT *
FROM invoices i1
WHERE invoice_total > (
    SELECT AVG(invoice_total)
    FROM invoices i2
    WHERE i1.client_id = i2.client_id
    );
-- 获取客户订单金额 大于该客户订单平均值的订单，（一个客户有多个订单，我们只需要那些多个订单中金额大于它订单平均金额的订单）

SELECT DISTINCT c.CLIENT_ID,name,address,city,state,phone
FROM clients c
JOIN invoices i
    USING (client_id);
-- ----------------
SELECT *
FROM clients
WHERE client_id IN (
    SELECT DISTINCT client_id
    FROM invoices
    );
-- ------------------
SELECT *
FROM clients
WHERE EXISTS(
    SELECT DISTINCT client_id
    FROM invoices
    WHERE clients.client_id = invoices.client_id
          );
-- EXIST关键词，当数据量巨大时使用EXIST可以提升性能，因为使用IN时子查询会返回结果集，但EXIST不会，注意：EXISTS子查询中需要进行表连接条件
-- 上述三种方法都可以实现获取下过订单的客户的客户

USE `sql_store`;
SELECT *
FROM products  p
WHERE NOT EXISTS(
    SELECT DISTINCT product_id
    FROM order_items
    WHERE p.product_id = order_items.product_id
    );
-- 查询没有被订购过的产品

USE `sql_invoicing`;
SELECT
       client_id,
       name,
       (SELECT SUM(invoice_total)
           FROM invoices
           WHERE c.client_id = client_id) AS total_sales,
       (SELECT AVG(invoice_total)
           FROM invoices) AS average,
       (SELECT total_sales - average) AS difference
FROM clients c ;
-- 在选择语句中进行子查询
-- 子查询不仅可以在WHERE子句中使用，还可以在选择子句以及FROM子句中使用。

SELECT *
FROM (
     SELECT
       client_id,
       name,
       (SELECT SUM(invoice_total)
           FROM invoices
           WHERE c.client_id = client_id) AS total_sales,
       (SELECT AVG(invoice_total)
           FROM invoices) AS average,
       (SELECT total_sales - average) AS difference
    FROM clients c
         ) AS sales_summary
WHERE total_sales IS NOT NULL;
-- 将上一条sql查询出来的表作为该sql语句FROM条件，但需要给上一个表起个别名，否则会报如下错误
-- Every derived table must have its own alias
-- 在查询语句的FROM子句中写子查询，会使我们的主查询变得复杂，所以仅限于一些简单的查询。好的解决方法是使用视图


-- ========第七章：函数=========
-- ===数值处理===
SELECT ROUND(5.73);
SELECT ROUND(5.7368,2);
-- 四舍五入
SELECT CEILING(5.2);
-- 上限函数，res:5
-- 返回大于或等于该数字的最小整数
SELECT FLOOR(5.7);
-- 下限函数，res:5
-- 返回小于或等于该数字的最大整数
SELECT ABS(-5.2);
-- 计算绝对值
SELECT RAND();
-- 生成0-1区间的随机浮点数

-- ===字符串处理===
SELECT LENGTH('Mysql');
-- res；5
SELECT UPPER('Mysql');
-- 转大写，res:MYSQL
SELECT LOWER('Mysql');
-- 转小写，res：mysql
SELECT TRIM('    Mysql     ');
-- 删除所有前导或者尾随空格，可以选择LTRIM或RTRIM;res:Mysql
SELECT LEFT('Mysql',2);
-- 获取该字符串左侧2个字符，res:My
SELECT RIGHT('Mysql',3);
-- 获取该字符串右侧3个字符，res:sql
SELECT SUBSTRING('Mysql',3,1);
-- 截取该字符串3开始的长度为1的字符，res:s
-- 第一个参数：起始位置，第二个参数：截取长度，注意：索引从1开始
SELECT LOCATE('Ys','Mysql');
-- 字符串Ys在Mysql中的位置，忽略大小写。res:2
SELECT REPLACE('Mysql','sql','');
-- 字符串替换，用空串替换Mysql中的sql，res:My
SELECT CONCAT('My','sql');
-- 字符串连接；res:Mysql

-- ===日期函数===
SELECT NOW(),CURDATE(),CURTIME();
-- 2021-05-26 21:04:41  ,  2021-05-26  ,  21:04:41
SELECT YEAR(NOW()),MONTH(NOW()),WEEK(NOW()),HOUR(NOW()),MINUTE(NOW()),SECOND(NOW());
-- 2021 , 5  , 21 , 21 ,  7  , 48
SELECT DAYNAME(NOW()),MONTHNAME(NOW()) ;
-- Wednesday  ,  May
SELECT EXTRACT(YEAR FROM NOW());
-- 从now函数返回的日期中提取年份  ，2021

-- ===格式化日期和时间===
SELECT DATE_FORMAT(NOW(),'%y'),DATE_FORMAT(NOW(),'%Y');
-- %y:返回两位数的年份，%Y返回完整年份; 21  ,  2021
SELECT DATE_FORMAT(NOW(),'%m_%Y'),DATE_FORMAT(NOW(),'%M %d %y'),TIME_FORMAT(NOW(),'%h:%i:%s'),DATE_FORMAT(NOW(),'%H:%i:%s');
-- 05_2021 ,  May 26 21  , 09:32:37  ,  21:32:37  ;%H:24小时,%h:12小时

-- ===计算时间和日期===
SELECT DATE_ADD(NOW(),INTERVAL 1 DAY ),DATE_ADD(NOW(),INTERVAL 1 YEAR );
-- 2021-05-27 21:36:27 ,2022-05-27 21:36:27 ;在当前日期上加一天，加一年
SELECT DATE_SUB(NOW(),INTERVAL 1 DAY ),DATE_ADD(NOW(),INTERVAL -1 DAY );
-- 2021-05-25 21:39:37，2021-05-25 21:39:37 ;当前日期减一天，上述语句具有相同效果
SELECT DATEDIFF('2021-05-25 21:39:37','2021-01-01'),DATEDIFF('2021-01-01','2021-05-25 21:39:37');
--   144 ,-144;计算两日期的间隔，不考虑时间间隔
SELECT TIME_TO_SEC('00:00:37');
-- 37;该时间距离00:00:00过去了37秒
SELECT TIME_TO_SEC(NOW())-TIME_TO_SEC('21:39:37');
-- 740，当前时间距离21:39:37过去了740秒

USE `sql_store`;
SELECT *,
       IFNULL(shipper_id,'没有承运人'),
       COALESCE(shipper_id,comments,'没有承运人')
FROM orders ;
-- 关键词IFNULL 和 COALESCE
-- IFNULL如果shipper_id中有空值则替换为“没有承运人”
-- COALESCE如果shipper_id列中有空值则先将其用comments替换，如果comments也为空，则使用“没有承运人”替换

SELECT order_id,
       customer_id,
       order_date,
        IF(YEAR(order_date) = '2019',
            '活跃的',
            '不活跃的') AS status
FROM orders ;
-- IF(条件，为真执行，为假执行)

SELECT   product_id,name,
                 COUNT(*) AS orders,
                 IF(COUNT(*)>1,
                     'Many times',
                     'Once') AS frequency
FROM order_items
JOIN products
    USING (product_id)
GROUP BY product_id;
-- 练习

SELECT
   order_id,
   customer_id,
   order_date,
       CASE
            WHEN YEAR(order_date) = 2019 THEN  '活跃'
            WHEN YEAR(order_date) = 2018 THEN '正常'
            WHEN YEAR(order_date) < 2018 THEN '消极'
            ELSE '未知'
        END AS status
FROM orders
-- 在有多个测试表达式且想要针对每个测试表达式返回不同值的时候使用CASE运算符；IF只能返回两种状态



