CREATE TABLE `multidoms_nas_tps` (
  `nas_id` smallint(6) unsigned NOT NULL,
  `domain_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `tp_id` smallint(6) unsigned NOT NULL,
  `datetime` datetime NOT NULL,
  `bonus_cards` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`domain_id`,`tp_id`,`nas_id`)
) COMMENT='Multidoms Dillers NAS TPS. For postpaid cards fees';


DELIMITER //
CREATE TRIGGER domain_add AFTER INSERT ON domains
FOR EACH ROW 
BEGIN


INSERT INTO `tarif_plans` (id,
  name,
  logins,
  domain_id,
  total_time_limit) VALUES
(1, '1 Hour', 1, NEW.id, 3600),
(12, '5 Hours',1, NEW.id, 18000),
(13, '24 Hours', 1, NEW.id, 86400);

INSERT INTO `nas_groups` (name, domain_id, `default`)
  VALUES ('Default', NEW.id, 1);


END;

//
DELIMITER ;
