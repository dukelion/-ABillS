CREATE TABLE `cards_bruteforce` (
  `uid` int(11) unsigned NOT NULL default '0',
  `pin` varchar(20) NOT NULL default '',
  `datetime` datetime NOT NULL default '0000-00-00 00:00:00'
) COMMENT='Cards bruteforce check' ;

CREATE TABLE `cards_dillers` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(45) NOT NULL default '',
  `address` varchar(100) NOT NULL default '',
  `phone` bigint(20) unsigned NOT NULL default '0',
  `email` varchar(35) NOT NULL default '0',
  `comments` text NOT NULL,
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `registration` date NOT NULL default '0000-00-00',
  `percentage` tinyint(3) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `tp_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `uid` (`uid`)
) COMMENT='Cards dillers';


CREATE TABLE `cards_users` (
  `number` int(11) unsigned zerofill NOT NULL default '00000000000',
  `login` varchar(20) NOT NULL default '',
  `status` tinyint(2) unsigned NOT NULL default '0',
  `datetime` datetime NOT NULL default '0000-00-00 00:00:00',
  `aid` int(11) unsigned NOT NULL default '0',
  `gid` smallint(6) unsigned NOT NULL default '0',
  `expire` date NOT NULL default '0000-00-00',
  `diller_id` smallint(6) unsigned NOT NULL default '0',
  `diller_date` date NOT NULL default '0000-00-00',
  `diller_sold_date` date NOT NULL default '0000-00-00',
  `sum` double(10,2) unsigned NOT NULL default '0.00',
  `serial` varchar(10) NOT NULL default '',
  `pin` blob NOT NULL default '',
  `uid` int(11) unsigned NOT NULL default '0',
  `domain_id` smallint(6) unsigned not null default 0,
  `created` DATETIME NOT NULL,
  UNIQUE KEY `serial` (`number`,`serial`, `domain_id`),
  KEY `diller_id` (`diller_id`),
  KEY `login` (`login`)
) COMMENT='Cards list';

CREATE TABLE `dillers_tps` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  `payment_type` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `percentage` TINYINT(3) UNSIGNED NOT NULL DEFAULT '0',
  `operation_payment` DOUBLE(14,2) UNSIGNED NOT NULL DEFAULT '0.00',
  `activate_price` DOUBLE(14,2) UNSIGNED NOT NULL DEFAULT '0.00',
  `change_price` DOUBLE(14,2) UNSIGNED NOT NULL DEFAULT '0.00',
  `credit` DOUBLE(10,2) UNSIGNED NOT NULL DEFAULT '0.00',
  `min_use` DOUBLE(14,3) UNSIGNED NOT NULL DEFAULT '0.000',
  `payment_expr` VARCHAR(240) COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
 ) COMMENT='Resellers Tarif Plans';
