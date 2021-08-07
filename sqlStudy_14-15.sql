-- ======第十四章：索引========
-- 索引的创建原则应该是基于查询条件，而不是基于表
-- 索引是以二叉树形式被创建
-- 创建了二级索引，mysql会自动将表的主键包含在这些二级索引中
-- 索引会占用较多空间，每次修改表中的数据的时候，对应的索引也会更新，所以索引越多，写入操作也会越慢。

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

-- 上面的这种方式对于英文等西文支持特别完美（因为英文两个单词之间默认以空格分），而对于中文就差强人意了，但也不是没有什么解决办法，此时我们需要mysql的一个插件 ngram;
CREATE FULLTEXT INDEX idx_title_body ON posts (title,body) WITH PARSER ngram;

-- ===复合索引===
-- 在MySQL中一个索引最多可以包含16个列
-- 复合索引中列的顺序规则：①让频繁使用的列排在前面，②把基数更大的列排在前面（基数表示索引中唯一值的数量）[例如：该表中有1010条数据，所以主键中的基数是1010；而对于表示性别的列来说，它的基数就是2]
USE sql_store;

-- 虽然我们在州上设置了索引，但假如维吉尼亚州有一千万人口，我们还是需要去查找这一千万条数据来找符合我们要求的，所以单独的索引无法获得最佳性能
-- 为了优化这一问题，这时我们就可以使用复合索引
CREATE INDEX idx_state_points ON customers (state,points);

EXPLAIN SELECT *
FROM customers
WHERE state = 'VA' AND points > 1000;

DROP INDEX idx_points ON customers;

-- MySQL会默认选择最快的索引来执行查询，但是我们也可以自己手动指定要使用的索引
SELECT *
FROM customers
USE INDEX (idx_state)  -- 手动指定要使用的索引
WHERE state = 'VA' AND points > 1000;

DROP INDEX idx_points ON customers;


CREATE INDEX idx_state_lastname ON customers(state,last_name);

SELECT customer_id
FROM customers
WHERE state = 'NY' AND last_name LIKE 'A%';
-- 在该查询中，因为'州'列上使用的是等号，所以它的约束性更强，而姓名的LIKE使它变得随意，所以对于这个特点查询来说，将州的列排在前面效率更高

-- ===优化===
-- 有时虽然我们创建了索引，但由于我我们写的查询语句的问题，会使我们建立的索引失效（这里的失效指虽然使用了索引，但还是进行了全表扫描）。
SELECT customer_id
FROM customers
WHERE state = 'CA' OR points > 1000;
-- 由于使用了OR，使得我们的还是进行了全表查询，这时我们就可以对其进行优化。

SELECT customer_id
FROM customers
WHERE state = 'CA'
UNION
SELECT customer_id
FROM customers
WHERE points > 1000;
-- 然后在state和points列分别建立单独的索引，通过这样修改，我们的查询由原来的全表减少到一半左右。

EXPLAIN SELECT customer_id
FROM customers
WHERE points + 10 > 2010;
-- 1,SIMPLE,customers,,index,,idx_points,4,,1011,100,Using where; Using index
-- 虽然我们在points列建立了索引，但是由于SQL语句中（ points + 10 > 2010 ）这个表达式的问题，导致我们的索引失效，从结果看，我们还是进行了全表扫描，共查了1011行

EXPLAIN SELECT customer_id
FROM customers
WHERE points > 2000;
-- 1,SIMPLE,customers,,range,idx_points,idx_points,4,,4,100,Using where; Using index
-- 从得出的结果来看，这样优化之后，我们只需要查询 4 行即可，相比前一个相同结果的查询语句极大的提升了查询效率

-- ===使用索引排序===
drop index idx_points on customers;
drop index idx_state on customers;
-- 这里为了使用复合索引来做排序，所以先删掉单独的索引

show variables;
SHOW STATUS LIKE 'last_query_cost';  -- 通过MySQL中的这个变量我们可以看到我们上一次查询的成本

EXPLAIN SELECT customer_id
FROM customers
ORDER BY first_name;
-- 'Last_query_cost', '1113.849000'

EXPLAIN SELECT customer_id
FROM customers
ORDER BY state,points;
-- 'Last_query_cost', '102.849000'
-- 排序的基本规则是，ORDER BY 子句中的列的顺序，应该与索引中的列的顺序相同

EXPLAIN SELECT customer_id
FROM customers
ORDER BY points,state ; -- 换了顺序
-- 'Last_query_cost', '1113.849000'


EXPLAIN SELECT customer_id
FROM customers
ORDER BY state, points DESC;
-- 'Last_query_cost', '1113.849000'

EXPLAIN SELECT customer_id
FROM customers
ORDER BY state DESC, points DESC;
-- 'Last_query_cost', '102.849000'

EXPLAIN SELECT customer_id
FROM customers
ORDER BY state ;
-- 'Last_query_cost', '102.849000'

EXPLAIN SELECT customer_id
FROM customers
ORDER BY points ;
-- 'Last_query_cost', '1113.849000'
-- 可以看到，通过points排序我们的查询成本也较高，原因是我们的顾客是按照他们的州排序的，然后在每个州下，再按他们的积分排序，所以MySQL不能依赖于索引中的记录顺序，为顾客按积分排序

EXPLAIN SELECT customer_id
FROM customers
WHERE state = 'VA'
ORDER BY points ;
-- 'Last_query_cost', '4.362396'
-- 可以看到我们通过确定具体的州之后，在使用points排序，成本只有4点多
-- 通过where子句MySQL就不会做”外部索引“，因为它会定位到这个州下，而该州下的顾客已经被按照积分排过序了。


EXPLAIN SELECT customer_id
FROM customers
ORDER BY state,first_name,points;
-- 'Last_query_cost', '1113.849000'

-- 由此可以得出，如果是基于两列的索引，比如A列和B列，可以按A排序，可以按A和B排序，可以按同样的列降序排序
-- 但不能混淆方向，也不能在其中添加一列，这些操作会导致全表扫描


-- ===覆盖索引===
-- 覆盖索引：一个包含所有满足查询需要数据的索引，通过该索引，MySQL就可以在不读取表的情况下执行查询
EXPLAIN SELECT *
FROM customers
ORDER BY state ;
-- 'Last_query_cost', '1113.849000'
-- 通过前面可以看到，我们所有的查询都只是查询customer_id，当我们查询所有列时，然后进行排序时，还是会去查询表
-- 这是由于我们放在州和积分列上的复合索引包含了关于每个顾客的三条信息(主键将包含在第二索引中)，即customer_id,state,points

EXPLAIN SELECT customer_id,state,points
FROM customers
ORDER BY state ;
-- 'Last_query_cost', '102.849000'
-- 所以我们只要查询这三个列，MySQL就可以完整使用我们的索引来满足查询

-- 由此，在我们设计索引，先看where子句，看最常用的列，是否包含在索引中，这样可以缩小查找范围，接着看order by子句，看是否可以在索引中包含这些列，最后查看select子句中使用的列。如果这些都满足，那我们就得到了覆盖索引，MySQL就会使用索引来满足我们的查询，而不再去查表

-- ===维护索引===
-- ①重复索引：同一组列上且顺序也一样的索引
-- ②多余索引：如果在两列（A和B）上有一个索引，然后在列A上在创建另一个索引，这就被判定为多余索引
-- 但如果在两列（A和B）上有一个索引，然后在列B上在创建另一个索引,这就不算多余索引
-- ③未使用的索引

-- 所以创建索引时先查看我们已经具有的索引

-- =========保护数据库========
