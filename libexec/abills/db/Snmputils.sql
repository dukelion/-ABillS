CREATE TABLE `snmputils_binding` (
  `uid` int(11) unsigned NOT NULL default '0',
  `binding` varchar(30) NOT NULL default '',
  `comments` varchar(100) NOT NULL default '',
  `params` varchar(20) NOT NULL default '',
  `id` int(11) unsigned NOT NULL auto_increment,
  UNIQUE KEY `binding` (`binding`),
  UNIQUE KEY `id` (`id`),
  KEY `uid` (`uid`)
) COMMENT='Snmputils binding' ;
