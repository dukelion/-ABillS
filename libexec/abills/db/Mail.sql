CREATE TABLE `mail_spamassassin` (
  `prefid` int(10) unsigned NOT NULL auto_increment,
  `username` varchar(128) NOT NULL default '',
  `preference` varchar(64) NOT NULL default '',
  `value` varchar(128) default NULL,
  `comments` varchar(128) NOT NULL default '',
  `create_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `change_date` datetime NOT NULL default '0000-00-00 00:00:00',
  PRIMARY KEY `prefid` (`prefid`),
  KEY `preference` (`preference`),
  KEY `username` (`username`),
  KEY `username_preference_value` (`username`,`preference`,`value`)
) COMMENT='Mail Spamassassin Preferences';

LOCK TABLES `mail_spamassassin` WRITE;
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','skip_rbl_checks','1',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','rbl_timeout','30',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','dns_available','no',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','bayes_auto_learn_threshold_nonspam','0.1',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','bayes_auto_learn_threshold_spam','12',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','use_auto_whitelist','1',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','auto_whitelist_factor','0.5',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','required_score','5.0',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','rewrite_header Subject','*** SPAM: _HITS_ ***',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','report_safe','1',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','score USER_IN_WHITELIST','-50',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','score USER_IN_BLACKLIST','50',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','bayes_auto_learn','1',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','ok_locales','all',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','use_bayes','1',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','use_razor2','1',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','use_dcc','1',now());
INSERT INTO `mail_spamassassin` (username, preference, value, create_date) VALUES ('$GLOBAL','use_pyzor','1',now());
UNLOCK TABLES;


CREATE TABLE `mail_awl` (
  `username` varchar(100) NOT NULL default '',
  `email` varchar(200) NOT NULL default '',
  `ip` varchar(10) NOT NULL default '',
  `count` int(11) default '0',
  `totscore` float default '0',
  PRIMARY KEY  (`username`,`email`,`ip`)
) COMMENT='Mail Auto whitelist';
