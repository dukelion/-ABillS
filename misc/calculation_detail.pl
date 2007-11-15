#!/usr/bin/perl


use vars  qw(%RAD %conf $db %ACCT
 %RAD_REQUEST %RAD_REPLY %RAD_CHECK 
 $begin_time
 $nas);
use strict;

use FindBin '$Bin';
BEGIN {
  unshift(@INC, $Bin . "/../Abills/", $Bin . '/../', $Bin . "/../Abills/mysql/",);
 }
require $Bin . '/../libexec/config.pl';





require Abills::Base;
Abills::Base->import();
my $begin_time = check_time();
my %acct_mod = ();

require Abills::SQL;
my $sql = Abills::SQL->connect($conf{dbtype}, "$conf{dbhost}", $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
$db = $sql->{db};

use main;
use Billing;

my $Billing = Billing->new($db, \%conf, );	
$Billing->{debug}=1;
my $ARGV = parse_arguments(\@ARGV);



if ($ARGV->{help}) {
	print " USER_NAME=test START=\"2006-10-11 15:11:12\" ACCT_SESSION_TIME=1211
  USER_NAME: User name
  START: Session start
  ACCT_SESSION_TIME : Session duration
  STOP: Session Stop (Optional)
Traffic parameters:
  INBYTE:
  OUTBYTE:
 ";

 exit;
}


my %INPUT = (USER_NAME => $ARGV->{USER_NAME},
             START     => $ARGV->{START},
             ACCT_SESSION_TIME  => $ARGV->{ACCT_SESSION_TIME} );

print "Input:\n";
while(my($k, $v)= each %INPUT) {
	print "$k - $v\n";
}


$Billing->query($db, "SELECT UNIX_TIMESTAMP('$INPUT{START}');");
my ($time)= @{ $Billing->{list}->[0] };

my %result = ();
    ($result{UID}, 
     $result{SUM}, 
     $result{BILL_ID}, 
     $result{TARIF_PLAN}, 
     $result{TIME_TARIF}, 
     $result{TRAF_TARIF}) = $Billing->session_sum("$INPUT{USER_NAME}", 
                                                  "$time", 
                                                   $INPUT{ACCT_SESSION_TIME}, 
                                                  { OUTBYTE => 10000,
                                                  	INBYTE  => 10000 }, 
                                                  { } );


my %Errors = ( 
 '-1' => "Less than minimun session trafic and time",
 '-2' => "Not found user in users db",
 '-3' => "SQL Error",
 '-4' => "Company not found",
 '-5' => "TP not found",
 '-16' => "Not allow start period"
 );

print "=================================\nResult:\n";

if ($result{UID} < 0) {
	print "Error: [$result{UID}] $Errors{$result{UID}}\n";
	print "=================================\n";
}


delete $result{UID};
while(my($k, $v)= each %result) {
	print "$k - $v\n";
}
