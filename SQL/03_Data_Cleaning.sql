/* =============================================================================
   SECTION 3: DATA CLEANING & BUSINESS VALIDATION
   
   Purpose:
   - Validate numerical ranges and domain constraint integrity.
   - Detect logically invalid values (negative price, future dates, invalid discounts).
   - Standardize text, fix incorrect data types, and handle NULLs/duplicates.
   - Verify referential cross-table business logic.
============================================================================= */

-- -----------------------------------------------------------------------------
-- 1. Orders: Check for Future Order Dates & Status Logic
-- -----------------------------------------------------------------------------
-- Check for future order dates
SELECT *
FROM orders
WHERE order_date > CURDATE();

-- Verification
SELECT 
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    COUNT(*) AS total_orders
FROM orders;

-- -----------------------------------------------------------------------------
-- 2. Order_Items: Check Invalid Quantity and Price
-- -----------------------------------------------------------------------------
SELECT *
FROM order_items
WHERE qty <= 0 
   OR price <= 0;

-- Verification
SELECT 
    MIN(qty) AS min_qty,
    MAX(qty) AS max_qty,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM order_items;

-- -----------------------------------------------------------------------------
-- 3. Payments: Check Invalid Payment Amounts & Methods
-- -----------------------------------------------------------------------------
SELECT *
FROM payments
WHERE amount <= 0;

-- Verification
SELECT 
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount,
    payment_method,
    COUNT(*) AS transaction_count
FROM payments
GROUP BY payment_method;

-- -----------------------------------------------------------------------------
-- 4. Promotions: Check Invalid Discounts & Date Overlaps
-- -----------------------------------------------------------------------------
SELECT *
FROM promotions
WHERE discount < 0 
   OR discount > 100;

-- Verification
SELECT 
    MIN(discount) AS min_discount,
    MAX(discount) AS max_discount
FROM promotions;

-- -----------------------------------------------------------------------------
-- 5. Return_Items: Check Invalid Refund Amounts
-- -----------------------------------------------------------------------------
SELECT *
FROM return_items
WHERE refund < 0;

-- Verification
SELECT 
    MIN(refund) AS min_refund,
    MAX(refund) AS max_refund
FROM return_items;

-- -----------------------------------------------------------------------------
-- 6. Shipments: Check Missing or Empty Statuses & Delivery Timeline Logic
-- -----------------------------------------------------------------------------
SELECT *
FROM shipments
WHERE status IS NULL 
   OR status = '';

-- Verification: Status breakdown
SELECT 
    status,
    COUNT(*) AS total_shipments
FROM shipments
GROUP BY status;

-- Logical Check: Shipments delivered before dispatch date
SELECT *
FROM shipments
WHERE delivery_date < shipment_date;

-- -----------------------------------------------------------------------------
-- 7. Stores: Check City Name Integrity
-- -----------------------------------------------------------------------------
SELECT *
FROM stores
WHERE city IS NULL 
   OR city = '';

-- Verification
SELECT DISTINCT city
FROM stores
ORDER BY city;

-- -----------------------------------------------------------------------------
-- 8. Suppliers: Check Country Name Integrity
-- -----------------------------------------------------------------------------
SELECT *
FROM suppliers
WHERE country IS NULL 
   OR country = '';

-- Verification
SELECT DISTINCT country
FROM suppliers
ORDER BY country;


/* =============================================================================
   SECTION 4: TABLE-BY-TABLE DETAILED CLEANING & STANDARDIZATION
============================================================================= */

-- -----------------------------------------------------------------------------
-- A. Customers Table Cleaning
-- -----------------------------------------------------------------------------

-- 1. Check for Invalid Date Formats or NULLs
SELECT signup_date 
FROM customers 
WHERE signup_date IS NULL 
   OR signup_date = '';

-- 2. Clean & Standardize signup_date: Convert 'MM/DD/YYYY' to ISO DATE
UPDATE customers 
SET signup_date = DATE_FORMAT(STR_TO_DATE(signup_date, '%c/%e/%Y'), '%Y-%m-%d')
WHERE signup_date IS NOT NULL 
  AND signup_date LIKE '%/%/%';

-- Modify the column data type to official DATE
ALTER TABLE customers 
MODIFY COLUMN signup_date DATE;

-- 3. Standardize Customer Text Fields (Trim spaces & casing)
UPDATE customers
SET 
    first_name = TRIM(first_name),
    last_name  = TRIM(last_name),
    city       = TRIM(CONCAT(UPPER(SUBSTRING(city, 1, 1)), LOWER(SUBSTRING(city, 2)))),
    email      = LOWER(TRIM(email));

-- Verification
DESCRIBE customers;

SELECT 
    MIN(signup_date) AS earliest_signup,
    MAX(signup_date) AS latest_signup,
    COUNT(DISTINCT customer_id) AS distinct_customers,
    COUNT(*) AS total_records
FROM customers;


-- -----------------------------------------------------------------------------
-- B. Products & Categories Cleaning
-- -----------------------------------------------------------------------------

-- 1. Check for negative prices or zero cost in Products
SELECT *
FROM products
WHERE unit_price <= 0 
   OR unit_cost < 0;

-- 2. Standardize Product Names and Categories (Remove extra whitespaces)
UPDATE products
SET product_name = TRIM(product_name);

UPDATE categories
SET category_name = TRIM(category_name);

-- 3. Check for Orphan Products (Categories that don't exist)
SELECT p.*
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id
WHERE c.category_id IS NULL;


-- -----------------------------------------------------------------------------
-- C. Orders & Shipments Cross-Validation
-- -----------------------------------------------------------------------------

-- 1. Check for Orders where Shipment Date is before Order Date
SELECT 
    o.order_id,
    o.order_date,
    s.shipment_date,
    s.delivery_date
FROM orders o
JOIN shipments s ON o.order_id = s.order_id
WHERE s.shipment_date < o.order_date;

-- 2. Check for Duplicate Orders
SELECT 
    order_id, 
    COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- -----------------------------------------------------------------------------
-- D. Return Items vs. Order Items Validation
-- -----------------------------------------------------------------------------

-- 1. Verify Refund Amount does not exceed Original Order Item Price * Qty
SELECT 
    r.return_id,
    r.order_item_id,
    r.refund,
    (oi.price * oi.qty) AS max_allowed_refund
FROM return_items r
JOIN order_items oi ON r.order_item_id = oi.order_item_id
WHERE r.refund > (oi.price * oi.qty);


-- -----------------------------------------------------------------------------
-- E. Employees & Stores Integrity
-- -----------------------------------------------------------------------------

-- 1. Standardize Employee emails and trim names
UPDATE employees
SET 
    first_name = TRIM(first_name),
    last_name  = TRIM(last_name),
    email      = LOWER(TRIM(email));

-- 2. Check for Employees assigned to non-existent stores
SELECT e.*
FROM employees e
LEFT JOIN stores s ON e.store_id = s.store_id
WHERE s.store_id IS NULL;


/* =============================================================================
   SECTION 5: FINAL INTEGRITY & ORPHAN RECORD CHECK
============================================================================= */

-- Check for Order Items with no matching Parent Order
SELECT oi.*
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Check for Payments with no matching Parent Order
SELECT p.*
FROM payments p
LEFT JOIN orders o ON p.order_id = o.order_id
WHERE o.order_id IS NULL;