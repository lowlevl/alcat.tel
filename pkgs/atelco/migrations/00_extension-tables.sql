-- Extension registry, with extension-related settings
CREATE TABLE extension (
  number TEXT NOT NULL,
  ringback TEXT,
  password TEXT,

  dectcode TEXT UNIQUE,
  dectpp TEXT UNIQUE,

  PRIMARY KEY(number)
);

-- Locations for a registered extension
CREATE TABLE location (
  number TEXT NOT NULL,
  data TEXT NOT NULL,
  expiry TIMESTAMP,

  PRIMARY KEY(number, data),
  FOREIGN KEY(number)
    REFERENCES extension(number)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);
