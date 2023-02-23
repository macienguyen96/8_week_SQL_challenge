/* ----------------------------------------
   Case Study 1 - Danny's Diner - Questions
   ---------------------------------------- */

-- 1. What is the total amount each customer spent at the restaurant?
SELECT
	s.customer_id,
    SUM(m.price) AS amount
FROM sales AS s
JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY customer_id ASC;

-- 2. How many days has each customer visited the restaurant?
SELECT
	customer_id,
    COUNT(DISTINCT order_date) AS count_visit
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT DISTINCT 
	s.customer_id, 
    m.product_name
FROM sales AS s
LEFT JOIN menu AS m
ON s.product_id = m.product_id
INNER JOIN (
  SELECT 
  	customer_id, 
  	MIN(order_date) AS first_occurence 
  FROM sales 
  GROUP BY customer_id) AS a
ON a.first_occurence = s.order_date AND s.customer_id = a.customer_id
ORDER BY s.customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	m.product_name, 
    COUNT(s.product_id) AS count_purchase
FROM sales AS s
JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY COUNT(s.product_id) DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
SELECT customer_id, product_name
FROM (
SELECT 
	s.customer_id,
    m.product_name, 
    COUNT(s.product_id),
    RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS ranking
FROM sales AS s
JOIN menu AS m
ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
) AS popular_items
WHERE ranking = 1;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT customer_id, product_name
FROM (
SELECT DISTINCT 
	s.customer_id, 
    m.product_name,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS ranking1
FROM sales AS s
INNER JOIN menu AS m
ON s.product_id = m.product_id
INNER JOIN members AS mem
ON mem.customer_id = s.customer_id
WHERE s.order_date >= mem.join_date
) AS ranking_first_item
WHERE ranking1 = 1
ORDER BY customer_id;

-- 7. Which item was purchased just before the customer became a member?
SELECT customer_id, product_name
FROM (
SELECT DISTINCT 
	s.customer_id, 
    m.product_name,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS ranking2
FROM sales AS s
INNER JOIN menu AS m
ON s.product_id = m.product_id
INNER JOIN members AS mem
ON mem.customer_id = s.customer_id
WHERE s.order_date < mem.join_date
) AS ranking_last_items
WHERE ranking2 = 1
ORDER BY customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT DISTINCT 
	s.customer_id, 
    COUNT(s.product_id) AS total_items,
    SUM(m.price) AS total_spent
FROM sales AS s
INNER JOIN menu AS m
ON s.product_id = m.product_id
INNER JOIN members AS mem
ON mem.customer_id = s.customer_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
	customer_id, 
    SUM(point) as total_point
FROM
  (SELECT 
      s.customer_id,
      CASE
          WHEN m.product_name = 'sushi' THEN 20 * m.price
          ELSE 10 * m.price
          END AS point
  FROM sales AS s
  JOIN menu AS m
  ON s.product_id = m.product_id) AS loyalty
GROUP BY customer_id
ORDER BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT 
	customer_id, 
    SUM(point) as total_point
FROM
  (SELECT 
      s.customer_id, s.order_date,
      CASE
          WHEN m.product_name = 'sushi' THEN 20 * m.price
   		  WHEN m.product_name != 'sushi' AND s.order_date >= mem.join_date AND s.order_date <= mem.join_date + 6 THEN 20 * m.price
          ELSE 10 * m.price
          END AS point
  FROM sales AS s
  JOIN menu AS m
  ON s.product_id = m.product_id
  JOIN members as mem
  ON mem.customer_id = s.customer_id) AS loyalty
WHERE customer_id IN ('A', 'B') AND order_date <= '2021-01-31'
GROUP BY customer_id
ORDER BY customer_id;

-- Bonus question
-- Join all the things
-- customer_id | order_date | product_name | price | member
SELECT 
	s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
    	WHEN s.order_date >= mem.join_date THEN 'Y'
        ELSE 'N'
        END AS member
FROM sales AS s
JOIN menu AS m
ON s.product_id = m.product_id
FULL JOIN members AS mem
ON mem.customer_id = s.customer_id;

-- Rank all the things
-- customer_id | order_date | product_name | price | member | ranking
WITH ranking_table AS
(
  SELECT 
	s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
    	WHEN s.order_date >= mem.join_date THEN 'Y'
        ELSE 'N'
        END AS member
  FROM sales AS s
  JOIN menu AS m
  ON s.product_id = m.product_id
  FULL JOIN members AS mem
  ON mem.customer_id = s.customer_id)
SELECT 
	customer_id,
    order_date,
    product_name,
    price,
    member,
    CASE
    	WHEN member = 'Y' THEN RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
        END AS ranking
FROM ranking_table;