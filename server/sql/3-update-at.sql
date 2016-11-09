ALTER TABLE map2.objects
  ADD COLUMN updateAt BIGINT(20) NOT NULL AFTER floorVersion;

ALTER TABLE map2.objects
  DROP COLUMN modifiedVersion;

SELECT * FROM map2.floors ORDER BY id, version DESC;
SELECT * FROM map2.objects ORDER BY id, floorId, floorVersion DESC;
