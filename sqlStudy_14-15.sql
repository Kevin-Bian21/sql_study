-- ======第十四章：索引========
-- 基于查询创建索引，而不是基于表
-- 索引是以二叉树形式被创建
use sql_store;
EXPLAIN SELECT customer_id FROM customers WHERE state = 'VA';
CREATE INDEX idx_state ON customers (state);

EXPLAIN SELECT customer_id FROM customers WHERE points > 1000;
CREATE INDEX  idx_points ON customers (points) ;
-- 存在多个索引的话，mysql会默认选择最快的索引执行查询

SHOW INDEXES IN customers;
-- 查看索引之前先分析一下这张表
ANALYZE TABLE customers;
-- mysql会为主键和外键建立索引

-- ===前缀索引===
CREATE INDEX idx_lastname ON customers(last_name(5));
-- 根据last_name 的前五个字符来创建索引

-- ===全文索引===
use sql_blog;
SELECT * FROM posts;

CREATE FULLTEXT INDEX idx_title_body ON posts (title,body);

SELECT *,MATCH(title,body) AGAINST('react redux') AS relevance
FROM posts
WHERE MATCH(title,body) AGAINST('react -redux + form' IN BOOLEAN MODE)
    OR MATCH(title,body) AGAINST('"what should I"');
-- 使用MATCH()、AGAINST()这两个内置函数来支持全文索引
-- MATCH()里必须要传入我们创建全文索引时的列，这里是title和body
-- AGAINST()这里传入我们要搜索的内容，这样就可以返回所有标题或者正文中包含这两个关键字的文章，这些单词可以按任何顺序排列，也可以被一个或多个单词分割
-- MATCH(title,body) AGAINST('react redux') AS relevance 会返回一个搜索的相关性得分，介于0-1之间的浮点数
-- 全文搜索有两种模式，一种是自然语言模式，另一种是布尔模式（这个模式可以使用正则表达式来包括或排除某些单词）和搜索引擎一致

-- ===复合索引===
-- 在MySQL中一个索引最多可以包含16个列
USE sql_store;

CREATE INDEX idx_state_points ON customers (state,points);

EXPLAIN SELECT *
FROM customers
WHERE state = 'VA' AND points > 1000;

DROP INDEX idx_points ON customers;