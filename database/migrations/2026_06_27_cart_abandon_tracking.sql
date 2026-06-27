-- Abandoned-cart reminder support: track when a cart last changed and when we
-- last reminded the customer about it. See backend/lib/sweeps.php.
ALTER TABLE cart
  ADD COLUMN cartUpdatedAt      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP AFTER cartCreatedAt,
  ADD COLUMN cartReminderSentAt DATETIME NULL AFTER cartUpdatedAt;

-- Seed existing carts so they aren't all instantly "abandoned".
UPDATE cart SET cartUpdatedAt = cartCreatedAt WHERE cartUpdatedAt < cartCreatedAt;
