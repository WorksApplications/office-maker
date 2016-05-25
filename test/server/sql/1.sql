SET SQL_SAFE_UPDATES=0;

CREATE TABLE users (
  id varchar(36) NOT NULL PRIMARY KEY,
  pass varchar(128) NOT NULL,
  role varchar(10) NOT NULL,
  personId varchar(36) NOT NULL
);

CREATE TABLE people (
  id varchar(36) NOT NULL PRIMARY KEY,
  name varchar(64) NOT NULL,
  org varchar(256) NOT NULL,
  tel varchar(16),
  mail varchar(64),
  image varchar(128)
);

CREATE TABLE floors (
  id varchar(36) NOT NULL,
  version int NOT NULL,
  name varchar(128) NOT NULL,
  image varchar(128),
  width int,
  height int,
  realWidth int,
  realHeight int,
  public boolean,
  updateBy varchar(36),
  updateAt bigint,
  UNIQUE(id, version)
);

CREATE TABLE equipments (
  id varchar(36) NOT NULL,
  name varchar(128) NOT NULL,
  x int NOT NULL,
  y int NOT NULL,
  width int NOT NULL,
  height int NOT NULL,
  color varchar(64) NOT NULL,
  personId varchar(36),
  floorId varchar(36) NOT NULL,
  floorVersion int NOT NULL,
  UNIQUE(id, floorId, floorVersion)
);

CREATE TABLE prototypes (
  id varchar(36) NOT NULL PRIMARY KEY,
  name varchar(128) NOT NULL,
  width int NOT NULL,
  height int NOT NULL,
  color varchar(64) NOT NULL
);

CREATE TABLE colors (
  id varchar(36) NOT NULL PRIMARY KEY,
  color0 varchar(64),
  color1 varchar(64),
  color2 varchar(64),
  color3 varchar(64),
  color4 varchar(64),
  color5 varchar(64),
  color6 varchar(64),
  color7 varchar(64),
  color8 varchar(64),
  color9 varchar(64),
  color10 varchar(64)
);
