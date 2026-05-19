CREATE DATABASE IF NOT EXISTS Sales_analytics;
USE Sales_analytics;
-- creating raw table where data is same as it was 

-- customer_raw TABLE 
CREATE TABLE IF NOT EXISTS customer_raw (
    customer_id VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(255),
    gender VARCHAR(50),
    city VARCHAR(255),
    state VARCHAR(255),
    signup_date VARCHAR(50),
    membership VARCHAR(100)
);


-- order_items_raw TABLE
CREATE TABLE IF NOT EXISTS order_items_raw (
    item_id VARCHAR(255),
    order_id VARCHAR(255),
    product_id VARCHAR(255),
    quantity VARCHAR(50),
    unit_price VARCHAR(50),
    line_total VARCHAR(100)
);

-- orders_raw TABLE
CREATE TABLE IF NOT EXISTS orders_raw (
    order_id VARCHAR(255),
    customer_id VARCHAR(255),
    order_date VARCHAR(50),
    payment_method VARCHAR(100),
    order_status VARCHAR(100),
    discount_pct VARCHAR(50),
    store_location VARCHAR(255)
);

-- products_raw TABLE
CREATE TABLE IF NOT EXISTS products_raw (
    product_id VARCHAR(255),
    product_name VARCHAR(255),
    category VARCHAR(255),
    mrp VARCHAR(50),
    cost_price VARCHAR(50),
    unit VARCHAR(50),
    brand VARCHAR(255),
    is_active VARCHAR(10)
);