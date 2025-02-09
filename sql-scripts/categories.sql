
-- Change the data type of the CategoryName column in the Categories table.
-- This will affect the ProductDetails view.
ALTER TABLE Categories
ALTER COLUMN CategoryName VARCHAR(100);
