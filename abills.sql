-- MySQL dump 8.22
--
-- Host: localhost    Database: stats
---------------------------------------------------------
-- Server version	3.23.53-log

--
-- Table structure for table 'accounts'
--

CREATE TABLE accounts (
  id int(11) unsigned NOT NULL auto_increment,
  name varchar(100) NOT NULL default '',
  deposit double(8,6) NOT NULL default '0.000000',
  tax_number varchar(250) NOT NULL default '',
  bank_account varchar(250) default NULL,
  bank_name varchar(150) default NULL,
  cor_bank_account varchar(150) default NULL,
  bank_bic varchar(100) default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  UNIQUE KEY name (name)
) TYPE=MyISAM;

--
-- Table structure for table 'acct_orders'
--

CREATE TABLE acct_orders (
  aid int(11) NOT NULL default '0',
  orders varchar(200) NOT NULL default '',
  counts int(10) unsigned NOT NULL default '0',
  unit tinyint(3) unsigned NOT NULL default '0',
  price float(8,2) unsigned NOT NULL default '0.00',
  KEY aid (aid)
) TYPE=MyISAM;

--
-- Table structure for table 'actions'
--

CREATE TABLE actions (
  id smallint(6) unsigned NOT NULL auto_increment,
  func char(12) NOT NULL default '',
  actions char(12) default NULL,
  par_func smallint(6) unsigned NOT NULL default '0',
  descr char(250) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY func (func),
  UNIQUE KEY id (id)
) TYPE=MyISAM;

--
-- Table structure for table 'admin_permits'
--

CREATE TABLE admin_permits (
  aid smallint(6) unsigned NOT NULL default '0',
  section smallint(6) unsigned NOT NULL default '0',
  actions smallint(6) unsigned NOT NULL default '0'
) TYPE=MyISAM;

--
-- Table structure for table 'admins'
--

CREATE TABLE admins (
  id varchar(12) default NULL,
  name varchar(24) default NULL,
  regdate date default NULL,
  password varchar(16) NOT NULL default '',
  gid tinyint(4) unsigned NOT NULL default '0',
  aid smallint(6) unsigned NOT NULL auto_increment,
  permissions varchar(60) NOT NULL default '',
  PRIMARY KEY  (aid),
  UNIQUE KEY id (id),
  UNIQUE KEY aid (aid)
) TYPE=MyISAM;

--
-- Table structure for table 'bill'
--

CREATE TABLE bill (
  id varchar(20) default NULL,
  sum float(10,2) default NULL
) TYPE=MyISAM;

--
-- Table structure for table 'calls'
--

CREATE TABLE calls (
  status int(3) default NULL,
  user_name varchar(32) default NULL,
  started datetime NOT NULL default '0000-00-00 00:00:00',
  nas_ip_address int(11) unsigned NOT NULL default '0',
  nas_port_id int(6) unsigned default NULL,
  acct_session_id varchar(25) NOT NULL default '',
  acct_session_time int(11) NOT NULL default '0',
  acct_input_octets int(11) NOT NULL default '0',
  acct_output_octets int(11) NOT NULL default '0',
  ex_input_octets int(11) NOT NULL default '0',
  ex_output_octets int(11) NOT NULL default '0',
  connect_term_reason int(4) NOT NULL default '0',
  framed_ip_address int(11) unsigned NOT NULL default '0',
  lupdated int(11) unsigned NOT NULL default '0',
  sum float(6,2) NOT NULL default '0.00',
  CID varchar(18) NOT NULL default '',
  CONNECT_INFO varchar(20) NOT NULL default '',
  KEY user_name (user_name)
) TYPE=MyISAM;

--
-- Table structure for table 'config'
--

CREATE TABLE config (
  param varchar(20) NOT NULL default '',
  value varchar(200) NOT NULL default '',
  UNIQUE KEY param (param)
) TYPE=MyISAM;

--
-- Table structure for table 'docs_acct'
--

CREATE TABLE docs_acct (
  id int(11) NOT NULL auto_increment,
  date date NOT NULL default '0000-00-00',
  time time NOT NULL default '00:00:00',
  customer varchar(200) NOT NULL default '',
  phone varchar(16) NOT NULL default '0',
  maked varchar(20) NOT NULL default '',
  user varchar(20) NOT NULL default '',
  aid int(10) unsigned NOT NULL default '0',
  uid int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table 'dunes'
--

CREATE TABLE dunes (
  err_id smallint(5) unsigned NOT NULL default '0',
  win_err_handle varchar(30) NOT NULL default '',
  translate varchar(200) NOT NULL default '',
  error_text varchar(200) NOT NULL default '',
  solution text
) TYPE=MyISAM;

--
-- Table structure for table 'exchange_rate'
--

CREATE TABLE exchange_rate (
  money varchar(30) NOT NULL default '',
  short_name varchar(30) NOT NULL default '',
  rate double(8,4) NOT NULL default '0.0000',
  changed date default NULL,
  UNIQUE KEY short_name (short_name),
  UNIQUE KEY money (money)
) TYPE=MyISAM;

--
-- Table structure for table 'fees'
--

CREATE TABLE fees (
  date datetime NOT NULL default '0000-00-00 00:00:00',
  sum double(10,2) NOT NULL default '0.00',
  dsc varchar(80) default NULL,
  ww varchar(40) NOT NULL default '',
  ip int(11) unsigned NOT NULL default '0',
  last_deposit double(7,6) NOT NULL default '0.000000',
  uid int(11) unsigned NOT NULL default '0',
  aid smallint(6) unsigned NOT NULL default '0',
  id int(11) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  KEY date (date),
  KEY uid (uid)
) TYPE=MyISAM;

--
-- Table structure for table 'filters'
--

CREATE TABLE filters (
  id smallint(5) unsigned NOT NULL auto_increment,
  filter varchar(100) NOT NULL default '',
  descr varchar(200) NOT NULL default '',
  PRIMARY KEY  (id),
  UNIQUE KEY filter (filter)
) TYPE=MyISAM;

--
-- Table structure for table 'groups'
--

CREATE TABLE groups (
  gid tinyint(4) unsigned NOT NULL auto_increment,
  name varchar(12) NOT NULL default '',
  descr tinyint(4) default NULL,
  PRIMARY KEY  (gid),
  UNIQUE KEY name (name),
  UNIQUE KEY gid (gid)
) TYPE=MyISAM;

--
-- Table structure for table 'holidays'
--

CREATE TABLE holidays (
  day varchar(5) NOT NULL default '',
  descr varchar(100) NOT NULL default '',
  PRIMARY KEY  (day)
) TYPE=MyISAM;

--
-- Table structure for table 'icards'
--

CREATE TABLE icards (
  id int(10) unsigned NOT NULL auto_increment,
  prefix varchar(4) NOT NULL default '',
  nominal float(8,2) NOT NULL default '0.00',
  variant smallint(6) NOT NULL default '0',
  period smallint(5) unsigned NOT NULL default '0',
  expire date NOT NULL default '0000-00-00',
  changes float(8,2) NOT NULL default '0.00',
  password varchar(16) NOT NULL default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table 'intervals'
--

CREATE TABLE intervals (
  vid tinyint(4) unsigned NOT NULL default '0',
  begin time NOT NULL default '00:00:00',
  end time NOT NULL default '00:00:00',
  tarif varchar(7) NOT NULL default '0',
  day tinyint(4) unsigned default '0',
  UNIQUE KEY vid (vid,begin,day)
) TYPE=MyISAM;

--
-- Table structure for table 'ippools'
--

CREATE TABLE ippools (
  id int(10) unsigned NOT NULL auto_increment,
  nas smallint(5) unsigned NOT NULL default '0',
  ip int(10) unsigned NOT NULL default '0',
  counts int(10) unsigned NOT NULL default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table 'log'
--

CREATE TABLE log (
  id varchar(20) default NULL,
  login datetime NOT NULL default '0000-00-00 00:00:00',
  variant smallint(5) unsigned NOT NULL default '0',
  duration int(11) NOT NULL default '0',
  sent int(10) unsigned NOT NULL default '0',
  recv int(10) unsigned NOT NULL default '0',
  minp float(10,2) NOT NULL default '0.00',
  kb float(10,2) NOT NULL default '0.00',
  sum double(10,6) NOT NULL default '0.000000',
  port_id smallint(5) unsigned NOT NULL default '0',
  nas_id tinyint(3) unsigned NOT NULL default '0',
  ip int(10) unsigned NOT NULL default '0',
  sent2 int(11) unsigned NOT NULL default '0',
  recv2 int(11) unsigned NOT NULL default '0',
  acct_session_id varchar(25) NOT NULL default '',
  CID varchar(18) NOT NULL default '',
  KEY login (login),
  KEY id (id)
) TYPE=MyISAM;

--
-- Table structure for table 'mail_access'
--

CREATE TABLE mail_access (
  pattern varchar(30) NOT NULL default '',
  action varchar(255) NOT NULL default '',
  id int(11) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (pattern),
  UNIQUE KEY id (id)
) TYPE=MyISAM;

--
-- Table structure for table 'mail_aliases'
--

CREATE TABLE mail_aliases (
  address varchar(255) NOT NULL default '',
  goto text NOT NULL,
  domain varchar(255) NOT NULL default '',
  create_date datetime NOT NULL default '0000-00-00 00:00:00',
  change_date datetime NOT NULL default '0000-00-00 00:00:00',
  status tinyint(2) unsigned NOT NULL default '1',
  id int(11) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (address),
  UNIQUE KEY id (id)
) TYPE=MyISAM;

--
-- Table structure for table 'mail_boxes'
--

CREATE TABLE mail_boxes (
  username varchar(255) NOT NULL default '',
  password varchar(255) NOT NULL default '',
  descr varchar(255) NOT NULL default '',
  maildir varchar(255) NOT NULL default '',
  create_date datetime NOT NULL default '0000-00-00 00:00:00',
  change_date datetime NOT NULL default '0000-00-00 00:00:00',
  quota tinytext NOT NULL,
  status tinyint(2) unsigned NOT NULL default '0',
  bill_id int(11) unsigned NOT NULL default '0',
  antivirus tinyint(1) unsigned NOT NULL default '1',
  antispam tinyint(1) unsigned NOT NULL default '1',
  expire date NOT NULL default '0000-00-00',
  id int(11) unsigned NOT NULL auto_increment,
  domain varchar(60) NOT NULL default '',
  PRIMARY KEY  (username,domain),
  UNIQUE KEY id (id),
  KEY username_antivirus (username,antivirus),
  KEY username_antispam (username,antispam)
) TYPE=MyISAM;

--
-- Table structure for table 'mail_domains'
--

CREATE TABLE mail_domains (
  domain varchar(255) NOT NULL default '',
  descr varchar(255) NOT NULL default '',
  create_date datetime NOT NULL default '0000-00-00 00:00:00',
  change_date datetime NOT NULL default '0000-00-00 00:00:00',
  status tinyint(2) unsigned NOT NULL default '0',
  id int(11) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (domain),
  UNIQUE KEY id (id)
) TYPE=MyISAM;

--
-- Table structure for table 'mail_transport'
--

CREATE TABLE mail_transport (
  domain varchar(128) NOT NULL default '',
  transport varchar(128) NOT NULL default '',
  UNIQUE KEY domain (domain)
) TYPE=MyISAM;

--
-- Table structure for table 'message_types'
--

CREATE TABLE message_types (
  id int(11) NOT NULL auto_increment,
  name varchar(20) default NULL,
  PRIMARY KEY  (id),
  UNIQUE KEY name (name)
) TYPE=MyISAM;

--
-- Table structure for table 'messages'
--

CREATE TABLE messages (
  id int(11) unsigned NOT NULL auto_increment,
  par int(11) unsigned NOT NULL default '0',
  uid int(11) unsigned NOT NULL default '0',
  type smallint(6) NOT NULL default '0',
  message text,
  admin varchar(12) default NULL,
  reply text,
  ip int(11) unsigned default '0',
  date datetime NOT NULL default '0000-00-00 00:00:00',
  state tinyint(2) unsigned default '0',
  aid smallint(6) unsigned NOT NULL default '0',
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table 'nas'
--

CREATE TABLE nas (
  id smallint(5) unsigned NOT NULL auto_increment,
  name varchar(30) default NULL,
  nas_identifier varchar(20) NOT NULL default '',
  descr varchar(250) default NULL,
  ip varchar(15) default NULL,
  nas_type varchar(20) default NULL,
  auth_type tinyint(3) unsigned NOT NULL default '0',
  mng_host_port varchar(21) default NULL,
  mng_user varchar(20) default NULL,
  mng_password varchar(16) default NULL,
  rad_pairs text NOT NULL,
  PRIMARY KEY  (id)
) TYPE=MyISAM;

--
-- Table structure for table 'networks'
--

CREATE TABLE networks (
  ip int(11) unsigned NOT NULL default '0',
  netmask int(11) unsigned NOT NULL default '0',
  domainname varchar(50) NOT NULL default '',
  hostname varchar(20) NOT NULL default '',
  descr text NOT NULL,
  changed datetime NOT NULL default '0000-00-00 00:00:00',
  type tinyint(3) unsigned NOT NULL default '0',
  mac varchar(18) NOT NULL default '',
  id int(11) unsigned NOT NULL auto_increment,
  status tinyint(2) unsigned NOT NULL default '0',
  PRIMARY KEY  (ip,netmask),
  UNIQUE KEY id (id)
) TYPE=MyISAM;

--
-- Table structure for table 'payment'
--

CREATE TABLE payment (
  date datetime NOT NULL default '0000-00-00 00:00:00',
  sum double(10,2) NOT NULL default '0.00',
  dsc varchar(80) default NULL,
  ww varchar(40) NOT NULL default '',
  ip int(11) unsigned NOT NULL default '0',
  last_deposit double(7,6) NOT NULL default '0.000000',
  uid int(11) unsigned NOT NULL default '0',
  aid smallint(6) unsigned NOT NULL default '0',
  id int(11) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  KEY date (date),
  KEY uid (uid)
) TYPE=MyISAM;

--
-- Table structure for table 's_detail'
--

CREATE TABLE s_detail (
  acct_session_id varchar(25) NOT NULL default '',
  nas_id smallint(5) unsigned NOT NULL default '0',
  uid varchar(15) NOT NULL default '0',
  acct_status tinyint(2) unsigned NOT NULL default '0',
  start datetime default NULL,
  last_update int(11) unsigned NOT NULL default '0',
  sent1 int(10) unsigned NOT NULL default '0',
  recv1 int(10) unsigned NOT NULL default '0',
  sent2 int(10) unsigned NOT NULL default '0',
  recv2 int(10) unsigned NOT NULL default '0',
  id varchar(16) NOT NULL default '',
  KEY sid (acct_session_id)
) TYPE=MyISAM;

--
-- Table structure for table 'shedule'
--

CREATE TABLE shedule (
  id int(10) unsigned NOT NULL auto_increment,
  uid int(11) unsigned NOT NULL default '0',
  date date NOT NULL default '0000-00-00',
  type varchar(50) NOT NULL default '',
  action varchar(200) NOT NULL default '',
  aid smallint(6) unsigned NOT NULL default '0',
  counts tinyint(4) unsigned NOT NULL default '0',
  d char(2) NOT NULL default '*',
  m char(2) NOT NULL default '*',
  y varchar(4) NOT NULL default '*',
  h char(2) NOT NULL default '*',
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  KEY date_type_uid (date,type,uid)
) TYPE=MyISAM;

--
-- Table structure for table 'trafic_tarifs'
--

CREATE TABLE trafic_tarifs (
  id tinyint(4) NOT NULL default '0',
  descr varchar(30) default NULL,
  nets text,
  price float(8,5) NOT NULL default '0.00000',
  vid smallint(5) unsigned NOT NULL default '0',
  prepaid int(11) unsigned default '0',
  in_price float(8,5) default '0.00000',
  out_price float(8,5) default '0.00000',
  speed int(10) unsigned NOT NULL default '0',
  UNIQUE KEY vid_id (vid,id),
  KEY vid (vid)
) TYPE=MyISAM;

--
-- Table structure for table 'userlog'
--

CREATE TABLE userlog (
  log varchar(60) default NULL,
  date datetime default NULL,
  ww varchar(40) default NULL,
  ip int(11) unsigned NOT NULL default '0',
  uid int(11) unsigned NOT NULL default '0',
  aid smallint(6) unsigned NOT NULL default '0',
  id int(11) unsigned NOT NULL auto_increment,
  PRIMARY KEY  (id),
  UNIQUE KEY id (id),
  KEY uid (uid)
) TYPE=MyISAM;

--
-- Table structure for table 'users'
--

CREATE TABLE users (
  id varchar(20) NOT NULL default '',
  fio varchar(40) NOT NULL default '',
  phone bigint(16) unsigned NOT NULL default '0',
  activate date NOT NULL default '0000-00-00',
  expire date NOT NULL default '0000-00-00',
  deposit double(7,6) NOT NULL default '0.000000',
  credit double(6,2) NOT NULL default '0.00',
  reduction double(3,2) NOT NULL default '0.00',
  variant tinyint(4) unsigned NOT NULL default '0',
  logins tinyint(3) unsigned NOT NULL default '0',
  nas int(10) unsigned NOT NULL default '0',
  registration date default '0000-00-00',
  ip int(10) unsigned NOT NULL default '0',
  filter_id varchar(15) NOT NULL default '',
  speed int(10) unsigned NOT NULL default '0',
  netmask int(10) unsigned NOT NULL default '4294967294',
  cid varchar(35) NOT NULL default '',
  password varchar(16) NOT NULL default '',
  uid int(11) unsigned NOT NULL auto_increment,
  gid smallint(6) unsigned NOT NULL default '0',
  email varchar(35) NOT NULL default '',
  address varchar(250) NOT NULL default '',
  tax_number text NOT NULL,
  bank_account text NOT NULL,
  bank_name text NOT NULL,
  cor_bank_account text NOT NULL,
  bank_bic text NOT NULL,
  comments text NOT NULL,
  PRIMARY KEY  (uid),
  UNIQUE KEY id (id),
  KEY variant (variant)
) TYPE=MyISAM;

--
-- Table structure for table 'users_nas'
--

CREATE TABLE users_nas (
  uid int(10) unsigned NOT NULL default '0',
  nas_id smallint(5) unsigned NOT NULL default '0',
  KEY uid (uid)
) TYPE=MyISAM;

--
-- Table structure for table 'variant'
--

CREATE TABLE variant (
  vrnt smallint(5) unsigned NOT NULL default '0',
  hourp float(10,5) default '0.00000',
  abon float(10,2) default '0.00',
  kb float(10,5) default '0.00000',
  uplimit float(10,2) default '0.00',
  name varchar(40) NOT NULL default 'без╕менний',
  df float(10,2) default NULL,
  ut time NOT NULL default '24:00:00',
  dt time NOT NULL default '00:00:00',
  logins tinyint(4) NOT NULL default '0',
  day_time_limit int(10) unsigned NOT NULL default '0',
  week_time_limit int(10) unsigned NOT NULL default '0',
  month_time_limit int(10) unsigned NOT NULL default '0',
  day_traf_limit int(10) unsigned NOT NULL default '0',
  week_traf_limit int(10) unsigned NOT NULL default '0',
  month_traf_limit int(10) unsigned NOT NULL default '0',
  prepaid_trafic int(10) unsigned NOT NULL default '0',
  change_price float(8,2) unsigned NOT NULL default '0.00',
  activate_price float(8,2) unsigned NOT NULL default '0.00',
  credit_tresshold double(6,2) NOT NULL default '0.00',
  PRIMARY KEY  (vrnt),
  UNIQUE KEY name (name),
  UNIQUE KEY vrnt (vrnt)
) TYPE=MyISAM;

--
-- Table structure for table 'vid_nas'
--

CREATE TABLE vid_nas (
  vid smallint(5) unsigned NOT NULL default '0',
  nas_id smallint(5) unsigned NOT NULL default '0',
  KEY vid (vid)
) TYPE=MyISAM;

--
-- Table structure for table 'web_online'
--

CREATE TABLE web_online (
  admin varchar(15) NOT NULL default '',
  ip varchar(15) NOT NULL default '',
  logtime int(11) unsigned NOT NULL default '0'
) TYPE=MyISAM;

