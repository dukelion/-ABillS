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
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
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
  UNIQUE KEY `serial` (`number`,`serial`),
  KEY `diller_id` (`diller_id`),
  KEY `login` (`login`)
) COMMENT='Cards list';
