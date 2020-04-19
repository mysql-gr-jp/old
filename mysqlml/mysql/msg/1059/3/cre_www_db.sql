CREATE TABLE www_db (
  id        INTEGER      NOT NULL  AUTO_INCREMENT,
  register  VARCHAR(100),
  email     VARCHAR(100),
  how_old   TINYINT,
  sex       TINYINT,
  ocupation TINYINT,
  sample    TINYINT,
  phpfi     TINYINT,
  rdbms     TINYINT,
  whole     TINYINT,
  PRIMARY KEY(id)
);

