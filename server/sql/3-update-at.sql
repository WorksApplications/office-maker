ALTER TABLE `map2`.`objects`
ADD COLUMN `updateAt` BIGINT(20) NOT NULL AFTER `floorVersion`;

ALTER TABLE `map2`.`objects`
DROP COLUMN `modifiedVersion`;
