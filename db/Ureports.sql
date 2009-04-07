CREATE TABLE `ureports_log` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `execute` DATETIME NOT NULL,
  `body` TEXT COLLATE latin1_swedish_ci NOT NULL,
  `destination` VARCHAR(60) COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  `report_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(5) UNSIGNED NOT NULL DEFAULT '0',
  `status` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `uid` (`uid`)
)ENGINE=MyISAM
AUTO_INCREMENT=36 ROW_FORMAT=DYNAMIC 
CHARACTER SET 'latin1' COLLATE 'latin1_swedish_ci'
COMMENT='Ureports log';

CREATE TABLE `ureports_main` (
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `registration` DATE NOT NULL,
  `status` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `type` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `destination` VARCHAR(40) COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`uid`),
  KEY `tp_id` (`tp_id`)
)ENGINE=MyISAM
AUTO_INCREMENT=0 ROW_FORMAT=DYNAMIC 
CHARACTER SET 'latin1' COLLATE 'latin1_swedish_ci'
COMMENT='Ureports user account';


CREATE TABLE `ureports_spool` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `added` DATETIME NOT NULL,
  `execute` DATE NOT NULL,
  `body` TEXT COLLATE latin1_swedish_ci NOT NULL,
  `destinatio` VARCHAR(60) COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `uid` (`uid`)
)
COMMENT='Ureports spool';


CREATE TABLE `ureports_tp` (
  `msg_price` DOUBLE(14,2) UNSIGNED NOT NULL DEFAULT '0.00',
  `tp_id` SMALLINT(5) UNSIGNED DEFAULT '0'
)
COMMENT='Ureports tariff plans';


CREATE TABLE `ureports_tp_reports` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `msg_price` DOUBLE(14,2) UNSIGNED NOT NULL DEFAULT '0.00',
  `report_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `tp_id` (`tp_id`, `report_id`)
)
COMMENT='Ureports users Tarif plans';


CREATE TABLE `ureports_users_reports` (
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `report_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `date` DATE NOT NULL DEFAULT '0000-00-00',
  `value` VARCHAR(10) COLLATE cp1251_general_ci NOT NULL DEFAULT ''
)
COMMENT='Ureports users reports';
