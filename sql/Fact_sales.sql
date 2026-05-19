USE Sales_analytics;

-- CREATING BUSINESS LAYER ///////////
 CREATE OR REPLACE VIEW Fact_sales AS 
 SELECT 
 oi.item_id AS item_id,
 o.order_id AS order_id,
 p.product_id AS product_id,
 o.customer_id AS customer_id,
 o.order_date AS order_date,
 p.cost_price AS cost_price,
 oi.quantity AS quantity,
 oi.unit_price AS unit_price,
 o.discount_pct AS discount_pct,
 oi.line_total AS line_total,
 o.payment_method AS payment_method,
 o.order_status AS order_status,
 o.store_location AS store_location,
 CASE 
 WHEN oi.line_total IS NULL THEN NULL 
 ELSE ROUND(oi.line_total*(1-COALESCE(o.discount_pct,0)/100),2) 
 END AS Revenue,
 
 CASE
 WHEN oi.quantity IS NULL THEN NULL
ELSE  oi.quantity*p.cost_price
END AS Total_cost,
 
  CASE 
 WHEN 
 oi.line_total IS NULL THEN NULL 
 ELSE 
 ROUND((oi.line_total*(1-COALESCE(o.discount_pct,0)/100))-(oi.quantity*p.cost_price),2)
 END AS Gross_profit,
 
 CASE 
 WHEN oi.line_total IS NULL THEN NULL
 WHEN SUM(oi.line_total)OVER(PARTITION BY o.order_id) <=500  THEN 'Low' 
 WHEN SUM(oi.line_total)OVER(PARTITION BY o.order_id) BETWEEN 501 AND 1500 THEN 'Mid'
 ELSE 'High'
 END AS Order_segment,
 
 CASE 
 WHEN oi.quantity IS NOT NULL 
 AND oi.unit_price IS NOT NULL
 AND oi.line_total IS NOT NULL
 THEN 'Verified' 
 
 WHEN  oi.line_total IS NOT NULL
 THEN 'Unverified'
 
 ELSE 'Invalid'
 END AS Line_total_status,
 
 CASE 
 WHEN o.discount_pct IS NULL THEN NULL 
  WHEN  o.discount_pct =0 THEN 'No_dsct'
 WHEN  o.discount_pct <=10 THEN 'Low_dsct'
 WHEN  o.discount_pct BETWEEN 11 AND 20 THEN 'Mid_dsct' 
 ELSE 'High_dsct'
 END AS discount_segmentation,
 
 CASE 
 WHEN 
 oi.line_total IS NULL THEN 'Invalid' 
 WHEN ROUND((oi.line_total*(1-COALESCE(o.discount_pct,0)/100))-(oi.quantity*p.cost_price),2) >0 THEN 'Profitable'
 WHEN ROUND((oi.line_total*(1-COALESCE(o.discount_pct,0)/100))-(oi.quantity*p.cost_price),2) = 0 THEN 'Break Even'
 ELSE 'Loss' 
 END AS Profit_flag
 
 
  FROM order_items_clean oi 
  JOIN orders_clean o ON oi.order_id = o.order_id 
  JOIN products_clean p ON oi.product_id = p.product_id;

 SELECT * FROM Fact_sales;



   