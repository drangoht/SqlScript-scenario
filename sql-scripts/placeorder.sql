
-- Modify the PlaceOrder stored procedure. Let's assume you want to add the Weight 
-- of the product to the OrderItems table.  This requires altering the OrderItems table
-- first (see below) and the OrderItemTableType.
ALTER PROCEDURE PlaceOrder (
    @CustomerID INT,
    @OrderDate DATETIME,
    @OrderItemsType OrderItemWithWeightTableType READONLY -- Updated table type
)
AS
BEGIN
  BEGIN TRANSACTION;

  DECLARE @OrderID INT;
  INSERT INTO Orders (CustomerID, OrderDate) VALUES (@CustomerID, @OrderDate);
  SET @OrderID = SCOPE_IDENTITY();

  INSERT INTO OrderItems (OrderID, ProductID, Quantity, Price, Weight)  -- Added Weight
  SELECT @OrderID, ProductID, Quantity, Price, Weight FROM @OrderItemsType; -- Added Weight


    UPDATE Orders
    SET TotalAmount = (
            SELECT SUM(oi.Quantity * oi.Price * (1 - p.DiscountPercentage))
            FROM OrderItems oi
            JOIN Products p ON oi.ProductID = p.ProductID
            WHERE oi.OrderID = @OrderID
        )
    WHERE OrderID = @OrderID;

  COMMIT TRANSACTION;
END;
