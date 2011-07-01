CREATE TABLE `paysys_log` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `system_id` tinyint(4) unsigned NOT NULL default '0',
  `datetime` datetime NOT NULL default '0000-00-00 00:00:00',
  `sum` double(10,2) unsigned NOT NULL default '0.00',
  `uid` int(11) unsigned NOT NULL default '0',
  `transaction_id` varchar(24) NOT NULL DEFAULT '',
  `info` text NOT NULL,
  `ip` int(11) unsigned NOT NULL default '0',
  `code` blob NOT NULL,
  `paysys_ip` int(11) unsigned NOT NULL DEFAULT '0',
  `domain_id` smallint(6) unsigned not null default '0',
  `status` tinyint(2) unsigned not null default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `ps_transaction_id` (`domain_id`, `transaction_id`)
) COMMENT='Paysys log';
