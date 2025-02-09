-- Alter Functions (if needed)

-- If any of your functions use columns that you've changed, you'll need to update them.
-- For example, if you had a function that returned the CategoryName, you would need to
-- update it to reflect the new length.  In this case, the functions don't directly
-- depend on the changed columns, so no changes are needed to them.

-- Alter Stored Procedures (with dependency impacts)

-- Modify the AddNewCustomer stored procedure.  Let's assume you want to add a 
-- default value for the Phone number.
ALTER PROCEDURE AddNewCustomer (
    @FirstName VARCHAR(255),
    @LastName VARCHAR(255),
    @Email VARCHAR(255),
    @Phone VARCHAR(20) = 'Unknown' -- Default value added
)
AS
BEGIN
    INSERT INTO Customers (FirstName, LastName, Email, Phone)
    VALUES (@FirstName, @LastName, @Email, @Phone);
END;
