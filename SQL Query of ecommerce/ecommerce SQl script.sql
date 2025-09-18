SELECT * FROM ecommerce_sales.ecommerce_sales;
#overall sales
SELECT 
    COUNT(DISTINCT order_id) as total_orders,
    COUNT(DISTINCT customer_id) as total_customers,
    SUM(quantity) as total_units_sold,
    SUM(total_amount) as total_revenue,
    ROUND(AVG(total_amount), 2) as avg_order_value
FROM ecommerce_sales;

#sales by region(top products in sales)
SELECT 
    region,
    COUNT(DISTINCT order_id) as total_orders,
    COUNT(DISTINCT customer_id) as unique_customers,
    SUM(quantity) as total_units,
    SUM(total_amount) as total_revenue,
    ROUND(SUM(total_amount) / COUNT(DISTINCT order_id), 2) as avg_order_value
FROM ecommerce_sales
GROUP BY region
ORDER BY total_revenue DESC;

----#TOP 10 PRODUCTS IN SELLING----
SELECT 
    product_id,
    product_category,
    SUM(quantity) as total_units_sold,
    SUM(total_amount) as total_revenue,
    ROUND(AVG(price), 2) as avg_price,
    ROUND(SUM(total_amount) * 100.0 / (SELECT SUM(total_amount) FROM ecommerce_sales), 2) as revenue_percentage
FROM ecommerce_sales
GROUP BY product_id, product_category
ORDER BY total_revenue DESC
LIMIT 10;

#--MONTHLY SALES OF PRODUCTS IN TRENDS----
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') as month_year,
    region,
    COUNT(DISTINCT order_id) as monthly_orders,
    SUM(quantity) as monthly_units,
    SUM(total_amount) as monthly_revenue,
    ROUND((SUM(total_amount) - LAG(SUM(total_amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m'))) / 
          LAG(SUM(total_amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) * 100, 2) as growth_percentage
FROM ecommerce_sales
GROUP BY month_year, region
ORDER BY month_year, region;

# CUSTOMER ANALYSIS BY REGION
SELECT 
    region,
    COUNT(DISTINCT customer_id) as total_customers,
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(COUNT(DISTINCT order_id) * 1.0 / COUNT(DISTINCT customer_id), 2) as avg_orders_per_customer,
    ROUND(SUM(total_amount) / COUNT(DISTINCT customer_id), 2) as avg_revenue_per_customer,
    ROUND(SUM(quantity) / COUNT(DISTINCT customer_id), 2) as avg_units_per_customer
FROM ecommerce_sales
GROUP BY region
ORDER BY avg_revenue_per_customer DESC;

# TOP PRODUCTS IN EVERY REGION
WITH regional_products AS (
    SELECT 
        region,
        product_id,
        product_category,
        SUM(total_amount) as regional_revenue,
        RANK() OVER (PARTITION BY region ORDER BY SUM(total_amount) DESC) as rank_in_region
    FROM ecommerce_sales
    GROUP BY region, product_id, product_category
)
SELECT 
    region,
    product_id,
    product_category,
    regional_revenue
FROM regional_products
WHERE rank_in_region <= 5
ORDER BY region, rank_in_region;

# MONTHLY GROWTH ANALYSIS
WITH monthly_sales AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') as month_year,
        SUM(total_amount) as monthly_revenue,
        LAG(SUM(total_amount)) OVER (ORDER BY DATE_FORMAT(order_date, '%Y-%m')) as prev_month_revenue
    FROM ecommerce_sales
    GROUP BY month_year
)
SELECT 
    month_year,
    monthly_revenue,
    prev_month_revenue,
    ROUND((monthly_revenue - prev_month_revenue) / prev_month_revenue * 100, 2) as growth_percentage,
    CASE 
        WHEN (monthly_revenue - prev_month_revenue) > 0 THEN 'Growth'
        WHEN (monthly_revenue - prev_month_revenue) < 0 THEN 'NO Growth'
        ELSE 'No Change'
    END as trend
FROM monthly_sales
ORDER BY month_year;

# PRICE RANGE ANALYSIS BY PRODUCT CATEGORY
SELECT 
    product_category,
    COUNT(*) as products_count,
    ROUND(MIN(price), 2) as min_price,
    ROUND(MAX(price), 2) as max_price,
    ROUND(AVG(price), 2) as avg_price,
    ROUND(STDDEV(price), 2) as price_std_dev
FROM ecommerce_sales
GROUP BY product_category
ORDER BY avg_price DESC;

# REGIONAL PRODUCTS PREFERENCES
SELECT 
    region,
    product_category,
    SUM(quantity) as total_units_sold,
    SUM(total_amount) as total_revenue,
    ROUND(SUM(total_amount) * 100.0 / SUM(SUM(total_amount)) OVER (PARTITION BY region), 2) as region_percentage
FROM ecommerce_sales
GROUP BY region, product_category
ORDER BY region, total_revenue DESC;

# QUEATERLY PERFORMANCE REPORT
SELECT 
    YEAR(order_date) as year,
    QUARTER(order_date) as quarter,
    region,
    COUNT(DISTINCT order_id) as orders,
    SUM(total_amount) as revenue,
    ROUND(SUM(total_amount) / COUNT(DISTINCT order_id), 2) as avg_orders
FROM ecommerce_sales
GROUP BY year, quarter, region
ORDER BY year, quarter, revenue DESC;