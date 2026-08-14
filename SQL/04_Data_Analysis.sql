/* =============================================================================
   SECTION 4: DATA ANALYSIS & BUSINESS INTELLIGENCE
   
   Structure per Query:
   - Business Question
   - SQL Query
   - Business Result (Populated upon execution)
   - Business Insight
============================================================================= */

-- =============================================================================
-- SECTION 1: EXECUTIVE KPIs
-- =============================================================================

-- -----------------------------------------------------------------------------
-- KPI 1.1: Total Gross Revenue (Order Line Items)
-- Business Question: What is the gross revenue generated across all sold items?
-- -----------------------------------------------------------------------------
SELECT 
    ROUND(SUM(qty * price), 2) AS total_gross_revenue
FROM order_items;

/*
Business Result:
[Execute in database to populate]

Business Insight:
Represents gross sales value prior to discounts, refunds, and payment settlement adjustments.
*/

-- -----------------------------------------------------------------------------
-- KPI 1.2: Total Net Revenue (Settled Payments)
-- Business Question: What is the net cash collected through settled payment transactions?
-- -----------------------------------------------------------------------------
SELECT 
    ROUND(SUM(amount), 2) AS total_net_revenue
FROM payments;

/*
Business Result:
[Execute in database to populate]

Business Insight:
Serves as the actual cash-flow baseline for finance team reconciliations.
*/

-- -----------------------------------------------------------------------------
-- KPI 2: Total Orders
-- Business Question: How many total orders have been placed in the system?
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_orders
FROM orders;

/*
Business Result:
[Execute in database to populate]

Business Insight:
Establishes baseline order volume for operational capacity and throughput metrics.
*/

-- -----------------------------------------------------------------------------
-- KPI 3: Total Customers
-- Business Question: What is the total registered customer base?
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_customers
FROM customers;

/*
Business Result:
[Execute in database to populate]

Business Insight:
Serves as the denominator for customer penetration and acquisition analyses.
*/

-- -----------------------------------------------------------------------------
-- KPI 4: Total Products
-- Business Question: How many unique products exist in the catalog?
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_products
FROM products;

/*
Business Result:
[Execute in database to populate]

Business Insight:
Reflects catalog breadth and overall SKU portfolio size.
*/

-- -----------------------------------------------------------------------------
-- KPI 5: Total Units Sold
-- Business Question: What is the cumulative quantity of items sold across all orders?
-- -----------------------------------------------------------------------------
SELECT 
    SUM(qty) AS total_units_sold
FROM order_items;

/*
Business Result:
[Execute in database to populate]

Business Insight:
Critical volume metric for warehouse throughput, freight planning, and inventory turnover.
*/

-- -----------------------------------------------------------------------------
-- KPI 6: Average Order Value (AOV)
-- Business Question: What is the average monetary value of a customer order?
-- -----------------------------------------------------------------------------
WITH OrderTotals AS (
    SELECT 
        order_id,
        SUM(qty * price) AS order_gross_value
    FROM order_items
    GROUP BY order_id
)
SELECT 
    ROUND(AVG(order_gross_value), 2) AS average_order_value
FROM OrderTotals;

/*
Business Result:
[Execute in database to populate]

Business Insight:
Key baseline for pricing, bundling, and promotional cross-selling strategies.
*/

-- -----------------------------------------------------------------------------
-- KPI 7: Total Refund Amount
-- Business Question: What is the cumulative value of all processed customer refunds?
-- -----------------------------------------------------------------------------
SELECT 
    ROUND(SUM(refund), 2) AS total_refund_amount
FROM return_items;

/*
Business Result:
[Execute in database to populate]

Business Insight:
Measures revenue leakage due to product defects, shipping delays, or buyer remorse.
*/

-- =============================================================================
-- SECTION 2: CUSTOMER ANALYSIS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 2.1: Top 10 Cities by Customer Volume & Revenue Contribution
-- Business Question: Where are our customers concentrated, and do high-volume 
--                    cities correlate with high revenue generation?
-- -----------------------------------------------------------------------------
SELECT 
    c.city,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.amount), 2) AS total_revenue,
    ROUND(SUM(p.amount) / COUNT(DISTINCT c.customer_id), 2) AS avg_revenue_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN payments p ON o.order_id = p.order_id
GROUP BY c.city
ORDER BY total_customers DESC
LIMIT 10;

/*
Business Result:
[Execute in database to populate]

Business Insight:
Identifies geographic concentration and reveals whether top customer markets yield high 
per-capita revenue value.
*/

-- -----------------------------------------------------------------------------
-- Query 2.2: Customer Acquisition Trend & Cumulative Growth Over Time
-- Business Question: What is our monthly new customer acquisition rate, and how 
--                    is our total customer base accumulating over time?
-- SQL Focus: Date Formatting, CTEs, Window Function (SUM OVER)
-- -----------------------------------------------------------------------------

WITH MonthlyAcquisitions AS (
    SELECT 
        DATE_FORMAT(signup_date, '%Y-%m') AS acquisition_month,
        COUNT(customer_id) AS new_customers
    FROM customers
    GROUP BY DATE_FORMAT(signup_date, '%Y-%m')
)
SELECT 
    acquisition_month,
    new_customers,
    SUM(new_customers) OVER (ORDER BY acquisition_month ASC) AS cumulative_customers
FROM MonthlyAcquisitions
ORDER BY acquisition_month ASC;
/*
Business Result:
[Execute in database to populate]

Business Insight:
Highlights acquisition velocity over time to support supply chain capacity planning.
*/

-- -----------------------------------------------------------------------------
-- Query 2.3: Customer Spend Segmentation (RFM-Lite Tiers)
-- Business Question: How is our customer base distributed across monetary spend tiers?
-- -----------------------------------------------------------------------------
WITH CustomerSpend AS (
    SELECT 
        c.customer_id,
        coalesce(SUM(p.amount),0) AS total_spend
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN payments p ON o.order_id = p.order_id
    GROUP BY c.customer_id
),
CustomerSegments AS (
    SELECT 
        customer_id,
        total_spend,
        CASE 
            WHEN total_spend = 0 THEN '4 - No Purchases'
            WHEN total_spend < 500 THEN '3 - Low Spender (< $500)'
            WHEN total_spend BETWEEN 500 AND 2000 THEN '2 - Medium Spender ($500-$2k)'
            ELSE '1 - High Spender (> $2k)'
        END AS spend_tier
    FROM CustomerSpend
)
SELECT 
    spend_tier,
    COUNT(customer_id) AS total_customers,
    ROUND(COUNT(customer_id) * 100.0 / (SELECT COUNT(*) FROM customers), 2) AS pct_of_total_customers,
    ROUND(SUM(total_spend), 2) AS total_tier_revenue
FROM CustomerSegments
GROUP BY spend_tier
ORDER BY spend_tier ASC;

/*
Business Result:
[Execute in database to populate]

Business Insight:
Tests Pareto concentration (e.g., whether top spenders drive majority revenue) to guide 
retention investments.
*/

-- -----------------------------------------------------------------------------
-- Query 2.4: Repeat Purchase Rate & Order Frequency
-- Business Question: What percentage of our customer base returns to make repeat purchases?
-- -----------------------------------------------------------------------------
WITH OrderCounts AS (
    SELECT 
        c.customer_id,
        COUNT(o.order_id) AS total_orders
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
)
SELECT 
    COUNT(CASE WHEN total_orders = 0 THEN 1 END) AS zero_order_customers,
    COUNT(CASE WHEN total_orders = 1 THEN 1 END) AS single_order_customers,
    COUNT(CASE WHEN total_orders > 1 THEN 1 END) AS repeat_customers,
    COUNT(*) AS total_customers,
    ROUND(COUNT(CASE WHEN total_orders > 1 THEN 1 END) * 100.0 / COUNT(*), 2) AS repeat_purchase_rate_pct
FROM OrderCounts;

/*
Business Result:
[Execute in database to populate]

Business Insight:
A core retention metric indicating product satisfaction and brand stickiness vs acquisition dependency.
*/



-- =============================================================================
-- SECTION 3: PRODUCT & CATEGORY ANALYSIS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 3.1: Top 3 Revenue-Generating Products Per Category
-- Business Question: What are the highest-performing products within each product 
--                    category, and how do they rank relative to peers?
-- SQL Focus: Multi-table JOINs, CTEs, Partitioned Window Function (DENSE_RANK)
-- -----------------------------------------------------------------------------

WITH RankedProducts AS (
    SELECT 
        c.category_name,
        p.product_id,
        SUM(oi.qty) AS total_units_sold,
        ROUND(SUM(oi.qty * oi.price), 2) AS total_gross_revenue,
        DENSE_RANK() OVER (
            PARTITION BY c.category_id 
            ORDER BY SUM(oi.qty * oi.price) DESC
        ) AS category_rank
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    GROUP BY c.category_id, c.category_name, p.product_id
)
SELECT 
    category_name,
    product_id,
    total_units_sold,
    total_gross_revenue,
    category_rank
FROM RankedProducts
WHERE category_rank <= 3
ORDER BY category_name ASC, category_rank ASC;

/*
Business Result:
[Execute in database to populate result table]

Business Insight:
Identifies hero SKUs per category. Helps retail buyers maintain stock priority 
on top-ranking items while avoiding stockouts during promotional events.
*/

-- -----------------------------------------------------------------------------
-- Query 3.2: Category Revenue Contribution & Concentration
-- Business Question: Which categories generate the bulk of our revenue, and what 
--                    is each category's share of total business volume?
-- SQL Focus: CTEs, Window Aggregations, Percentage Share Calculation
-- -----------------------------------------------------------------------------

WITH CategoryPerformance AS (
    SELECT 
        c.category_name,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        SUM(oi.qty) AS total_units_sold,
        ROUND(SUM(oi.qty * oi.price), 2) AS category_revenue
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    GROUP BY c.category_id, c.category_name 
)
SELECT 
    category_name,
    total_orders,
    total_units_sold,
    category_revenue,
    ROUND(
        category_revenue * 100.0 / SUM(category_revenue) OVER (), 
        2
    ) AS pct_share_of_total_revenue
FROM CategoryPerformance
ORDER BY category_revenue DESC limit 3;

/*
Business Result:
[Execute in database to populate result table]

Business Insight:
Evaluates business concentration risk. If 2 categories account for over 60% of total revenue, 
the business is vulnerable to supply chain disruptions in those specific supplier bases.
*/

-- -----------------------------------------------------------------------------
-- Query 3.3: Product Price Point Distribution & Unit Velocity
-- Business Question: How does product pricing impact unit sales velocity and overall 
--                    revenue contribution?
-- SQL Focus: Conditional CASE Bucketing, Sub-aggregations
-- -----------------------------------------------------------------------------

WITH ProductMetrics AS (
    SELECT 
        p.product_id,
        p.price AS catalog_price,
        COALESCE(SUM(oi.qty), 0) AS total_units_sold,
        COALESCE(SUM(oi.qty * oi.price), 0) AS gross_revenue
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.price
),
PriceTiers AS (
    SELECT 
        product_id,
        total_units_sold,
        gross_revenue,
        CASE 
            WHEN catalog_price < 20 THEN '1 - Budget (< $20)'
            WHEN catalog_price BETWEEN 20 AND 100 THEN '2 - Mid-Tier ($20-$100)'
            ELSE '3 - Premium (> $100)'
        END AS price_tier
    FROM ProductMetrics
)
SELECT 
    price_tier,
    COUNT(product_id) AS catalog_sku_count,
    SUM(total_units_sold) AS total_units_sold,
    ROUND(SUM(gross_revenue), 2) AS total_tier_revenue,
    ROUND(SUM(gross_revenue) / NULLIF(SUM(total_units_sold), 0), 2) AS avg_realized_unit_price
FROM PriceTiers
GROUP BY price_tier
ORDER BY price_tier ASC;

/*
Business Result:
[Execute in database to populate result table]

Business Insight:
Reveals whether revenue is driven by high-volume budget items or high-margin premium products, 
informing catalog strategy and merchandising focus.
*/

-- -----------------------------------------------------------------------------
-- Query 3.4: Underperforming / Slow-Moving SKUs (Inventory Leakage)
-- Business Question: Which catalog products have generated zero or minimal sales, 
--                    representing potential dead stock?
-- SQL Focus: LEFT JOINs, NULL Handling, Filtering
-- -----------------------------------------------------------------------------

SELECT 
    p.product_id,
    c.category_name,
    p.price AS catalog_price,
    COALESCE(SUM(oi.qty), 0) AS total_units_sold,
    COALESCE(SUM(oi.qty * oi.price), 0) AS total_revenue_generated
FROM products p
JOIN categories c ON p.category_id = c.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, c.category_name, p.price
HAVING COALESCE(SUM(oi.qty), 0) = 0
ORDER BY p.price DESC
LIMIT 20;

/*
Business Result:
[Execute in database to populate result table]

Business Insight:
Highlights dormant SKUs sitting in the product master table. In real-world retail, 
carrying unsold inventory incurs holding costs and requires vendor markdown strategies.
*/


-- =============================================================================
-- SECTION 4: SUPPLY CHAIN, SHIPMENTS & RETURNS ANALYSIS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Query 4.1: Order Fulfillment & Shipment Status Distribution
-- Business Question: What proportion of our total orders successfully reach 
--                    delivery vs getting delayed, cancelled, or returned?
-- SQL Focus: JOINs, CASE Statements, Proportion / Percentage Calculation
-- -----------------------------------------------------------------------------

SELECT 
    s.status AS shipment_status,
    COUNT(s.shipment_id) AS total_shipments,
    ROUND(
        COUNT(s.shipment_id) * 100.0 / (SELECT COUNT(*) FROM shipments), 
        2
    ) AS pct_of_total_shipments
FROM shipments s
GROUP BY s.status
ORDER BY total_shipments DESC;

/*
Business Result:
[Execute in database to populate result table]

Business Insight:
Identifies operational bottlenecks. A high percentage of 'Cancelled' or 'In Transit' 
orders indicates potential carrier SLA breaches or inventory stockout failures.
*/

-- -----------------------------------------------------------------------------
-- Query 4.2: Category Return Rates & Revenue Leakage
-- Business Question: Which product categories generate the highest return rates 
--                    and refund costs?
-- SQL Focus: Multi-table JOINs, Sub-aggregations, Rate Calculations
-- -----------------------------------------------------------------------------

WITH CategorySales AS (
    SELECT 
        c.category_id,
        c.category_name,
        COUNT(DISTINCT oi.order_item_id) AS total_items_sold,
        SUM(oi.qty * oi.price) AS gross_sales
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    GROUP BY c.category_id, c.category_name
),
CategoryReturns AS (
    SELECT 
        p.category_id,
        COUNT(DISTINCT ri.return_id) AS total_items_returned,
        SUM(ri.refund) AS total_refunded_amount
    FROM return_items ri
    JOIN order_items oi ON ri.order_item_id = oi.order_item_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY p.category_id
)
SELECT 
    cs.category_name,
    cs.total_items_sold,
    COALESCE(cr.total_items_returned, 0) AS total_items_returned,
    ROUND(
        COALESCE(cr.total_items_returned, 0) * 100.0 / cs.total_items_sold, 
        2
    ) AS return_rate_pct,
    ROUND(cs.gross_sales, 2) AS gross_sales,
    ROUND(COALESCE(cr.total_refunded_amount, 0), 2) AS total_refund_payout,
    ROUND(
        COALESCE(cr.total_refunded_amount, 0) * 100.0 / NULLIF(cs.gross_sales, 0), 
        2
    ) AS revenue_leakage_pct
FROM CategorySales cs
LEFT JOIN CategoryReturns cr ON cs.category_id = cr.category_id
ORDER BY return_rate_pct DESC;

/*
Business Result:
[Execute in database to populate result table]

Business Insight:
High return rates in specific categories (e.g., Apparel due to sizing issues) point to 
product description defects, quality assurance problems, or poor vendor fulfillment.
*/

-- -----------------------------------------------------------------------------
-- Query 4.3: Top 10 Suppliers by Return Refund Exposure
-- Business Question: Which suppliers are contributing most to product defects 
--                    and refund payouts?
-- SQL Focus: Multi-table JOINs, Supplier Aggregations, Ranking
-- -----------------------------------------------------------------------------

SELECT 
    s.supplier_id,
    s.country AS supplier_country,
    COUNT(DISTINCT p.product_id) AS catalog_skus_supplied,
    COUNT(DISTINCT ri.return_id) AS total_refunded_items,
    ROUND(SUM(ri.refund), 2) AS total_refund_cost
FROM suppliers s
JOIN products p ON s.supplier_id = p.supplier_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN return_items ri ON oi.order_item_id = ri.order_item_id
GROUP BY s.supplier_id, s.country
ORDER BY total_refund_cost DESC
LIMIT 10;

/*
Business Result:
[Execute in database to populate result table]

Business Insight:
Vendor management tool. Equips procurement teams with data to negotiate quality control 
SLAs or chargeback agreements with high-defect suppliers.
*/

-- -----------------------------------------------------------------------------
-- Query 4.4: Promotional Discount Depth vs. Return Probability
-- Business Question: Does heavier promotional discounting lead to higher rates 
--                    of product returns?
-- SQL Focus: CTEs, Conditional Bucketing, Return Ratios
-- -----------------------------------------------------------------------------

WITH OrderPromotions AS (
    SELECT 
        o.order_id,
        COALESCE(pr.discount, 0) AS discount_pct,
        CASE 
            WHEN COALESCE(pr.discount, 0) = 0 THEN '1 - Full Price (0%)'
            WHEN pr.discount <= 15 THEN '2 - Moderate Discount (1-15%)'
            ELSE '3 - Heavy Discount (> 15%)'
        END AS discount_tier
    FROM orders o
    LEFT JOIN promotions pr ON o.promotion_id = pr.promotion_id
),
OrderReturns AS (
    SELECT 
        oi.order_id,
        COUNT(ri.return_id) AS return_count
    FROM order_items oi
    JOIN return_items ri ON oi.order_item_id = ri.order_item_id
    GROUP BY oi.order_id
)
SELECT 
    op.discount_tier,
    COUNT(DISTINCT op.order_id) AS total_orders,
    COUNT(DISTINCT ord.order_id) AS orders_with_returns,
    ROUND(
        COUNT(DISTINCT ord.order_id) * 100.0 / COUNT(DISTINCT op.order_id), 
        2
    ) AS return_order_rate_pct
FROM OrderPromotions op
LEFT JOIN OrderReturns ord ON op.order_id = ord.order_id AND ord.return_count > 0
GROUP BY op.discount_tier
ORDER BY op.discount_tier ASC;

/*
Business Result:
[Execute in database to populate result table]

Business Insight:
Evaluates whether promotional price cuts attract lower-intent buyers who return goods at a 
higher rate, eating into net margin gains from volume surges.
*/