-- Vehicle catalogue tables.
-- Run this once in phpMyAdmin (or include it after schema.sql).
-- The app serves brand/model data from these tables instead of calling
-- the NHTSA API directly from the mobile client (which times out from Malaysia).

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

-- ── Seed: Motorcycle makes ────────────────────────────────────────────────────
INSERT IGNORE INTO vehicle_makes (vehicleType, makeName) VALUES
  ('Motorcycle','Aprilia'),('Motorcycle','Benelli'),('Motorcycle','BMW'),
  ('Motorcycle','Ducati'),('Motorcycle','Harley-Davidson'),('Motorcycle','Honda'),
  ('Motorcycle','Kawasaki'),('Motorcycle','KTM'),('Motorcycle','Modenas'),
  ('Motorcycle','Royal Enfield'),('Motorcycle','Suzuki'),('Motorcycle','SYM'),
  ('Motorcycle','Triumph'),('Motorcycle','Yamaha');

-- ── Seed: Car makes ───────────────────────────────────────────────────────────
INSERT IGNORE INTO vehicle_makes (vehicleType, makeName) VALUES
  ('Car','Audi'),('Car','BMW'),('Car','BYD'),('Car','Chery'),('Car','Daihatsu'),
  ('Car','Ford'),('Car','Honda'),('Car','Hyundai'),('Car','Kia'),('Car','Mazda'),
  ('Car','Mercedes-Benz'),('Car','Mitsubishi'),('Car','Nissan'),('Car','Perodua'),
  ('Car','Proton'),('Car','Subaru'),('Car','Suzuki'),('Car','Toyota'),
  ('Car','Volkswagen'),('Car','Volvo');

-- ── Seed: Van makes ───────────────────────────────────────────────────────────
INSERT IGNORE INTO vehicle_makes (vehicleType, makeName) VALUES
  ('Van','Ford'),('Van','Hyundai'),('Van','Maxus'),('Van','Mercedes-Benz'),
  ('Van','Nissan'),('Van','Peugeot'),('Van','Renault'),('Van','Toyota'),
  ('Van','Volkswagen');

-- ── Seed: Truck makes ─────────────────────────────────────────────────────────
INSERT IGNORE INTO vehicle_makes (vehicleType, makeName) VALUES
  ('Truck','DAF'),('Truck','Hino'),('Truck','Isuzu'),('Truck','MAN'),
  ('Truck','Mercedes-Benz'),('Truck','Mitsubishi Fuso'),('Truck','Nissan'),
  ('Truck','Renault'),('Truck','Scania'),('Truck','Toyota'),('Truck','Volvo');

-- ── Seed: Motorcycle models ───────────────────────────────────────────────────
INSERT IGNORE INTO vehicle_models (vehicleType, makeName, modelName) VALUES
  ('Motorcycle','Honda','CB150R'),('Motorcycle','Honda','CB500F'),
  ('Motorcycle','Honda','CB650R'),('Motorcycle','Honda','CBR150R'),
  ('Motorcycle','Honda','CBR250RR'),('Motorcycle','Honda','CBR600RR'),
  ('Motorcycle','Honda','CRF150L'),('Motorcycle','Honda','EX5 Dream'),
  ('Motorcycle','Honda','Revo'),('Motorcycle','Honda','RS150R'),
  ('Motorcycle','Honda','Vario 150'),('Motorcycle','Honda','Wave 110'),
  ('Motorcycle','Honda','Wave Alpha'),('Motorcycle','Honda','Winner X'),

  ('Motorcycle','Yamaha','Crypton'),('Motorcycle','Yamaha','Ego Avantiz'),
  ('Motorcycle','Yamaha','Ego S'),('Motorcycle','Yamaha','Exciter 150'),
  ('Motorcycle','Yamaha','FZ25'),('Motorcycle','Yamaha','LC135'),
  ('Motorcycle','Yamaha','MT-07'),('Motorcycle','Yamaha','MT-09'),
  ('Motorcycle','Yamaha','MT-15'),('Motorcycle','Yamaha','NMax 155'),
  ('Motorcycle','Yamaha','R15'),('Motorcycle','Yamaha','R25'),
  ('Motorcycle','Yamaha','XMax 250'),('Motorcycle','Yamaha','Y15ZR'),

  ('Motorcycle','Kawasaki','Ninja 250'),('Motorcycle','Kawasaki','Ninja 400'),
  ('Motorcycle','Kawasaki','Ninja 650'),('Motorcycle','Kawasaki','Ninja ZX-10R'),
  ('Motorcycle','Kawasaki','Ninja ZX-6R'),('Motorcycle','Kawasaki','Versys 650'),
  ('Motorcycle','Kawasaki','W175'),('Motorcycle','Kawasaki','Z400'),
  ('Motorcycle','Kawasaki','Z650'),('Motorcycle','Kawasaki','Z900'),

  ('Motorcycle','Suzuki','Address 115'),('Motorcycle','Suzuki','Belang R150'),
  ('Motorcycle','Suzuki','Burgman 400'),('Motorcycle','Suzuki','GSX-R150'),
  ('Motorcycle','Suzuki','GSX-S150'),('Motorcycle','Suzuki','Hayabusa'),
  ('Motorcycle','Suzuki','Raider R150'),('Motorcycle','Suzuki','Skydrive 125'),

  ('Motorcycle','Modenas','Boss 185'),('Motorcycle','Modenas','CT100B'),
  ('Motorcycle','Modenas','Dominar 400'),('Motorcycle','Modenas','Elegan 250'),
  ('Motorcycle','Modenas','GT128'),('Motorcycle','Modenas','Kriss 110'),
  ('Motorcycle','Modenas','Kriss 110R'),('Motorcycle','Modenas','V15'),

  ('Motorcycle','SYM','Bonus 110'),('Motorcycle','SYM','CITYCOM S 300i'),
  ('Motorcycle','SYM','Fiamma 50'),('Motorcycle','SYM','Jet14 200'),
  ('Motorcycle','SYM','Sport Rider 150'),('Motorcycle','SYM','VF3i 185'),

  ('Motorcycle','KTM','200 Duke'),('Motorcycle','KTM','390 Adventure'),
  ('Motorcycle','KTM','390 Duke'),('Motorcycle','KTM','690 Duke'),
  ('Motorcycle','KTM','890 Duke'),

  ('Motorcycle','Benelli','302R'),('Motorcycle','Benelli','502C'),
  ('Motorcycle','Benelli','TNT 135'),('Motorcycle','Benelli','TNT 249S'),
  ('Motorcycle','Benelli','TNT 302'),

  ('Motorcycle','BMW','G 310 GS'),('Motorcycle','BMW','G 310 R'),
  ('Motorcycle','BMW','R 1250 GS'),('Motorcycle','BMW','S 1000 RR'),

  ('Motorcycle','Ducati','Monster 937'),('Motorcycle','Ducati','Panigale V2'),
  ('Motorcycle','Ducati','Panigale V4'),('Motorcycle','Ducati','Scrambler 800'),

  ('Motorcycle','Harley-Davidson','Fat Bob'),('Motorcycle','Harley-Davidson','Fat Boy'),
  ('Motorcycle','Harley-Davidson','Iron 883'),('Motorcycle','Harley-Davidson','Road King'),
  ('Motorcycle','Harley-Davidson','Street 750'),

  ('Motorcycle','Royal Enfield','Classic 350'),('Motorcycle','Royal Enfield','Himalayan'),
  ('Motorcycle','Royal Enfield','Meteor 350'),('Motorcycle','Royal Enfield','Thunderbird X'),

  ('Motorcycle','Triumph','Bonneville T100'),('Motorcycle','Triumph','Speed Triple'),
  ('Motorcycle','Triumph','Street Triple'),('Motorcycle','Triumph','Tiger 900'),

  ('Motorcycle','Aprilia','RS 660'),('Motorcycle','Aprilia','RS4 125'),
  ('Motorcycle','Aprilia','Tuono 660');

-- ── Seed: Car models ──────────────────────────────────────────────────────────
INSERT IGNORE INTO vehicle_models (vehicleType, makeName, modelName) VALUES
  ('Car','Perodua','Ativa'),('Car','Perodua','Axia'),('Car','Perodua','Bezza'),
  ('Car','Perodua','Kancil'),('Car','Perodua','Kelisa'),('Car','Perodua','Kenari'),
  ('Car','Perodua','Kembara'),('Car','Perodua','Myvi'),('Car','Perodua','Nautica'),
  ('Car','Perodua','Viva'),

  ('Car','Proton','Ertiga'),('Car','Proton','Exora'),('Car','Proton','Gen-2'),
  ('Car','Proton','Iriz'),('Car','Proton','Perdana'),('Car','Proton','Persona'),
  ('Car','Proton','Preve'),('Car','Proton','Saga'),('Car','Proton','Satria Neo'),
  ('Car','Proton','Suprima S'),('Car','Proton','Waja'),('Car','Proton','Wira'),
  ('Car','Proton','X50'),('Car','Proton','X70'),('Car','Proton','X90'),

  ('Car','Toyota','Alphard'),('Car','Toyota','Altis'),('Car','Toyota','Avanza'),
  ('Car','Toyota','C-HR'),('Car','Toyota','Camry'),('Car','Toyota','Corolla Cross'),
  ('Car','Toyota','Fortuner'),('Car','Toyota','GR86'),('Car','Toyota','Harrier'),
  ('Car','Toyota','Vellfire'),('Car','Toyota','Veloz'),('Car','Toyota','Vios'),
  ('Car','Toyota','Yaris'),

  ('Car','Honda','Accord'),('Car','Honda','BR-V'),('Car','Honda','City'),
  ('Car','Honda','City Hatchback'),('Car','Honda','Civic'),('Car','Honda','CR-V'),
  ('Car','Honda','HR-V'),('Car','Honda','Jazz'),('Car','Honda','Odyssey'),
  ('Car','Honda','WR-V'),

  ('Car','Nissan','Almera'),('Car','Nissan','Grand Livina'),('Car','Nissan','Kicks'),
  ('Car','Nissan','Navara'),('Car','Nissan','Note'),('Car','Nissan','Serena'),
  ('Car','Nissan','X-Trail'),

  ('Car','Mitsubishi','ASX'),('Car','Mitsubishi','Eclipse Cross'),
  ('Car','Mitsubishi','Outlander'),('Car','Mitsubishi','Pajero Sport'),
  ('Car','Mitsubishi','Xpander'),

  ('Car','Mazda','CX-3'),('Car','Mazda','CX-30'),('Car','Mazda','CX-5'),
  ('Car','Mazda','CX-60'),('Car','Mazda','CX-8'),('Car','Mazda','Mazda2'),
  ('Car','Mazda','Mazda3'),('Car','Mazda','Mazda6'),('Car','Mazda','MX-5'),

  ('Car','Hyundai','Elantra'),('Car','Hyundai','i10'),('Car','Hyundai','i20'),
  ('Car','Hyundai','Ioniq 5'),('Car','Hyundai','Ioniq 6'),('Car','Hyundai','Kona'),
  ('Car','Hyundai','Santa Fe'),('Car','Hyundai','Tucson'),

  ('Car','Kia','Carnival'),('Car','Kia','EV6'),('Car','Kia','Niro'),
  ('Car','Kia','Seltos'),('Car','Kia','Sonet'),('Car','Kia','Sorento'),
  ('Car','Kia','Sportage'),

  ('Car','Suzuki','Baleno'),('Car','Suzuki','Ertiga'),('Car','Suzuki','Ignis'),
  ('Car','Suzuki','Jimny'),('Car','Suzuki','Swift'),('Car','Suzuki','Vitara'),

  ('Car','Mercedes-Benz','A-Class'),('Car','Mercedes-Benz','C-Class'),
  ('Car','Mercedes-Benz','CLA'),('Car','Mercedes-Benz','E-Class'),
  ('Car','Mercedes-Benz','GLA'),('Car','Mercedes-Benz','GLC'),
  ('Car','Mercedes-Benz','GLE'),('Car','Mercedes-Benz','S-Class'),

  ('Car','BMW','1 Series'),('Car','BMW','2 Series'),('Car','BMW','3 Series'),
  ('Car','BMW','5 Series'),('Car','BMW','7 Series'),('Car','BMW','X1'),
  ('Car','BMW','X3'),('Car','BMW','X5'),

  ('Car','Audi','A3'),('Car','Audi','A4'),('Car','Audi','A6'),
  ('Car','Audi','Q2'),('Car','Audi','Q3'),('Car','Audi','Q5'),
  ('Car','Audi','Q7'),('Car','Audi','Q8'),

  ('Car','Volkswagen','Golf'),('Car','Volkswagen','Passat'),
  ('Car','Volkswagen','Polo'),('Car','Volkswagen','Tiguan'),

  ('Car','Volvo','S60'),('Car','Volvo','S90'),('Car','Volvo','XC40'),
  ('Car','Volvo','XC60'),('Car','Volvo','XC90'),

  ('Car','Ford','EcoSport'),('Car','Ford','Everest'),('Car','Ford','Fiesta'),
  ('Car','Ford','Focus'),('Car','Ford','Mustang'),('Car','Ford','Ranger'),

  ('Car','Subaru','BRZ'),('Car','Subaru','Forester'),('Car','Subaru','Impreza'),
  ('Car','Subaru','Outback'),('Car','Subaru','WRX'),('Car','Subaru','XV'),

  ('Car','Daihatsu','Gran Max'),('Car','Daihatsu','Rocky'),
  ('Car','Daihatsu','Sirion'),('Car','Daihatsu','Terios'),

  ('Car','BYD','Atto 3'),('Car','BYD','Dolphin'),('Car','BYD','Seal'),
  ('Car','BYD','Tang'),

  ('Car','Chery','Omoda 5'),('Car','Chery','Tiggo 5x'),
  ('Car','Chery','Tiggo 7 Pro'),('Car','Chery','Tiggo 8 Pro');

-- ── Seed: Van models ──────────────────────────────────────────────────────────
INSERT IGNORE INTO vehicle_models (vehicleType, makeName, modelName) VALUES
  ('Van','Toyota','Hiace'),('Van','Toyota','Hiace Commuter'),
  ('Van','Toyota','HiAce Super Grandia'),
  ('Van','Nissan','NV200'),('Van','Nissan','NV350 Urvan'),('Van','Nissan','Urvan'),
  ('Van','Mercedes-Benz','Sprinter'),('Van','Mercedes-Benz','Viano'),
  ('Van','Mercedes-Benz','Vito'),
  ('Van','Ford','Transit'),('Van','Ford','Transit Connect'),
  ('Van','Ford','Transit Custom'),
  ('Van','Volkswagen','Caravelle'),('Van','Volkswagen','Multivan'),
  ('Van','Volkswagen','Transporter'),
  ('Van','Hyundai','H-1'),('Van','Hyundai','Starex'),('Van','Hyundai','Staria'),
  ('Van','Maxus','G10'),('Van','Maxus','T60'),('Van','Maxus','V80'),
  ('Van','Renault','Master'),('Van','Renault','Trafic'),
  ('Van','Peugeot','Boxer'),('Van','Peugeot','Expert'),('Van','Peugeot','Partner');

-- ── Seed: Truck models ────────────────────────────────────────────────────────
INSERT IGNORE INTO vehicle_models (vehicleType, makeName, modelName) VALUES
  ('Truck','Isuzu','D-Max'),('Truck','Isuzu','ELF 150'),('Truck','Isuzu','ELF 250'),
  ('Truck','Isuzu','Forward'),('Truck','Isuzu','FVR'),('Truck','Isuzu','NMR'),
  ('Truck','Isuzu','NQR'),('Truck','Isuzu','NRR'),
  ('Truck','Hino','300 Series'),('Truck','Hino','500 Series'),
  ('Truck','Hino','700 Series'),
  ('Truck','Mitsubishi Fuso','Canter'),('Truck','Mitsubishi Fuso','Fighter'),
  ('Truck','Mitsubishi Fuso','Rosa'),('Truck','Mitsubishi Fuso','Super Great'),
  ('Truck','MAN','TGA'),('Truck','MAN','TGM'),('Truck','MAN','TGS'),
  ('Truck','MAN','TGX'),
  ('Truck','Scania','G Series'),('Truck','Scania','P Series'),
  ('Truck','Scania','R Series'),('Truck','Scania','S Series'),
  ('Truck','Mercedes-Benz','Actros'),('Truck','Mercedes-Benz','Arocs'),
  ('Truck','Mercedes-Benz','Atego'),('Truck','Mercedes-Benz','Axor'),
  ('Truck','Volvo','FH'),('Truck','Volvo','FL'),('Truck','Volvo','FM'),
  ('Truck','Volvo','FMX'),
  ('Truck','Toyota','Hilux'),('Truck','Toyota','Land Cruiser 70'),
  ('Truck','Nissan','Navara'),('Truck','Nissan','NT400'),('Truck','Nissan','NT500'),
  ('Truck','DAF','CF'),('Truck','DAF','LF'),('Truck','DAF','XF'),
  ('Truck','Renault','C-Range'),('Truck','Renault','D-Range'),
  ('Truck','Renault','K-Range'),('Truck','Renault','T-Range');
