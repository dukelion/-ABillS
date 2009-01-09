CREATE TABLE `abon_tariffs` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `name` varchar(20) NOT NULL default '',
  `period` tinyint(2) unsigned NOT NULL default '0',
  `price` double(14,2) unsigned NOT NULL default '0.00',
  `payment_type` tinyint(1) unsigned NOT NULL default '0',
  `period_alignment` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Abon tariffs';

CREATE TABLE `abon_user_list` (
  `uid` int(11) unsigned NOT NULL default '0',
  `tp_id` smallint(6) unsigned NOT NULL default '0',
  `date` date NOT NULL default '0000-00-00'
) COMMENT='Abon user list';
