-- Structured delivery address (Malaysian format).
--
-- Previously the delivery address was a single free-text field, so customers
-- could (and did) miss out parts the courier needs — postcode, state, etc.
-- This splits it into structured columns matching how Shopee/Lazada collect a
-- Malaysian address: line 1, optional line 2, postcode, city, state.
--
-- The original combined columns (customer.shippingAddress,
-- order.orderDeliveryAddress) are KEPT and populated with a formatted
-- single-line string built from the structured parts, so every screen that
-- displays a one-line address (admin, delivery, courier) keeps working with no
-- change. The structured columns are the source of truth for the checkout form.
--
-- Existing rows: the new columns are NULL (old customers/orders pre-date them).
-- The combined column still holds their original address.
--
-- Apply to an existing database:
--   phpMyAdmin → shoear database → SQL → paste → Go

ALTER TABLE customer
  ADD COLUMN addressLine1 VARCHAR(255) NULL AFTER shippingAddress,
  ADD COLUMN addressLine2 VARCHAR(255) NULL AFTER addressLine1,
  ADD COLUMN postcode     VARCHAR(10)  NULL AFTER addressLine2,
  ADD COLUMN city         VARCHAR(100) NULL AFTER postcode,
  ADD COLUMN state        VARCHAR(50)  NULL AFTER city;

ALTER TABLE `order`
  ADD COLUMN deliveryLine1    VARCHAR(255) NULL AFTER orderDeliveryAddress,
  ADD COLUMN deliveryLine2    VARCHAR(255) NULL AFTER deliveryLine1,
  ADD COLUMN deliveryPostcode VARCHAR(10)  NULL AFTER deliveryLine2,
  ADD COLUMN deliveryCity     VARCHAR(100) NULL AFTER deliveryPostcode,
  ADD COLUMN deliveryState    VARCHAR(50)  NULL AFTER deliveryCity;
