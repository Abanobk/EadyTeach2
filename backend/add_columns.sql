-- ================================================
-- Add missing columns for products & categories
-- Run on easytech_v2 database
-- ================================================
USE easytech_v2;

ALTER TABLE products ADD COLUMN IF NOT EXISTS stock INT DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_featured TINYINT(1) DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS original_price DECIMAL(12,2) NULL;

ALTER TABLE categories ADD COLUMN IF NOT EXISTS description TEXT NULL;

-- Set default stock for all existing products
UPDATE products SET stock = 10 WHERE stock = 0 OR stock IS NULL;
