CREATE TABLE IF NOT EXISTS `portal_articles` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `title` varchar(255) character set utf8 default NULL,
  `short_description` text character set utf8 NOT NULL,
  `content` text character set utf8,
  `status` tinyint(1) default NULL,
  `on_main_page` tinyint(1) default '0',
  `date` datetime default NULL,
  `portal_menu_id` int(10) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `fk_portal_content_portal_menu` (`portal_menu_id`)
)COMMENT='information about article';


CREATE TABLE IF NOT EXISTS `portal_menu` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(45) character set utf8 default NULL,
  `url` varchar(100) character set utf8 default NULL,
  `date` datetime default NULL,
  `status` tinyint(1) default NULL,
  PRIMARY KEY  (`id`)
)COMMENT='information about menu' ;



