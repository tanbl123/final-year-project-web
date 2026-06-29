-- Delivery method: in-house courier vs standard (3PL) shipping.
--
-- ShoeAR's in-house couriers are a LOCAL service — one rider picks up from the
-- supplier and drops at the customer, which only works when both are in the same
-- state. When the supplier and customer are in different states the parcel is
-- routed to STANDARD shipping instead (the supplier ships via an external courier
-- and provides a tracking number); no in-house courier is assigned.
--
-- deliveryMethod is decided at dispatch (lib/delivery.php) by comparing the
-- supplier's operational state with the order's delivery state. trackingCarrier
-- + trackingNumber are filled in later when the supplier ships a Standard parcel.
--
-- Apply to an existing database:
--   phpMyAdmin → shoear database → SQL → paste → Go

ALTER TABLE delivery
  ADD COLUMN deliveryMethod  ENUM('InHouse','Standard') NOT NULL DEFAULT 'InHouse' AFTER deliveryPersonnelId,
  ADD COLUMN trackingCarrier VARCHAR(50) NULL AFTER deliveryMethod,
  ADD COLUMN trackingNumber  VARCHAR(64) NULL AFTER trackingCarrier;
