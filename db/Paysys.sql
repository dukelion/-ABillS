CREATE TABLE `paysys_log` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `system_id` tinyint(4) unsigned NOT NULL default '0',
  `datetime` datetime NOT NULL default '0000-00-00 00:00:00',
  `sum` double(10,2) unsigned NOT NULL default '0.00',
  `uid` int(11) unsigned NOT NULL default '0',
  `transaction_id` int(11) unsigned NOT NULL default '0',
  `info` text NOT NULL,
  `ip` int(11) unsigned NOT NULL default '0',
  `code` blob NOT NULL,
  `paysys_ip` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `ps_transaction_id` (`transaction_id`)
) COMMENT='Paysys';
