CREATE TABLE `notepad` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `notified` datetime DEFAULT '0000-00-00 00:00:00',
  `create_date` date DEFAULT '0000-00-00',
  `status` int(3) unsigned not null DEFAULT 0,
  `subject` varchar(60) not null DEFAULT '',
  `text` text,
  `aid` smallint(5) unsigned not null DEFAULT 0,
  PRIMARY KEY (`id`)
) COMMENT="Notepad";

