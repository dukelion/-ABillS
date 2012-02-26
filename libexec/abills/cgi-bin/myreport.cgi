#!/usr/bin/perl
use vars  qw(%conf @MODULES $db $DATE $TIME $GZIP $TAR
  %LIST_PARAMS
  $DEBUG
  $users
  $Log
 );

my $WARN_DAYS = 10;

use strict;
use Data::Dumper::Simple;
use Text::Table;
use Time::Local;

use POSIX;

use FindBin '$Bin';
use Sys::Hostname;

require $Bin . '/config.pl';
unshift(@INC, $Bin . '/../', $Bin . '/../Abills', $Bin . "/../Abills/$conf{dbtype}");

require "Abills/defs.conf";
require "Abills/templates.pl";

require Abills::SQL;
Abills::SQL->import();
require Users;
Users->import();

require "Abills/mysql/Dv.pm";
require Admins;
Admins->import();
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $db = $sql->{db};
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

my $Dv       = Dv->new($db, $admin, \%conf);

if ($admin->{errno}) {
  if($admin->{errno} == 2) {
    print "Can't find system administrator. ID $conf{SYSTEM_ADMIN_ID}\n";
   }
  else {
    print "$admin->{errno} $admin->{errstr}\n";
   }
  exit 0;
}

$users = Users->new($db, $admin, \%conf);

my $list = $users->list({
			UID => '>0',
			PAGE_ROWS    => 1000000,
                              });

#warn Dumper($list);

my %tab;
foreach my $line (@$list) {
	my $uid = @$line[7];

	my $warn = 0;

        my $info = $Dv->info($uid);
	my $user = $users->info($uid);

	next if($user->{DISABLE} != 0);

	#warn Dumper($info);
	#warn Dumper($user);

	  # Get next payment period
	  if ($info->{MONTH_ABON}> 0 &&  ! $info->{STATUS} && ! $user->{DISABLE} &&
		($user->{DEPOSIT}+$user->{CREDIT} > 0 ||
		 $info->{POSTPAID_ABON} ||
		 $info->{PAYMENT_TYPE} == 1 )) {

	    if ($user->{ACTIVATE} ne '0000-00-00') {
	      my ($Y, $M, $D)=split(/-/, $user->{ACTIVATE}, 3);
	      $M--;
	      $info->{ABON_DATE} = strftime "%Y-%m-%d", localtime(  (mktime(0, 0, 0, $D, $M, ($Y-1900), 0, 0, 0)  + 31 * 86400) );
	     }
	    else {
	      my ($Y, $M, $D)=split(/-/, $DATE, 3);
	      $M++;
	      if ($M == 13) {
		$M = 1;
		$Y++;
	       }

	      if ($conf{START_PERIOD_DAY}) {
		$D=$conf{START_PERIOD_DAY};
	       }
	      else {
		$D='01';
	       }

	      $info->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y,$M,$D);
	     }
	  }
	my ($creddate, $abondate) = 0;
	if ($user->{CREDIT_DATE} and $user->{CREDIT_DATE} != '0000-00-00') { 
		my ($year,$month,$day) = split(/-/,$user->{CREDIT_DATE});
		$creddate = timelocal(0,0,0,$day,--$month,$year);
	}
	if ($info->{ABON_DATE} and $info->{ABON_DATE} != '0000-00-00') { 
		my ($year,$month,$day) = split(/-/,$info->{ABON_DATE});
		$abondate = timelocal(0,0,0,$day,--$month,$year);
	}

	my $now = strftime("%s",localtime());
	my $disableDate = 0;

	if ( $user->{DEPOSIT} + $user->{CREDIT} < 0.01 ) {
		$warn = 1;
		$disableDate = $now;
	} elsif ($creddate and ($creddate - $now < $WARN_DAYS*86400) and $user->{DEPOSIT} < 0.01) {
	 	$warn = 2;
		$disableDate = $creddate;
	} elsif ($abondate and  ($abondate - $now < $WARN_DAYS*86400) and $info->{MONTH_ABON} > 0.01) {
		if ($user->{DEPOSIT} + $user->{CREDIT} - $info->{MONTH_ABON} < 0 ) {
			$warn = 3;
			$disableDate = $abondate;
		} elsif ( $creddate and ($creddate - $now < $WARN_DAYS*86400) and $user->{DEPOSIT} - $info->{MONTH_ABON} < 0 ) {
			$warn = 4;
			$disableDate = max ($creddate, $abondate);
		}
	}

	if ($warn > 0) { 
		#$tab->load(["|".$user->{LOGIN},"|".$user->{DEPOSIT},"|".$user->{CREDIT},"|".$user->{CREDIT_DATE},"|".$info->{ABON_DATE},"|".$info->{MONTH_ABON},"|".$warn]); 
		my $warncustomer;
		$warncustomer->{'Deposit'} = $user->{DEPOSIT};
		$warncustomer->{'Credit'} = $user->{CREDIT};
		$warncustomer->{'CreditExpiryDate'} = ($user->{CREDIT} < 0.01 || $user->{CREDIT_DATE} eq '0000-00-00' ) ? '' : $user->{CREDIT_DATE};
		$warncustomer->{'DebitDate'} = $info->{ABON_DATE};
		$warncustomer->{'MonthFee'} = $info->{MONTH_ABON},;
		$warncustomer->{'Errno'} = $warn;
		$warncustomer->{'DisableDate'} = strftime("%Y-%m-%d",localtime($disableDate));
		$tab{ $user->{LOGIN} } = $warncustomer;
	};
};

#exit(0) unless %tab;
my $texttab = Text::Table->new("login",\' | ',"Deposit",\' | ',"Credit",\' | ',"Credit Expiry",\' | ',"Debit date",\' | ',"Month fee",\' | ',"Errno",\' | ',"Disable Date");

foreach my $line (sort { $tab{$a}{'DisableDate'} cmp $tab{$b}{'DisableDate'} } keys(%tab)){
$texttab->load( [$line,@{$tab{$line}}{qw/Deposit Credit CreditExpiryDate DebitDate MonthFee Errno DisableDate/}]);
}; 
print $texttab;
