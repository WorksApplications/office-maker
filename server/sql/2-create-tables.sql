CREATE TABLE map2.floors (
  id VARCHAR(36) NOT NULL,
  tenantId VARCHAR(64),
  version INT NOT NULL,
  name VARCHAR(128) NOT NULL,
  ord INT NOT NULL,
  image VARCHAR(128),
  width INT NOT NULL,
  height INT NOT NULL,
  realWidth INT,
  realHeight INT,
  public BOOLEAN,
  updateBy VARCHAR(128),
  updateAt BIGINT,
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
  personId VARCHAR(128),
  floorId VARCHAR(36) NOT NULL,
  floorVersion INT NOT NULL,
  UNIQUE(id, floorId, floorVersion)
);

CREATE TABLE map2.prototypes (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  tenantId VARCHAR(64) NOT NULL,
  name VARCHAR(128) NOT NULL,
  width INT NOT NULL,
  height INT NOT NULL,
  backgroundColor VARCHAR(64) NOT NULL,
  color VARCHAR(64) NOT NULL,
  fontSize DECIMAL(4,1) NOT NULL,
  shape VARCHAR(64) NOT NULL
);

CREATE TABLE map2.colors (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  tenantId VARCHAR(64) NOT NULL,
  ord INT NOT NULL,
  type VARCHAR(16) NOT NULL,
  color VARCHAR(64) NOT NULL
);
