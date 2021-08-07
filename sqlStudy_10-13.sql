-- =======十一章：事务=========
-- ACID
SHOW VARIABLES LIKE 'AUTOCOMMIT';
-- 要么都成功，要么都失败

USE `sql_store`;
-- ===创建事务===
START TRANSACTION ;

INSERT INTO orders(CUSTOMER_ID, ORDER_DATE, STATUS)
VALUES (2,CURDATE(),1);

INSERT INTO order_items
VALUES (LAST_INSERT_ID(),2,3.11);

COMMIT;
-- ROLLBACK ;
-- order_items表某列插入出错后，orders表插入也将失败

-- ===并发和锁定===
START TRANSACTION;
UPDATE customers
SET points = points + 10
WHERE customer_id = 1;
COMMIT;
-- 如果一个事务试图修改一行或多行，他将给这些行上锁，这个锁可以防止其他事务修改这些行，直到第一个事务完成，其他事务才能去操作这些行
-- 模拟并发，在两个不同的console（会话中）中创建事务分别对customer_id = 1的顾客进行更改，第一个事务开启并进行更改但不执行COMMIT，然后让第二个事务开启，接着执行更新操作，会看到执行超时，然后报如下错误
-- Lock wait timeout exceeded; try restarting transaction

-- ===并发问题===
-- ①丢失更新：当两个事务更新相同的数据并没有上锁时，较提交的事务会覆盖较早事务所做的更改，一般情况下，Mysql数据库会自动给事务上锁。
-- ②脏读：一个事务读取了未被提交的数据。 为此我们要设置事务隔离级别，这样事务修改但未提交的数据不会被其他事务读取
-- ③不可重复读：在一次事务执行过程中读取某个数据两次，但得到了不同的结果。为此要增加事务隔离级别，确保数据更改对其他事务不可见
-- 注：只有增删改操作才会锁数据，读数据不会上锁。
-- ④幻读：我们的查询中缺失了数据，因为别的事务正在修改数据，但我们没有意识到事务的修改。为此需要我们的事务按序列化执行

-- ===事务隔离级别===
-- ①读未提交：不能解决任何并发问题
-- ②读已提交：可以解决脏读问题
-- ③可重复读：可以解决除幻读之外的其他并发问题，Mysql默认的事务隔离级别。
-- ④序列化：可以解决上述四种并发问题
-- 注：隔离级别越高，需要用到更多的锁和资源，会损害性能和可扩展性，但也意味着更少的并发问题。

SHOW VARIABLES LIKE 'tx_isolation';
-- REPEATABLE-READ
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- 为下一个事务设置隔离级别为序列化

SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- 为该会话中的所有事务设置隔离级别

SET GLOBAL TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- 为所有会话中的所有事务设置隔离级别

-- ===读未提交===
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;
SELECT points
FROM customers
WHERE customer_id = 1;
-- 在我们更新customer_id = 1的客户积分points = 20但未提交的情况下，我们的查询语句会读到该客户的points为20，但表中此时还是原来的数据2273，出现了脏读
-- 最低事务隔离等级，在这一级别可能会遇到所有的并发问题

-- ===读已提交===
SET TRANSACTION ISOLATION LEVEL READ COMMITTED ;
START TRANSACTION ;
SELECT points FROM customers WHERE customer_id = 1;
SELECT points FROM customers WHERE customer_id = 1;
COMMIT ;
-- 解决了脏读问题，但是又出现不可重复读的问题

-- ===可重复读===
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ ;
START TRANSACTION ;
SELECT points FROM customers WHERE customer_id = 1;
SELECT points FROM customers WHERE customer_id = 1;
COMMIT ;
-- 使我们读取的数据具有一致性，但还不能解决幻读问题

-- ===序列化===
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE ;
START TRANSACTION ;
SELECT * FROM customers WHERE state = 'VA';
COMMIT;
-- 设置序列化隔离级别后，开启我们的事务，但是不执行查询，然后我们去执行另一个事务更新我们的数据，
-- 但是并不执行COMMIT，接着回来执行我们的查询，此时我们的查询将超时并报错，只有我们将我们更改数据事务进行提交后，才能执行查询。
-- [40001][1205] Lock wait timeout exceeded; try restarting transaction
-- 序列化解决了所有并发问题，因为所有的事务都是一个接一个按顺序执行的，但是会大大降低我们的效率。

-- ===死锁===
START TRANSACTION;
UPDATE customers SET state = 'VA' WHERE customer_id = '1';
UPDATE orders SET status = 1 WHERE order_id = 5;
COMMIT;
-- 如果需要“修改”一条数据，首先数据库管理系统会在上面加锁，以保证在同一时间只有一个事务能进行修改操作。锁定(Locking)发生在当一个事务获得对某一资源的“锁”时，这时，其他的事务就不能更改这个资源了

-- 当我们开启第一个事务，并执行了更新customer_id = '1'的客户state='VA'后qu开启第二个个事务，然后执行更新order_id = 5的客户信息，此时一切安好，
-- 接着我们回来执行第一个事务更新order_id = 5的客户信息（此时由于数据库默认锁的存在，导致我们更新该语句会超时），接着我们去执行第二个事务更新customer_id = '1'的客户state='VA'，
-- 此时我们的数据库就陷入了死锁。报如下错误：
-- Deadlock found when trying to get lock; try restarting transaction



-- ========第十二章：数据类型===========
-- ===strings===
-- CHAR():存储固定长度的字符串。
-- VARCHAR() ：用以存储可变长度字符串。varchar最大长度65535（64KB）
-- MEDIUMTEXT :文本串，能存储约1600万个字符（16MB），一般用来存json文件或vsc文件
-- LONGTEXT ：长文本串，可存储4GB的文本数据 （4GB），一般用来存储多年来的日志文件
-- TINYTEXT ：微文本类型，可存储255个字符。
-- TEXT :文本类型，可存储65535个字符，和varchar一样（64KB）
-- 这些类型都支持国际字符
-- 注：一个英文字符占一个字节，而一个中文占3个字节，

-- ===Integers===
-- TINYINT :微整型  1B  [-128,127]
-- UNSIGNED TINYINT :无符号微整型  1B  [0，255]
-- SMALLINT :小整型 2B  [-32768,32767]
-- MEDIUMINT :中整型 3B  [-8M,8M-1]([-8388608,8388607])
-- INT :整型 4B [-2147483648,2147483647]
-- BIGINT:大整型 8B [-2^63,2^63-1]
-- 选择能够满足自己需求的最小的范围

-- ===定点和浮点===
-- DECIMAL(p,s) :小数型 存储定点数 p：精度(明确了最大位数，介于1-65) s:小数位数
-- DEC / NUMERIC / FIXED 这是DECIMAL的同义词
-- ------------------
-- FLOAT : 浮点型 4B
-- DOUBLE :双精度  8B

-- ===布尔型===
-- BOOL : TRUE FALSE
-- BOOLEAN :TRUE(1) FALSE(0)

-- ===枚举和集合==
-- ENUM(固定值)
-- enum可以在一列选取一个enum中设定的值
-- 不推荐使用，尽量通过建表来实现和ENUM()相似的功能
-- SET(……)
-- set使我们可以在一列存储多个set中设定的值

-- ===日期和时间===
-- DATE :存储一个没有时间成分的日期
-- TIME :存储一个时间值
-- DATETIME ：日期时间 8B
-- TIMESTAMP  ：时间戳 4B 可以存储2038年之前的日期
-- YEAR ：四位数的年份

-- ===BLOB类型===
-- 如图像、视频、PDF、word等文件，几乎囊括了所有二进制数据
-- TINYBLOB : 255B 最大存储255B的二进制数据
-- BLOB ：65KB
-- MEDIUMBLOB : 16MB
-- LONGBLOB : 4GB
-- 一般最好不要把文件存在数据库中，因为关系型数据库是为了处理结构化关系数据库设计的，而非二进制数据。
-- 此外会增加我们的数据库的大小，弱化数据库备份能力，还会出现性能问题，此外在数据库读取或存储图像还得写额外的代码

-- ===JSON类型===
-- 键值对：键是字符串类型，值为Object（任意）类型
-- MySQL数据库版本要在8.0以上才支持JSON格式

alter table products
	add properties json not null;

UPDATE products
SET properties = '
{
  "dimensions ": [1,2,3],
  "weight": 10,
  "manufacturer": { "name" : "sony" }
}'
WHERE product_id = 1;
-- 上下两种sql功能相同，下面这个sql使用了函数
UPDATE products
SET properties = JSON_OBJECT(
    'weight', 10,
    'dimensions' , JSON_ARRAY(1,2,3),
    'manufacturer', JSON_OBJECT ( 'name' , 'sony' )
)
WHERE product_id = 1;

SELECT product_id,JSON_EXTRACT(properties,'$.weight' )
FROM products
WHERE product_id = 1;
-- 上下两种写法功能一样，只不过上边的sql使用了官方的函数
SELECT product_id, properties->'$.weight'
FROM products
WHERE product_id = 1;

SELECT product_id, properties ->> '$.manufacturer.name'
FROM products
WHERE product_id = 1;
-- ->返回"sony"(带引号的)
-- ->>返回sony

-- JSON_SET()：重新设置属性
-- JSON_REMOVE():用以删除一个或多个属性



-- ========第十三章：数据库设计==============
-- 数据建模
-- 概念模型：实体关系图
-- 逻辑模型：抽象的数据模型，能清楚的显示我们的实体及关系架构。实体中属性的数据类型，实体间的关系（一对一、一对多、多对多）
-- 实体模型：比逻辑模型更进一步，逻辑模型中不需要管主键、外键问题是逻辑模型通过特定数据库技术的实现
-- 注：概念模型并不能为我们提供存储数据的结构，它只代表业务实体及其关系；逻辑模型增添了更多细节

-- 主键：唯一标识表中记录的列
-- 外键：在一张表中引用了另一张表的主键的列
-- 外键约束：当作为外键时，主键所在的表的信息发生变化作为外键的那个表的对应记录应该做出的变化：更新（级联，拒绝，置空），删除（不变、拒绝、级联）
-- 标准化：审查我们的设计，防止数据冗余或重复，有七条规则即七范式。

-- 第一范式：要求一行中的每一个单元格都应该有单一值，且不能出现重复值，为了满足第一范式，我们可能需要链接表。
-- 链接表：将多对多关系通过添加一张表变为两个一对多关系，一般情况下链接表只有多对多关系的两张表中的主键两列。
-- 第二范式：一张表中的每一列都应该是在描述该表代表的实体。如果有一列描述的不是该实体，我们应该去除它，并将它放入一张单独的表中。
-- 第三范式：表中的列不应派生自其他列，如结余是由订单总额减去付款总额得到的、first_name,last_name以及full_name

-- 先从逻辑或者概念模型入手，不要直接开始创建表，但也不要什么都建模，具体视业务需求，项目背景而定，一切从简

-- 创建数据库
CREATE DATABASE  IF NOT EXISTS sql_store2;
-- 创建数据表
USE sql_store2;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
CREATE TABLE IF NOT EXISTS customers
(
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL ,
    points INT NOT NULL DEFAULT 0,
    email VARCHAR(255) NOT NULL UNIQUE -- UNIQUE:唯一
);
-- 声明为主键后可以省略NOT NULL，因为主键一定不为空

-- 修改表
ALTER TABLE customers
    ADD last_name varchar(50) NOT NULL AFTER first_name,
    MODIFY COLUMN first_name VARCHAR(55) DEFAULT '',
    DROP points;


CREATE TABLE orders
(
    order_id INT PRIMARY KEY ,
    customer_id INT NOT NULL,
    FOREIGN KEY fk_orders_customers (customer_id)
        REFERENCES customers (customer_id)
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);
-- 设置外键约束 首先给外键取名：fk_orders_customers（取名规则：fk_+外键表名+主键列的名称），接着，在括号中，列出我们想要添加这个外键的列，
-- 然后告诉Mysql，这一列引用了顾客表中的customer_id列，下来我们要指定更新和删除行为，是级联它们还是拒绝它们等等。

-- 改变外键关联
ALTER TABLE orders
    ADD PRIMARY KEY (order_id),
    DROP PRIMARY KEY ,
    DROP FOREIGN KEY fk_orders_customers,
    ADD FOREIGN KEY fk_orders_customers (customer_id)
        REFERENCES customers (customer_id)
        ON UPDATE CASCADE
        ON DELETE NO ACTION;

-- 字符集和排序顺序
SHOW CHARACTER SET ;
-- utf8,UTF-8 Unicode,utf8_general_ci,3
-- ci:case-insensitive(排序时不区分大小写),3：最大三个字节

-- 在数据库级别进行设置字符编码
CREATE DATABASE db_test
    CHARACTER SET UTF8;
-- 在表级别设置字符编码
CREATE TABLE db_test
(
    name varchar(50) CHARACTER SET latin1 -- 在列上设置字符集编码
) CHARACTER SET latin1;

-- ===存储引擎===
SHOW ENGINES;
-- InnoDB,DEFAULT,"Supports transactions, row-level locking, and foreign keys",YES,YES,YES
ALTER TABLE customers
ENGINE = InnoDB







