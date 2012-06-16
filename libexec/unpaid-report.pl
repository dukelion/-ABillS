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
#use Email::MIME::CreateHTML;
#use Email::Send;
use Mail::Sender;
use Time::Local;
use List::Util qw[min max];
use Spreadsheet::WriteExcel;
use File::Temp;

use POSIX;

use FindBin '$Bin';
use Sys::Hostname;

my ($DEBUG) = @ARGV;
$DEBUG     = $DEBUG     ? 1 : 0  ;

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
}


require Users;
Users->import();
$users = Users->new($db, $admin, \%conf);
my $list = $users->list({
			UID => '>0',
			PAGE_ROWS    => 1000000,
                              });

my %disabled_tab;
my %active_tab;

require "Abills/mysql/Dv.pm";

my $q = qq|
select  users.id,users.uid,coalesce(invoice_sum,0), coalesce(pay_sum,0)
from
users left join
(SELECT i.uid,sum(o.price) as invoice_sum FROM `docs_invoices` i, docs_invoice_orders o WHERE  i.id = o.invoice_id group by uid) as i on users.uid = i.uid
left join
(SELECT uid,sum(sum) as pay_sum FROM payments p group by uid) as p  on p.uid = i.uid
|;

print $q;

my $res = $admin->query($db,$q);
my @balance = @{$$res{'list'}};

my $Dv       = Dv->new($db, $admin, \%conf);

my %tab;
my $total=0;
foreach my $line (@balance) {
	my ($username,$uid,$invoice_sum,$payments_sum) = @$line;

        my $info = $Dv->info($uid);
	my $user = $users->info($uid);

#	next if($user->{DISABLE} != 0);

        my $customer;
        my $pi = $users->pi({UID => $uid});
        $customer->{'username'} = $pi->{FIO};
        $customer->{'uid'} = $uid;
        $customer->{'invoice_sum'} = $invoice_sum;
        $customer->{'payments_sum'} = $payments_sum;
        $customer->{'outbalance'} = $payments_sum - $invoice_sum;
        $customer->{'deposit'} = $user->{DEPOSIT};
        $customer->{'status'} = $user->{DISABLE};
        $customer->{'tarif_status'} = $service_status[$info->{STATUS}];
        $total += $customer->{'outbalance'};

        $tab{$username} = $customer;

};

sub generate_htmltab {
	my (%tab) = @_;
	my $htmltab = new HTML::Table(
		-cols=>7,
		-head=>["Login","Customer Name","Invoice Sum","Payments Sum","Abills Deposit","Customer status","Tariff Status","Outstanding Balance"],
		-border=>1,
		-bgcolor=>'WhiteSmoke',
	);
	foreach my $line (keys(%tab)){
		my @array = ($line,@{$tab{$line}}{qw/username invoice_sum payments_sum deposit status tarif_status outbalance/});
		$array[0] = sprintf '<a title="%s" href="https://bill.neda.af/admin/index.cgi?index=15&UID=%s">%s</a>',$line,$tab{$line}{UID},$line;
                $array[7] = sprintf '<b>%s</b>',$tab{$line}{outbalance};
		$htmltab->addRow(@array);
	};
	my $htmlmessage = sprintf "<p>%s</p>\n",$htmltab->getTable;
	return $htmlmessage;
}

sub generate_texttab {
	my (%tab) = @_;
	my $texttab = Text::Table->new(
		      "Login",
	      \' | ', "Customer Name",
	      \' | ', "Customer ID",
	      \' | ', "Invoice Sum",
	      \' | ', "Payments Sum",
	      \' | ', "Abills Deposit",
	      \' | ', "Customer status",
	      \' | ', "Tariff Status",
	      \' | ', "Outstanding Balance"
        );
	foreach my $line (keys(%tab)){
		my @array = ($line,@{$tab{$line}}{qw/username uid invoice_sum payments_sum deposit status tarif_status outbalance/});
		$texttab->load([@array]);
	};

	my $textmessage = $texttab->title;
	$textmessage .= $texttab->rule('-','+');
	$textmessage .= $texttab->body;

	return $textmessage;
}
sub generate_exceltab {
  my (%tab) = @_;
  #my $fh = File::Temp->new();
  #my $fname = $fh->filename;
  unlink ('/tmp/unpaid.xls');
  my $fname = '/tmp/unpaid.xls';

  my $exceltab = Spreadsheet::WriteExcel->new($fname);
  my $sheet1 = $exceltab->add_worksheet();
  my @colnames = ("Login","Customer Name","Invoice Sum","Payments Sum","Abills Deposit","Customer status","Tariff Status","Outstanding Balance");
  my @colvalues = (qw/username invoice_sum payments_sum deposit status tarif_status outbalance/);

  &writerowexcel(\@colnames,0);
  my $datarow = 1;
  foreach my $line (sort { $tab{$a}{'DisableDate'} cmp $tab{$b}{'DisableDate'} } keys(%tab)){
          my @array = ($line,@{$tab{$line}}{qw/username invoice_sum payments_sum deposit status tarif_status outbalance/});
          $array[0] = sprintf 'https://bill.neda.af/admin/index.cgi?index=15&UID=%s',$line,$tab{$line}{UID};
          &writerowexcel (\@array,$datarow);
          $datarow++;
  };

  $exceltab->close();
  return $fname;

  sub writerowexcel {
    my ($row,$rownum) = @_;
    my $col = 0;
    foreach my $value (@$row) {
      $sheet1->write($rownum,$col,$value);
#      warn Dumper $value;
      $col++;
    }
  }
}


my $footer;

$footer .= "\nTotal outstanding balance: $total\n";

if ($begin_time > 0)  {
	Time::HiRes->import(qw(gettimeofday));
	my $end_time = gettimeofday();
	my $gen_time = $end_time - $begin_time;
	$footer .= sprintf("\n\n GT: %2.5f\n", $gen_time);
}

my $excelfile = generate_exceltab(%tab);

my $htmlmessage;
$htmlmessage .= generate_htmltab(%tab);
$htmlmessage .= "\n$footer\n";

my $textmessage;
#$textmessage .= generate_texttab(%tab);
$textmessage .= $footer;


if ($DEBUG) {
	print $textmessage;
} else {
#	my $email = Email::MIME->create_html(
#		header => [
#			From => "$conf{ADMIN_MAIL}",
##			To =>   'valferov@neda.af',
#			To =>   'Billing Mailing list <billing@neda.af>, <devteam@neda.af>, Hamidullah <hamidullah@neda.af>',
##			To =>	"Billing Mailing list <billing@neda.af>, <devteam@neda.af>",
#			Subject => "Outstanding balance report ".strftime("%Y-%m-%d",localtime()),
#		],
#		body => $htmlmessage,
#		text_body => $textmessage
#	);
#	my $sender = Email::Send->new({mailer => 'Sendmail'});
#	$sender->send($email);
  my $to_addresses = 'valferov@neda.af';
  my $subject = "Outstanding balance report ".strftime("%Y-%m-%d",localtime());
  my $message = $textmessage;

  my $sender = new Mail::Sender
  {
      smtp => '192.168.1.17',
      from => "$conf{ADMIN_MAIL}"
  };
  $sender->MailFile(
    {
        to      => $to_addresses,
        subject => $subject,
        msg     => $textmessage,
        file    => $excelfile
    });
}

sub updateDisableDate () {
	my $_disableDate = shift;
	my $_disableCode = shift;
	my $disableDate = shift;
	my $disableCode = shift;
	if (!($disableDate) or $_disableDate < $disableDate) { $disableDate = $_disableDate; $disableCode = $_disableCode}
	return ($disableDate,$disableCode);

};
