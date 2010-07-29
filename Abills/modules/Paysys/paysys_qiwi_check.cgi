#!/usr/bin/perl -w
# PaySys Console
# Console interface for payments and fees import


use vars qw($begin_time %FORM %LANG
$DATE $TIME
$CHARSET
@MODULES);



BEGIN {
 my $libpath = '../../../';
 $sql_type='mysql';
 unshift(@INC, './');
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, "/usr/abills/Abills/$sql_type/");
 unshift(@INC, "/usr/abills/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');

 eval { require Time::HiRes; };
 if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
   }
 else {
    $begin_time = 0;
  }
}

use FindBin '$Bin';

require $Bin . '/../../../libexec/config.pl';


use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Users;
use Paysys;
use Finance;
use Admins;

my $html = Abills::HTML->new();
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};
#Operation status

my $admin    = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $payments = Finance->payments($db, $admin, \%conf);
my $fees     = Finance->fees($db, $admin, \%conf);
my $Paysys   = Paysys->new($db, $admin, \%conf);
my $Users    = Users->new($db, $admin, \%conf);
my $debug    = 0;
my $error_str= '';
%PAYSYS_PAYMENTS_METHODS=%{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };

#Arguments
my $ARGV = parse_arguments(\@ARGV);

if (defined($ARGV->{help})) {
	help();
	exit;
}

if ($ARGV->{DEBUG}) {
	$debug=$ARGV->{DEBUG};
	print "DEBUG: $debug\n";
}

$DATE = $ARGV->{DATE} if ($ARGV->{DATE});

qiwi_check();

#**********************************************************
#
#**********************************************************
sub qiwi_check {
	my ($attr)=@_;
	require "Abills/modules/Paysys/Qiwi.pm";

my $list = $Paysys->list( { %LIST_PARAMS, 
	                          PAYMENT_SYSTEM => 59, 
	                          INFO => '-',
	                          PAGE_ROWS => 1000000 } );	

my %status_hash = (
10 => 'Не обработана',
20 => 'Отправлен запрос провайдеру',
25 => 'Авторизуется',
30 => 'Авторизована',
48 => 'Проходит финансовый контроль',
49 => 'Проходит финансовый контроль',
50 => 'Проводится',
51 => 'Проведена (51)',
58 => 'Перепроводится',
59 => 'Принята к оплате',
60 => 'Проведена',
61 => 'Проведена',
125 => 'Не смогли отправить провайдеру',
130 => 'Отказ от провайдера',
148 => 'Не прошел фин. контроль',
149 => 'Не прошел фин. контроль',
150 => 'Ошибка на терминале',
160 => 'Не проведена',
161 => 'Отменен (Истекло время)'
);



my @ids_arr = ();
foreach my $line (@$list) {
  push @ids_arr, $line->[5];
}

my $result = qiwi_status({ IDS   => \@ids_arr,
	                         DEBUG => $debug });

my %res_hash = ();
foreach my $id ( keys %{ $result->{'bills-list'}->[0]->{bill} } ) {
	$res_hash{$id}=$result->{'bills-list'}->[0]->{bill}->{$id}->{status};

}

foreach my $line (@$list) {
  print "$line->[1] LOGIN: $line->[2] SUM: $line->[3] PAYSYS: $line->[4] PAYSYS_ID: $line->[5]  $line->[6] STATUS: $res_hash{$line->[5]}\n" if ($debug > 0);
  if ($res_hash{$line->[5]} == 50) {
  	
   }
  elsif ( $res_hash{$line->[5]} == 60 ||  $res_hash{$line->[5]} == 61 || $res_hash{$line->[5]} == 51) {
  	 my $user = $Users->info($line->[7]);
     $payments->add($user, {SUM      => $line->[3],
    	                     DESCRIBE     => 'QIWI', 
    	                     METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{54}) ? 54 : '2',  
  	                       EXT_ID       => "QIWI:$line->[5]",
  	                       CHECK_EXT_ID => "QIWI:$line->[5]" } );  

     $Paysys->change({ ID        => $line->[0],
     	                 PAYSYS_IP => $ENV{'REMOTE_ADDR'},
 	                     INFO      => "$_DATE: $DATE $TIME $res_hash{$line->[5]} - $status_hash{$res_hash{$line->[5]}}"
      	            });
   }
  elsif (in_array($res_hash{$line->[5]}, [ 160, 161 ])) {
     $Paysys->change({ ID        => $line->[0],
     	                 PAYSYS_IP => $ENV{'REMOTE_ADDR'},
 	                     INFO      => "$_DATE: $DATE $TIME $res_hash{$line->[5]} - $status_hash{$res_hash{$line->[5]}}"
      	            });
   }
}
	
	return 0;
}

#**********************************************************
#
#**********************************************************
sub	help {

print << "[END]";	
  QIWI checker:
    DEBUG=... - debug mode
    help      - this help
[END]

}

1
