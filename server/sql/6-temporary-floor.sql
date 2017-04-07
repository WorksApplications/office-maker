ALTER TABLE `map2`.`floors`
DROP COLUMN `public`,
ADD COLUMN `temporary` TINYINT(1) NOT NULL AFTER `realHeight`;
