CREATE TABLE ext (
  ext TEXT NOT NULL,
  module TEXT,
  location TEXT,

  PRIMARY KEY(ext),
  UNIQUE(module, location)
);

INSERT INTO ext VALUES('181', 'analog', 'local-fxs/1');
INSERT INTO ext VALUES('182', 'analog', 'local-fxs/2');
INSERT INTO ext VALUES('183', 'analog', 'local-fxs/3');
INSERT INTO ext VALUES('184', 'analog', 'local-fxs/4');

INSERT INTO ext VALUES('991', 'tone', 'dial');
INSERT INTO ext VALUES('992', 'tone', 'busy');
INSERT INTO ext VALUES('993', 'tone', 'ring');
INSERT INTO ext VALUES('994', 'tone', 'specdial');
INSERT INTO ext VALUES('995', 'tone', 'congestion');
INSERT INTO ext VALUES('996', 'tone', 'outoforder');
INSERT INTO ext VALUES('997', 'tone', 'milliwatt');
INSERT INTO ext VALUES('998', 'tone', 'info');

INSERT INTO ext VALUES('F', NULL, '181');
INSERT INTO ext VALUES('112', NULL, NULL);
INSERT INTO ext VALUES('1234', 'sip', NULL);
