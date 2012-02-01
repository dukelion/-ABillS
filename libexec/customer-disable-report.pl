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
use List::Util qw[min max];

use POSIX;

use FindBin '$Bin';
use Sys::Hostname;

require $Bin . '/config.pl';
unshift(@INC, $Bin . '/../', $Bin . '/../Abills', $Bin . "/../Abills/$conf{dbtype}");

require "Abills/defs.conf";
require "Abills/templates.pl";

require Abills::Base;
Abills::Base->import(qw{check_time sendmail});
my $begin_time = check_time();

require Abills::SQL;
Abills::SQL->import();

require Admins;
Admins->import();
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $db = $sql->{db};
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });


if ($admin->{errno}) {
  if($admin->{errno} == 2) {
    print "Can't find system administrator. ID $conf{SYSTEM_ADMIN_ID}\n";
   }
  else {
    print "$admin->{errno} $admin->{errstr}\n";
   }
  exit 0;
}


require Users;
Users->import();
$users = Users->new($db, $admin, \%conf);
my $list = $users->list({
			UID => '>0',
			PAGE_ROWS    => 1000000,
                              });

my %tab;

require "Abills/mysql/Dv.pm";
my $Dv       = Dv->new($db, $admin, \%conf);
foreach my $line (@$list) {
	my $uid = @$line[7];

	my $warn = 0;

        my $info = $Dv->info($uid);
	my $user = $users->info($uid);

	next if($user->{DISABLE} != 0);

#	warn Dumper($info);
#	warn Dumper($user);

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
	my $monthAbon = $info->{MONTH_ABON} * (100 - ($user->{REDUCTION}? $user->{REDUCTION} : 0))/100;

	my $now = strftime("%s",localtime());
	my $disableDate = 0;

	if ( $user->{DEPOSIT} + $user->{CREDIT} < 0.01 ) {
		$warn = 1;
		$disableDate = $now;
	} elsif ($creddate and ($creddate - $now < $WARN_DAYS*86400) and $user->{DEPOSIT} < 0.01) {
	 	$warn = 2;
		$disableDate = $creddate;
	} elsif ($abondate and  ($abondate - $now < $WARN_DAYS*86400) and $monthAbon > 0.01) {
		if ($user->{DEPOSIT} + $user->{CREDIT} - $monthAbon < 0.01 ) {
			$warn = 3;
			$disableDate = $abondate;
		} elsif ( $creddate and $abondate and ($creddate - $now < $WARN_DAYS*86400) and $user->{DEPOSIT} - $monthAbon < 0 ) {
			$warn = 4;
			$disableDate = max($creddate, $abondate);
		}
	}

	if ($warn > 0) { 
		my $warncustomer;
		$warncustomer->{'Deposit'} = $user->{DEPOSIT};
		$warncustomer->{'Credit'} = $user->{CREDIT};
		$warncustomer->{'CreditExpiryDate'} = ($user->{CREDIT} < 0.01 || $user->{CREDIT_DATE} eq '0000-00-00' ) ? '' : $user->{CREDIT_DATE};
		$warncustomer->{'DebitDate'} = $info->{ABON_DATE};
		$warncustomer->{'MonthFee'} = $monthAbon;
		$warncustomer->{'Errno'} = $warn;
		$warncustomer->{'DisableDate'} = strftime("%Y-%m-%d",localtime($disableDate));
		$tab{ $user->{LOGIN} } = $warncustomer;
	};
};

#exit(0) unless %tab;
my $texttab = Text::Table->new("login",\' | ',"Balance",\' | ',"Credit",\' | ',"Credit Expiry",\' | ',"Debit date",\' | ',"Month fee",\' | ',"Disable Date",\' | ',"Reason Code");

foreach my $line (sort { $tab{$a}{'DisableDate'} cmp $tab{$b}{'DisableDate'} } keys(%tab)){
$texttab->load( [$line,@{$tab{$line}}{qw/Deposit Credit CreditExpiryDate DebitDate MonthFee DisableDate Errno/}]);
}; 

my $message = $texttab->title;
$message .= $texttab->rule('-','+');
$message .= $texttab->body;

$message .= <<EOF

Possible reasons:
	1: Current balance is less or equal to 0 (typically when account is already suspended)
	2: Expiry date for Credit is near,  Current balance is less or equal to 0.
	3: (Balance+Credit) is not enough to write off next monthly fee, debiting date is near.
	4: Balance is not enough to write off next monthly fee, debiting date and credit expiry date are near.
EOF
;

if ($begin_time > 0)  {
	Time::HiRes->import(qw(gettimeofday));
	my $end_time = gettimeofday();
	my $gen_time = $end_time - $begin_time;
	$message .= sprintf("\n\n GT: %2.5f\n", $gen_time);
}

#sendmail("$conf{ADMIN_MAIL}", 'Artem Belotski <artem@neda.af>, Elena Yampolskaya <eyampolskaya@neda.af>, Igor Karmanov <ikarmanov@neda.af>, <valferov@neda.af>', "Customers disabling report ".strftime("%Y-%m-%d",localtime()),
#              "$message", "$conf{MAIL_CHARSET}", "2 (High)");
print $message;

