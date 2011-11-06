CREATE TABLE turbo_mode (
   `id` int(11) unsigned NOT NULL auto_increment,
  `mode_id` smallint(6) unsigned NOT NULL default '0',
  `start` datetime NOT NULL default '0000-00-00 00:00:00',
  `speed` int(10) unsigned NOT NULL default '0',
  `speed_type` tinyint(1) unsigned NOT NULL default '0',
  `time` int(11) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
   PRIMARY KEY  (`id`),
  KEY `uid` (`uid`, `start`)  
) COMMENT='Turbo mode Active Sessions';
