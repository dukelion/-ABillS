CREATE TABLE `admin_actions` (
  `actions` varchar(100) NOT NULL default '',
  `datetime` datetime NOT NULL default '0000-00-00 00:00:00',
  `ip` int(11) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  `module` varchar(10) NOT NULL default '',
  `action_type` TINYINT(2) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `uid` (`uid`)
) COMMENT="Users changes log" ;


CREATE TABLE `admin_system_actions` (
 `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `actions` varchar(200) NOT NULL default '',
  `datetime` DATETIME NOT NULL,
  `ip` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `module` VARCHAR(10) NOT NULL DEFAULT '',
  `action_type` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) COMMENT='System Changes';   


CREATE TABLE `admin_permits` (
  `aid` smallint(6) unsigned NOT NULL default '0',
  `section` smallint(6) unsigned NOT NULL default '0',
  `actions` smallint(6) unsigned NOT NULL default '0',
  `module` varchar(12) NOT NULL default '',
  UNIQUE KEY `aid_modules` (`aid`,`module`,`section`,`actions`),
  KEY `aid` (`aid`)
) ;


CREATE TABLE `admins` (
  `id` varchar(12) NOT NULL default '',
  `name` varchar(50) NOT NULL default '',
  `regdate` date NOT NULL default '0000-00-00',
  `password` BLOB NOT NULL,
  `gid` smallint(4) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL auto_increment,
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `phone` varchar(16) NOT NULL default '',
  `web_options` text NOT NULL,
  `email` varchar(35) NOT NULL default '',
  `comments` text NOT NULL,
  `domain_id` smallint(6) unsigned not null default '0',
  `min_search_chars` tinyint(2) unsigned NOT NULL DEFAULT '0',
  `max_rows` smallint(6) unsigned NOT NULL DEFAULT '0',
  `address` VARCHAR(60) NOT NULL DEFAULT '',
  `cell_phone` varchar(20) NOT NULL DEFAULT '',
  `pasport_num` varchar(16) NOT NULL default '',
  `pasport_date` date NOT NULL default '0000-00-00',
  `pasport_grant` varchar(100) NOT NULL default '',
  `inn` varchar(20) NOT NULL default '',
  `birthday` DATE NOT NULL default '0000-00-00',
  PRIMARY KEY  (`aid`),
  UNIQUE KEY `aid` (`aid`),
  UNIQUE KEY `id` (`id`)
);

CREATE TABLE `admins_allow_ips` (
  `aid` smallint(6) unsigned NOT NULL default 0,
  `ip` int(11) unsigned NOT NULL default 0,
   UNIQUE KEY `aid` (`aid`, `ip`)
) ;


CREATE TABLE `admins_groups` (
  `gid` smallint(6) unsigned NOT NULL default '0',
  `aid` smallint(5) unsigned NOT NULL default '0',
  KEY `gid` (`gid`,`aid`)
);


CREATE TABLE `bills` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `deposit` double(15,6) NOT NULL default '0.000000',
  `uid` int(11) unsigned NOT NULL default '0',
  `company_id` int(11) unsigned NOT NULL default '0',
  `registration` date NOT NULL default '0000-00-00',
  PRIMARY KEY  (`id`),
  KEY `uid` (`uid`,`company_id`)
) ;


CREATE TABLE `domains` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(30) NOT NULL DEFAULT '',
  `comments` TEXT NOT NULL,
  `created` DATE NOT NULL,
  `state` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Domains List';


CREATE TABLE `dv_calls` (
  `status` int(3) NOT NULL default '0',
  `user_name` varchar(32) NOT NULL default '',
  `started` datetime NOT NULL default '0000-00-00 00:00:00',
  `nas_ip_address` int(11) unsigned NOT NULL default '0',
  `nas_port_id` int(6) unsigned NOT NULL default '0',
  `acct_session_id` varchar(25) NOT NULL default '',
  `acct_session_time` int(11) unsigned NOT NULL default '0',
  `acct_input_octets` bigint(14) unsigned NOT NULL default '0',
  `acct_output_octets` bigint(14) unsigned NOT NULL default '0',
  `ex_input_octets` bigint(14) unsigned NOT NULL default '0',
  `ex_output_octets` bigint(14) unsigned NOT NULL default '0',
  `connect_term_reason` int(4) unsigned NOT NULL default '0',
  `framed_ip_address` int(11) unsigned NOT NULL default '0',
  `lupdated` int(11) unsigned NOT NULL default '0',
  `sum` double(14,6) NOT NULL default '0.000000',
  `CID` varchar(18) NOT NULL default '',
  `CONNECT_INFO` varchar(30) NOT NULL default '',
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `nas_id` smallint(6) unsigned NOT NULL default '0',
  `acct_input_gigawords` smallint(4) unsigned NOT NULL default '0',
  `acct_output_gigawords` smallint(4) unsigned NOT NULL default '0',
  `ex_input_octets_gigawords` smallint(4) unsigned NOT NULL default '0',
  `ex_output_octets_gigawords` smallint(4) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `join_service` int(11) unsigned NOT NULL default '0',
  `turbo_mode` varchar(30) NOT NULL default '',
  `guest` tinyint(1) unsigned NOT NULL default '0',
  KEY `user_name` (`user_name`),
  KEY `acct_session_id` (`acct_session_id`),
  KEY `uid` (`uid`)
);


CREATE TABLE `dv_log_intervals` (
  `interval_id` smallint(6) unsigned NOT NULL default '0',
  `sent` int(11) unsigned NOT NULL default '0',
  `recv` int(11) unsigned NOT NULL default '0',
  `duration` int(11) unsigned NOT NULL default '0',
  `traffic_type` tinyint(4) unsigned NOT NULL default '0',
  `sum` double(14,6) unsigned NOT NULL default '0.000000',
  `acct_session_id` varchar(25) NOT NULL default '',
  `added` timestamp NOT NULL,
  KEY `acct_session_id` (`acct_session_id`),
  KEY `session_interval` (`acct_session_id`,`interval_id`)
) ;


CREATE TABLE `errors_log` (
  `date` datetime NOT NULL,
  `log_type` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `action` varchar(10) NOT NULL,
  `user` varchar(20) NOT NULL,
  `message` varchar(120) NOT NULL,
  `nas_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  KEY `user` (`user`),
  KEY `date` (`date`),
  KEY `log_type` (`log_type`)
) COMMENT='Error log';

CREATE TABLE `companies` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(100) NOT NULL default '',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `tax_number` varchar(250) NOT NULL default '',
  `bank_account` varchar(250) default NULL,
  `bank_name` varchar(150) default NULL,
  `cor_bank_account` varchar(150) default NULL,
  `bank_bic` varchar(100) default NULL,
  `registration` date NOT NULL default '0000-00-00',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `credit` double(8,2) NOT NULL default '0.00',
  `credit_date` date NOT NULL default '0000-00-00',
  `address` varchar(100) NOT NULL default '',
  `phone` varchar(20) NOT NULL default '',
  `vat` double(5,2) unsigned NOT NULL default '0.00',
  `contract_id` varchar(10) NOT NULL default '',
  `contract_date` date NOT NULL default '0000-00-00',
  `ext_bill_id` int(10) unsigned NOT NULL DEFAULT '0',
  `domain_id` smallint(6) unsigned not null default 0,
  `representative` VARCHAR(120) NOT NULL DEFAULT '',
  `contract_sufix` VARCHAR(5) NOT NULL DEFAULT '',
  PRIMARY KEY  (`id`),
  KEY `bill_id` (`bill_id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`domain_id`, `name`)
) COMMENT='Companies';


CREATE TABLE `companie_admins` (
  `company_id` int(10) unsigned NOT NULL DEFAULT '0',
  `uid` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`company_id`,`uid`)
) COMMENT='Companie Super Users';

CREATE TABLE `config` (
  `param` varchar(30) NOT NULL default '',
  `value` varchar(200) NOT NULL default '',
  `domain_id` smallint(6) unsigned not null default '0',
  UNIQUE KEY `param` (`domain_id`, `param`)
) COMMENT='System config' ;

CREATE TABLE `docs_acct` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `date` date NOT NULL default '0000-00-00',
  `created` datetime NOT NULL default '0000-00-00 00:00:00',
  `customer` varchar(200) NOT NULL default '',
  `phone` varchar(16) NOT NULL default '0',
  `user` varchar(20) NOT NULL default '',
  `acct_id` int(10) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `vat` double(5,2) unsigned NOT NULL default '0.00',
  `domain_id` smallint(6) unsigned not null default 0, 
  `payment_id` int(11) unsigned NOT NULL default 0,
  `deposit` double(15,6) NOT NULL default '0.000000',
  `delivery_status` tinyint(2) unsigned NOT NULL default '0',
  `exchange_rate` double(12,4) NOT NULL default '0.0000',
  `currency` smallint unsigned  NOT NULL default 0,  
  PRIMARY KEY  (`id`),
  KEY `payment_id` (`payment_id`),
  KEY `domain_id` (`domain_id`)
) COMMENT='Docs Accounts'  ;

CREATE TABLE `docs_acct_orders` (
  `acct_id` int(11) unsigned NOT NULL default '0',
  `orders` varchar(200) NOT NULL default '',
  `counts` int(10) unsigned NOT NULL default '0',
  `unit` tinyint(3) unsigned NOT NULL default '0',
  `price` double(10,2) unsigned NOT NULL default '0.00',
  `fees_id` int(11) unsigned NOT NULL default 0,
  KEY `aid` (`acct_id`)
)  COMMENT='Docs Accounts Orders' ;

CREATE TABLE `docs_acts` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL DEFAULT '0000-00-00',
  `created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `act_id` int(10) unsigned NOT NULL DEFAULT '0',
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `aid` smallint(6) unsigned NOT NULL DEFAULT '0',
  `vat` double(5,2) unsigned NOT NULL DEFAULT '0.00',
  `company_id` int(11) unsigned NOT NULL DEFAULT '0',
  `domain_id` smallint(6) unsigned not null default 0,
  `sum` double(10,2) unsigned NOT NULL default '0.00',
  PRIMARY KEY (`id`),
  UNIQUE KEY `date` (`date`,`company_id`),
  KEY `domain_id` (`domain_id`)
) COMMENT='Docs Acts';



CREATE TABLE `docs_invoice` (
  `id` int(11) NOT NULL auto_increment,
  `date` date NOT NULL default '0000-00-00',
  `customer` varchar(200) NOT NULL default '',
  `phone` varchar(16) NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `created` datetime NOT NULL default '0000-00-00 00:00:00',
  `invoice_id` int(10) unsigned NOT NULL default '0',
  `vat` double(5,2) unsigned NOT NULL default '0.00',
  `by_proxy_seria` varchar(40) NOT NULL default '',
  `by_proxy_person` varchar(15) NOT NULL default '',
  `by_proxy_date` date NOT NULL default '0000-00-00',
  `domain_id` smallint(6) unsigned not null default 0,
  `payment_id` int(11) unsigned NOT NULL default 0,
  `deposit` double(15,6) NOT NULL default '0.000000',
  `delivery_status` tinyint(2) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `payment_id` (`payment_id`),
  KEY `domain_id` (`domain_id`)
)  COMMENT='Docs invoices';

CREATE TABLE `docs_invoice_orders` (
  `invoice_id` int(11) unsigned NOT NULL default '0',
  `orders` varchar(200) NOT NULL default '',
  `counts` int(10) unsigned NOT NULL default '0',
  `unit` tinyint(3) unsigned NOT NULL default '0',
  `price` double(10,2) unsigned NOT NULL default '0.00',
  `fees_id` int(11) unsigned NOT NULL default 0,
  KEY `invoice_id` (`invoice_id`)
) COMMENT='Docs invoices orders';

CREATE TABLE `docs_main` (
  `uid` int(11) unsigned NOT NULL default '0' PRIMARY KEY,
  `send_docs` tinyint(1) unsigned NOT NULL default '0',
  `personal_delivery` tinyint(1) unsigned NOT NULL default '0',
  `invoicing_period` tinyint(3) unsigned NOT NULL default '0',
  `periodic_create_docs` tinyint(1) unsigned NOT NULL default '0',
  `email` varchar(200) NOT NULL default '',
  `comments` text not null
) COMMENT='Docs users settings';


CREATE TABLE `docs_tax_invoices` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `date` date NOT NULL DEFAULT '0000-00-00',
  `created` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `tax_invoice_id` int(10) unsigned NOT NULL DEFAULT '0',
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `aid` smallint(6) unsigned NOT NULL DEFAULT '0',
  `vat` double(5,2) unsigned NOT NULL DEFAULT '0.00',
  `company_id` int(11) unsigned NOT NULL DEFAULT '0',
  `domain_id` smallint(6) unsigned not null default 0,
  `account_id` int(11) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `date` (`date`,`company_id`),
  KEY `domain_id` (`domain_id`)
) COMMENT='Docs Tax Invoices';

CREATE TABLE `docs_tax_invoice_orders` (
  `tax_invoice_id` int(11) unsigned NOT NULL default '0',
  `orders` varchar(200) NOT NULL default '',
  `counts` int(10) unsigned NOT NULL default '0',
  `unit` tinyint(3) unsigned NOT NULL default '0',
  `price` double(10,2) unsigned NOT NULL default '0.00',
  KEY `aid` (`tax_invoice_id`)
) COMMENT='Docs Tax Invoices Orders' ;

CREATE TABLE `dv_main` (
  `uid` int(11) unsigned NOT NULL auto_increment,
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `logins` tinyint(3) unsigned NOT NULL default '0',
  `registration` date default '0000-00-00',
  `ip` int(10) unsigned NOT NULL default '0',
  `filter_id` varchar(150) NOT NULL default '',
  `speed` int(10) unsigned NOT NULL default '0',
  `netmask` int(10) unsigned NOT NULL default '4294967294',
  `cid` varchar(35) NOT NULL default '',
  `password` BLOB NOT NULL,
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `callback` tinyint(1) unsigned NOT NULL default '0',
  `port` int(11) unsigned NOT NULL default '0',
  `join_service` int(11) unsigned NOT NULL DEFAULT '0',
  `turbo_mode` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`uid`),
  KEY `tp_id` (`tp_id`),
  KEY CID (CID)
) COMMENT='Dv accounts' ;

CREATE TABLE `exchange_rate` (
  `money` varchar(30) NOT NULL default '',
  `short_name` varchar(30) NOT NULL default '',
  `iso` smallint unsigned  NOT NULL default 0,
  `rate` double(12,4) NOT NULL default '0.0000',
  `changed` date NOT NULL default '0000-00-00',
  `id` smallint(6) unsigned NOT NULL auto_increment,
  UNIQUE KEY `money` (`money`),
  UNIQUE KEY `short_name` (`short_name`),
  UNIQUE KEY `id` (`id`)
) COMMENT='Exchange rate';


CREATE TABLE `exchange_rate_log` (
  `date` datetime NOT NULL default '0000-00-00 00:00:00',
  `exchange_rate_id` smallint unsigned  NOT NULL default 0,
  `rate` double(12,4) NOT NULL default '0.0000',
  `id`  int(10) unsigned NOT NULL auto_increment primary key,
  KEY `date` (`date`) 
) COMMENT='Exchange rate log';


CREATE TABLE `fees` (
  `date` datetime NOT NULL default '0000-00-00 00:00:00',
  `sum` double(12,2) NOT NULL default '0.00',
  `dsc` varchar(80) NOT NULL default '',
  `ip` int(11) unsigned NOT NULL default '0',
  `last_deposit` double(15,6) NOT NULL default '0.000000',
  `uid` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  `bill_id` int(11) unsigned NOT NULL default '0',
  `vat` double(5,2) unsigned NOT NULL default '0.00',
  `inner_describe` VARCHAR( 80 ) NOT NULL default '',
  `method` tinyint(4) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `date` (`date`),
  KEY `uid` (`uid`)
) ;

CREATE TABLE `filters` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `filter` varchar(100) NOT NULL default '',
  `descr` varchar(200) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `filter` (`filter`)
)  ;

CREATE TABLE `groups` (
  `gid` smallint(4) unsigned NOT NULL default '0',
  `name` varchar(30) NOT NULL default '',
  `descr` varchar(200) NOT NULL default '',
  `domain_id` smallint(6) unsigned not null default 0,
  `separate_docs` tinyint(1) unsigned not null default 0,
  PRIMARY KEY  (`gid`),
  UNIQUE KEY `name` (`domain_id`, `name`)
) ;


CREATE TABLE `holidays` (
  `day` varchar(5) NOT NULL default '',
  `descr` varchar(100) NOT NULL default '',
  PRIMARY KEY  (`day`)
) ;

CREATE TABLE `intervals` (
  `tp_id` smallint(6) unsigned NOT NULL default '0',
  `begin` time NOT NULL default '00:00:00',
  `end` time NOT NULL default '00:00:00',
  `tarif` varchar(7) NOT NULL default '0',
  `day` tinyint(4) unsigned default '0',
  `id` smallint(6) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `tp_intervals` (`tp_id`,`begin`,`day`)
)  ;

CREATE TABLE `ippools` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `nas` smallint(5) unsigned NOT NULL default '0',
  `ip` int(10) unsigned NOT NULL default '0',
  `counts` int(10) unsigned NOT NULL default '0',
  `name` varchar(25) NOT NULL,
  `priority` tinyint(4) NOT NULL DEFAULT '0',
  `static` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `speed` int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `nas` (`nas`,`ip`)
)  ;

CREATE TABLE `dv_log` (
  `start` datetime NOT NULL default '0000-00-00 00:00:00',
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `duration` int(11) NOT NULL default '0',
  `sent` int(10) unsigned NOT NULL default '0',
  `recv` int(10) unsigned NOT NULL default '0',
  `minp` double(10,2) unsigned NOT NULL default '0.00',
  `kb` double(10,2) unsigned NOT NULL default '0.00',
  `sum` double(14,6) NOT NULL default '0.000000',
  `port_id` smallint(5) unsigned NOT NULL default '0',
  `nas_id` tinyint(3) unsigned NOT NULL default '0',
  `ip` int(10) unsigned NOT NULL default '0',
  `sent2` int(11) unsigned NOT NULL default '0',
  `recv2` int(11) unsigned NOT NULL default '0',
  `acct_session_id` varchar(20) NOT NULL default '',
  `CID` varchar(18) NOT NULL default '',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `terminate_cause` tinyint(4) unsigned NOT NULL default '0',
  `acct_input_gigawords` smallint(4) unsigned NOT NULL default '0',
  `acct_output_gigawords` smallint(4) unsigned NOT NULL default '0',
  `ex_input_octets_gigawords` smallint(4) unsigned NOT NULL default '0',
  `ex_output_octets_gigawords` smallint(4) unsigned NOT NULL default '0',
  KEY `uid` (`uid`,`start`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `mail_access`
#

CREATE TABLE `mail_access` (
  `pattern` varchar(30) NOT NULL default '',
  `action` varchar(255) NOT NULL default '',
  `id` int(11) unsigned NOT NULL auto_increment,
  `comments` varchar(255) NOT NULL default '',
  `change_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`pattern`),
  UNIQUE KEY `id` (`id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `mail_aliases`
#

CREATE TABLE `mail_aliases` (
  `address` varchar(255) NOT NULL default '',
  `goto` text NOT NULL,
  `domain` varchar(255) NOT NULL default '',
  `create_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `change_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` tinyint(2) unsigned NOT NULL default '1',
  `id` int(11) unsigned NOT NULL auto_increment,
  `comments` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`address`),
  UNIQUE KEY `id` (`id`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `mail_boxes`
#

CREATE TABLE `mail_boxes` (
  `username` varchar(255) NOT NULL default '',
  `password` blob NOT NULL,
  `descr` varchar(255) NOT NULL default '',
  `maildir` varchar(255) NOT NULL default '',
  `create_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `change_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `mails_limit` int(11) unsigned NOT NULL default '0',
  `status` tinyint(2) unsigned NOT NULL default '0',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `antivirus` tinyint(1) unsigned NOT NULL default '1',
  `antispam` tinyint(1) unsigned NOT NULL default '1',
  `expire` date NOT NULL default '0000-00-00',
  `id` int(11) unsigned NOT NULL auto_increment,
  `domain_id` smallint(6) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `box_size` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`username`,`domain_id`),
  UNIQUE KEY `id` (`id`),
  KEY `username_antivirus` (`username`,`antivirus`),
  KEY `username_antispam` (`username`,`antispam`)
)  ;


CREATE TABLE `mail_domains` (
  `domain` varchar(255) NOT NULL default '',
  `create_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `change_date` datetime NOT NULL default '0000-00-00 00:00:00',
  `status` tinyint(2) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  `backup_mx` tinyint(1) unsigned NOT NULL default '0',
  `transport` varchar(128) NOT NULL default '',
  `comments` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`domain`),
  UNIQUE KEY `id` (`id`)
) ;

CREATE TABLE `msgs_admins` (
  `aid` smallint(6) unsigned NOT NULL default '0',
  `chapter_id` int(11) unsigned NOT NULL default '0',
  `priority` tinyint(4) unsigned NOT NULL default '0',
  `email_notify` tinyint(4) unsigned NOT NULL default '0',
  `deligation_level` tinyint(4) unsigned NOT NULL default '0',
  UNIQUE KEY `aid` (`aid`,`chapter_id`)
) COMMENT='Msgs admins';

CREATE TABLE `msgs_attachments` (   `id` bigint(20) unsigned NOT NULL auto_increment,
   `message_id` bigint(20) NOT NULL default '0',
   `filename` varchar(250) NOT NULL  default '',
   `content_size` varchar(30) NOT NULL default '',
   `content_type` varchar(250) NOT NULL default '',
   `content` longblob NOT NULL,
   `create_time` datetime NOT NULL default '0000-00-00 00:00:00',
   `create_by` int(11) NOT NULL default '0',
   `change_time` datetime NOT NULL default '0000-00-00 00:00:00',
   `change_by` int(11) NOT NULL default '0',
   `message_type` tinyint(2) NOT NULL default '0',
   PRIMARY KEY  (`id`),
   KEY `article_attachment_article_id` (`message_id`) 
) COMMENT='Messages Attachment table';


CREATE TABLE `msgs_chapters` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `name` varchar(20) NOT NULL default '',
  `inner_chapter` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Msgs chapters';

CREATE TABLE `msgs_dispatch` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `created` DATETIME NOT NULL,
  `plan_date` DATE NOT NULL,
  `comments` TEXT NOT NULL,
  `state` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `closed_date` DATE NOT NULL,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `resposible` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `plan_date` (`plan_date`, `state`)
) COMMENT='Msgs dispatches';

CREATE TABLE `msgs_dispatch_admins` (
  `dispatch_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0'
) COMMENT='Msgs Dispatch admins';


CREATE TABLE `msgs_messages` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `par` int(11) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `chapter` smallint(6) unsigned NOT NULL default '0',
  `message` text not null default '',
  `reply` text not null default '',
  `ip` int(11) unsigned NOT NULL default '0',
  `date` datetime NOT NULL default '0000-00-00 00:00:00',
  `state` tinyint(2) unsigned default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `subject` varchar(45) NOT NULL default '',
  `gid` smallint(4) unsigned NOT NULL default '0',
  `priority` tinyint(4) unsigned NOT NULL default '0',
  `lock_msg` tinyint(1) unsigned NOT NULL default '0',
  `closed_date` datetime NOT NULL default '0000-00-00',
  `done_date` date NOT NULL default '0000-00-00',
  `plan_date` date NOT NULL default '0000-00-00',
  `plan_time` time NOT NULL default '00:00:00', 
  `user_read` datetime NOT NULL default '0000-00-00 00:00:00',
  `admin_read` datetime NOT NULL default '0000-00-00 00:00:00',
  `resposible` smallint(6) unsigned NOT NULL default '0',
  `inner_msg` tinyint(1) unsigned NOT NULL default '0',
  `phone` VARCHAR(16) NOT NULL DEFAULT '',
  `dispatch_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `deligation` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `deligation_level` tinyint(4) unsigned NOT NULL default '0',
  `survey_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY  (`id`),
  KEY `uid` (`uid`)
) COMMENT='Msgs Messages';

CREATE TABLE `msgs_reply` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `main_msg` int(11) unsigned NOT NULL default '0',
  `text` text NOT NULL default '',
  `datetime` datetime NOT NULL default '0000-00-00 00:00:00',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `status` tinyint(4) unsigned NOT NULL default '0',
  `caption` varchar(40) NOT NULL default '',
  `ip` int(11) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `inner_msg` tinyint(1) unsigned NOT NULL default '0',
  `survey_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  run_time int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `main_msg` (`main_msg`)
) COMMENT='Msgs replies';

CREATE TABLE `msgs_unreg_requests` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `datetime` DATETIME NOT NULL,
  `received_admin` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `state` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `priority` TINYINT(2) UNSIGNED NOT NULL DEFAULT '0',
  `subject` VARCHAR(45) NOT NULL DEFAULT '',
  `chapter` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `request` TEXT  NOT NULL,
  `comments` TEXT  NOT NULL, 
  `responsible_admin` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `fio` VARCHAR(40)  NOT NULL DEFAULT '',
  `phone` BIGINT(16) UNSIGNED NOT NULL DEFAULT '0',
  `email` VARCHAR(250)  NOT NULL DEFAULT '',
  `company` VARCHAR(60) NOT NULL DEFAULT '',
  `country_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `address_street` VARCHAR(100)  NOT NULL DEFAULT '',
  `address_build` VARCHAR(10)  NOT NULL DEFAULT '',
  `address_flat` VARCHAR(10)  NOT NULL DEFAULT '',
  `location_id` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `ip` INTEGER(11) UNSIGNED NOT NULL,
  `closed_date` DATETIME NOT NULL,
  `uid` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `connection_time` DATETIME NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `datetime` (`datetime`)
) COMMENT='Msgs from unregister users';

CREATE TABLE `msgs_survey_questions` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `survey_id` smallint(6) unsigned NOT NULL DEFAULT 0,
  `num` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `question` varchar(200) NOT NULL,
  `params` varchar(250) NOT NULL,
  `comments` text NOT NULL,
  `user_comments` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `fill_default` tinyint(1) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) COMMENT 'Messages Survey questions';

CREATE TABLE `msgs_survey_subjects` (
  `id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(60) NOT NULL,
  `comments` text NOT NULL,
  `aid` smallint(6) unsigned NOT NULL DEFAULT '0',
  `created` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT 'Messages Survey Subjects';


CREATE TABLE `msgs_survey_answers` (
  `question_id` int(11) unsigned NOT NULL DEFAULT '0',
  `uid` int(11) unsigned NOT NULL DEFAULT '0',
  `answer` tinyint(4) unsigned NOT NULL DEFAULT '0',
  `comments` text NOT NULL,
  `date_time` datetime NOT NULL,
  `survey_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `msg_id` int(11) unsigned NOT NULL DEFAULT '0',
  `reply_id` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`uid`, `msg_id`, `reply_id`, `question_id`)
) COMMENT 'Messages Survey Answers';


CREATE TABLE `nas` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `name` varchar(30) default NULL,
  `nas_identifier` varchar(20) NOT NULL default '',
  `descr` varchar(250) default NULL,
  `ip` varchar(15) default NULL,
  `nas_type` varchar(20) default NULL,
  `auth_type` tinyint(3) unsigned NOT NULL default '0',
  `mng_host_port` varchar(21) default NULL,
  `mng_user` varchar(20) default NULL,
  `mng_password` blob NOT NULL,
  `rad_pairs` text NOT NULL,
  `alive` smallint(6) unsigned NOT NULL default '0',
  `disable` tinyint(6) unsigned NOT NULL default '0',
  `ext_acct` tinyint(1) unsigned NOT NULL, 
  `domain_id` smallint(6) unsigned not null default 0,
  `address_street` varchar(100) NOT NULL default '',
  `address_build` varchar(10) NOT NULL default '',
  `address_flat` varchar(10) NOT NULL default '',
  `zip` varchar(7) NOT NULL default '',
  `city` varchar(20) NOT NULL default '',
  `country` tinyint(6) unsigned NOT NULL default '0',
  `gid` smallint(6) unsigned NOT NULL default 0,
  `mac` varchar(17) NOT NULL default '',
  `changed` datetime NOT NULL default '0000-00-00 00:00:00',
  `location_id` INTEGER(11) UNSIGNED NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `domain_id` (`domain_id`, `ip`, `nas_identifier`)
) COMMENT='Nas servers list';

CREATE TABLE `nas_groups` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(40) NOT NULL default '',
  `comments` text not null,
  `disable` tinyint(6) unsigned NOT NULL default '0',
  `domain_id` smallint(6) unsigned not null default 0,
  `default` TINYINT(1) UNSIGNED NOT NULL DEFAULT '0',
  `main_page` VARCHAR(120) NOT NULL DEFAULT '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `domain_id` (`domain_id`,`name`)
) COMMENT='NAS servers groups'; 

CREATE TABLE `nas_ippools` (
  `pool_id` int(10) unsigned NOT NULL default 0,
  `nas_id` smallint(5) unsigned NOT NULL default '0',
  UNIQUE KEY `nas` (`nas_id`,`pool_id`)
) COMMENT='NAS IP Pools';


CREATE TABLE `netflow_address` (
  `client_ip` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`client_ip`),
  UNIQUE KEY `client_ip` (`client_ip`)
) ;

# --------------------------------------------------------

#
# Структура таблиці `networks`
#

CREATE TABLE `networks` (
  `ip` int(11) unsigned NOT NULL default '0',
  `netmask` int(11) unsigned NOT NULL default '0',
  `domainname` varchar(50) NOT NULL default '',
  `hostname` varchar(20) NOT NULL default '',
  `descr` text NOT NULL,
  `changed` datetime NOT NULL default '0000-00-00 00:00:00',
  `type` tinyint(3) unsigned NOT NULL default '0',
  `mac` varchar(18) NOT NULL default '',
  `id` int(11) unsigned NOT NULL auto_increment,
  `status` tinyint(2) unsigned NOT NULL default '0',
  `web_control` varchar(21) NOT NULL default '',
  PRIMARY KEY  (`ip`,`netmask`),
  UNIQUE KEY `id` (`id`)
)  ;


CREATE TABLE `payments` (
  `date` datetime NOT NULL default '0000-00-00 00:00:00',
  `sum` double(10,2) NOT NULL default '0.00',
  `dsc` varchar(80) default NULL,
  `ip` int(11) unsigned NOT NULL default '0',
  `last_deposit` double(15,6) NOT NULL default '0.000000',
  `uid` int(11) unsigned NOT NULL default '0',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  `method` tinyint(4) unsigned NOT NULL default '0',
  `ext_id` varchar(28) NOT NULL default '',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `inner_describe` varchar(80) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `date` (`date`),
  KEY `uid` (`uid`)
) COMMENT "Payments log"  ;


CREATE TABLE fees_types (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `sum` double(10,2) NOT NULL default '0.00',
  `name` varchar(16) NOT NULL default '',
  `default_describe` varchar(80) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Payments types';


CREATE TABLE `s_detail` (
  `acct_session_id` varchar(25) NOT NULL default '',
  `nas_id` smallint(5) unsigned NOT NULL default '0',
  `acct_status` tinyint(2) unsigned NOT NULL default '0',
  `start` datetime default NULL,
  `last_update` int(11) unsigned NOT NULL default '0',
  `sent1` bigint unsigned NOT NULL default '0',
  `recv1` bigint unsigned NOT NULL default '0',
  `sent2` bigint unsigned NOT NULL default '0',
  `recv2` bigint unsigned NOT NULL default '0',
  `id` varchar(16) NOT NULL default '',
  `sum` double(14,6) NOT NULL default '0.000000',
  KEY `sid` (`acct_session_id`)
) ;


CREATE TABLE `shedule` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `uid` int(11) unsigned NOT NULL default '0',
  `date` date NOT NULL default '0000-00-00',
  `type` varchar(50) NOT NULL default '',
  `action` varchar(250) NOT NULL default '',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `counts` tinyint(4) unsigned NOT NULL default '0',
  `d` char(2) NOT NULL default '*',
  `m` char(2) NOT NULL default '*',
  `y` varchar(4) NOT NULL default '*',
  `h` char(2) NOT NULL default '*',
  `module` varchar(12) NOT NULL default '',
  `comments` varchar(120) NOT NULL default '', 
  `admin_action` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `uniq_action` (`h`,`d`,`m`,`y`,`type`,`uid`),
  KEY `date_type_uid` (`date`,`type`,`uid`)
) COMMENT='Shedules';

CREATE TABLE `tarif_plans` (
  `id` smallint(5) unsigned NOT NULL default '0',
  `month_fee` double(14,2) unsigned NOT NULL default '0.00',
  `uplimit` double(14,2) NOT NULL default '0.00',
  `name` varchar(40) NOT NULL default '',
  `day_fee` double(14,2) unsigned NOT NULL default '0.00',
  `active_day_fee` tinyint(1) unsigned NOT NULL default '0',
  `logins` tinyint(4) NOT NULL default '0',
  `day_time_limit` int(10) unsigned NOT NULL default '0',
  `week_time_limit` int(10) unsigned NOT NULL default '0',
  `month_time_limit` int(10) unsigned NOT NULL default '0',
  `day_traf_limit` int(10) unsigned NOT NULL default '0',
  `week_traf_limit` int(10) unsigned NOT NULL default '0',
  `month_traf_limit` int(10) unsigned NOT NULL default '0',
  `prepaid_trafic` int(10) unsigned NOT NULL default '0',
  `change_price` double(14,2) unsigned NOT NULL default '0.00',
  `activate_price` double(14,2) unsigned NOT NULL default '0.00',
  `credit_tresshold` double(8,2) unsigned NOT NULL default '0.00',
  `age` smallint(6) unsigned NOT NULL default '0',
  `octets_direction` tinyint(2) unsigned NOT NULL default '0',
  `max_session_duration` mediumint unsigned NOT NULL default '0',
  `filter_id` varchar(15) NOT NULL default '',
  `payment_type` tinyint(1) NOT NULL default '0',
  `min_session_cost` double(14,5) unsigned NOT NULL default '0.00000',
  `rad_pairs` text NOT NULL,
  `reduction_fee` tinyint(1) unsigned NOT NULL default '0',
  `postpaid_daily_fee` tinyint(1) unsigned NOT NULL default '0',
  `postpaid_monthly_fee` tinyint(1) unsigned NOT NULL default '0',
  `module` varchar(12) NOT NULL default '',
  `traffic_transfer_period` tinyint(4) unsigned NOT NULL default '0',
  `gid` smallint(6) unsigned NOT NULL default '0',
  `neg_deposit_filter_id` varchar(150) NOT NULL default '',
  `tp_id` int(11) unsigned NOT NULL auto_increment,
  `ext_bill_account` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `credit` double(10,2) unsigned NOT NULL DEFAULT '0.00',
  `ippool` smallint(6) unsigned NOT NULL DEFAULT '0',
  `period_alignment` tinyint(1) NOT NULL DEFAULT '0',
  `min_use` double(14,2) unsigned NOT NULL DEFAULT '0.00',
  `abon_distribution` tinyint(1) NOT NULL DEFAULT '0',
  `small_deposit_action` smallint(6) NOT NULL default '0',
  `domain_id` smallint(6) unsigned not null default 0,
  `total_time_limit` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `total_traf_limit` INTEGER(11) UNSIGNED NOT NULL DEFAULT '0',
  `priority` smallint(5) unsigned NOT NULL DEFAULT '0',
  `comments` text not null default '',
  `bills_priority` tinyint(5) unsigned NOT NULL DEFAULT '0',
  `fine` double(14,2) unsigned NOT NULL default '0.00',
  `neg_deposit_ippool` smallint(6) unsigned NOT NULL DEFAULT '0',
  `next_tp_id` smallint(6) unsigned NOT NULL DEFAULT '0',
  `fees_method` tinyint(4) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY  (`id`,`module`, `domain_id`),
  UNIQUE KEY `tp_id` (`tp_id`),
  KEY `name` (`name`, `domain_id`)
) COMMENT='Tarif plans';


CREATE TABLE `tp_bonus_rating` (
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `rating_from` int(11) unsigned NOT NULL default '0',
  `rating_to` int(11) unsigned NOT NULL default '0',
  `action` smallint(5) unsigned NOT NULL default '0',
  `change_bonus` double(14,2) unsigned NOT NULL default '0.00',
  `activate_bonus` double(14,2) unsigned NOT NULL default '0.00',
  `ext_bill_account` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `comments` text NOT NULL default '',
  PRIMARY KEY  (`tp_id`)
) COMMENT='Tarif plans bonus rating';


CREATE TABLE `tp_groups` (
  `id` smallint(6) unsigned NOT NULL auto_increment,
  `name` varchar(20) NOT NULL default '',
  `user_chg_tp` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Tarif Plans Groups';

# --------------------------------------------------------
#
# Структура таблиці `tp_nas`
#

CREATE TABLE `tp_nas` (
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `nas_id` smallint(5) unsigned NOT NULL default '0',
  KEY `vid` (`tp_id`)
) ;

CREATE TABLE `trafic_tarifs` (
  `id` tinyint(4) NOT NULL default '0',
  `descr` varchar(30) default NULL,
  `net_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `nets` text,
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `prepaid` int(11) unsigned default '0',
  `in_price` double(13,5) unsigned NOT NULL default '0.00000',
  `out_price` double(13,5) unsigned NOT NULL default '0.00000',
  `in_speed` int(10) unsigned NOT NULL default '0',
  `interval_id` smallint(6) unsigned NOT NULL default '0',
  `rad_pairs` text NOT NULL,
  `out_speed` int(10) unsigned NOT NULL default '0',
  `expression` varchar(255) NOT NULL default '',
  UNIQUE KEY `id` (`id`,`interval_id`)
) ;

CREATE TABLE `traffic_classes` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(25) NOT NULL DEFAULT '',
  `nets` TEXT,
  `comments` TEXT NOT NULL,
  `changed` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`)
) COMMENT='Traffic Classes';

INSERT INTO traffic_classes (name, nets) VALUES ('Global', '0.0.0.0/0');



CREATE TABLE `users` (
  `id` varchar(20) NOT NULL default '',
  `activate` date NOT NULL default '0000-00-00',
  `expire` date NOT NULL default '0000-00-00',
  `credit` double(10,2) NOT NULL default '0.00',
  `reduction` double(6,2) NOT NULL default '0.00',
  `reduction_date` date not null default '0000-00-00',
  `registration` date default '0000-00-00',
  `password` blob NOT NULL,
  `uid` int(11) unsigned NOT NULL auto_increment,
  `gid` smallint(6) unsigned NOT NULL default '0',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `company_id` int(11) unsigned NOT NULL default '0',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `ext_bill_id` int(10) unsigned NOT NULL DEFAULT '0',
  `credit_date` date default '0000-00-00',
  `domain_id` smallint(6) unsigned not null default 0,
  `deleted` tinyint(1) unsigned NOT NULL default '0',
  PRIMARY KEY  (`uid`),
  UNIQUE KEY `id` (domain_id, id),
  KEY `bill_id` (`bill_id`), 
  KEY `company_id` (`company_id`)
) COMMENT='Users list';


CREATE TABLE `web_users_sessions` (
  `uid` int(11) unsigned NOT NULL default '0',
  `datetime` int(11) unsigned NOT NULL default '0',
  `login` varchar(20) NOT NULL default '',
  `remote_addr` int(11) unsigned NOT NULL default '0',
  `sid` varchar(32) NOT NULL default '',
  `ext_info` varchar(200) NOT NULL default '',
  PRIMARY KEY  (`sid`),
  UNIQUE KEY `sid` (`sid`)
) COMMENT='User Web Sessions';


CREATE TABLE `users_bruteforce` (
  `login` varchar(20) NOT NULL default '',
  `password` blob NOT NULL,
  `datetime` datetime NOT NULL default '0000-00-00 00:00:00',
  `ip` int(11) unsigned NOT NULL default '0',
  `auth_state` tinyint(1) unsigned NOT NULL default '0',
  KEY `login` (`login`)
);


CREATE TABLE `users_nas` (
  `uid` int(10) unsigned NOT NULL default '0',
  `nas_id` smallint(5) unsigned NOT NULL default '0',
  KEY `uid` (`uid`)
) ;


CREATE TABLE `users_pi` (
  `uid` int(11) unsigned NOT NULL auto_increment,
  `fio` varchar(60) NOT NULL default '',
  `phone` varchar(16) NOT NULL default '',
  `email` varchar(250) NOT NULL default '',
  `country_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `address_street` varchar(100) NOT NULL default '',
  `address_build` varchar(10) NOT NULL default '',
  `address_flat` varchar(10) NOT NULL default '',
  `comments` text NOT NULL,
  `contract_id` varchar(10) NOT NULL default '',
  `contract_date` date NOT NULL,
  `contract_sufix` VARCHAR(5) NOT NULL DEFAULT '',
  `pasport_num` varchar(16) NOT NULL default '',
  `pasport_date` date NOT NULL default '0000-00-00',
  `pasport_grant` varchar(100) NOT NULL default '',
  `zip` varchar(7) NOT NULL default '',
  `city` varchar(20) NOT NULL default '',
  `accept_rules` tinyint(1) unsigned NOT NULL default '0',
  `location_id` INTEGER(11) UNSIGNED NOT NULL default '0',
  PRIMARY KEY  (`uid`)
) COMMENT='Users personal info';


CREATE TABLE `voip_calls` (
  `status` tinyint(4) unsigned NOT NULL default '0',
  `user_name` varchar(32) NOT NULL default '',
  `acct_session_id` varchar(25) NOT NULL default '',
  `calling_station_id` varchar(32) NOT NULL default '',
  `called_station_id` varchar(32) NOT NULL default '',
  `lupdated` int(11) unsigned NOT NULL default '0',
  `started` datetime NOT NULL default '0000-00-00 00:00:00',
  `nas_id` smallint(6) unsigned NOT NULL default '0',
  `client_ip_address` int(11) unsigned NOT NULL default '0',
  `conf_id` varchar(64) NOT NULL default '',
  `call_origin` tinyint(1) unsigned NOT NULL default '0',
  `uid` int(11) unsigned NOT NULL default '0',
  `tp_id` smallint(5) unsigned NOT NULL default '0',
  `route_id` int(11) unsigned NOT NULL default '0',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `reduction` double(6,2) unsigned NOT NULL default '0.00',
   KEY `tp_id` (`tp_id`),
  KEY `uid` (`uid`)
) ;


CREATE TABLE `voip_log` (
  `uid` int(11) unsigned NOT NULL default '0',
  `start` datetime NOT NULL default '0000-00-00 00:00:00',
  `duration` int(11) unsigned NOT NULL default '0',
  `calling_station_id` varchar(16) NOT NULL default '',
  `called_station_id` varchar(16) NOT NULL default '',
  `nas_id` smallint(6) NOT NULL default '0',
  `client_ip_address` int(11) unsigned NOT NULL default '0',
  `acct_session_id` varchar(25) NOT NULL default '',
  `tp_id` smallint(6) unsigned NOT NULL default '0',
  `bill_id` int(11) unsigned NOT NULL default '0',
  `sum` double(14,6) NOT NULL default '0.000000',
  `route_id` int(11) unsigned NOT NULL default '0',
  `terminate_cause` tinyint(4) unsigned NOT NULL default '0',
  `call_origin` tinyint(1) unsigned NOT NULL default '0',
  KEY `uid` (`uid`) 
) ;

CREATE TABLE `voip_main` (
  `uid` int(11) unsigned NOT NULL default '0',
  `tp_id` smallint(6) unsigned NOT NULL default '0',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `number` varchar(16) NOT NULL default '',
  `registration` date NOT NULL default '0000-00-00',
  `ip` int(11) unsigned NOT NULL default '0',
  `cid` varchar(35) NOT NULL default '',
  `allow_answer` tinyint(1) unsigned NOT NULL default '1',
  `allow_calls` tinyint(1) unsigned NOT NULL default '1',
  `logins` tinyint(3) unsigned NOT NULL default '0',
  `provision_nas_id` smallint(6) unsigned NOT NULL default '0',
  `provision_port` smallint(6) unsigned NOT NULL default '0',
  PRIMARY KEY (`number`),
  KEY `uid` (`uid`)
) ;

CREATE TABLE `voip_route_extra_tarification` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(32) not null default '',
  `date` date NOT NULL default '0000-00-00',
  `prepaid_time` INT UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE(`name`)
) COMMENT "Voip extra tarification" ;

CREATE TABLE `voip_route_groups` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(32) not null default '',
  PRIMARY KEY (`id`)
) COMMENT "Voip route groups" ;


CREATE TABLE `voip_route_prices` (
  `route_id` int(11) unsigned NOT NULL default '0',
  `interval_id` int(11) unsigned NOT NULL default '0',
  `price` double(15,5) unsigned NOT NULL default '0.00000',
  `unit_price` double(15,5) unsigned NOT NULL default '0.00000',
  `extra_tarification` smallint(5) unsigned NOT NULL default 0,
  `date` date NOT NULL default '0000-00-00',
  `trunk` SMALLINT UNSIGNED NOT NULL DEFAULT '0',
  UNIQUE KEY `route_id` (`route_id`,`interval_id`)
) ;


CREATE TABLE `voip_routes` (
  `prefix` varchar(14) NOT NULL default '',
  `name` varchar(20) NOT NULL default '',
  `disable` tinyint(1) unsigned NOT NULL default '0',
  `date` date NOT NULL default '0000-00-00',
  `parent` int(11) unsigned NOT NULL default '0',
  `descr` varchar(120) NOT NULL default '',
  `gateway_id` smallint(6) unsigned NOT NULL default '0',
  `id` int(11) unsigned NOT NULL auto_increment,
  `iso_codes` varchar(10) NOT NULL default '',
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `prefix` (`prefix`)
) COMMENT 'Voip routes list';


CREATE TABLE `voip_tps` (
  `id` smallint(5) unsigned NOT NULL default '0',
  `day_time_limit` int(10) unsigned NOT NULL default '0',
  `week_time_limit` int(10) unsigned NOT NULL default '0',
  `month_time_limit` int(10) unsigned NOT NULL default '0',
  `max_session_duration` smallint(6) unsigned NOT NULL default '0',
  `min_session_cost` double(15,5) unsigned NOT NULL default '0.00000',
  `rad_pairs` text NOT NULL,
  `first_period` int(10) unsigned NOT NULL default '0',
  `first_period_step` int(10) unsigned NOT NULL default '0',
  `next_period` int(10) unsigned NOT NULL default '0',
  `next_period_step` int(10) unsigned NOT NULL default '0',
  `free_time` int(10) unsigned NOT NULL default '0',
  `time_division` smallint(6) unsigned NOT NULL default '0', 
  PRIMARY KEY  (`id`),
  UNIQUE KEY `id` (`id`)
) ;



CREATE TABLE IF NOT EXISTS `voip_trunks` (
  `id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `name` char(20) NOT NULL,
  `trunkprefix` char(20) DEFAULT NULL,
  `protocol` char(10) NOT NULL,
  `provider_ip` char(80) NOT NULL,
  `removeprefix` char(20) DEFAULT NULL,
  `addprefix` char(20) DEFAULT NULL,
  `secondusedreal` smallint(5) unsigned DEFAULT '0',
  `secondusedcarrier` smallint(5) unsigned DEFAULT '0',
  `secondusedratecard` smallint(5) unsigned DEFAULT '0',
  `failover_trunk` smallint(5) unsigned NOT NULL DEFAULT '0',
  `addparameter` char(120) DEFAULT NULL,
  `provider_name` char(120) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ;


CREATE TABLE `sqlcmd_history` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `datetime` DATETIME NOT NULL,
  `aid` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '000000',
  `sql_query` TEXT NOT NULL,
  `db_id` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `comments` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  KEY `aid` (`aid`)
) COMMENT='Sqlcmd history';

CREATE TABLE `help` (
  `function` varchar(20) NOT NULL default '',
  `title` varchar(200) NOT NULL default '',
  `help` text NOT NULL,
  PRIMARY KEY  (`function`),
  UNIQUE KEY `function` (`function`)
);

CREATE TABLE `streets` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL DEFAULT '',  
  `district_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `name_district` (`name`, `district_id`),
  UNIQUE KEY `name_2` (`name`)
) COMMENT='Locations streets';


CREATE TABLE `districts` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(100) NOT NULL DEFAULT '',
  `country` TINYINT(4) UNSIGNED NOT NULL,
  `zip` VARCHAR(7) NOT NULL DEFAULT '',
  `city` VARCHAR(30) NOT NULL DEFAULT '',  
  `comments` TEXT NOT NULL,
  `coordx` DOUBLE(20,14) NOT NULL DEFAULT '0',
  `coordy` DOUBLE(20,14) NOT NULL DEFAULT '0',
  `zoom` tinyint(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `name_2` (`name`)
) COMMENT='Locations districts';

INSERT INTO districts (name) VALUES ('Main District');

CREATE TABLE `builds` (
  `id` INTEGER(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `street_id` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `number` VARCHAR(10)  NOT NULL DEFAULT '',
  `flors` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `entrances` TINYINT(4) UNSIGNED NOT NULL DEFAULT '0',
  `added` DATE NOT NULL,
  `map_x` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_y` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_x2` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_y2` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_x3` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_y3` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_x4` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `map_y4` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  `coordx` DOUBLE(20,14) NOT NULL DEFAULT '0',
  `coordy` DOUBLE(20,14) NOT NULL DEFAULT '0',
  `flats` SMALLINT(6) UNSIGNED NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`),
  UNIQUE KEY `street_id` (`street_id`, `number`)
) COMMENT='Builds';


CREATE TABLE `web_online` (
  `admin` varchar(15) NOT NULL default '',
  `ip` varchar(15) NOT NULL default '',
  `logtime` int(11) unsigned NOT NULL default '0',
  `page_index` int unsigned NOT NULL Default 0
) ;

CREATE TABLE `reg_wizard` (
  `param` varchar(40) NOT NULL default '',
  `value` text NOT NULL default '',
  `aid` smallint(6) unsigned NOT NULL default '0',
  `module` varchar(40) NOT NULL default '',
  `step` tinyint(2) NOT NULL default '0',
  `session_id` varchar(30) NOT NULL default '',
 UNIQUE KEY `session_id` (`session_id`, `step`, `param`) 
) COMMENT "Registration wizard temp table";

    


INSERT INTO admins (id, name, regdate, password, gid, aid, disable, phone, web_options) VALUES ('abills','abills',curdate(), ENCODE('abills', 'test12345678901234567890'), 0, 1,0,'', '');
INSERT INTO admins (id, name, regdate, password, gid, aid, disable, phone, web_options) VALUES ('system','System user',curdate(), ENCODE(md5(RAND()), 'test12345678901234567890'), 0, 2, 0,'', '');
INSERT INTO admins (id, name, regdate, password, gid, aid, disable, phone, web_options) VALUES ('users_web','Users web portal', curdate(), ENCODE(md5(RAND()), 'test12345678901234567890'), 0, 3, 0,'', '');
INSERT INTO `admin_permits` (`aid`, `section`, `actions`, `module`) VALUES 
  (1,0,0,''),
  (1,0,1,''),
  (1,0,2,''),
  (1,0,3,''),
  (1,0,4,''),
  (1,0,5,''),
  (1,0,6,''),
  (1,0,7,''),
  (1,0,8,''),
  (1,0,9,''),
  (1,0,10,''),
  (1,0,11,''),
  (1,1,0,''),
  (1,1,1,''),
  (1,1,2,''),
  (1,1,3,''),
  (1,2,0,''),
  (1,2,1,''),
  (1,2,2,''),
  (1,2,3,''),
  (1,3,0,''),
  (1,3,1,''),
  (1,4,0,''),
  (1,4,1,''),
  (1,4,2,''),
  (1,4,3,''),
  (1,4,4,''),
  (1,5,0,''),
  (1,6,0,''),
  (1,7,0,''),
  (1,8,0,'');


INSERT INTO `users` (`id`, `activate`, `expire`, `credit`, `reduction`, `registration`, `password`, `uid`, `gid`, `disable`, `company_id`, `bill_id`, `ext_bill_id`, `credit_date`, `domain_id`) VALUES ('test','0000-00-00','0000-00-00',0.00,0.00,'2009-08-03', ENCODE('123456','test12345678901234567890'),1,0,0,0,1,0,'0000-00-00',0);

INSERT INTO `users_pi` (uid, fio) VALUES (1,'Test user');

INSERT INTO `bills` VALUES (1,0.000000,1,0,'2009-08-03');

INSERT INTO `tarif_plans` (id, name, payment_type, module) VALUES (100,'Admin',1, 'Dv');

INSERT INTO `dv_main` VALUES (1,100,0,'2009-08-03',0,'',0,4294967295,'','',0,0,0,0,0);

INSERT INTO `admin_actions` VALUES ('LOGIN:test','2009-08-03 11:42:53',1534854767,1,1,1,'',7),('BILL_ID ->1;','2009-08-03 11:42:53',1534854767,1,1,2,'',2),('PASSWORD *->*;','2009-08-03 11:42:53',1534854767,1,1,3,'',2),('ADD PI','2009-08-03 11:42:53',1534854767,1,1,4,'',0),('ACTIVE','2009-08-03 11:42:53',1534854767,1,1,5,'Dv',1);

INSERT INTO `nas` (id, name, nas_identifier, descr, ip, nas_type, auth_type, mng_host_port, mng_user, mng_password, alive) VALUES (1,'NAS Server','','NAS Server','127.0.0.1','mpd5', 0,'127.0.0.1:5005','admin', ENCODE('secretpass','test12345678901234567890'),300);
INSERT INTO `ippools` ( id, nas, ip, counts, name, priority) VALUES (1,1,167772161,256,'Main',0);

INSERT INTO `nas_ippools` (pool_id, nas_id) VALUES (1,1);
INSERT INTO `msgs_chapters` (name) VALUES ('-');

INSERT INTO fees_types (id, name) VALUES (1, '$_ABON'), (2, '$_FINE'), (3, '$_ACTIVATE'), (4, '$_MONEY_TRANSFER'), (0, '$_ONE_TIME');
UPDATE fees_types SET id=0 where name='$_ONE_TIME';


