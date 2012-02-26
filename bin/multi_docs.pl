#!/usr/bin/perl 
#
#

#use strict;

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
  $Docs

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
  @WEEKDAYS

  @MONTHES
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

use POSIX qw(strftime mktime);


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
$html = Abills::HTML->new({ CONF => \%conf, 
	                          # pdf => 1 
	                        });

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

$html->{language}=$conf{default_language};

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

require $Bin ."/../Abills/modules/Docs/webinterface";

$docs_in_file    = $ARGV->{DOCS_IN_FILE} || $docs_in_file;
my $save_filename = $pdf_result_path .'/multidoc_.pdf';

if (! -d $pdf_result_path) {
	mkdir ($pdf_result_path);
}

my %LIST_PARAMS = ();

if ($ARGV->{LOGIN}) {
	$LIST_PARAMS{LOGIN}=$ARGV->{LOGIN};
}

if ($ARGV->{POSTPAID_ACCOUNT}) {
	postpaid_accounts();
 }
elsif($ARGV->{PERIODIC_INVOICE}) {
	periodic_invoice();
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
sub periodic_invoice {
	my ($attr) = @_;
	
	my @ids = ();
	
	$Docs->{debug}=1 if ($debug > 6);
  $DATE = $ARGV->{DATE} if ($ARGV->{DATE});

  #Get period intervals for users with activate 0000-00-00	
	if (! $FORM{INCLUDE_CUR_BILLING_PERIOD}) {
 		$FORM{FROM_DATE}="$DATE";
 	 }
  
  my ($Y, $M, $D)= split(/-/, $DATE);
  my $start_period_unixtime;
  my ($TO_Y, $TO_M, $TO_D);

  
  if ($M+1 > 12) {
  	$M=1;
  	$Y++;
   }
  else {
  	$M++;
   }



  $D   = '01';
  my $NEXT_MONTH = sprintf("%4.d-%02d-%02d", $Y, $M, $D);
  $TO_D=($M!=2?(($M%2)^($M>7))+30:(!($Y%400)||!($Y%4)&&($Y%25)?29:28));

  if (($conf{SYSTEM_CURRENCY} && $conf{DOCS_CURRENCY}) 
         && $conf{SYSTEM_CURRENCY} ne $conf{DOCS_CURRENCY}) {
    my $Finance = Finance->new($db, $admin);
       
    #if ($FORM{CURRENCY} == $conf{DOCS_CURRENCY}) {
       $Finance->exchange_info(0, {  ISO => $FORM{DOCS_CURRENCY} || $conf{DOCS_CURRENCY} });
       $FORM{EXCHANGE_RATE}=$Finance->{ER_RATE};
       $FORM{DOCS_CURRENCY}=$Finance->{ISO};
    # }
  }


	my $list = $Docs->user_list({ %LIST_PARAMS,
		                            PRE_INVOICE_DATE => $DATE,
		                            DISCOUNT         => '>=0'  
		                           });
	
	    
	foreach my $line ( @$list ) {
    my %user = ( LOGIN          => $line->[0],
                 FIO            => $line->[1],
                 DEPOSIT        => $line->[2],
                 CREDIT         => $line->[3],
                 STATUS         => $line->[3],
                 INVOICE_DATE   => $line->[5],
                 NEXT_INVOICE_DATE   => $line->[6],
                 INVOICE_PERIOD => $line->[7],
                 EMAIL          => $line->[8],
                 SEND_DOCS      => $line->[9],
                 UID            => $line->[10],
                 ACTIVATE       => $line->[11],
                 DISCOUNT       => $line->[12] || 0,
                 DOCS_CURRENCY  => $conf{DOCS_CURRENCY},
                 EXCHANGE_RATE  => $FORM{EXCHANGE_RATE}
                );

    $FORM{NEXT_PERIOD}=$user{INVOICE_PERIOD};
    if ($debug > 0) {
    	print "$user{LOGIN} [$user{UID}] DEPOSIT: $user{DEPOSIT} INVOICE_DATE: $user{INVOICE_DATE} NEXT: $user{NEXT_INVOICE_DATE} SEND_DOCS: $user{SEND_DOCS} EMAIL: $user{EMAIL}\n";
     } 

    my $total_sum         = 0;
    my $total_not_invoice = 0;
    my $amount_for_pay    = 0;
    my $num               = 0;
    my %ORDERS_HASH       = ();

    # No invoicing service from last invoice
    my $list = $Docs->invoice_new({ FROM_DATE => '2011-01-01', #$user{INVOICE_DATE},
   	                                TO_DATE   => $DATE,
   	                                PAGE_ROWS => 500,
    	                              UID       => $user{UID}
    	                            });

    foreach my $line (@$list) {
       next if ($line->[5]);
       $num++;
       push @ids, $num;
       $ORDERS_HASH{"ORDER_".$num}   = "$line->[3]";
       $ORDERS_HASH{"SUM_".$num}     = "$line->[4]";
       $ORDERS_HASH{"FEES_ID_".$num} = "$line->[0]";
       $total_not_invoice           += $line->[4]; 
     }

    if ($user{ACTIVATE} ne '0000-00-00') {
      $FORM{FROM_DATE}           = $user{ACTIVATE};
      ($Y, $M, $D)               = split(/-/, $FORM{FROM_DATE}, 3);
    	$start_period_unixtime     =  (mktime(0, 0, 0, $D, ($M-1), ($Y-1900), 0, 0, 0) + 30 * 86400) ;
    	$user{INVOICE_PERIOD_START}=strftime '%Y-%m-%d',  localtime( (mktime(0, 0, 0, $D, ($M-1), ($Y-1900), 0, 0, 0) + 30 * 86400) );
    	$user{INVOICE_PERIOD_STOP} = strftime '%Y-%m-%d',  localtime( (mktime(0, 0, 0, $D, ($M-1), ($Y-1900), 0, 0, 0) + 30 * 86400) );
    	($Y, $M, $D)=split(/-/, $user{INVOICE_PERIOD_START}, 3);
     }
    else {
    	$user{INVOICE_PERIOD_START}=$NEXT_MONTH;
     }

    #Next period payments
    if ($FORM{NEXT_PERIOD}) {
  	  # Get invoces
   	  my %current_invoice = ();
 	    my $list = $Docs->invoices_list({ UID         => $FORM{UID}, 
 	    	                                PAYMENT_ID  => 0, 
 	    	                                ORDERS_LIST => 1 
 	    	                              });
    	
   	  foreach my $line (@$list) {
    		$current_invoice{$line->[1]}=$line->[0];
 	     }

      $FORM{UID}=$user{UID};
      
 	    my $cross_modules_return = cross_modules_call('_docs', { %user, SKIP_MODULES => 'Docs,Multidoms,BSR1000,Snmputils,Ipn' });
      my $next_period = $FORM{NEXT_PERIOD};
      if ($user{ACTIVATE} ne '0000-00-00') {
  	 	  ($Y, $M, $D)=split(/-/, strftime "%Y-%m-%d", localtime( (mktime(0, 0, 0, $D, ($M-1), ($Y-1900), 0, 0, 0) + 
  	 	  (( ($start_period_unixtime > time) ? 0 : 1 ) +30 *(($start_period_unixtime > time)?0:1)) * 86400) )); 
        $FORM{FROM_DATE}="$Y-$M-$D";

        ($Y, $M, $D)=split(/-/, strftime "%Y-%m-%d", localtime( (mktime(0, 0, 0, $D, ($M-1), ($Y-1900), 0, 0, 0) + 
        ( (($start_period_unixtime > time) ? 1 : ( 1*$next_period-1 )) +  30 * (($start_period_unixtime > time) ? 1 : $next_period) )  * 86400) )); 
        $FORM{TO_DATE}="$Y-$M-$D";
       }
      else {
      	$FORM{FROM_DATE}=$NEXT_MONTH; 
#        $M+=1;
# 	      if ($M < 12) {
#  	      $M=sprintf("%02d", $M);
#  	     }
#        else {
#          $M = sprintf("%02d", $M-12);
#          $Y++;
#         }
#        $FORM{FROM_DATE} = "$Y-$M-$D";
#
#        $M+=$next_period-1;
# 	      if ($M < 12) {
#  	      $M=sprintf("%02d", $M);
#  	     }
#        else {
#          $M = sprintf("%02d", $M-13);
#          $Y++;
#         }
#      
#       if ($users->{ACTIVATE} eq '0000-00-00') {      
#         $TO_D=($M!=2?(($M%2)^($M>7))+30:(!($Y%400)||!($Y%4)&&($Y%25)?29:28));
#        }
#       else {
#     	   $TO_D=$D;
#        }
#
#       $FORM{TO_DATE} = "$Y-$M-$TO_D";
      }
#
 	 	 	my $period_from = $FORM{FROM_DATE};
      my $period_to   = $FORM{FROM_DATE}; 
     
 	    foreach my $module (sort keys %$cross_modules_return) {
 	 	   if (ref $cross_modules_return->{$module} eq 'ARRAY') {
 	 	 	   next if ( $#{ $cross_modules_return->{$module} } == -1 );

 	 	 	   foreach my $line ( @{ $cross_modules_return->{$module} } ) {
 	 	 	     my ($name, $describe, $sum)=split(/\|/, $line);
 	 	 	 	   next if ($sum < 0);
 	 	 	   	 $period_from = $FORM{FROM_DATE};
 	 	 	   	 
 	 	 	   	 for (my $i=($FORM{NEXT_PERIOD}==-1) ? -2 : 0; $i<int($FORM{NEXT_PERIOD}); $i++) {
 	 	 	 	     my $result_sum = sprintf("%.2f", $sum);
 	 	 	 	   
 	 	 	 	     if ($user{DISCOUNT} && $module ne 'Abon') {
 	 	 	 	   	   $result_sum = sprintf("%.2f",  $sum * (100 - $user{DISCOUNT}) / 100);
 	 	 	 	      }
 	 	 	 	     

             my ($Y, $M, $D) = split(/-/, $period_from, 3);
             if ($user{ACTIVATE} ne '0000-00-00') {
  	 	         ($Y, $M, $D)=split(/-/, strftime "%Y-%m-%d", localtime( (mktime(0, 0, 0, $D, ($M-1), ($Y-1900), 0, 0, 0)))); #+ (31 * $i) * 86400) )); 
               $period_from="$Y-$M-$D";

               ($Y, $M, $D)=split(/-/, strftime "%Y-%m-%d", localtime( (mktime(0, 0, 0, $D, ($M-1), ($Y-1900), 0, 0, 0) + (30) * 86400) )); 
               $period_to="$Y-$M-$D";
              }
             else { 
               $M+=1 if ($i>0);
 	             if ($M < 12) {
  	             $M=sprintf("%02d", $M);
  	            }
               else {
                 $M = sprintf("%02d", $M-12);
                 $Y++;
                } 
               $period_from = "$Y-$M-01";

               #$M+=1;
 	             if ($M < 12) {
  	             $M=sprintf("%02d", $M);
  	            }
               else {
                 $M = sprintf("%02d", $M-13);
                 $Y++;
                }
      
               if ($user{ACTIVATE} eq '0000-00-00') {      
                 $TO_D=($M!=2?(($M%2)^($M>7))+30:(!($Y%400)||!($Y%4)&&($Y%25)?29:28));
                }
               else {
     	           $TO_D=$D;
                }

               $period_to = "$Y-$M-$TO_D";
              }
 	 	 	 	     
 	 	 	 	     my $order = "$name $describe($period_from-$period_to)";
	 	 	   	   $user{INVOICE_PERIOD_STOP}=$period_to;
 	 	         if ( ! $current_invoice{$order}) {
 	 	         	 $num++;
 	 	         	 push @ids, $num;
 	 	           $ORDERS_HASH{'ORDER_'.$num}= $order;
 	           	 $ORDERS_HASH{'SUM_'.$num}  = $result_sum;
 	           	 $total_sum	               += $result_sum;
 	 	          }

 	 	         $period_from = strftime "%Y-%m-%d", localtime( (mktime(0, 0, 0, $D, ($M-1), ($Y-1900), 0, 0, 0) + 1 * 86400) );
           }
 	 	      } 
 	 	    }
 	     }
    }

    
    $amount_for_pay  = ($total_sum<$user{DEPOSIT}) ? 0 : $total_sum-$user{DEPOSIT};
    $total_sum      += $total_not_invoice;
    $ORDERS_HASH{IDS}=join(', ', @ids);

    if ($debug > 1) {
      print "$user{LOGIN}: Invoice period: $user{INVOICE_PERIOD_START} - $user{INVOICE_PERIOD_STOP}\n";
      for (my $i=1; $i<=$num; $i++) {
        print "$i|".  $ORDERS_HASH{'ORDER_'.$i} ."|". $ORDERS_HASH{'SUM_'.$i} ."| ". ($ORDERS_HASH{'FEES_ID_'.$i} || '') ."\n";
       }
      print "Total: $num  SUM: $total_sum Amount to pay: $amount_for_pay\n";
     }


    $Docs->{FROM_DATE} = $html->date_fld2('FROM_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'invoice_add', WEEK_DAYS => \@WEEKDAYS });
    $Docs->{TO_DATE}   = $html->date_fld2('TO_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'invoice_add', WEEK_DAYS => \@WEEKDAYS });
    $FORM{NEXT_PERIOD} = 0 if ($FORM{NEXT_PERIOD} < 0);

#Add to DB
    if ($num > 0) {
    	if ($debug < 5) {
		    $Docs->invoice_add({ %user, %ORDERS_HASH });		
		    $Docs->user_change({ UID          => $user{UID}, 
		    	                   INVOICE_DATE => $user{INVOICE_PERIOD_START}, 
		    	                   CHANGE_DATE  => 1
		    	                  });
		    #Sendemail		    
        
        if ($user{SEND_DOCS}) {
        	$FORM{print} = $Docs->{DOC_ID};
          docs_invoice({ GET_EMAIL_INFO    => 1,
                         SEND_EMAIL        => $user{SEND_DOCS} || 0, 
                         UID               => $user{UID}
              	         #%$attr
            	         });
         }
		   }
		 }
	 }
}


#**********************************************************
# Calls function for all registration modules if function exist 
#
# HASH_REF = cross_modules_call(function_sufix, attr) 
#
# return HASH_REF
#   MODULE -> return
#**********************************************************
sub cross_modules_call {
  my ($function_sufix, $attr) = @_;

  my %full_return  = ();
  my @skip_modules = ();
  
  if ($attr->{SKIP_MODULES}) {
  	$attr->{SKIP_MODULES}=~s/\s+//g;
  	@skip_modules=split(/,/, $attr->{SKIP_MODULES});
   }

  foreach my $mod (@MODULES) {
  	if (in_array($mod, \@skip_modules)) {
  		next;
  	 }
    load_module("$mod", $html);

    my $function = \&{ lc($mod).$function_sufix };
    
    my $return;
    if (defined(&$function)) {
     	$return = $function->($attr);
     }
    $full_return{$mod}=$return;
   }

  return \%full_return;
}


#**********************************************************
# load_module($string, \%HASH_REF);
#**********************************************************
sub load_module {
	my ($module, $attr) = @_;

	my $lang_file = '';
  foreach my $prefix (@INC) {
    my $realfilename = "$prefix/Abills/modules/$module/lng_$attr->{language}.pl";
    if (-f $realfilename) {
      $lang_file =  $realfilename;
      last;
     }
    elsif (-f "$prefix/Abills/modules/$module/lng_english.pl") {
    	$lang_file = "$prefix/Abills/modules/$module/lng_english.pl";
     }
   }

  if ($lang_file ne '') {
    require $lang_file;
   }

 	require "Abills/modules/$module/webinterface";

	return 0;
}
































#**********************************************************
#
#**********************************************************
sub send_accounts {
  my ($attr) = @_;

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
  my %EXTRA    = ();
  my $doc_num = 0;

foreach my $line (@$list) {
	my $uid      = $line->[(6+$Module_name->{SEARCH_FIELDS_COUNT})];
  my $tp_id    = $line->[(9+$Module_name->{SEARCH_FIELDS_COUNT})];


 	print "UID: $uid LOGIN: $line->[0] FIO: $line->[1] TP: $tp_id / $Module_name->{SEARCH_FIELDS_COUNT}\n" if ($debug > 2);

  $Docs->user_info($uid);
  if (! $Docs->{PERIODIC_CREATE_DOCS} ) {
  	print "Skip create docs\n" if ($debug > 2);
  	next;
   }

  %FORM = (
           UID       => $uid,
 	         create    => 1,
 	         SEND_EMAIL=> $Docs->{SEND_DOCS},
 	         pdf       => 1,
 	         CUSTOMER  => '-',
 	         EMAIL     => $Docs->{EMAIL}
 	         );


	#Add debetor accouns
  if ($line->[2] && $line->[2] < 0) {
		print "  DEPOSIT: $line->[2]\n" if ($debug > 2);
		$FORM{SUM}  =abs($line->[2]);
    $FORM{ORDER}="$_DEBT";
    docs_account({ QUITE => 1 });
	 } 
	
	#add  tp account
  if ($TP_LIST->{$tp_id}) {
  	my ($tp_name, $fees_sum)=split(/;/, $TP_LIST->{$tp_id});
    print "  TP_ID: $tp_id FEES: $fees_sum\n" if ($debug > 2);
		$FORM{SUM}  =$fees_sum;
    $FORM{ORDER}="$_TARIF_PLAN";
    docs_account({ QUITE => 1 });	         
   }

 }
print "TOTAL USERS: $Module_name->{TOTAL} DOCS: $doc_num\n";
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

 my $list = $Company->list({ 
		                        DISABLE       => 0,
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
  #Check month periodic
  $Docs->user_info($admin_user);
  if (! $Docs->{PERIODIC_CREATE_DOCS} ) {
  	print "Skip create docs\n" if ($debug > 2);
  	next;
   }

  %FORM = (
           UID       => $admin_user,
   	       create    => 1,
   	       SEND_EMAIL=> $Docs->{SEND_DOCS},
   	       pdf       => 1,
   	       CUSTOMER  => '-',
   	       EMAIL     => $Docs->{EMAIL}
   	      );

   
  # make debt account
  if ($deposit < 0) {
    $FORM{SUM}= abs($deposit);
    $FORM{ORDER}="$_DEBT";
    docs_account({ QUITE => 1 });
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
    $FORM{SUM}= $tp_sum;
    $FORM{ORDER}="$_TARIF_PLAN";
    docs_account({ QUITE => 1 });	         
   }
 }


print "TOTAL USERS: $Company->{TOTAL} DOCS: $doc_num\n";
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
  PERIODIC_INVOICE - Create periodic invoice for clients
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
