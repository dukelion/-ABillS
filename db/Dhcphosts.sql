CREATE TABLE `dhcphosts_hosts` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `uid` int(11) NOT NULL default '0',
  `ip` int(10) unsigned NOT NULL default '0',
  `hostname` varchar(40) NOT NULL default '',
  `network` smallint(5) unsigned NOT NULL default '0',
  `mac` varchar(17) NOT NULL default '00:00:00:00:00:00',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `forced` int(1) NOT NULL default '0',
  `blocktime` int(3) unsigned NOT NULL default '3',
  `expire` date NOT NULL default '0000-00-00',
  `seen` int(1) NOT NULL default '0',
  `comments` varchar(250) NOT NULL default '',
  `ports` varchar(100) NOT NULL DEFAULT '',
  `vid` smallint(6) unsigned NOT NULL default '0',
  `nas` smallint(6) unsigned NOT NULL default '0',
  `option_82` tinyint(1) unsigned NOT NULL default '0',
  `boot_file` VARCHAR( 150 ) NOT NULL default '',
  changed datetime not null default '0000-00-00 00:00:00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `cid` (`ip`),
  UNIQUE KEY `mac` (`mac`),
  UNIQUE KEY `host` (`hostname`)
) COMMENT='Dhcphosts hosts';


CREATE TABLE `dhcphosts_routes` (
  `id` int(3) unsigned NOT NULL auto_increment,
  `network` int(3) unsigned NOT NULL default '0',
  `src` int(10) unsigned NOT NULL default '0',
  `mask` int(10) unsigned NOT NULL default '4294967294',
  `router` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) COMMENT='Dhcphosts routes';

CREATE TABLE `dhcphosts_networks` (
  `id` smallint(3) unsigned NOT NULL auto_increment,
  `name` varchar(40) NOT NULL default '',
  `network` int(10) unsigned NOT NULL default '0',
  `mask` int(11) unsigned NOT NULL default '4294967294',
  `block_network` int(10) unsigned NOT NULL default '0',
  `block_mask` int(10) unsigned NOT NULL default '0',
  `suffix` varchar(20) NOT NULL default '',
  `dns` varchar(32) NOT NULL default '',
  `dns2` varchar(32) NOT NULL default '',
  `ntp` varchar(100) NOT NULL default '',
  `coordinator` varchar(50) NOT NULL default '',
  `phone` varchar(20) NOT NULL default '',
  `routers` int(11) unsigned NOT NULL default '0',
  `ip_range_first` int(11) unsigned NOT NULL DEFAULT '0',
  `ip_range_last` int(11) unsigned NOT NULL DEFAULT '0',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `comments` varchar(250) not null default '',
  `deny_unknown_clients` tinyint(1) unsigned not null default 0,
  `authoritative` tinyint(1) unsigned not null default 0,
  `net_parent` smallint(5) unsigned NOT NULL DEFAULT '0',
  `guest_vlan` smallint(5) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Dhcphost networks';

CREATE TABLE `dhcphosts_leases` (
  `start` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `ends` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `state` tinyint(2) NOT NULL DEFAULT '0',
  `next_state` tinyint(2) NOT NULL DEFAULT '0',
  `hardware` varchar(17) NOT NULL DEFAULT '',
  `uid` varchar(30) NOT NULL DEFAULT '',
  `circuit_id` varchar(25) NOT NULL DEFAULT '',
  `remote_id` varchar(25) NOT NULL DEFAULT '',
  `hostname` varchar(30) NOT NULL DEFAULT '',
  `nas_id` smallint(6) NOT NULL DEFAULT '0',
  `ip` int(11) unsigned NOT NULL DEFAULT '0',
  `port` smallint(6) unsigned NOT NULL DEFAULT '0',
  `vlan` smallint(6) unsigned NOT NULL DEFAULT '0',
  `switch_mac` varchar(17) NOT NULL DEFAULT '',
  `flag` tinyint(2) NOT NULL DEFAULT '0',
  KEY `ip` (`ip`),
  KEY `nas_id` (`nas_id`)
) COMMENT='Dhcphosts leaseds';

CREATE TABLE `dhcphosts_log` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `datetime` DATETIME NOT NULL,
  `hostname` VARCHAR(20) NOT NULL DEFAULT '',
  `message_type` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `message` VARCHAR(90) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) COMMENT='Dhcphosts log';
