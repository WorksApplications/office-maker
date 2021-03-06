CREATE TABLE map2.objects_opt (
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
  bold TINYINT(1) NOT NULL,
  url VARCHAR(1024) NOT NULL,
  personId VARCHAR(128),
  personName VARCHAR(128) NOT NULL,
  personEmpNo VARCHAR(32) NOT NULL,
  personPost VARCHAR(512) NOT NULL,
  personTel1 VARCHAR(32) NOT NULL,
  personTel2 VARCHAR(32) NOT NULL,
  personMail VARCHAR(128) NOT NULL,
  personImage VARCHAR(256) NOT NULL,
  floorId VARCHAR(36) NOT NULL,
  editing TINYINT(1) NOT NULL,
  updateAt BIGINT(20) NOT NULL,
  UNIQUE(id, floorId, editing)
);
