

CREATE TABLE IF NOT EXISTS `storage_accountability` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `aid` smallint(5) unsigned NOT NULL default '0',
  `storage_incoming_articles_id` int(10) unsigned NOT NULL default '0',
  `count` int(10) unsigned NOT NULL default '0',
  `date` datetime NOT NULL,
  `comments` text,
  KEY `id` (`id`),
  KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
) DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `storage_articles` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  `article_type` smallint(6) unsigned NOT NULL default '0',
  `measure` varchar(2) NOT NULL default '0',
  `comments` text,
  `add_date` date NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `article_type` (`article_type`)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `storage_article_types` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(255) default NULL,
  `comments` text,
  PRIMARY KEY  (`id`)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `storage_discard` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `storage_incoming_articles_id` int(10) unsigned default '0',
  `count` int(10) unsigned NOT NULL default '0',
  `aid` int(10) unsigned default '0',
  `date` datetime default '0000-00-00 00:00:00',
  `comments` text,
  PRIMARY KEY  (`id`),
  KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `storage_incoming` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `date` datetime NOT NULL,
  `aid` smallint(5) unsigned NOT NULL default '0',
  `ip` int(10) unsigned NOT NULL default '0',
  `comments` text NOT NULL,
  `supplier_id` smallint(5) unsigned NOT NULL default '0',
  `storage_id` tinyint(4) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `supplier_id` (`supplier_id`)
) DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `storage_incoming_articles` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `article_id` smallint(6) unsigned default NULL,
  `count` int(11) unsigned NOT NULL default '0',
  `sum` int(10) unsigned NOT NULL default '0',
  `sn` int(10) unsigned NOT NULL default '0',
  `main_article_id` smallint(5) unsigned NOT NULL default '0',
  `storage_incoming_id` smallint(5) unsigned NOT NULL default '0',
  `sell_price` int(10) unsigned NOT NULL default '0',
  `rent_price` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `storage_incoming_id` (`storage_incoming_id`),
  KEY `article_id` (`article_id`)
) DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS `storage_installation` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `storage_incoming_articles_id` int(10) unsigned default '0',
  `location_id` int(10) unsigned default '0',
  `count` int(10) unsigned NOT NULL default '0',
  `aid` int(10) unsigned default '0',
  `uid` int(10) unsigned default '0',
  `nas_id` int(10) unsigned default '0',
  `comments` text,
  `sum` int(10) unsigned NOT NULL default '0',
  `mac` varchar(40) NOT NULL,
  `type` smallint(1) NOT NULL,
  `grounds` varchar(40) NOT NULL,
  `date` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`),
  KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
) DEFAULT CHARSET=utf8;



CREATE TABLE `storage_log` (
  `id` int(11) NOT NULL auto_increment,
  `date` datetime NOT NULL,
  `aid` tinyint(4) unsigned NOT NULL default '0',
  `storage_main_id` int(10) unsigned NOT NULL default '0',
  `storage_id` tinyint(3) unsigned NOT NULL default '0',
  `comments` text,
  `action` tinyint(3) unsigned NOT NULL default '0',
  `ip` int(10) unsigned NOT NULL default '0',
  `count` int(10) unsigned NOT NULL default '0',
  `storage_installation_id` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `storage_reserve` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `storage_incoming_articles_id` int(10) unsigned default '0',
  `count` int(10) unsigned default '0',
  `aid` int(10) unsigned default '0',
  `date` datetime default NULL,
  `comments` text,
  PRIMARY KEY  (`id`),
  KEY `storage_incoming_articles_id` (`storage_incoming_articles_id`)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `storage_suppliers` (
  `id` smallint(6) NOT NULL auto_increment,
  `name` varchar(15) NOT NULL default '',
  `date` date NOT NULL,
  `okpo` varchar(12) NOT NULL default '',
  `inn` varchar(20) NOT NULL default '',
  `inn_svid` varchar(40) NOT NULL default '',
  `bank_name` varchar(200) NOT NULL default '',
  `mfo` varchar(8) NOT NULL default '',
  `account` varchar(16) NOT NULL default '',
  `phone` varchar(16) NOT NULL default '',
  `phone2` varchar(16) NOT NULL default '',
  `fax` varchar(16) NOT NULL default '',
  `url` varchar(100) NOT NULL default '',
  `email` varchar(250) NOT NULL default '',
  `icq` varchar(12) NOT NULL default '',
  `accountant` varchar(150) NOT NULL default '',
  `director` varchar(150) NOT NULL default '',
  `managment` varchar(150) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `storage_sn` (
  `id` int(11) NOT NULL auto_increment,
  `storage_incoming_articles_id` smallint(6) NOT NULL,
  `storage_installation_id` smallint(6) NOT NULL,
  `serial` text character set utf8 NOT NULL,
  PRIMARY KEY  (`id`)
) DEFAULT CHARSET=utf8;


