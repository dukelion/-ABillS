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
  %FORM
  $users

  @ones
  @twos
  @fifth
  @one
  @onest
  @ten
  @tens
  @hundred
  @money_unit_names


  $_DEBT
  $_TARIF_PLAN
  $_ACCOUNT
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
require Tariffs;
Tariffs->import();
require Dv;
Dv->import();

require Abills::HTML;
Abills::HTML->import();
$html = Abills::HTML->new({ CONF => \%conf, pdf => 1 });

my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $db = $sql->{db};
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });



require Finance;
Finance->import();
my $Fees    = Finance->fees($db, $admin, \%conf);
my $Users   = Users->new($db, $admin, \%conf);
$users = $Users;
my $Tariffs = Tariffs->new($db, $admin, \%conf);
my $Docs    = Docs->new($db, $admin, \%conf);
my $Dv      = Dv->new($db, $admin, \%conf);

require $Bin ."/../Abills/modules/Docs/lng_$conf{default_language}.pl";
require "language/$conf{default_language}.pl";

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

my %LIST_PARAMS = ();

if ($ARGV->{POSTPAID_ACCOUNT}) {
	postpaid_accounts();
 }
elsif ($ARGV->{PREPAID_ACCOUNTS}) {
	prepaid_accounts() if (! $ARGV->{COMPANY_ID});
	prepaid_accounts_company() if (! $ARGV->{LOGIN});
 }
else {
	help();
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
sub send_accounts {
  my ($attr) = @_;

  require $Bin ."/../Abills/modules/Docs/webinterface";

  foreach my $id ( @{ $attr->{ACCOUNTS_IDS} } ) {
   	$FORM{pdf}   = 1;
   	$FORM{print} = $id;

    docs_account({ GET_EMAIL_INFO    => 1,
            	     SEND_EMAIL        => 1,
            	     %$attr
                 });
    if ($debug > 3) {
    	print "ID: $id Sended\n";
     }
   }

}




#**********************************************************
#
#**********************************************************
sub prepaid_accounts {
 # Modules
 #Dv
 my @MODULES = ('Dv');


 require $MODULES[0].'.pm';
 $MODULES[0]->import();
 my $Module_name = $MODULES[0]->new($db, $admin, \%conf);
 $LIST_PARAMS{TP_ID} = $ARGV->{TP_ID} if ($ARGV->{TP_ID});
 $LIST_PARAMS{LOGIN} = $ARGV->{LOGIN} if ($ARGV->{LOGIN});
 my @accounts_ids = ();
 my $TP_LIST = get_tps();

 my $list = $Module_name->list({ 
 	                          #DEPOSIT       => '<0',
		                        DISABLE       => 0,
		                        COMPANY_ID    => 0,
                            CONTRACT_ID   => '*',
                            CONTRACT_DATE => '>=0000-00-00',
                            ADDRESS_STREET=> '*',
                            ADDRESS_BUILD => '*',
                            ADDRESS_FLAT  => '*',
                            
		                        PAGE_ROWS     => 1000000,
#		                        %INFO_FIELDS_SEARCH,
		                        SORT          => $sort,
		                        SKIP_TOTAL    => 1,
		                        %LIST_PARAMS,
		                       });

  my @MULTI_ARR = ();
  my $doc_num = 0;
  my %EXTRA    = ();

foreach my $line (@$list) {
	my $uid      = $line->[(6+$Module_name->{SEARCH_FIELDS_COUNT})];
  my $tp_id    = $line->[(9+$Module_name->{SEARCH_FIELDS_COUNT})];


 	print "UID: $uid LOGIN: $line->[0] FIO: $line->[1] TP: $tp_id / $Module_name->{SEARCH_FIELDS_COUNT}\n" if ($debug > 2);
	#Add debetor accouns
  if ($line->[2] && $line->[2] < 0) {
		print "  DEPOSIT: $line->[2]\n" if ($debug > 2);
    $Docs->account_add({ UID   => $uid,
 	  	                   SUM   => abs($line->[2]),
 	   	                   ORDER => "$_DEBT"  });
		push @accounts_ids, $Docs->{DOC_ID};
		$doc_num++
	 } 
	
	#add  tp account
  if ($TP_LIST->{$tp_id}) {
  	my ($tp_name, $fees_sum)=split(/;/, $TP_LIST->{$tp_id});
    print "  TP_ID: $tp_id FEES: $fees_sum\n" if ($debug > 2);
    $Docs->account_add({ UID   => $uid,
 	  	                   SUM   => abs($fees_sum),
 	   	                   ORDER => "$_TARIF_PLAN: $tp_name"  
 	   	                 });
    push @accounts_ids, $Docs->{DOC_ID};
    $doc_num++
   }

 }




print "TOTAL USERS: $Module_name->{TOTAL} DOCS: $doc_num\n";

if ($debug < 5) {
  send_accounts({ ACCOUNTS_IDS => \@accounts_ids });
 }
}

#**********************************************************
#
#**********************************************************
sub get_tps {
	my ($attr)=@_;
	
  #Get TPS
  my %TP_LIST=();
  my $tp_list = $Tariffs->list({ %LIST_PARAMS });
  foreach my $line (@$tp_list) {
 	  if ($line->[6] > 0) {
 	    $TP_LIST{$line->[0]}="$line->[2];$line->[6]",
 	   }
    elsif ($line->[5] > 0) {
   	  $TP_LIST{$line->[0]}="$line->[2];".($line->[5]*30); 
     }
   }

	return \%TP_LIST;
}


#**********************************************************
#
#**********************************************************
sub prepaid_accounts_company {
 # Modules
 #Dv
 require Customers;
 Customers->import();
 my $customer = Customers->new($db, $admin, \%conf);
 my $Company = $customer->company();


 require $MODULES[0].'.pm';
 $MODULES[0]->import();
 $LIST_PARAMS{TP_ID} = $ARGV->{TP_ID} if ($ARGV->{TP_ID});
 $LIST_PARAMS{LOGIN} = $ARGV->{LOGIN} if ($ARGV->{LOGIN});
 $LIST_PARAMS{COMPANY_ID} = $ARGV->{COMPANY_ID} if ($ARGV->{COMPANY_ID});

 my $TP_LIST = get_tps();
 my @accounts_ids = ();

 #$Company->{debug}=1;
 my $list = $Company->list({ 
		                        DISABLE       => 0,
#		                        COMPANY_ID    => 0,
#                            CONTRACT_ID   => '*',
#                            CONTRACT_DATE => '>=0000-00-00',
#                            ADDRESS_STREET=> '*',
#                            ADDRESS_BUILD => '*',
#                            ADDRESS_FLAT  => '*',
                            
		                        PAGE_ROWS     => 1000000,
#		                        %INFO_FIELDS_SEARCH,
		                        SORT          => $sort,
		                        SKIP_TOTAL    => 1,
		                        %LIST_PARAMS,
		                       });
  my @MULTI_ARR = ();
  my $doc_num = 0;
  my %EXTRA    = ();

foreach my $line (@$list) {
	my $name       = $line->[0];
	my $deposit    = $line->[1];
	my $company_id = $line->[5];
  
  print "COMPANY: $name CID: $company_id DEPOSIT: $deposit\n" if ($debug > 2);

  #get main user
  my $admin_user = 0;
  my $admin_user_email = '';
  my $admin_list = $Company->admins_list({ GET_ADMINS => 1 });
  
  if ($Company->{TOTAL} < 1) {
  	print "Company don't have admin user\n";
  	next;
   }
  else {
  	$admin_user = $admin_list->[0]->[4];
  	$admin_user_email = $admin_list->[0]->[3];
   }
  # make debt account
  if ($deposit < 0) {
  	$Docs->account_add({ UID   => $admin_user,
	  	                   SUM   => abs($deposit),
 	   	                   ORDER => "$_DEBT"  
	   	                 });
	  push @accounts_ids, $Docs->{DOC_ID} if ($admin_user_email ne '');
   }
  #Get company users
  my $list = $Dv->list({ 
 		                        DISABLE       => 0,
		                        COMPANY_ID    => $company_id,
		                        PAGE_ROWS     => 1000000,
#		                        %INFO_FIELDS_SEARCH,
		                        SORT          => $sort,
		                        SKIP_TOTAL    => 1,
		                        %LIST_PARAMS,
		                       });
  my $tp_sum  = 0;
  my $doc_num = 0;
  foreach my $line (@$list) {
  	my $uid      = $line->[(6+$Dv->{SEARCH_FIELDS_COUNT})];
    my $tp_id    = $line->[(9+$Dv->{SEARCH_FIELDS_COUNT})] || 0;
    my $fio      = $line->[1] || '';
    
 	  print "UID: $uid LOGIN: $line->[0] FIO: $fio TP: $tp_id\n" if ($debug > 2);
	  #Add debetor accouns
    if ($TP_LIST->{$tp_id}) {
    	my ($tp_name, $fees_sum)=split(/;/, $TP_LIST->{$tp_id});
    	$tp_sum += $fees_sum;
		  print "  DEPOSIT: $line->[2]\n" if ($debug > 2);
		  $doc_num++		  
	   }
   }
  # make tps account
  if ($tp_sum > 0) {
  	print "TP SUM: $tp_sum\n";
    $Docs->account_add({ UID   => $admin_user,
 	  	                   SUM   => abs($tp_sum),
 	   	                   ORDER => "$_TARIF_PLAN"  
 	   	                 });
 	  push @accounts_ids, $Docs->{DOC_ID} if ($admin_user_email ne '');
   }
  
 }


print "TOTAL USERS: $Company->{TOTAL} DOCS: $doc_num\n";

if ($debug < 5) {
  send_accounts({ ACCOUNTS_IDS => \@accounts_ids });
 }


}



#**********************************************************
#
#**********************************************************
sub postpaid_accounts {
  $save_filename = $pdf_result_path .'/multidoc_postpaid_accounts.pdf';
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

  $Users->{debug}=1 if ($debug > 6);
	my $list = $Users->list({ DEPOSIT       => '<0',
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

if ($Users->{EXTRA_FIELDS}) {
  foreach my $line (@{ $Users->{EXTRA_FIELDS} }) {
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
    
    if ($ARGV->{ADDRESS2} && $line->[$Users->{SEARCH_FIELDS_COUNT} + 4 - 2]) {
      $full_address  = $line->[$Users->{SEARCH_FIELDS_COUNT} + 4 - 2] || '';
      $full_address .= ' ' . $line->[$Users->{SEARCH_FIELDS_COUNT} + 4 - 1] || '';
      $full_address .= '/' . $line->[$Users->{SEARCH_FIELDS_COUNT} + 4] || '';
     }
    else {
      $full_address  = $line->[5+$ext_bill] || '';  #/ B: $line->[6] / f: $line->[7]";
      $full_address .= ' ' .$line->[6+$ext_bill] || '';
      $full_address .= '/' . $line->[7+$ext_bill] || '';
     }
    
    my $month_fee = ($FEES_LIST_HASH{$line->[$Users->{SEARCH_FIELDS_COUNT} + 5]}) ? $FEES_LIST_HASH{$line->[$Users->{SEARCH_FIELDS_COUNT} + 5]} : '0.00';

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

print "TOTAL: ".$Users->{TOTAL};

if ($debug < 5) {
  multi_tpls(_include('docs_multi_invoice', 'Docs'), \@MULTI_ARR );
 }

}



#**********************************************************
#
#**********************************************************
sub multi_tpls {
  my ($tpl, $MULTI_ARR, $attr) = @_;	
#  my $tpl_name = $1 if ($tpl =~ /\/([a-zA-Z\.0-9\_]+)$/);
  
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
Multi documents creator	
  POSTPAID_ACCOUNT - Created for previe month debetors
  PREPAID_ACCOUNTS - Create cridit account and next month payments account
  
  LOGIN            - User login
  TP_ID            - Tariff Plan
  COMPANY_ID       - Company id. if defined company id generated only companies accounts. U can use wilde card *
  
  RESULT_DIR=      - Output dir (default: abills/cgi-bin/admin/pdf)
  DOCS_IN_FILE=    - docs in single file (default: $docs_in_file)
  ADDRESS2         - User second address (fields: _c_address, _c_build, _c_flat)
  DATE=YYYY-MM-DD  - Accounts create date
  SORT=            - Sort by 
  DEBUG=[1..5]     - Debug mode
[END]
}




1
