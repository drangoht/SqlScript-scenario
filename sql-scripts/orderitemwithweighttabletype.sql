
CREATE TYPE OrderItemWithWeightTableType AS TABLE ( -- Create the new type
    ProductID INT,
    Quantity INT,
    Price DECIMAL(10,2),
    Weight DECIMAL(5,2) -- Added Weight
);


-- Modify the UpdateProductStock (no changes needed, but good to check)
-- In this example, UpdateProductStock does not depend on the changed columns, so no changes are needed.