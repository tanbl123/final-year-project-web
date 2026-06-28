-- Extra courier KYC collected at registration: driving-licence class + expiry,
-- date of birth (for the 18+ eligibility check) and PDPA/T&C consent timestamp.
ALTER TABLE delivery_personnel
  ADD COLUMN licenseClass    VARCHAR(10) NOT NULL DEFAULT '' AFTER licensePhotoUrl,
  ADD COLUMN licenseExpiry   DATE        NULL               AFTER licenseClass,
  ADD COLUMN dateOfBirth     DATE        NULL               AFTER icPhotoUrl,
  ADD COLUMN termsAcceptedAt DATETIME    NULL               AFTER dateOfBirth;
