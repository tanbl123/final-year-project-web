-- Couriers can be Malaysian (12-digit NRIC) or foreign (passport + work permit).
-- identityType drives which validation applies; icNumber/icPhotoUrl now hold the
-- NRIC *or* the passport, and workPermitUrl is the foreigner's work pass photo.
ALTER TABLE delivery_personnel
  ADD COLUMN identityType  ENUM('Malaysian','Foreigner') NOT NULL DEFAULT 'Malaysian' AFTER licensePhotoUrl,
  ADD COLUMN workPermitUrl VARCHAR(255) NULL AFTER icPhotoUrl;
