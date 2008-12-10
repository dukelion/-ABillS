#!/usr/bin/perl -w
#
#
use strict;

my $tmp_path        = '/tmp/';
my $pdf_result_path = '../cgi-bin/admin/pdf/';
my $debug           = 1;
my $docs_in_file    = 4000;


use vars  qw(%RAD %conf @MODULES $db $html $DATE $TIME $GZIP $TAR
  $MYSQLDUMP
  %ADMIN_REPORT
  $DEBUG

  @ones
  @twos
  @fifth
  @one
  @onest
  @ten
  @tens
  @hundred
  @money_unit_names
  
 );


#use strict;
use FindBin '$Bin';
use Sys::Hostname;

require $Bin .'/../libexec/config.pl';
unshift(@INC, $Bin . '/../', $Bin . '/../Abills', $Bin . "/../Abills/$conf{dbtype}");


require "Abills/defs.conf";
require "Abills/templates.pl";

require Abills::Base;
Abills::Base->import();

my $begin_time = check_time();

require Abills::SQL;
Abills::SQL->import();
require Users;
Users->import();
require Admins;
Admins->import();
require Docs;
Docs->import();
require Abills::HTML;
Abills::HTML->import();
$html = Abills::HTML->new({ CONF => \%conf, pdf => 1 });

my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $db = $sql->{db};
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });



require Finance;
Finance->import();
my $Fees = Finance->fees($db, $admin, \%conf);




my $users = Users->new($db, $admin, \%conf);


require $Bin ."/../Abills/modules/Docs/lng_$conf{default_language}.pl";

my $ARGV = parse_arguments(\@ARGV);

if (defined($ARGV->{help})) {
	help();
	exit;
}

$debug = $ARGV->{DEBUG} || $debug;

my ($Y, $m, $d)=split(/-/, $DATE, 3);
if ($ARGV->{RESULT_DIR}) {
  $pdf_result_path = $ARGV->{RESULT_DIR};
 }
else {
  $pdf_result_path = $pdf_result_path . "/$Y-$m/";
}

my $sort = ($ARGV->{SORT}) ? $ARGV->{SORT} : 1;

if (! -d $pdf_result_path) {
  mkdir($pdf_result_path);
  print "Directory no exists '$pdf_result_path'. Created." if ($debug > 0);
 }


$docs_in_file    = $ARGV->{DOCS_IN_FILE} || $docs_in_file;

my $save_filename = $pdf_result_path .'/multidoc_.pdf';



if (! -d $pdf_result_path) {
	mkdir ($pdf_result_path);
}

$Fees->{debug}=1 if ($debug > 6);
#Fees get month fees - abon. payments
my $fees_list = $Fees->reports({ INTERVAL => "$Y-$m-01/$DATE",  
	                               METHODS  => 1,
	                               TYPE     => 'USERS' 
	                               });
# UID / SUM
my %FEES_LIST_HASH = ();
foreach my $line (@$fees_list) {
	$FEES_LIST_HASH{$line->[4]}=$line->[3];
}

#Users info  
  my %INFO_FIELDS = ('_c_address' => 'ADDRESS_STREET',
                     '_c_build'   => 'ADDRESS_BUILD',
                     '_c_flat'    => 'ADDRESS_FLAT'
                     );

  my %INFO_FIELDS_SEARCH = ();

  foreach my $key ( keys %INFO_FIELDS ) {
  	$INFO_FIELDS_SEARCH{$key}='*';
   }

  $Fees->{users}=1 if ($debug > 6);
	my $list = $users->list({ DEPOSIT       => '<0',
		                        DISABLE       => 0,
                            CONTRACT_ID   => '*',
                            CONTRACT_DATE => '>=0000-00-00',
                            ADDRESS_STREET=> '*',
                            ADDRESS_BUILD => '*',
                            ADDRESS_FLAT  => '*',
                            
		                        PAGE_ROWS     => 1000000,
		                        %INFO_FIELDS_SEARCH,
		                        SORT          => $sort
		                       });

if ($users->{EXTRA_FIELDS}) {
  foreach my $line (@{ $users->{EXTRA_FIELDS} }) {
    if ($line->[0] =~ /ifu(\S+)/) {
      my $field_id = $1;
      my ($position, $type, $name)=split(/:/, $line->[1]);
     }
   }
}


  my @MULTI_ARR = ();
  my $doc_num = 0;
  


my $ext_bill = ($conf{EXT_BILL_ACCOUNT}) ? 1 : 0;
my %EXTRA    = ();
foreach my $line (@$list) {
    
    my $full_address = '';
    
    if ($ARGV->{ADDRESS2} && $line->[$users->{SEARCH_FIELDS_COUNT} + 4 - 2]) {
      $full_address  = $line->[$users->{SEARCH_FIELDS_COUNT} + 4 - 2] || '';
      $full_address .= ' ' . $line->[$users->{SEARCH_FIELDS_COUNT} + 4 - 1] || '';
      $full_address .= '/' . $line->[$users->{SEARCH_FIELDS_COUNT} + 4] || '';
     }
    else {
      $full_address  = $line->[5+$ext_bill] || '';  #/ B: $line->[6] / f: $line->[7]";
      $full_address .= ' ' .$line->[6+$ext_bill] || '';
      $full_address .= '/' . $line->[7+$ext_bill] || '';
     }
    
    my $month_fee = ($FEES_LIST_HASH{$line->[$users->{SEARCH_FIELDS_COUNT} + 5]}) ? $FEES_LIST_HASH{$line->[$users->{SEARCH_FIELDS_COUNT} + 5]} : '0.00';

    push @MULTI_ARR, { LOGIN         => $line->[0], 
    	                 FIO           => $line->[1], 
    	                 DEPOSIT       => sprintf("%.2f", $line->[2] + $month_fee),
    	                 CREDIT        => $line->[3],
  	                   SUM           => sprintf("%.2f", abs($line->[2])),
                       DISABLE       => 0,
    	                 ORDER_TOTAL_SUM_VAT => ($conf{DOCS_VAT_INCLUDE}) ? sprintf("%.2f", abs($line->[2] / ((100 + $conf{DOCS_VAT_INCLUDE} ) / $conf{DOCS_VAT_INCLUDE}))) : 0.00,
    	                 NUMBER        => $line->[8+$ext_bill]."-$m",
                       ACTIVATE      => '>=$DATE',
                       EXPIRE        => '0000-00-00',
                       MONTH_FEE     => $month_fee,
                       TOTAL_SUM     => sprintf("%.2f", abs($line->[2])),
                       CONTRACT_ID   => $line->[8+$ext_bill],
                       CONTRACT_DATE => $line->[9+$ext_bill],
                       DATE          => $DATE, 
                       FULL_ADDRESS  => $full_address,
                       SUM_LIT       => int2ml(sprintf("%.2f", abs($line->[2])), { 
  	 ONES             => \@ones,
     TWOS             => \@twos,
     FIFTH            => \@fifth,
     ONE              => \@one,
     ONEST            => \@onest,
     TEN              => \@ten,
     TENS             => \@tens,
     HUNDRED          => \@hundred,
     MONEY_UNIT_NAMES => $conf{MONEY_UNIT_NAMES} || \@money_unit_names
  	  }),

                       DOC_NUMBER => sprintf("%.6d",  $doc_num),
    	                };
    
    print "UID: LOGIN: $line->[0] FIO: $line->[1] SUM: $line->[2]\n" if ($debug > 2);

    $doc_num++
	 }

print "TOTAL: ".$users->{TOTAL};

if ($debug < 5) {
  multi_tpls(_include('docs_multi_invoice', 'Docs'), \@MULTI_ARR );
 }



if ($begin_time > 0)  {
    Time::HiRes->import(qw(gettimeofday));
    my $end_time = gettimeofday();
    my $gen_time = $end_time - $begin_time;
    printf(" GT: %2.5f\n", $gen_time);
 }



#**********************************************************
#
#**********************************************************
sub multi_tpls {
  my ($tpl, $MULTI_ARR, $attr) = @_;	
  my $tpl_name = $1 if ($tpl =~ /\/([a-zA-Z\.0-9\_]+)$/);
  
  my $single_tpl = $html->tpl_show($tpl, undef, 
                                           { MULTI_DOCS   => $MULTI_ARR, 
  	                                         SAVE_AS      => $save_filename,
  	                                         DOCS_IN_FILE => $docs_in_file,
  	                                         debug        => $debug
  	                                       }); 
}


#**********************************************************
#
#**********************************************************
sub help {

print << "[END]";	
	RESULT_DIR=    - Output dir (default: abills/cgi-bin/admin/pdf)
	DOCS_IN_FILE=  - docs in single file (default: $docs_in_file)
  ADDRESS2       - User second address (fields: _c_address, _c_build, _c_flat)
  SORT=          - Sort by 
	DEBUG=[1..5]   - Debug mode
[END]
}



1
