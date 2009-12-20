CREATE TABLE `mdelivery_list` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `date` date NOT NULL default '0000-00-00',
  `added` datetime NOT NULL default '0000-00-00 00:00:00',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `text` text NOT NULL,
  `subject` varchar(250) NOT NULL default '',
  `gid` smallint(4) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `sender` varchar(20) NOT NULL default '',
  `priority` tinyint(2) unsigned NOT NULL default '0',
  `status` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) COMMENT='Mdelivery list';

CREATE TABLE `mdelivery_users` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `mdelivery_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `status` TINYINT(1) UNSIGNED NOT NULL default '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `mdelivery_id` (`mdelivery_id`, `uid`)
) COMMENT='Mdelivery users';
