-- Vehicle catalogue tables.
-- Run this once in phpMyAdmin after schema.sql.
--
-- Only Malaysian brands (absent from NHTSA) are seeded with models here.
-- All other brand names are seeded so the dropdown is never empty on first
-- launch. Models for international brands are fetched automatically from
-- NHTSA on first selection and cached in vehicle_models — no manual seeding
-- needed. The 30-day stale-while-revalidate keeps everything up to date.

CREATE TABLE IF NOT EXISTS vehicle_makes (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  vehicleType ENUM('Motorcycle','Car','Van','Truck') NOT NULL,
  makeName    VARCHAR(100) NOT NULL,
  UNIQUE KEY uq_type_make (vehicleType, makeName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS vehicle_models (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  vehicleType ENUM('Motorcycle','Car','Van','Truck') NOT NULL,
  makeName    VARCHAR(100) NOT NULL,
  modelName   VARCHAR(100) NOT NULL,
  UNIQUE KEY uq_type_make_model (vehicleType, makeName, modelName)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tracks when each cache key was last successfully refreshed from NHTSA.
CREATE TABLE IF NOT EXISTS vehicle_cache_log (
  cacheKey  VARCHAR(200) PRIMARY KEY,
  cachedAt  DATETIME     NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ── Seed: brand names (makes only — models fetched from NHTSA on demand) ──────
INSERT IGNORE INTO vehicle_makes (vehicleType, makeName) VALUES
  ('Motorcycle','Aprilia'),('Motorcycle','Benelli'),('Motorcycle','BMW'),
  ('Motorcycle','Ducati'),('Motorcycle','Harley-Davidson'),('Motorcycle','Honda'),
  ('Motorcycle','Kawasaki'),('Motorcycle','KTM'),('Motorcycle','Modenas'),
  ('Motorcycle','Royal Enfield'),('Motorcycle','Suzuki'),('Motorcycle','SYM'),
  ('Motorcycle','Triumph'),('Motorcycle','Yamaha'),

  ('Car','Audi'),('Car','BMW'),('Car','BYD'),('Car','Chery'),('Car','Daihatsu'),
  ('Car','Ford'),('Car','Honda'),('Car','Hyundai'),('Car','Kia'),('Car','Mazda'),
  ('Car','Mercedes-Benz'),('Car','Mitsubishi'),('Car','Nissan'),('Car','Perodua'),
  ('Car','Proton'),('Car','Subaru'),('Car','Suzuki'),('Car','Toyota'),
  ('Car','Volkswagen'),('Car','Volvo'),

  ('Van','Ford'),('Van','Hyundai'),('Van','Maxus'),('Van','Mercedes-Benz'),
  ('Van','Nissan'),('Van','Peugeot'),('Van','Renault'),('Van','Toyota'),
  ('Van','Volkswagen'),

  ('Truck','DAF'),('Truck','Hino'),('Truck','Isuzu'),('Truck','MAN'),
  ('Truck','Mercedes-Benz'),('Truck','Mitsubishi Fuso'),('Truck','Nissan'),
  ('Truck','Renault'),('Truck','Scania'),('Truck','Toyota'),('Truck','Volvo');

-- ── Seed: Malaysian brand models (NHTSA has no data for these) ────────────────
INSERT IGNORE INTO vehicle_models (vehicleType, makeName, modelName) VALUES
  ('Motorcycle','Modenas','Boss 185'),('Motorcycle','Modenas','CT100B'),
  ('Motorcycle','Modenas','Dominar 400'),('Motorcycle','Modenas','Elegan 250'),
  ('Motorcycle','Modenas','GT128'),('Motorcycle','Modenas','Kriss 110'),
  ('Motorcycle','Modenas','Kriss 110R'),('Motorcycle','Modenas','V15'),

  ('Motorcycle','SYM','Bonus 110'),('Motorcycle','SYM','CITYCOM S 300i'),
  ('Motorcycle','SYM','Fiamma 50'),('Motorcycle','SYM','Jet14 200'),
  ('Motorcycle','SYM','Sport Rider 150'),('Motorcycle','SYM','VF3i 185'),

  ('Car','Perodua','Ativa'),('Car','Perodua','Axia'),('Car','Perodua','Bezza'),
  ('Car','Perodua','Kancil'),('Car','Perodua','Kelisa'),('Car','Perodua','Kenari'),
  ('Car','Perodua','Kembara'),('Car','Perodua','Myvi'),('Car','Perodua','Nautica'),
  ('Car','Perodua','Viva'),

  ('Car','Proton','Ertiga'),('Car','Proton','Exora'),('Car','Proton','Gen-2'),
  ('Car','Proton','Iriz'),('Car','Proton','Perdana'),('Car','Proton','Persona'),
  ('Car','Proton','Preve'),('Car','Proton','Saga'),('Car','Proton','Satria Neo'),
  ('Car','Proton','Suprima S'),('Car','Proton','Waja'),('Car','Proton','Wira'),
  ('Car','Proton','X50'),('Car','Proton','X70'),('Car','Proton','X90');
