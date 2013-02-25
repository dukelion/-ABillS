#!/usr/bin/perl
use vars  qw(%conf @MODULES $db $DATE $TIME $GZIP $TAR
  %LIST_PARAMS
  $DEBUG
  $users
  $Log
 );

use strict;
use Data::Dumper::Simple;
use Text::Table;
use HTML::Table;
use Email::MIME::CreateHTML;
use Email::Send;
use Time::Local;
use List::Util qw[min max];

use POSIX;

use FindBin '$Bin';
use Sys::Hostname;

my ($WARN_DAYS,$DEBUG) = @ARGV;
$WARN_DAYS = $WARN_DAYS ? $WARN_DAYS : 10;
$DEBUG     = $DEBUG     ? 1 : 0  ;

my %reciepients = (
	Yahsat 	=> {gid=>300,email=>'yahsatbilling@neda.af'},
	HomeNet => {gid=>200,email=>'homenetbilling@neda.af'},
	WiMAX 	=> {gid=>0,email=>'wimaxbilling@neda.af'},
	WiMAX 	=> {gid=>1,email=>'wimaxbilling@neda.af'},
	VSAT 	=> {gid=>3,email=>'vsatbilling@neda.af'},
);


require $Bin . '/config.pl';
unshift(@INC, $Bin . '/../', $Bin . '/../Abills', $Bin . "/../Abills/$conf{dbtype}");

require "Abills/defs.conf";
require "Abills/templates.pl";

my @service_status = ( "Enabled", "Disabled", "Not Active", "Held Up", "Disabled: Non payment", "Too Small Deposit");

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
};

foreach my $gname (keys %reciepients) {
	my ($active,$disabled)=&reportforgroups($reciepients{$gname}{gid});
	&sendreport($active,$disabled,$gname,'eyampolskaya@neda.af');
}


sub reportforgroups(){
	my $groupid = shift;
	require Users;
	Users->import();
	$users = Users->new($db, $admin, \%conf);
	my $list = $users->list({
				UID => '>0',
				PAGE_ROWS    => 1000000,
				GID => $groupid,
				      });

	my %disabled_tab;
	my %active_tab;

	require "Abills/mysql/Dv.pm";

	my $Dv       = Dv->new($db, $admin, \%conf);
	foreach my $line (@$list) {
#		warn Dumper($line);
		my $uid = @$line[8];

		my $info = $Dv->info($uid);
		my $user = $users->info($uid);

		next if($user->{DISABLE} != 0);

#		warn Dumper($info);
#		warn Dumper($user);

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
			if ($conf{START_PERIOD_DAY} && $conf{START_PERIOD_DAY} > $D) {
			 }
			else {
			  $M++;
			 }
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
			$Dv->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y,$M,$D);
		  }
		}
		my ($creddate, $abondate, $expireDate) = 0;
		if ($user->{CREDIT_DATE} and $user->{CREDIT_DATE} != '0000-00-00') {
			my ($year,$month,$day) = split(/-/,$user->{CREDIT_DATE});
			$creddate = timelocal(0,0,0,$day,--$month,$year);
		}
		if ($info->{ABON_DATE} and $info->{ABON_DATE} != '0000-00-00') {
			my ($year,$month,$day) = split(/-/,$info->{ABON_DATE});
			$abondate = timelocal(0,0,0,$day,--$month,$year);
		}
		my $monthAbon = $info->{MONTH_ABON} * (100 - ($user->{REDUCTION}? $user->{REDUCTION} : 0))/100;

		if ($user->{EXPIRE} and $user->{EXPIRE} != '0000-00-00') {
			my ($year,$month,$day) = split(/-/,$user->{EXPIRE});
			$expireDate = timelocal(0,0,0,$day,--$month,$year);
		}

		my $now = strftime("%s",localtime());
		my $disableDate = 0;
		my $disableCode = 0;

		if ($info->{STATUS} == 5) {
			($disableDate,$disableCode) = &updateDisableDate($now,1,$disableDate,$disableCode);
		}
		if ( $user->{DEPOSIT} + $user->{CREDIT} < 0.01 ) {
			($disableDate,$disableCode) = &updateDisableDate($now,1,$disableDate,$disableCode);
		}
		if ($creddate and ($creddate - $now < $WARN_DAYS*86400) and $user->{DEPOSIT} < 0.01) {
			($disableDate,$disableCode) = &updateDisableDate($creddate,2,$disableDate,$disableCode);
		}
		if ($abondate and  ($abondate - $now < $WARN_DAYS*86400) and $monthAbon > 0.01) {
			if ($user->{DEPOSIT} + $user->{CREDIT} - $monthAbon < 0.01 ) {
				($disableDate,$disableCode) = &updateDisableDate($abondate,3,$disableDate,$disableCode);
			} elsif ( $creddate and $abondate and ($creddate - $now < $WARN_DAYS*86400) and $user->{DEPOSIT} - $monthAbon < 0 ) {
				($disableDate,$disableCode) = &updateDisableDate(max($abondate,$creddate),3,$disableDate,$disableCode);
			}
		}
		if ($expireDate and $expireDate - $now < $WARN_DAYS*86400) {
			($disableDate,$disableCode) = updateDisableDate($expireDate,5);
		}

		if ($disableCode > 0) {
			my $pi = $users->pi({UID => $uid});
		#warn Dumper($pi);
			my $warncustomer;
			$warncustomer->{'FIO'} = $pi->{FIO};
			$warncustomer->{'Deposit'} = $user->{DEPOSIT};
			$warncustomer->{'Credit'} = $user->{CREDIT};
			$warncustomer->{'CreditExpiryDate'} = ($user->{CREDIT} < 0.01 || $user->{CREDIT_DATE} eq '0000-00-00' ) ? '' : $user->{CREDIT_DATE};
			$warncustomer->{'DebitDate'} = $info->{ABON_DATE};
			$warncustomer->{'MonthFee'} = $monthAbon;
			$warncustomer->{'Errno'} = $disableCode;
			$warncustomer->{'ExpireDate'} = $user->{EXPIRE} eq '0000-00-00' ? '' : $user->{EXPIRE};
			$warncustomer->{'DisableDate'} = strftime("%Y-%m-%d",localtime($disableDate));
			$warncustomer->{'UID'} = $user->{UID};
			$warncustomer->{'TSTATUS'} = $service_status[$info->{STATUS}];
			if ($info->{STATUS} == 1 or $info->{STATUS}==4) {
				$disabled_tab{ $user->{LOGIN} } = $warncustomer;
			} else {
				$active_tab{ $user->{LOGIN} } = $warncustomer;
			}
		};
	};
	return (\%active_tab,\%disabled_tab);
};

sub generate_htmltab {
	my (%tab) = @_;
	my $htmltab = new HTML::Table(
		-cols=>8,
		-head=>["login","Customer Name","Balance","Credit","Credit Expiry","Debit date","Month fee","Expire Date","Tariff Status","Disable Date","Reason Code"],
		-border=>1,
		-bgcolor=>'WhiteSmoke',
	);
	foreach my $line (sort { $tab{$a}{'DisableDate'} cmp $tab{$b}{'DisableDate'} } keys(%tab)){
		my @array = ($line,@{$tab{$line}}{qw/FIO Deposit Credit CreditExpiryDate DebitDate MonthFee ExpireDate TSTATUS DisableDate Errno/});
		$array[0] = sprintf '<a title="%s" href="https://bill.neda.af/admin/index.cgi?index=15&UID=%s">%s</a>',$line,$tab{$line}{UID},$line;
		$htmltab->addRow(@array);
	};
	my $htmlmessage = sprintf "<p>%s</p>\n",$htmltab->getTable;
	return $htmlmessage;
}

sub generate_texttab {
	my (%tab) = @_;
	my $texttab = Text::Table->new(
		      "login",
	      \' | ', "Customer Name",
	      \' | ', "Balance",
	      \' | ', "Credit",
	      \' | ', "Credit Expiry",
	      \' | ', "Debit date",
	      \' | ', "Month fee",
	      \' | ', "Expire Date",
	      \' | ', "Tariff Status",
	      \' | ', "Disable Date",
	      \' | ', "Reason Code");
	foreach my $line (sort { $tab{$a}{'DisableDate'} cmp $tab{$b}{'DisableDate'} } keys(%tab)){
		my @array = ($line,@{$tab{$line}}{qw/FIO Deposit Credit CreditExpiryDate DebitDate MonthFee ExpireDate TSTATUS DisableDate Errno/});
		$texttab->load([@array]);
	};

	my $textmessage = $texttab->title;
	$textmessage .= $texttab->rule('-','+');
	$textmessage .= $texttab->body;

	return $textmessage;
}

sub sendreport(){
	my $active_tab_ref = shift;
	my $disabled_tab_ref = shift;
	my $gname = shift;
	my $targetemail = shift;
	my %active_tab = %$active_tab_ref;
	my %disabled_tab = %$disabled_tab_ref;

	my $footer = <<EOF

	Possible reasons:
	<dl>
		<dt>1:</dt><dd> Current balance is less or equal to 0 (typically when account is already suspended)</dd>
		<dt>2:</dt><dd> Expiry date for Credit is near,  Current balance is less or equal to 0.</dd>
		<dt>3:</dt><dd> (Balance+Credit) is not enough to write off next monthly fee, debiting date is near.</dd>
		<dt>4:</dt><dd> Balance is not enough to write off next monthly fee, debiting date and credit expiry date are near.</dd>
		<dt>5:</dt><dd> User expiration date is near or in past</dd>
	</dl>

EOF
;


	my $htmlmessage='';
	$htmlmessage .=  "<p>$gname customers who are suspended or going to be suspended automatically</p>";
	$htmlmessage .= generate_htmltab(%active_tab);
	$htmlmessage .=  "<p>$gname customers who was cancelled or suspended manually by request</p>";
	$htmlmessage .= generate_htmltab(%disabled_tab);
	$htmlmessage .= "\n$footer\n";

	my $textmessage='';
	$textmessage .=  "$gname customers who are suspended or going to be suspended automatically\n";
	$textmessage .= generate_texttab(%active_tab);
	$textmessage .=  "$gname customers who was cancelled or suspended manually by request\n";
	$textmessage .= generate_texttab(%disabled_tab);
	$textmessage .= $footer;

	if ($DEBUG) {
		print $textmessage;
	} else {
		my $email = Email::MIME->create_html(
			header => [
				From => "$conf{ADMIN_MAIL}",
				To =>   $targetemail,
				Subject => "Customers disabling report for group $gname".strftime("%Y-%m-%d",localtime()),
			],
			body => $htmlmessage,
			text_body => $textmessage
		);
		my $sender = Email::Send->new({mailer => 'Sendmail'});
		$sender->send($email);
	}
};

sub updateDisableDate () {
	my $_disableDate = shift;
	my $_disableCode = shift;
	my $disableDate = shift;
	my $disableCode = shift;
	if (!($disableDate) or $_disableDate < $disableDate) { $disableDate = $_disableDate; $disableCode = $_disableCode}
	return ($disableDate,$disableCode);

};

	if ($begin_time > 0)  {
		Time::HiRes->import(qw(gettimeofday));
		my $end_time = gettimeofday();
		my $gen_time = $end_time - $begin_time;
		printf("\n\n GT: %2.5f\n", $gen_time);
	}
