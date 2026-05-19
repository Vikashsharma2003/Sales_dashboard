USE Sales_analytics; 
-- ///////    TABLE order_items_raw    /////

SELECT COUNT(*) AS total_rows FROM order_items_raw;
-- total rows 4594

-- DATA CHECKING 
SELECT * FROM order_items_raw
LIMIT 50;
 
 -- DUPLICATE CHECK
SELECT item_id,product_id,quantity,COUNT(*) 
FROM order_items_raw
GROUP BY item_id,product_id,quantity
HAVING COUNT(*) > 1;

-- INVALID VALUE LIKE WHITE SPACE BLANK 
SELECT *
FROM order_items_raw
WHERE 
    quantity IS NULL OR TRIM(quantity) = '' OR quantity REGEXP '[^0-9]'
    OR unit_price IS NULL OR TRIM(unit_price) = '' OR unit_price REGEXP '[^0-9.]'
    OR line_total IS NULL OR TRIM(line_total) = '' OR line_total REGEXP '[^0-9.]';
    
    
    -- INVALID line_value
    
    SELECT * FROM order_items_raw
    WHERE line_total < quantity*unit_price; 
    
    
-- ////////    table items_raw /////////
SELECT * FROM orders_raw
LIMIT 50;


-- CHECK DUPLICATE 
SELECT order_id , COUNT(*) 
FROM orders_raw
GROUP BY order_id
HAVING COUNT(*)>1 ; -- 50 ROWS 
 
-- CHECK PAYMENT_METHOD 
SELECT DISTINCT  payment_method COLLATE utf8mb4_bin FROM orders_raw;

-- CHECK order_status 
SELECT DISTINCT  order_status COLLATE utf8mb4_bin FROM orders_raw;

-- CHECK store_location 
SELECT DISTINCT  store_location COLLATE utf8mb4_bin FROM orders_raw;

-- DISCOUNT_PCT HAVING SYMBOL
SELECT * FROM orders_raw
WHERE TRIM(discount_pct) = '' OR 
TRIM(discount_pct) = '0' OR 
TRIM(discount_pct) REGEXP'[^0-9]'; -- 366 WRONG VALUE 


-- ORDER TABLE ///////

SELECT COUNT(*) AS total_rows FROM orders_raw;
-- total rows 1050 

-- DUPLICATE COUNT 
SELECT order_id , COUNT(*) 
FROM orders_raw
GROUP BY order_id
HAVING  COUNT(*) >1 ;-- 50 DUPLICATE ORDER 

-- CHECKING DATE AND ITS FORMATS
SELECT DISTINCT order_date FROM orders_raw; -- MULTIPLE FORMAT WITH AMBIGUOUS DATE

-- CHECKING PAYMENT METHOD 
  SELECT DISTINCT payment_method  COLLATE utf8mb4_bin FROM orders_raw; -- MULTIPLE VALUE FOR SAME PAYMENT METHOD   
  
  
-- CHECKING order_status 
  SELECT DISTINCT order_status  COLLATE utf8mb4_bin FROM orders_raw; -- MULTIPLE VALUE FOR SAME order_status 
  
  -- CHECKING discount_pct 
  SELECT DISTINCT discount_pct  COLLATE utf8mb4_bin FROM orders_raw; -- OUTLIERS,- DISCOUNT AND BLANK VALUE
  
  -- CHECKING store_location  
  SELECT DISTINCT store_location  COLLATE utf8mb4_bin FROM orders_raw;
  
  -- CUSTOMER TABLE ////////
   SELECT COUNT(*) FROM customer_raw;
   -- 300 ROWS
   
   
   -- DUPLICATE CHECK 
   SELECT customer_id,COUNT(*) 
   FROM  customer_raw
   GROUP BY customer_id
   HAVING COUNT(*) >1; -- NO DUPLICATE FOUND 
   
   
   -- CHECK INVALID CUSTOMER ID
   SELECT * FROM customer_raw
   WHERE TRIM(customer_id) = '' OR customer_id IS NULL;
   
   -- CHECK INVALID EMAIL ID 
   SELECT * FROM customer_raw
   WHERE email NOT LIKE '%@gmail.com' AND  email NOT LIKE '%@yahoo.com'; -- SOME INVALID AND BLANK EMAIL 
   
   -- CHECKING gender
   SELECT DISTINCT gender  COLLATE utf8mb4_bin  FROM customer_raw; -- MULTIPLE VALUE FOR SAME GENDER WITH SOME BLANK
   
	-- CHECKING city  
   SELECT DISTINCT city  COLLATE utf8mb4_bin  FROM customer_raw; -- MULTIPLE VALUE FOR SAME city WITH SOME BLANK
   
   -- CHECKING state  
   SELECT DISTINCT state  COLLATE utf8mb4_bin  FROM customer_raw; -- MULTIPLE VALUE FOR SAME state WITH SOME BLANK

 -- CHECKING membership  
   SELECT DISTINCT membership  COLLATE utf8mb4_bin  FROM customer_raw; -- MULTIPLE VALUE FOR SAME membership WITH SOME BLANK
   
   
   
   -- ////// product table
    SELECT COUNT(*) FROM products_raw;
   -- 44 rows
   
   -- CHECKING DUPLICATE
   SELECT product_id,COUNT(*)
   FROM  products_raw
   GROUP BY product_id
   HAVING COUNT(*) >1;
   -- 0 DUPLICATE
   
   -- CHECKING INVALID product_id
   SELECT * FROM products_raw
   WHERE TRIM(product_id) = ''; -- 0 INVALID VALUE 
   
   -- CHECKING CATEGORY
   SELECT DISTINCT category COLLATE utf8mb4_bin  FROM products_raw ;
   
   -- CHECKING SYMBOL IN MRP AND COST 
   SELECT * FROM products_raw
   WHERE mrp REGEXP '[^0-9]' OR cost_price REGEXP '[^0-9]'; -- 0 INVALID ENTRY
   
   -- CHECK DISTINCT is_active
    SELECT DISTINCT is_active COLLATE utf8mb4_bin  FROM products_raw ;
SELECT * FROM products_raw;