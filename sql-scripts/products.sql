-- Alter Tables (with dependency impacts)

-- Add a new column to the Products table. This will affect the ProductDetails view.
ALTER TABLE Products
ADD Weight DECIMAL(5, 2);
