-- Default service & testing numbers
INSERT INTO extension VALUES('991', NULL);
INSERT INTO location VALUES('991', 'tone/dial', NULL);

INSERT INTO extension VALUES('992', NULL);
INSERT INTO location VALUES('992', 'tone/busy', NULL);

INSERT INTO extension VALUES('993', NULL);
INSERT INTO location VALUES('993', 'tone/ring', NULL);

INSERT INTO extension VALUES('994', NULL);
INSERT INTO location VALUES('994', 'tone/specdial', NULL);

INSERT INTO extension VALUES('995', NULL);
INSERT INTO location VALUES('995', 'tone/congestion', NULL);

INSERT INTO extension VALUES('996', NULL);
INSERT INTO location VALUES('996', 'tone/outoforder', NULL);

INSERT INTO extension VALUES('997', NULL);
INSERT INTO location VALUES('997', 'tone/milliwatt', NULL);

INSERT INTO extension VALUES('998', NULL);
INSERT INTO location VALUES('998', 'tone/info', NULL);

-- Default analog routing
INSERT INTO extension VALUES('181', NULL);
INSERT INTO location VALUES('181', 'analog/local-fxs/1', NULL);

INSERT INTO extension VALUES('182', NULL);
INSERT INTO location VALUES('182', 'analog/local-fxs/2', NULL);

INSERT INTO extension VALUES('183', NULL);
INSERT INTO location VALUES('183', 'analog/local-fxs/3', NULL);

INSERT INTO extension VALUES('184', NULL);
INSERT INTO location VALUES('184', 'analog/local-fxs/4', NULL);

-- An alias to all analog lines
INSERT INTO extension VALUES('180', NULL);
INSERT INTO location VALUES('180', 'lateroute/181', NULL);
INSERT INTO location VALUES('180', 'lateroute/182', NULL);
INSERT INTO location VALUES('180', 'lateroute/183', NULL);
INSERT INTO location VALUES('180', 'lateroute/184', NULL);

-- Reserved extensions
INSERT INTO extension VALUES('F', NULL);
INSERT INTO extension VALUES('15', NULL);
INSERT INTO extension VALUES('17', NULL);
INSERT INTO extension VALUES('18', NULL);

INSERT INTO extension VALUES('1234', NULL);

-- A nasty routing loop
INSERT INTO extension VALUES('5667', NULL);
INSERT INTO location VALUES('5667', 'lateroute/7665', NULL);

INSERT INTO extension VALUES('7665', NULL);
INSERT INTO location VALUES('7665', 'lateroute/5667', NULL);
