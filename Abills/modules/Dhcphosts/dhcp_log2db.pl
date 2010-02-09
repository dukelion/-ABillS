#!/usr/bin/perl -w
# Log grabber


use vars  qw(%conf $db $DATE $TIME);
use strict;

my $version = 0.01;
my $debug = 1;

use FindBin '$Bin';
require $Bin . '/config.pl';
unshift(@INC, $Bin . '/../', $Bin . "/../Abills/$conf{dbtype}");
require Abills::Base;
Abills::Base->import();
use POSIX qw(strftime);

my $begin_time = check_time();

require Abills::SQL;
require Dhcphosts;
Dhcphosts->import();

my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db  = $sql->{db};
my $Dhcphosts = Dhcphosts->new($db, undef, \%conf);

my %DHCP_MESSAGE_TYPES = (
  DHCPDISCOVER          =>  1,
  DHCPOFFER             =>  2,
  DHCPREQUEST           =>  3,
  DHCPDECLINE           =>  4,
  DHCPACK               =>  5,
  DHCPNAK               =>  6,
  DHCPRELEASE           =>  7,
  DHCPINFORM            =>  8,
  DHCPLEASEQUERY        =>  10,
  DHCPLEASEUNASSIGNED   =>  11,
  DHCPLEASEUNKNOWN      =>  12,
  DHCPLEASEACTIVE       =>  13 
 );

my %month_names = (Jan => '01', 
Feb => '02', 
Mar => '03', 
Apr => '04', 
May => '05', 
Jun => '06', 
Jul => '07', 
Aug => '08', 
Sep => '09', 
Oct => '10', 
Nov => '11',	
Dec => '12');

my $year = strftime "%Y", localtime(time);


add_logs2db();


#**********************************************************
#
#**********************************************************
sub add_logs2db {
  while (my $line=<>) {
    my ($month_name, $month_day, $time, $hostname, $log_daemon, $message_type, $log)=split(/ /, $line, 7);
    if ($DHCP_MESSAGE_TYPES{$message_type}) {
      $Dhcphosts->log_add({ DATETIME => sprintf("%s-%s-%.02d %s", $year, $month_names{$month_name}, $month_day, $time),
      	 HOSTNAME     => "$hostname", 
      	 MESSAGE_TYPE => $DHCP_MESSAGE_TYPES{$message_type} || 0, 
      	 MESSAGE      => $log
      	});
     }
   }
}

