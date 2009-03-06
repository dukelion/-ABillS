CREATE TABLE IF NOT EXISTS `ureports_log` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `execute` datetime NOT NULL,
  `body` text NOT NULL,
  `destination` varchar(60) NOT NULL,
  `report_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `tp_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  `status` tinyint(3) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `uid` (`uid`)
) COMMENT='Ureports log';

CREATE TABLE `ureports_main` (
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `tp_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `registration` date NOT NULL,
  `status` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `type` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `destination` varchar(40) NOT NULL,
  PRIMARY KEY (`uid`),
  KEY `tp_id` (`tp_id`)
) COMMENT='Ureports user account';

CREATE TABLE `ureports_spool` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `added` datetime NOT NULL,
  `execute` date NOT NULL,
  `body` text NOT NULL,
  `destinatio` varchar(60) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `uid` (`uid`)
) COMMENT='Ureports spool';

CREATE TABLE `ureports_tp` (
  `msg_price` double(14,2) unsigned NOT NULL DEFAULT '0.00',
  `tp_id` smallint(5) unsigned DEFAULT '0'
) COMMENT='Ureports tarif plans';


CREATE TABLE `ureports_tp_reports` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `tp_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `msg_price` double(14,2) unsigned NOT NULL DEFAULT '0.00',
  `report_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `tp_id` (`tp_id`,`report_id`)
) COMMENT='Ureports tarif plans reports';

CREATE TABLE `ureports_users_reports` (
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `report_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `date` date NOT NULL DEFAULT '0000-00-00',
  `value` varchar(10) NOT NULL
) COMMENT='Ureports users reports';

