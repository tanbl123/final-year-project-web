-- Profile picture for accounts. Stores a URL to the uploaded image (same swap
-- seam as product images — local now, Firebase later). NULL = no photo, so the
-- UI falls back to an initials avatar.
--
-- Apply to an existing database:
--   phpMyAdmin -> shoear database -> SQL -> paste -> Go

ALTER TABLE `user`
  ADD COLUMN avatarUrl VARCHAR(255) NULL AFTER phoneNumber;
