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
  `vid` smallint(6) unsigned NOT NULL default '0',
  `nas` smallint(6) unsigned NOT NULL default '0',
  `option_82` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `cid` (`ip`),
  UNIQUE KEY `mac` (`mac`)
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
  `dns` varchar(100) NOT NULL default '',
  `coordinator` varchar(50) NOT NULL default '',
  `phone` varchar(20) NOT NULL default '',
  `routers` int(11) unsigned NOT NULL default '0',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Dhcphost networks';
