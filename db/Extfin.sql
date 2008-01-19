CREATE TABLE `extfin_paids` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `date` date NOT NULL default '0000-00-00',
  `sum` double(14,2) unsigned NOT NULL default '0.00',
  `comments` varchar(100) NOT NULL default '',
  `uid` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `status` tinyint(2) unsigned NOT NULL default '0',
  `type_id` smallint(6) unsigned NOT NULL default '0',
  `maccount_id` tinyint(4) unsigned NOT NULL default '0', 
  `status_date` date NOT NULL default '0000-00-00',
  `ext_id` varchar(24) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`)
)  COMMENT='Extfin paids list';



CREATE TABLE `extfin_money_accounts` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `date` date NOT NULL default '0000-00-00',
  `name` varchar(60)  NOT NULL default '',
  `comments` varchar(200) NOT NULL default '',
  `expire` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Extfin Money accounts list';


CREATE TABLE `extfin_paids_periodic` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `uid` int(11) unsigned NOT NULL default '0',
  `type_id` smallint(6) unsigned NOT NULL default '0',
  `sum` double(14,2) unsigned NOT NULL default '0.00',
  `date` date NOT NULL default '0000-00-00',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `comments` varchar(100) NOT NULL default '',
  `maccount_id` tinyint(4) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
)  COMMENT='Extfin periodic paids';


CREATE TABLE `extfin_paids_types` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `name` varchar(120) NOT NULL default '',
  `periodic` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) COMMENT='Extfin payments types';


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
