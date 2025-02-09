
-- Alter Table (required for PlaceOrder change)
ALTER TABLE OrderItems
ADD Weight DECIMAL(5,2);

-- Alter Type (required for PlaceOrder change)
ALTER TYPE OrderItemTableType  -- Drop the old type first
DROP;
