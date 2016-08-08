CREATE TABLE map2.users (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  pass VARCHAR(128) NOT NULL,
  role VARCHAR(10) NOT NULL,
  personId VARCHAR(36) NOT NULL
);

CREATE TABLE map2.people (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  name VARCHAR(64) NOT NULL,
  org VARCHAR(256) NOT NULL,
  tel VARCHAR(16),
  mail VARCHAR(64),
  image VARCHAR(128)
);

CREATE TABLE map2.floors (
  id VARCHAR(36) NOT NULL,
  version INT NOT NULL,
  name VARCHAR(128) NOT NULL,
  ord INT NOT NULL,
  image VARCHAR(128),
  width INT,
  height INT,
  realWidth INT,
  realHeight INT,
  public boolean,
  updateBy VARCHAR(36),
  updateAt bigINT,
  UNIQUE(id, version)
);

CREATE TABLE map2.objects (
  id VARCHAR(36) NOT NULL,
  type VARCHAR(16) NOT NULL,
  name VARCHAR(128) NOT NULL,
  x INT NOT NULL,
  y INT NOT NULL,
  width INT NOT NULL,
  height INT NOT NULL,
  backgroundColor VARCHAR(64) NOT NULL,
  color VARCHAR(64) NOT NULL,
  fontSize DECIMAL(4,1) NOT NULL,
  shape VARCHAR(64) NOT NULL,
  modifiedVersion INT(11) NOT NULL,
  personId VARCHAR(36),
  floorId VARCHAR(36) NOT NULL,
  floorVersion INT NOT NULL,
  UNIQUE(id, floorId, floorVersion)
);

CREATE TABLE map2.prototypes (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  name VARCHAR(128) NOT NULL,
  width INT NOT NULL,
  height INT NOT NULL,
  color VARCHAR(64) NOT NULL
);

CREATE TABLE map2.colors (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  ord INT NOT NULL,
  type VARCHAR(16) NOT NULL,
  color VARCHAR(64) NOT NULL
);
