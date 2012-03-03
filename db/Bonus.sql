CREATE TABLE `bonus_log` (
  `date` datetime NOT NULL default '0000-00-00 00:00:00',
  `sum` double(10,2) NOT NULL default '0.00',
  `dsc` varchar(80) default NULL,
  `ip` int(11) unsigned NOT NULL default '0',
  `last_deposit` double(15,6) NOT NULL default '0.000000',
  `uid` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  `method` tinyint(4) unsigned NOT NULL default '0',
  `ext_id` varchar(28) NOT NULL default '',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `inner_describe` varchar(80) NOT NULL default '',
  `action_type` tinyint(11) unsigned NOT NULL default '0',
  `expire` date NOT NULL default '0000-00-00',  
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `date` (`date`),
  KEY `uid` (`uid`)
) COMMENT "Bonus log"  ;

CREATE TABLE `bonus_service_discount` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `service_period` smallint(4) unsigned NOT NULL default '0',
  `registration_days` smallint(4) unsigned NOT NULL default '0',
  `discount` double(10,2) NOT NULL default '0.00',
  `discount_days` smallint(4) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) COMMENT "Bonus service discount"  ;
