CREATE TABLE route (
  ext TEXT NOT NULL,
  module TEXT,
  address TEXT,

  PRIMARY KEY(ext),
  UNIQUE(module, address)
);

-- Default service & testing numbers
INSERT INTO route VALUES('991', 'tone', 'dial');
INSERT INTO route VALUES('992', 'tone', 'busy');
INSERT INTO route VALUES('993', 'tone', 'ring');
INSERT INTO route VALUES('994', 'tone', 'specdial');
INSERT INTO route VALUES('995', 'tone', 'congestion');
INSERT INTO route VALUES('996', 'tone', 'outoforder');
INSERT INTO route VALUES('997', 'tone', 'milliwatt');
INSERT INTO route VALUES('998', 'tone', 'info');

-- Default analog routing
INSERT INTO route VALUES('181', 'analog', 'local-fxs/1');
INSERT INTO route VALUES('182', 'analog', 'local-fxs/2');
INSERT INTO route VALUES('183', 'analog', 'local-fxs/3');
INSERT INTO route VALUES('184', 'analog', 'local-fxs/4');

-- Examples
INSERT INTO route VALUES('F', NULL, '181');
INSERT INTO route VALUES('112', NULL, NULL);
INSERT INTO route VALUES('1234', 'sip', NULL);

-- A nasty routing loop
INSERT INTO route VALUES('5667', NULL, '7665');
INSERT INTO route VALUES('7665', NULL, '5667');
