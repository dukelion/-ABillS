CREATE TABLE `netlist_groups` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `name` char(20) NOT NULL default '',
  `comments` char(250) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Netlist groups';


CREATE TABLE `netlist_ips` (
  `ip` int(11) unsigned NOT NULL default '0',
  `gid` smallint(6) unsigned NOT NULL default '0',
  `netmask` int(11) unsigned NOT NULL default '0',
  `hostname` varchar(50) NOT NULL default '',
  `status` tinyint(2) unsigned NOT NULL default '0',
  `comments` text NOT NULL,
  `date` datetime NOT NULL default '0000-00-00 00:00:00',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `descr` varchar(200) NOT NULL default '',
  `machine_type` smallint(6) unsigned NOT NULL default '0',
  `location` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`ip`),
  UNIQUE KEY `ip` (`ip`)
) COMMENT='Netlist ips';
