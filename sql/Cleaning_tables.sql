USE Sales_analytics; 

-- DATA CLEANING FILE


CREATE OR REPLACE VIEW order_items_clean AS 
WITH remove_duplicate AS (
SELECT *,
ROW_NUMBER()OVER(PARTITION BY item_id,order_id )
 AS row_num
 
FROM order_items_raw),

-- FOUND 150 DUPLICATE ROW 
Dedup AS (
SELECT * FROM remove_duplicate 
WHERE row_num = 1)

-- REMOVED DUPLICATE 
 SELECT 
 NULLIF(TRIM(item_id), '') AS item_id, -- TRIMMING AND SETTING TO NULL 
 NULLIF(TRIM(order_id), '') AS order_id, -- TRIMMING AND SETTING TO NULL 
 NULLIF(TRIM(product_id), '') AS product_id, -- TRIMMING AND SETTING TO NULL
 
 -- HANDLING 0 NEGATIVE AND BLANK NUMBER 
 -- SET TO NULL
 CASE
 WHEN TRIM(quantity) ='' OR quantity IS NULL THEN NULL
 WHEN ABS(CAST(TRIM(quantity) AS SIGNED)) >5 OR ABS(CAST(TRIM(quantity) AS SIGNED)) = 0 THEN NULL
 ELSE ABS(CAST(TRIM(quantity) AS SIGNED)) 
 END
 AS quantity ,
 
  -- HANDLING 0 NEGATIVE AND BLANK NUMBER ALSO REMOVINF SYMBOL LIKE RS RUPEE ETC
 -- SET TO NULL
 CASE 
 WHEN TRIM(unit_price) ='' OR unit_price  IS NULL THEN NULL
 
 WHEN CAST(REGEXP_REPLACE(TRIM(unit_price),'[^0-9.]','') AS DECIMAL(10,2)) = 0 OR 
 CAST(REGEXP_REPLACE(TRIM(unit_price),'[^0-9.]','') AS DECIMAL(10,2)) >500  THEN NULL
 
 ELSE ABS(CAST(REGEXP_REPLACE(TRIM(unit_price),'[^0-9.]','') AS DECIMAL(10,2)))
 
 END  AS unit_price,
 
 -- line_total WRONG CALCULATION,NEGATIVE AND 0 
 -- FILLING RIGHT BY USING quantity*unit_price
  CASE 
WHEN ABS(CAST(TRIM(quantity) AS SIGNED)) > 0 
     AND ABS(CAST(REGEXP_REPLACE(TRIM(unit_price),'[^0-9.]','') AS DECIMAL(10,2))) > 0 
THEN 
    CASE 
        -- ✅ apply outlier on CALCULATED value
        WHEN ABS(CAST(TRIM(quantity) AS SIGNED)) *
             ABS(CAST(REGEXP_REPLACE(TRIM(unit_price),'[^0-9.]','') AS DECIMAL(10,2))) > 2000
        THEN NULL
        
        ELSE ABS(CAST(TRIM(quantity) AS SIGNED)) *
             ABS(CAST(REGEXP_REPLACE(TRIM(unit_price),'[^0-9.]','') AS DECIMAL(10,2)))
    END

-- fallback when calculation not possible
WHEN CAST(TRIM(quantity) AS SIGNED) <= 0 
     OR CAST(REGEXP_REPLACE(TRIM(unit_price),'[^0-9.]','') AS DECIMAL(10,2)) <= 0 
THEN 
    CASE 
        -- ✅ outlier on raw value
        WHEN TRIM(line_total) = '' OR TRIM(line_total) = '0' OR
             ABS(CAST(TRIM(line_total) AS DECIMAL(10,2))) > 2000
        THEN NULL
        
        ELSE ABS(CAST(TRIM(line_total) AS DECIMAL(10,2)))
    END

ELSE NULL
END AS line_total
  
  FROM Dedup ;
  
SELECT * FROM order_items_clean;  

-- orders_clean table cleaning
CREATE OR REPLACE VIEW orders_clean AS 
WITH Remove_duplicate AS (
  SELECT *,
  ROW_NUMBER() OVER(
  PARTITION BY order_id 
  ORDER BY customer_id) 
  AS row_num
  FROM orders_raw) ,
  
  -- DEDUP 
 Dedup AS
 ( SELECT * FROM Remove_duplicate
  WHERE row_num= 1 )
  
  SELECT 
  -- TRIMMING order_id
  TRIM(order_id) AS order_id,
  -- TRIMMING AND SETTING NULL customer_id WHERE BLANK OR INVALID VALUE IS PRESENT
  NULLIF(TRIM(customer_id),'') AS customer_id,
   -- formatting order_date to YYYY-mm-dd 
   -- multipe format of  date present
   CASE 
   WHEN TRIM(order_date) REGEXP'^[0-9]{4}-[0-9]{2}-[0-9]{2}$' 
   THEN STR_TO_DATE(TRIM(order_date),'%Y-%m-%d')
   
    WHEN TRIM(order_date) REGEXP'^[0-9]{2}/[0-9]{2}/[0-9]{4}$' 
   THEN STR_TO_DATE(TRIM(order_date),'%d/%m/%Y')
   
    WHEN TRIM(order_date) REGEXP'^[0-9]{2}\\.[0-9]{2}\\.[0-9]{4}$' 
   THEN STR_TO_DATE(TRIM(order_date),'%d.%m.%Y')
   
    WHEN TRIM(order_date) REGEXP'^[a-zA-Z]+ [0-9]{2}, [0-9]{4}$' 
   THEN STR_TO_DATE(TRIM(order_date),'%M %d, %Y')
   
   -- ambiguous date like DD-MM-YYYY VS MM-DD-YYYY 
   -- IF DAY >12 THEN DD-MM-YYYY FORMAT 
    WHEN TRIM(order_date) REGEXP'^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 
    AND SUBSTRING(TRIM(order_date),1,2) + 0 >12
   THEN STR_TO_DATE(TRIM(order_date),'%d-%m-%Y')
   
    -- IF MONTH >12 THEN MM-DD-YYYY FORMAT 
    WHEN TRIM(order_date) REGEXP'^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 
    AND SUBSTRING(TRIM(order_date),4,2) + 0 >12
   THEN STR_TO_DATE(TRIM(order_date),'%m-%d-%Y')
   
   -- assuming having all indian date ambiguous date is set to DD-MM-YYYY
    WHEN TRIM(order_date) REGEXP'^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 
   THEN STR_TO_DATE(TRIM(order_date),'%d-%m-%Y')
   
   ELSE NULL
   END AS order_date,
   
   -- STANDARDIZATION OF payment_method AS IT HAVE MULTIPLE VALUE FOR SAME METHOD
   CASE 
   WHEN LOWER(TRIM(payment_method)) IN('cash','cs') THEN 'CASH'
   WHEN LOWER(TRIM(payment_method)) IN('credit card','cd') THEN 'Credit Card'
   WHEN LOWER(TRIM(payment_method)) IN('debit card','db') THEN 'Debit Card'
   WHEN LOWER(TRIM(payment_method)) IN('netbanking','net banking') THEN 'Net Banking'
   WHEN LOWER(TRIM(payment_method)) IN('upi') THEN 'UPI'
   WHEN LOWER(TRIM(payment_method)) IN('wallet') THEN 'Wallet'
   
   ELSE null
   END AS payment_method,
   
    -- STANDARDIZATION OF order_status AS IT HAVE MULTIPLE VALUE FOR SAME METHOD
	CASE 
    WHEN LOWER(TRIM(order_status)) IN ('cancelled','cancel') THEN 'Cancelled'
    WHEN LOWER(TRIM(order_status)) IN ('delivered','deliver') THEN 'Delivered'
	WHEN LOWER(TRIM(order_status)) IN ('Pending','pnd') THEN 'Pending'
    WHEN LOWER(TRIM(order_status)) IN ('Returned','return','rtn') THEN 'Returned'
    ELSE null 
    END AS order_status,
    
    -- CASTING discount_pct 
    -- SETTING NULL TO OUTLIERS,-DISCOUNT AND BLANK AND REMOVE ANY SYMBOL 
    CASE 
    WHEN TRIM(discount_pct) = '' THEN NULL 
    WHEN CAST(REGEXP_REPLACE(TRIM(discount_pct),'[^0-9.]','') AS DECIMAL(5,1)) > 50 THEN NULL 
    WHEN CAST(REGEXP_REPLACE(TRIM(discount_pct),'[^0-9.]','') AS DECIMAL(5,1)) < 0 THEN NULL
    ELSE CAST(REGEXP_REPLACE(TRIM(discount_pct),'[^0-9.]','') AS DECIMAL(5,1)) 
    END AS discount_pct,
    
    -- TRIMMING AND SETTING NULL TO BLANK
    NULLIF(TRIM(store_location),'') AS store_location
  FROM Dedup;
  SELECT * FROM orders_clean ;


--  ///////////////// CLEANING CUSTOMER TABLE //////////
CREATE OR REPLACE VIEW customer_clean AS 

SELECT 
-- TRIMMING customer_id 
 TRIM(customer_id) AS customer_id, -- NO NULL OR BLANK
 
 -- TRIMMING AND SET TO NULL BLANK first_name
NULLIF(TRIM(first_name),'') AS first_name,

-- TRIMMING AND SET TO NULL BLANK last_name
NULLIF(TRIM(last_name),'') AS last_name,

-- SETTING NULL TO INVALID EMAIL (BLANK AND INVALID)
 CASE
  WHEN TRIM(email) ='' THEN NULL 
  WHEN TRIM(email) NOT LIKE'%@gmail.com' AND TRIM(email) NOT LIKE'%@yahoo.com' THEN NULL 
  ELSE TRIM(email) 
  END AS email,
  
 -- SET TO NULL BLANK NUMBER , REMONE NON-DIGIT CHARS AND COUNTRY CODE, KEEP VALID 10 DIGIT NUMBER  
CASE 
WHEN TRIM(phone) = '' THEN NULL 
WHEN LENGTH(REGEXP_REPLACE(TRIM(phone),'[^0-9]','')) < 10 THEN NULL
ELSE RIGHT(REGEXP_REPLACE(TRIM(phone),'[^0-9]',''),10)
END AS phone,

-- STANDARDIZATION OF gender and set to null for blank (IT HAS MULTIPLE VALUE FOR SAME GENDER)

CASE 
WHEN TRIM(gender) = '' THEN NULL 
WHEN LOWER(TRIM(gender)) IN ('female','f') THEN 'Female' 
WHEN LOWER(TRIM(gender)) IN ('male','m') THEN 'Male' 
ELSE TRIM(gender) 

 END AS gender,

 -- STANDARDIZATION OF city and set to null for blank (IT HAS MULTIPLE VALUE FOR SAME city)
 CASE
  WHEN TRIM(city) = '' THEN NULL
    WHEN LOWER(TRIM(city)) IN ('ahemdabad','ahmedabad')
        THEN 'Ahmedabad'

    WHEN LOWER(TRIM(city)) IN ('bangalore','bangaluru','bengaluru')
        THEN 'Bengaluru'

    WHEN LOWER(TRIM(city)) = 'bhopal'
        THEN 'Bhopal'

    WHEN LOWER(TRIM(city)) IN ('bombay','mumbai')
        THEN 'Mumbai'

    WHEN LOWER(TRIM(city)) IN ('calcutta','kolkata')
        THEN 'Kolkata'

    WHEN LOWER(TRIM(city)) IN ('chennai','madras')
        THEN 'Chennai'

    WHEN LOWER(TRIM(city)) IN ('delhi','new delhi','delhi ncr')
        THEN 'Delhi'

    WHEN LOWER(TRIM(city)) IN ('hyd','hyderabad')
        THEN 'Hyderabad'

    WHEN LOWER(TRIM(city)) = 'jaipur'
        THEN 'Jaipur'

    WHEN LOWER(TRIM(city)) IN ('lko','lucknow')
        THEN 'Lucknow'

    WHEN LOWER(TRIM(city)) IN ('pink city')
        THEN 'Jaipur'

    WHEN LOWER(TRIM(city)) IN ('poona','pune')
        THEN 'Pune'

    WHEN LOWER(TRIM(city)) = 'surat'
        THEN 'Surat'

    ELSE TRIM(city)
END AS city,

-- STANDARDIZATION OF state and set to null for blank (IT HAS MULTIPLE VALUE FOR SAME state)
CASE
    WHEN TRIM(state) = '' THEN NULL
    WHEN LOWER(TRIM(state)) IN ('delhi','dl','nct delhi')
        THEN 'Delhi'

    WHEN LOWER(TRIM(state)) IN ('gj','gujarat','gujrat')
        THEN 'Gujarat'

    WHEN LOWER(TRIM(state)) IN ('ka','karnataka','karnatka')
        THEN 'Karnataka'

    WHEN LOWER(TRIM(state)) IN ('mp','madhya pradesh')
        THEN 'Madhya Pradesh'

    WHEN LOWER(TRIM(state)) IN ('mh','maharashtra','maharastra')
        THEN 'Maharashtra'

    WHEN LOWER(TRIM(state)) IN ('rajasthan','rajsthan','rj')
        THEN 'Rajasthan'

    WHEN LOWER(TRIM(state)) IN ('tn','tamil nadu','tamilnadu')
        THEN 'Tamil Nadu'

    WHEN LOWER(TRIM(state)) IN ('ts','telangana','telegana')
        THEN 'Telangana'

    WHEN LOWER(TRIM(state)) IN ('up','u.p.','uttar pradesh')
        THEN 'Uttar Pradesh'

    WHEN LOWER(TRIM(state)) IN ('wb','w bengal','west bengal')
        THEN 'West Bengal'

    ELSE TRIM(state)
END AS state,

 -- formatting signup_date to YYYY-mm-dd 
   -- multipe format of  date present
   CASE 
   WHEN TRIM(signup_date) REGEXP'^[0-9]{4}-[0-9]{2}-[0-9]{2}$' 
   THEN STR_TO_DATE(TRIM(signup_date),'%Y-%m-%d')
   
    WHEN TRIM(signup_date) REGEXP'^[0-9]{2}/[0-9]{2}/[0-9]{4}$' 
   THEN STR_TO_DATE(TRIM(signup_date),'%d/%m/%Y')
   
    WHEN TRIM(signup_date) REGEXP'^[0-9]{2}\\.[0-9]{2}\\.[0-9]{4}$' 
   THEN STR_TO_DATE(TRIM(signup_date),'%d.%m.%Y')
   
    WHEN TRIM(signup_date) REGEXP'^[a-zA-Z]+ [0-9]{2}, [0-9]{4}$' 
   THEN STR_TO_DATE(TRIM(signup_date),'%M %d, %Y')
   
   -- ambiguous date like DD-MM-YYYY VS MM-DD-YYYY 
   -- IF DAY >12 THEN DD-MM-YYYY FORMAT 
    WHEN TRIM(signup_date) REGEXP'^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 
    AND SUBSTRING(TRIM(signup_date),1,2) + 0 >12
   THEN STR_TO_DATE(TRIM(signup_date),'%d-%m-%Y')
   
    -- IF MONTH >12 THEN MM-DD-YYYY FORMAT 
    WHEN TRIM(signup_date) REGEXP'^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 
    AND SUBSTRING(TRIM(signup_date),4,2) + 0 >12
   THEN STR_TO_DATE(TRIM(signup_date),'%m-%d-%Y')
   
   -- assuming having all indian date ambiguous date is set to DD-MM-YYYY
    WHEN TRIM(signup_date) REGEXP'^[0-9]{2}-[0-9]{2}-[0-9]{4}$' 
   THEN STR_TO_DATE(TRIM(signup_date),'%d-%m-%Y')
   
   ELSE NULL
   END AS signup_date,
   
   -- STANDARDIZATION OF membership and set to null for blank (IT HAS MULTIPLE VALUE FOR SAME membership)
   CASE
    WHEN  TRIM(membership) = '' THEN NULL
    WHEN LOWER(TRIM(membership)) = 'bronze'
        THEN 'Bronze'

    WHEN LOWER(TRIM(membership)) = 'silver'
        THEN 'Silver'

    WHEN LOWER(TRIM(membership)) = 'gold'
        THEN 'Gold'

    WHEN LOWER(TRIM(membership)) = 'platinum'
        THEN 'Platinum'

    ELSE TRIM(membership)
END AS membership

FROM  customer_raw;
   SELECT * FROM customer_clean; 
   
   -- cleaning of products table
   CREATE OR REPLACE VIEW products_clean AS 
   SELECT
   
   -- TRIMMING product_id
   TRIM(product_id) AS product_id,
   
   -- TRIMMING product_name AND SETTING NULL TO BLANK IF EXISTS
   NULLIF(TRIM(product_name) , '') AS product_name,
   
   -- TRIMMING category AND SETTING NULL TO BLANK IF EXISTS
   NULLIF(TRIM(category),'') AS category,
   
   --  SET TO NULL BLANK mrp , REMONE NON-DIGIT CHARS AND KEEP VALID mrp
	CAST(NULLIF(REGEXP_REPLACE(TRIM(mrp),'[^0-9]',''),'') AS DECIMAL(5,1)) AS mrp,
     
      --  SET TO NULL BLANK mrp , REMONE NON-DIGIT CHARS AND KEEP VALID mrp
    CAST(NULLIF(REGEXP_REPLACE(TRIM(cost_price),'[^0-9]',''),'') AS DECIMAL(5,1)) AS cost_price,
    
    -- TRIMMING unit AND SETTING BLANK TO NULL 
    NULLIF(TRIM(unit),'') AS unit,
    
	-- TRIMMING brand AND SETTING BLANK TO NULL 
     NULLIF(TRIM(brand),'') AS brand,
     
     -- TRIMMING AND CASTING TO BOOLEAN
     CASE
    WHEN UPPER(TRIM(is_active)) = 'YES' THEN TRUE
    WHEN UPPER(TRIM(is_active)) = 'NO' THEN FALSE
    ELSE NULL
    END AS is_active
    FROM products_raw;
    
    SELECT * FROM products_clean;
SELECT * FROM products_raw
LIMIT 50;



