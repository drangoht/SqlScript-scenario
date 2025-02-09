-- Tables

CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY IDENTITY,
    CategoryName VARCHAR(255) NOT NULL,
    Description TEXT
);

CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY,
    ProductName VARCHAR(255) NOT NULL,
    CategoryID INT NOT NULL,
    Description TEXT,
    Price DECIMAL(10, 2) NOT NULL,
    StockQuantity INT NOT NULL,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY,
    FirstName VARCHAR(255) NOT NULL,
    LastName VARCHAR(255) NOT NULL,
    Email VARCHAR(255) UNIQUE,
    Phone VARCHAR(20)
);

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY,
    CustomerID INT NOT NULL,
    OrderDate DATETIME NOT NULL DEFAULT GETDATE(),
    TotalAmount DECIMAL(10, 2),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE OrderItems (
    OrderItemID INT PRIMARY KEY IDENTITY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,  -- Price at the time of order
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);


-- Views

CREATE VIEW ProductDetails AS
SELECT
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    p.Description,
    p.Price,
    p.StockQuantity
FROM
    Products p
JOIN
    Categories c ON p.CategoryID = c.CategoryID;

CREATE VIEW OrderSummary AS
SELECT
    o.OrderID,
    c.FirstName + ' ' + c.LastName AS CustomerName,
    o.OrderDate,
    o.TotalAmount
FROM
    Orders o
JOIN
    Customers c ON o.CustomerID = c.CustomerID;


-- Functions

CREATE FUNCTION CalculateTotalOrderAmount (@OrderID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @Total DECIMAL(10, 2);

    SELECT @Total = SUM(Quantity * Price)
    FROM OrderItems
    WHERE OrderID = @OrderID;

    RETURN @Total;
END;

CREATE FUNCTION GetProductPrice (@ProductID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
  DECLARE @Price DECIMAL(10,2);
  SELECT @Price = Price FROM Products WHERE ProductID = @ProductID;
  RETURN @Price;
END;


-- Stored Procedures

CREATE PROCEDURE AddNewCustomer (
    @FirstName VARCHAR(255),
    @LastName VARCHAR(255),
    @Email VARCHAR(255),
    @Phone VARCHAR(20)
)
AS
BEGIN
    INSERT INTO Customers (FirstName, LastName, Email, Phone)
    VALUES (@FirstName, @LastName, @Email, @Phone);
END;

CREATE PROCEDURE PlaceOrder (
    @CustomerID INT,
    @OrderDate DATETIME,
    @OrderItemsType OrderItemTableType READONLY -- Table-valued parameter (see below)
)
AS
BEGIN
  BEGIN TRANSACTION; -- Start a transaction

  DECLARE @OrderID INT;
  INSERT INTO Orders (CustomerID, OrderDate) VALUES (@CustomerID, @OrderDate);
  SET @OrderID = SCOPE_IDENTITY(); -- Get the newly created OrderID

  INSERT INTO OrderItems (OrderID, ProductID, Quantity, Price)
  SELECT @OrderID, ProductID, Quantity, Price FROM @OrderItemsType;

    UPDATE Orders
    SET TotalAmount = dbo.CalculateTotalOrderAmount(@OrderID)
    WHERE OrderID = @OrderID;

  COMMIT TRANSACTION; -- Commit the transaction

END;

-- Table-valued parameter type for PlaceOrder stored procedure
CREATE TYPE OrderItemTableType AS TABLE (
    ProductID INT,
    Quantity INT,
    Price DECIMAL(10,2)
);

CREATE PROCEDURE UpdateProductStock (@ProductID INT, @QuantityChange INT)
AS
BEGIN
    UPDATE Products
    SET StockQuantity = StockQuantity + @QuantityChange
    WHERE ProductID = @ProductID;
END;

-- Example of how to use the PlaceOrder procedure:
--DECLARE @OrderItems OrderItemTableType;
--INSERT INTO @OrderItems (ProductID, Quantity, Price) VALUES (1, 2, 10.00);
--INSERT INTO @OrderItems (ProductID, Quantity, Price) VALUES (2, 1, 20.00);
--EXEC PlaceOrder @CustomerID = 1, @OrderDate = '2024-10-27', @OrderItemsType = @OrderItems;