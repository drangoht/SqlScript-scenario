
-- Alter Views (to reflect table changes)

-- Modify the ProductDetails view to include the new Weight column
ALTER VIEW ProductDetails AS
SELECT
    p.ProductID,
    p.ProductName,
    c.CategoryName,  -- This will still work even though CategoryName's length changed
    p.Description,
    p.Price,
    p.StockQuantity,
    p.Weight       -- Added the new Weight column
FROM
    Products p
JOIN
    Categories c ON p.CategoryID = c.CategoryID;
