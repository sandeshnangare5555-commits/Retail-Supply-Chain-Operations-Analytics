/* =============================================================================
   SECTION 2: DATA QUALITY AUDIT
   
   Purpose:
   - Perform single-pass data integrity checks per table.
   - Verify primary key uniqueness and identify duplicate record counts.
   - Audit NULL / missing values across key fields.
   - Inspect temporal ranges for date attributes.
============================================================================= */

-- -----------------------------------------------------------------------------
-- 1. Categories Table Audit
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT category_id) AS unique_category_ids,
    COUNT(*) - COUNT(DISTINCT category_id) AS duplicate_pk_count,
    SUM(category_id IS NULL) AS missing_category_ids,
    SUM(category_name IS NULL) AS missing_category_names
FROM categories;

-- -----------------------------------------------------------------------------
-- 2. Customers Table Audit
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_pk_count,
    SUM(customer_id IS NULL) AS missing_customer_ids,
    SUM(city IS NULL) AS missing_cities,
    SUM(signup_date IS NULL) AS missing_signup_dates,
    MIN(signup_date) AS earliest_signup_date,
    MAX(signup_date) AS latest_signup_date
FROM customers;

-- -----------------------------------------------------------------------------
-- 3. Employees Table Audit
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT employee_id) AS unique_employee_ids,
    COUNT(*) - COUNT(DISTINCT employee_id) AS duplicate_pk_count,
    SUM(employee_id IS NULL) AS missing_employee_ids,
    SUM(store_id IS NULL) AS missing_store_ids,
    SUM(salary IS NULL) AS missing_salaries
FROM employees;

-- -----------------------------------------------------------------------------
-- 4. Order_Items Table Audit
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_item_id) AS unique_order_item_ids,
    COUNT(*) - COUNT(DISTINCT order_item_id) AS duplicate_pk_count,
    SUM(order_item_id IS NULL) AS missing_order_item_ids,
    SUM(order_id IS NULL) AS missing_order_ids,
    SUM(product_id IS NULL) AS missing_product_ids,
    SUM(qty IS NULL) AS missing_quantities,
    SUM(price IS NULL) AS missing_prices
FROM order_items;

-- -----------------------------------------------------------------------------
-- 5. Orders Table Audit
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_pk_count,
    SUM(order_id IS NULL) AS missing_order_ids,
    SUM(customer_id IS NULL) AS missing_customer_ids,
    SUM(store_id IS NULL) AS missing_store_ids,
    SUM(order_date IS NULL) AS missing_order_dates,
    SUM(promotion_id IS NULL) AS missing_promotion_ids,
    MIN(order_date) AS earliest_order_date,
    MAX(order_date) AS latest_order_date
FROM orders;

-- -----------------------------------------------------------------------------
-- 6. Payments Table Audit
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT payment_id) AS unique_payment_ids,
    COUNT(*) - COUNT(DISTINCT payment_id) AS duplicate_pk_count,
    SUM(payment_id IS NULL) AS missing_payment_ids,
    SUM(order_id IS NULL) AS missing_order_ids,
    SUM(amount IS NULL) AS missing_amounts
FROM payments;

-- -----------------------------------------------------------------------------
-- 7. Products Table Audit
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_product_ids,
    COUNT(*) - COUNT(DISTINCT product_id) AS duplicate_pk_count,
    SUM(product_id IS NULL) AS missing_product_ids,
    SUM(category_id IS NULL) AS missing_category_ids,
    SUM(supplier_id IS NULL) AS missing_supplier_ids,
    SUM(price IS NULL) AS missing_prices
FROM products;

-- -----------------------------------------------------------------------------
-- 8. Promotions Table Audit
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT promotion_id) AS unique_promotion_ids,
    COUNT(*) - COUNT(DISTINCT promotion_id) AS duplicate_pk_count,
    SUM(promotion_id IS NULL) AS missing_promotion_ids,
    SUM(discount IS NULL) AS missing_discounts
FROM promotions;

-- -----------------------------------------------------------------------------
-- 9. Return_Items Table Audit
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT return_id) AS unique_return_ids,
    COUNT(*) - COUNT(DISTINCT return_id) AS duplicate_pk_count,
    SUM(return_id IS NULL) AS missing_return_ids,
    SUM(order_item_id IS NULL) AS missing_order_item_ids,
    SUM(refund IS NULL) AS missing_refunds
FROM return_items;

-- -----------------------------------------------------------------------------
-- 10. Shipments Table Audit
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT shipment_id) AS unique_shipment_ids,
    COUNT(*) - COUNT(DISTINCT shipment_id) AS duplicate_pk_count,
    SUM(shipment_id IS NULL) AS missing_shipment_ids,
    SUM(order_id IS NULL) AS missing_order_ids,
    SUM(status IS NULL) AS missing_statuses
FROM shipments;

-- -----------------------------------------------------------------------------
-- 11. Stores Table Audit
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT store_id) AS unique_store_ids,
    COUNT(*) - COUNT(DISTINCT store_id) AS duplicate_pk_count,
    SUM(store_id IS NULL) AS missing_store_ids,
    SUM(city IS NULL) AS missing_cities
FROM stores;

-- -----------------------------------------------------------------------------
-- 12. Suppliers Table Audit
-- -----------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT supplier_id) AS unique_supplier_ids,
    COUNT(*) - COUNT(DISTINCT supplier_id) AS duplicate_pk_count,
    SUM(supplier_id IS NULL) AS missing_supplier_ids,
    SUM(country IS NULL) AS missing_countries
FROM suppliers;