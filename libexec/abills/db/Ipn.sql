CREATE TABLE `ipn_club_comps` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(20) NOT NULL default '0',
  `ip` int(11) unsigned NOT NULL default '0',
  `cid` varchar(17) NOT NULL default '',
  `number` smallint(6) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `ip` (`ip`),
  UNIQUE KEY `number` (`number`)
) COMMENT='Ipn club comps';

CREATE TABLE `ipn_log` (
  `uid` int(11) unsigned NOT NULL default '0',
  `start` datetime NOT NULL default '0000-00-00 00:00:00',
  `stop` datetime NOT NULL default '0000-00-00 00:00:00',
  `traffic_class` smallint(3) unsigned NOT NULL default '0',
  `traffic_in` bigint(14)  unsigned NOT NULL default '0',
  `traffic_out` bigint(14) unsigned NOT NULL default '0',
  `nas_id` smallint(6) unsigned NOT NULL default '0',
  `ip` int(11) unsigned NOT NULL default '0',
  `interval_id` smallint(5) unsigned NOT NULL default '0',
  `sum` double(15,6) unsigned NOT NULL default '0.000000',
  `session_id` char(20) NOT NULL default '',
  KEY uid_traffic_class (uid, traffic_class),
  KEY `uid` (`uid`),
  KEY `session_id` (`session_id`)
) COMMENT='Ipn log traffic class';


CREATE TABLE `ipn_traf_detail` (
  `src_addr` int(11) unsigned NOT NULL default '0',
  `dst_addr` int(11) unsigned NOT NULL default '0',
  `src_port` smallint(5) unsigned NOT NULL default '0',
  `dst_port` smallint(5) unsigned NOT NULL default '0',
  `protocol` tinyint(3) unsigned default '0',
  `size` int(10) unsigned NOT NULL default '0',
  `f_time` datetime NOT NULL default '0000-00-00 00:00:00',
  `s_time` datetime NOT NULL default '0000-00-00 00:00:00',
  `nas_id` smallint(5) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0'
) COMMENT='Ipn detail log traffic class';


CREATE TABLE `traffic_prepaid_sum` (
  `started` DATE NOT NULL DEFAULT '0000-00-00',
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `traffic_class` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `traffic_in` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  `traffic_out` BIGINT(14) UNSIGNED NOT NULL DEFAULT '0',
  KEY `uid` (`uid`, `started`, `traffic_class`)
) COMMENT='Prepaid traffic summary';


CREATE TABLE `ipn_unknow_ips` (
`src_ip` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
`dst_ip` INTEGER(11) UNSIGNED NOT NULL,
`size` INTEGER(11) UNSIGNED NOT NULL,
`nas_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
`datetime` DATETIME NOT NULL
) COMMENT='Ipn unknow ips';  
