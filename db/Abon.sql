CREATE TABLE `abon_tariffs` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `name` varchar(100) NOT NULL default '',
  `period` tinyint(2) unsigned NOT NULL default '0',
  `price` double(14,2) unsigned NOT NULL default '0.00',
  `payment_type` tinyint(1) unsigned NOT NULL default '0',
  `period_alignment` tinyint(1) NOT NULL DEFAULT '0',
  `ext_bill_account` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `nonfix_period` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `priority` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `account` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `fees_type` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `create_account` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `vat` tinyint(1) unsigned NOT NULL DEFAULT '0', 
  `notification1` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `notification2` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `notification_account` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `alert` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `alert_account` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `ext_cmd` VARCHAR(240) NOT NULL DEFAULT '' ,
  `discount` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Abon tariffs';

CREATE TABLE `abon_user_list` (
  `uid` int(11) unsigned NOT NULL default '0',
  `tp_id` smallint(6) unsigned NOT NULL default '0',
  `date` date NOT NULL default '0000-00-00',
  `comments` VARCHAR(240) NOT NULL DEFAULT '',
  `notification1` date NOT NULL default '0000-00-00',
  `notification1_account_id` int(11) unsigned NOT NULL DEFAULT 0, 
  `notification2` date NOT NULL default '0000-00-00',
  KEY `uid` (`uid`, `tp_id`)
) COMMENT='Abon user list';
