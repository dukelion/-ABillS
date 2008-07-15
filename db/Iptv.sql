
CREATE TABLE `iptv_main` (
  `uid` int(11) unsigned NOT NULL default '0',
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `filter_id` varchar(15) NOT NULL default '',
  `cid` varchar(35) NOT NULL default '',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `registration` date default '0000-00-00',
  PRIMARY KEY  (`uid`),
  KEY `tp_id` (`tp_id`)
) COMMENT='IPTV users settings';

CREATE TABLE `iptv_tps` (
  `id` smallint(5) unsigned NOT NULL default '0',
  `day_time_limit` int(10) unsigned NOT NULL default '0',
  `week_time_limit` int(10) unsigned NOT NULL default '0',
  `month_time_limit` int(10) unsigned NOT NULL default '0',
  `max_session_duration` smallint(6) unsigned NOT NULL default '0',
  `min_session_cost` double(15,5) unsigned NOT NULL default '0.00000',
  `rad_pairs` text NOT NULL,
  `first_period` int(10) unsigned NOT NULL default '0',
  `first_period_step` int(10) unsigned NOT NULL default '0',
  `next_period` int(10) unsigned NOT NULL default '0',
  `next_period_step` int(10) unsigned NOT NULL default '0',
  `free_time` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`)
) COMMENT='IPTV TPs';

CREATE TABLE `iptv_channels` (
  `id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `num` smallint(6) unsigned NOT NULL DEFAULT '0',
  `port` smallint(6) unsigned NOT NULL DEFAULT '0',
  `comments` text NOT NULL,
  `disable` tinyint(2) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `num` (`num`)
) COMMENT='IPTV channels';

CREATE TABLE `iptv_ti_channels` (
  `interval_id` int(11) unsigned NOT NULL DEFAULT '0',
  `channel_id` int(11) unsigned NOT NULL DEFAULT '0',
  `date` date NOT NULL DEFAULT '0000-00-00',
  UNIQUE KEY `channel_id` (`channel_id`,`interval_id`)
) COMMENT='IPTV channels prices';


