-- Extension registry, with extension-related settings
CREATE TABLE extension (
  number TEXT NOT NULL,
  ringback TEXT,

  PRIMARY KEY(number)
);

-- Locations for a registered extension
CREATE TABLE location (
  number TEXT NOT NULL,
  data TEXT NOT NULL,
  expiry TIMESTAMP,

  FOREIGN KEY(number)
    REFERENCES extension(number)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- Authentication for extension (mainly for SIP)
CREATE TABLE auth (
  number TEXT NOT NULL,
  password TEXT NOT NULL,

  PRIMARY KEY(number),
  FOREIGN KEY(number)
    REFERENCES extension(number)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

