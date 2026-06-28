-- Courier KYC captured at registration (reviewed by the admin before approval):
-- driving licence (number + photo) and IC (number + photo). The profile photo
-- reuses the existing user.avatarUrl column.
ALTER TABLE delivery_personnel
  ADD COLUMN licenseNumber   VARCHAR(50)  NOT NULL DEFAULT '' AFTER vehiclePlate,
  ADD COLUMN licensePhotoUrl VARCHAR(255) NULL AFTER licenseNumber,
  ADD COLUMN icNumber        VARCHAR(20)  NOT NULL DEFAULT '' AFTER licensePhotoUrl,
  ADD COLUMN icPhotoUrl      VARCHAR(255) NULL AFTER icNumber;
