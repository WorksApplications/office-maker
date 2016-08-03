ALTER TABLE `map2`.`equipments`
ADD COLUMN `type` VARCHAR(16) NOT NULL DEFAULT 'desk' AFTER `id`,
ADD COLUMN `fontSize` DECIMAL(4,1) NOT NULL AFTER `color`;


ALTER TABLE `map2`.`equipments`
CHANGE COLUMN `color` `color` VARCHAR(64) NOT NULL DEFAULT '#000' ,
ADD COLUMN `backgroundColor` VARCHAR(64) NOT NULL DEFAULT '#fff' AFTER `height`,
ADD COLUMN `shape` VARCHAR(64) NOT NULL DEFAULT 'rectangle' AFTER `fontSize`;


ALTER TABLE `map2`.`equipments`
ADD COLUMN `modifiedVersion` INT(11) NOT NULL AFTER `floorVersion`;
