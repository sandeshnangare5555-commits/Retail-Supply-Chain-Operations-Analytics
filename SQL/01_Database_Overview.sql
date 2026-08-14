/* =============================================================================
   SECTION 1: DATABASE OVERVIEW
   
   Purpose:
   - Inspect table schemas and data types.
   - Preview sample records across all 12 tables in the data warehouse.
============================================================================= */

-- 1. Categories
DESCRIBE categories;
SELECT * FROM categories LIMIT 5;

-- 2. Customers
DESCRIBE customers;
SELECT * FROM customers LIMIT 5;

-- 3. Employees
DESCRIBE employees;
SELECT * FROM employees LIMIT 5;

-- 4. Order_Items
DESCRIBE order_items;
SELECT * FROM order_items LIMIT 5;

-- 5. Orders
DESCRIBE orders;
SELECT * FROM orders LIMIT 5;

-- 6. Payments
DESCRIBE payments;
SELECT * FROM payments LIMIT 5;

-- 7. Products
DESCRIBE products;
SELECT * FROM products LIMIT 5;

-- 8. Promotions
DESCRIBE promotions;
SELECT * FROM promotions LIMIT 5;

-- 9. Return_Items
DESCRIBE return_items;
SELECT * FROM return_items LIMIT 5;

-- 10. Shipments
DESCRIBE shipments;
SELECT * FROM shipments LIMIT 5;

-- 11. Stores
DESCRIBE stores;
SELECT * FROM stores LIMIT 5;

-- 12. Suppliers
DESCRIBE suppliers;
SELECT * FROM suppliers LIMIT 5;