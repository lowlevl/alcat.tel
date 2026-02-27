-- Default service & testing numbers
INSERT INTO extension(number) VALUES('991');
INSERT INTO location VALUES('991', 'tone/dial', NULL);

INSERT INTO extension(number) VALUES('992');
INSERT INTO location VALUES('992', 'tone/busy', NULL);

INSERT INTO extension(number) VALUES('993');
INSERT INTO location VALUES('993', 'tone/ring', NULL);

INSERT INTO extension(number) VALUES('994');
INSERT INTO location VALUES('994', 'tone/specdial', NULL);

INSERT INTO extension(number) VALUES('995');
INSERT INTO location VALUES('995', 'tone/congestion', NULL);

INSERT INTO extension(number) VALUES('996');
INSERT INTO location VALUES('996', 'tone/outoforder', NULL);

INSERT INTO extension(number) VALUES('997');
INSERT INTO location VALUES('997', 'tone/milliwatt', NULL);

INSERT INTO extension(number) VALUES('998');
INSERT INTO location VALUES('998', 'tone/info', NULL);

-- Default analog routing
INSERT INTO extension(number) VALUES('181');
INSERT INTO location VALUES('181', 'analog/local-fxs/1', NULL);

INSERT INTO extension(number) VALUES('182');
INSERT INTO location VALUES('182', 'analog/local-fxs/2', NULL);

INSERT INTO extension(number) VALUES('183');
INSERT INTO location VALUES('183', 'analog/local-fxs/3', NULL);

INSERT INTO extension(number) VALUES('184');
INSERT INTO location VALUES('184', 'analog/local-fxs/4', NULL);

-- An alias to all analog lines
INSERT INTO extension(number) VALUES('180');
INSERT INTO location VALUES('180', 'lateroute/181', NULL);
INSERT INTO location VALUES('180', 'lateroute/182', NULL);
INSERT INTO location VALUES('180', 'lateroute/183', NULL);
INSERT INTO location VALUES('180', 'lateroute/184', NULL);

-- Reserved extensions
INSERT INTO extension(number) VALUES('F');
INSERT INTO extension(number) VALUES('15');
INSERT INTO extension(number) VALUES('17');

INSERT INTO extension(number) VALUES('1234');

-- A nasty routing loop
INSERT INTO extension(number) VALUES('5667');
INSERT INTO location VALUES('5667', 'lateroute/7665', NULL);

INSERT INTO extension(number) VALUES('7665');
INSERT INTO location VALUES('7665', 'lateroute/5667', NULL);
