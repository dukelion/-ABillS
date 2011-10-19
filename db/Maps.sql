
CREATE TABLE IF NOT EXISTS `maps_routes` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(45) default NULL,
  `type` tinyint(3) unsigned default '0',
  `descr` text,
  `nas1` smallint(5) unsigned default '0',
  `nas2` smallint(5) unsigned default '0',
  `nas1_port` tinyint(3) unsigned default '0',
  `nas2_port` tinyint(3) unsigned default '0',
  `length` smallint(5) unsigned default '0',
  PRIMARY KEY  (`id`)
) COMMENT='Routes information';

CREATE TABLE IF NOT EXISTS `maps_routes_coords` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `routes_id` int(10) unsigned default '0',
  `coordx` double(20,14) default '0.00000000000000',
  `coordy` double(20,14) default '0.00000000000000',
  PRIMARY KEY  (`id`)
) COMMENT='Routes coords';


