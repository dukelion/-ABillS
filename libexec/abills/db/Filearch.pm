CREATE TABLE `filearch` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `filename` varchar(100) NOT NULL default '',
  `path` varchar(250) NOT NULL default '',
  `name` varchar(200) NOT NULL default '',
  `checksum` varchar(150) NOT NULL default '',
  `added` date NOT NULL default '0000-00-00',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `size` int(11) unsigned NOT NULL default '0',
  `comments` text NOT NULL,
  `state` tinyint(2) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `filename` (`filename`,`path`)
) COMMENT='Filearch';


CREATE TABLE `filearch_film_actors` (
  `video_id` int(11) unsigned NOT NULL default '0',
  `actor_id` smallint(6) unsigned NOT NULL default '0',
  UNIQUE KEY `video_id` (`video_id`,`actor_id`),
  KEY `actor_id` (`actor_id`)
) COMMENT='Filearch actors';


CREATE TABLE `filearch_film_genres` (
  `video_id` int(11) unsigned NOT NULL default '0',
  `genre_id` smallint(6) unsigned NOT NULL default '0',
  KEY `video_id` (`video_id`)
) COMMENT='Filearch genres';

CREATE TABLE `filearch_state` (
  `file_id` int(11) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `state` tinyint(2) unsigned NOT NULL default '0',
  KEY `file_id` (`file_id`)
) COMMENT='Filearch state';

CREATE TABLE `filearch_video` (
  `id` int(11) unsigned NOT NULL default '0',
  `original_name` varchar(200) NOT NULL default '',
  `year` smallint(2) unsigned NOT NULL default '0',
  `genre` tinyint(4) unsigned NOT NULL default '0',
  `producer` varchar(50) NOT NULL default '',
  `descr` text NOT NULL,
  `studio` varchar(150) not null default '',
  `duration` time NOT NULL default '00:00:00',
  `language` tinyint(4) unsigned NOT NULL default '0',
  `file_format` varchar(20) NOT NULL default '',
  `file_quality` varchar(20) NOT NULL default '',
  `file_vsize` varchar(50) NOT NULL default '',
  `file_sound` varchar(50) NOT NULL default '',
  `cover_url` varchar(200) NOT NULL default '',
  `imdb` int(11) unsigned NOT NULL default '0',
  `parent` int(11) unsigned NOT NULL default '0',
  `extra` varchar(200) NOT NULL default '',
  `country` tinyint(4) unsigned  NOT NULL default '0',
  `cover_small_url` varchar(200) NOT NULL default '',
  `pin_access` tinyint(1) unsigned NOT NULL default '0',
  `updated` datetime not null default '0000-00-00 00:00:00',
  UNIQUE KEY `id` (`id`)
) COMMENT='Filearch';

CREATE TABLE `filearch_video_actors` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `name` varchar(60) NOT NULL default '',
  `bio` text NOT NULL,
  `origin_name` varchar(60) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `origin_name` (`origin_name`)
) COMMENT='Filearch';

CREATE TABLE `filearch_video_genres` (
  `id` tinyint(4) unsigned NOT NULL auto_increment,
  `name` varchar(20) NOT NULL default '',
  `imdb` varchar(20) default NULL,
  `sharereactor` varchar(20) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Filearch';

CREATE TABLE `filearch_countries` (
  `id` tinyint(4) unsigned NOT NULL auto_increment,
  `name` varchar(30) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Filearch';
