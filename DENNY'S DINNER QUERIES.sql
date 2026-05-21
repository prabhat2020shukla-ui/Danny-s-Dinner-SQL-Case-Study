CREATE database dannys_diner;
Use database dannys_dinner

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
SELECT * FROM SALES;
SELECT * FROM MENU;
SELECT * FROM MEMBERS;

-- Q-1. What is the total amount each customer spent at the restaurant?
SELECT S.CUSTOMER_ID, SUM(M.PRICE)  AS CUSTOMER_SPENT
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY S.CUSTOMER_ID;

-- Q-2. How many days has each customer visited the restaurant?
SELECT CUSTOMER_ID, COUNT(DISTINCT ORDER_DATE) AS CUSTOMER_VISIT
FROM SALES
GROUP BY CUSTOMER_ID;

-- Q-3. What was the first item from the menu purchased by each customer?
SELECT S.CUSTOMER_ID, S.ORDER_DATE, M.PRODUCT_ID, M.PRODUCT_NAME
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
WHERE S.ORDER_DATE = ( SELECT MIN(S2.ORDER_DATE)
FROM SALES S2
WHERE S2.CUSTOMER_ID = S.CUSTOMER_ID)

-- Q-4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH CTE AS (
SELECT M.PRODUCT_NAME, COUNT(S.PRODUCT_ID) AS PURCHASE_COUNT
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY M.PRODUCT_NAME)
SELECT * FROM CTE 
WHERE PURCHASE_COUNT = (SELECT MAX(PURCHASE_COUNT)
FROM CTE);

-- Q-5. Which item was the most popular for each customer?
WITH CTE AS (
SELECT S.CUSTOMER_ID, M.PRODUCT_NAME, COUNT(S.PRODUCT_ID) AS PURCHASE_COUNT,
DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY COUNT(*) DESC) AS RNK
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY  S.CUSTOMER_ID, M.PRODUCT_NAME)
SELECT CUSTOMER_ID, PRODUCT_NAME, PURCHASE_COUNT, RNK
FROM CTE 
WHERE RNK = '1';

 -- Q-6. Which item was purchased first by the customer after they became a member?
WITH CTE AS(
SELECT S.CUSTOMER_ID, M.PRODUCT_ID, MEM.JOIN_DATE, S.ORDER_DATE,
DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE ASC) AS RNK
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS MEM ON S.CUSTOMER_ID = MEM.CUSTOMER_ID
WHERE S.ORDER_DATE >= MEM.JOIN_DATE)
SELECT JOIN_DATE, CUSTOMER_ID, PRODUCT_ID, ORDER_DATE
FROM CTE
WHERE RNK = '1';

-- Q-7. Which item was purchased just before the customer became a member?
WITH CTE AS(
SELECT S.CUSTOMER_ID, M.PRODUCT_ID, MEM.JOIN_DATE, S.ORDER_DATE,
DENSE_RANK() OVER(PARTITION BY S.CUSTOMER_ID ORDER BY S.ORDER_DATE DESC) AS RNK
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS MEM ON S.CUSTOMER_ID = MEM.CUSTOMER_ID
WHERE S.ORDER_DATE < MEM.JOIN_DATE)
SELECT JOIN_DATE, CUSTOMER_ID, PRODUCT_ID, ORDER_DATE
FROM CTE
WHERE RNK = '1';

-- Q-8. What is the total items and amount spent for each member before they became a member? 
SELECT S.CUSTOMER_ID, COUNT(*) AS TOTAL_ITEMS, SUM(M.PRICE) AS TOTAL_AMOUNT
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS MEM ON S.CUSTOMER_ID = MEM.CUSTOMER_ID
WHERE S.ORDER_DATE < MEM.JOIN_DATE
GROUP BY S.CUSTOMER_ID;

/*  Q-9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many 
points would each customer have?*/
SELECT S.CUSTOMER_ID, 
SUM( CASE WHEN M.PRODUCT_NAME = 'sushi' THEN M.PRICE * 20
ELSE M.PRICE * 10 END) AS TOTAL_POINTS
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
GROUP BY S.CUSTOMER_ID;

/* Q-10. In the first week after a customer joins the program (including their join date) they 
earn 2x points on all items, not just sushi - how many points do customer A and B have at the 
end of January?*/
SELECT S.CUSTOMER_ID,
SUM( CASE WHEN S.ORDER_DATE BETWEEN MEM.JOIN_DATE AND DATEADD(DAY,6,MEM.JOIN_DATE)
THEN M.PRICE * 20 WHEN M.PRODUCT_NAME = 'sushi'
THEN M.PRICE * 20
ELSE M.PRICE * 10 END ) AS TOTAL_POINTS
FROM SALES S
JOIN MENU M ON S.PRODUCT_ID = M.PRODUCT_ID
JOIN MEMBERS MEM ON S.CUSTOMER_ID = MEM.CUSTOMER_ID
WHERE MONTH(S.ORDER_DATE) = 1
GROUP BY S.CUSTOMER_ID;


