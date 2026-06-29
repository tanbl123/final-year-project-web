-- A courier can hold more than one licence class (e.g. B2 motorcycle + D car),
-- so licenseClass now stores a comma-separated list. Widen the column.
ALTER TABLE delivery_personnel
  MODIFY COLUMN licenseClass VARCHAR(60) NOT NULL DEFAULT '';
