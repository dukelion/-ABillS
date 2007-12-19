CREATE TABLE `extfin_reports` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `period` varchar(7) NOT NULL default '0000-00',
  `sum` double(14,2) unsigned NOT NULL default '0.00',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `date` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `period` (`period`,`bill_id`)
) COMMENT='Extfin reports';


CREATE TABLE `extfin_paids` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `date` date NOT NULL default '0000-00-00',
  `sum` double(14,2) unsigned NOT NULL default '0.00',
  `describe` varchar(100) NOT NULL default '',
  `uid` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `status` tinyint(2) unsigned NOT NULL default '0',
  `type` smallint(6) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`)
) COMMENT='Extfin paids list';


CREATE TABLE `extfin_paids_types` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `name` varchar(120) NOT NULL default '',
  `periodic` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) COMMENT='Extfin payments types';
