#!/usr/bin/perl
# Ureports sender
use vars  qw(%RAD %conf $db %AUTH $DATE $TIME $var_dir
%ADMIN_REPORT
%LIST_PARAMS
$DEBUG

);
#use strict;


my $debug = 0;

use FindBin '$Bin';
require $Bin . '/config.pl';
unshift(@INC, $Bin . '/../', $Bin . "/../Abills/$conf{dbtype}");
require Abills::Base;
Abills::Base->import();
require Abills::HTML;
Abills::HTML->import();
my $html = Abills::HTML->new( { IMG_PATH => 'img/',
	                     NO_PRINT => 1,
	                     CONF     => \%conf,
	                     CHARSET  => $conf{default_charset}
	                    });

my $begin_time = check_time();

require Abills::SQL;
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db  = $sql->{db};



require Dv;
Dv->import();
require Dv_Sessions;
Dv_Sessions->import();
require Finance;
Finance->import();
require Fees;
Fees->import();
require Ureports;
Ureports->import();
#use Shedule;
require Tariffs;
Tariffs->import();
require Admins;
Admins->import();
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });


my $Ureports = Ureports->new($db, $admin, \%conf);
my $fees     = Fees->new($db, $admin, \%conf);
my $tariffs  = Tariffs->new($db, \%conf, $admin);

require $Bin ."/../language/$html->{language}.pl";
require $Bin ."/../Abills/modules/Ureports/lng_$html->{language}.pl";

my %FORM_BASE = ();
my @service_status = ( "$_ENABLE", "$_DISABLE", "$_NOT_ACTIVE" );
my @service_type = ( "E-mail", "SMS", "Fax" );
my %REPORTS = ( 1 => "$_DEPOSIT_BELOW",       
                2 => "$_PREPAID_TRAFFIC_BELOW",
                3 => "$_TRAFFIC_BELOW",
                4 => "$_MONTH_REPORT",
             );

use POSIX qw(strftime);


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


my $debug_output = ureports_periodic_reports({ %$ARGV });

print $debug_output;


#**********************************************************
# ureports_send_reports
#**********************************************************
sub ureports_send_reports {
  my ($type, $destination, $message, $attr)=@_;

  if ($type == 0) {
  	my $subject = $attr->{SUBJECT} || '';
  	if (! sendmail($conf{ADMIN_MAIL}, $destination, $subject, $message, $conf{MAIL_CHARSET})) {

  		 return 0;
  	 }
   }
  elsif($type == 1) {
  	if ($conf{UREPORTS_SMS_CMD}) {
  	  my $cmd = `$conf{UREPORTS_SMS_CMD} $destination $message`;
  	 }
   }
  elsif($type == 2) {
  	
   }
 
 
 
  return 1;
}

#**********************************************************
# ureports_periodic_reports
#**********************************************************
sub ureports_periodic_reports {
  my ($attr) =@_;

	my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

 $debug_output .= "Ureports: Daily spool former\n" if ($debug > 1);

 $LIST_PARAMS{MODULE}='Ureports';
 $LIST_PARAMS{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID});

 my %SERVICE_LIST_PARAMS = ();
 $SERVICE_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});

  my $list = $tariffs->list({ %LIST_PARAMS });
 $ADMIN_REPORT{DATE}=$DATE if (! $ADMIN_REPORT{DATE});

 foreach my $line (@$list) {
     my $TP_ID = $line->[0];
     my %TP_INFO = ();
     $TP_INFO{POSTPAID}   = $line->[12];
     $TP_INFO{REDUCTION}  = $line->[11];


 	   $debug_output .= "TP ID: $TP_ID DF: $line->[5] MF: $line->[6] POSTPAID: $TP_INFO{POSTPAID_DAILY} REDUCTION: $TP_INFO{REDUCTION} EXT_BILL: $line->[13] CREDIT: $line->[14]\n" if ($debug > 1);

     #Get users
 	   my $ulist = $Ureports->tp_user_reports_list({
         DATE      => '0000-00-00',
         TP_ID     => $TP_ID,
         SORT      => 1,
         PAGE_ROWS => 1000000,
         REPORT_ID => '',
         %SERVICE_LIST_PARAMS
 	   	 });


     foreach my $u (@$ulist) {
     	 #Check bill id and deposit 
     	 my %user = (
     	  REPORT_ID        => $u->[0],
     	  DESTINATION_TYPE => $u->[1],
     	  DESTINATION_ID   => $u->[2],
 	      VALUE            => $u->[3],
 	      MSG_PRICE        => $u->[4],
 	      DEPOSIT          => $u->[5], 
 	      CREDIT           => $u->[6],
 	      FIO              => $u->[7],
 	      UID              => $u->[8],
 	      BILL_ID          => $u->[9],
 	      TP_ID            => $TP_ID 
     	 ); 




       if ($user{BILL_ID} > 0 && defined($user{DEPOSIT})) {
         if ($user{REPORT_ID} == 1) {
         	 if ($user{VALUE} > $user{DEPOSIT}) {
         	 	 if ($user{MSG_PRICE} > 0 && $user{DEPOSIT} + $user{CREDIT} < 0 && $TP_INFO{POSTPAID}  == 0) {
         	 	 	  $debug_output .= "UID: $user{UID} REPORT_ID: $user{REPORT_ID} DEPOSIT: $user{DEPOSIT}/$user{CREDIT} Small Deposit\n" if ($debug > 0);
         	 	 	  next;
         	 	  }

         	 	 ureports_send_reports($user{DESTINATION_TYPE}, 
         	 	                       $user{DESTINATION_ID}, 
         	 	                       "$_DEPOSIT: $user{DEPOSIT}", 
         	 	                       { SUBJECT => "$_DEPOSIT_BELOW" });
         	 	 
         	 	 $Ureports->tp_user_reports_update({ UID       => $user{UID},
         	 	 	                                   REPORT_ID => $user{REPORT_ID} 
         	 	 	                                });
         	 	     
         	 	 if ($user{MSG_PRICE} > 0) {
               $sum = $user{MSG_PRICE};

         	 	 	
         	 	 	 my %PARAMS = ( 
               DESCRIBE => "$_REPORTS ($user{REPORT_ID}) ",
               DATE     => "$ADMIN_REPORT{DATE} $TIME",
               METHOD   => 1 );


             if ($debug > 4) {
                $debug_output .= " UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
              }
             else {

               $fees->take(\%user, $sum, { %PARAMS } );
               if ($fees->{errno}) {
               	 print "Error: [$fees->{errno}] $fees->{errstr} ";
               	 if ($fees->{errno} == 14 ) {
               	 	 print "[ $user{UID} ] $user{LOGIN} - Don't have money account";
               	  }
               	 print "\n";
               	}
               elsif($debug > 0) {
               	 $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n" if ($debug > 0);
                 #$debug_output .= " UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
                }
              }

         	 	 	
         	 	  }	
         	 	 $debug_output .= "UID: $user{UID} REPORT_ID: $user{REPORT_ID} DESTINATION_TYPE: $user{DESTINATION_TYPE} DESTINATION: $user{DESTINATION_ID}\n" if ($debug > 0);
         	 	 
       	 	   $Ureports->log_add({ 
             	 DESTINATION => $user{DESTINATION_ID},
   	           BODY        => '',
   	           UID         => $user{UID},
   	           TP_ID       => $user{TP_ID},
  	           REPORT_ID   => $user{REPORT_ID},
  	           STATUS      => 0
  	         });

         	  }
          }
        }
       else {
       	  print "[ $user{UID} ] $user{LOGIN} - Don't have money account\n";
        }

      }
  }


  $DEBUG .= $debug_output;
  return $debug_output;
}



#**********************************************************
# monthly_fees
# Extended parameters  
# TP_ID - Make periodic only for  TP_ID
# LOGIN - Make periodic only for user. You can use wildcard (*)
#**********************************************************
sub ureports_periodic_monthly {
 my ($attr) = @_;

 my $debug = $attr->{DEBUG} || 0;
 my $debug_output = '';
 $debug_output .= "DV: Monthly periodic payments\n" if ($debug > 1);
 
 
 require Users;
 Users->import();
 
 $LIST_PARAMS{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID});
 my %DV_LIST_PARAMS = ();
 $DV_LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});

 my $users = Users->new($db, $admin, \%conf); 
 my $list = $tariffs->list({ %LIST_PARAMS });


 $ADMIN_REPORT{DATE}=$DATE if (! $ADMIN_REPORT{DATE});
 my ($y, $m, $d)=split(/-/, $ADMIN_REPORT{DATE}, 3);
 my $days_in_month=($m!=2?(($m%2)^($m>7))+30:(!($y%400)||!($y%4)&&($y%25)?29:28));

 $m--;
 my $date_unixtime =  mktime(0, 0, 0, $d, $m, $y - 1900, 0, 0, 0);

 #Get Preview month begin end days
 if ($m == 0) {
   $m = 12;
   $y--;
  }

 $m = sprintf("%02.d", $m);
 my $days_in_pre_month=($m!=2?(($m%2)^($m>7))+30:(!($y%400)||!($y%4)&&($y%25)?29:28));

 my $pre_month_begin = "$y-$m-01";
 my $pre_month_end = "$y-$m-$days_in_pre_month";
 $START_PERIOD_DAY = ($conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} : 1;

 foreach my $line (@$list) {
   my %TP_INFO     = ();
 	 my $TP_ID       = $line->[0];
 	 my $min_use_sum = $line->[16];
 	 my $abon_distrib= $line->[17];
 	 my $postpaid    = $line->[4];
   my $month_fee   = $line->[6];
   my $activate_date = "<='$ADMIN_REPORT{DATE}'";

   $TP_INFO{POSTPAID_MONTHLY} = $line->[13];
   $TP_INFO{REDUCTION}        = $line->[11];

   my %used_traffic = ();
  
   #Monthfee & min use
 	 if ($month_fee > 0 || $min_use_sum > 0) {
 	   $debug_output .= "TP ID: $line->[0] MF: $line->[6] POSTPAID: $TP_INFO{POSTPAID_MONTHLY} REDUCTION: $TP_INFO{REDUCTION} EXT_BILL_ID: $line->[14] CREDIT: $line->[15] MIN_USE: $min_use_sum ABON_DISTR: $abon_distrib\n" if ($debug > 1);

 	   #get used  traffic for min use functions
 	   my %processed_users = ();
     if ($min_use_sum > 0 ) {
       next if ($d != $START_PERIOD_DAY && ! $conf{DV_MIN_USER_FULLPERIOD});
       my $interval = "$pre_month_begin/$pre_month_end";
       
       if ($conf{DV_MIN_USER_FULLPERIOD}) {
       	 $activate_date = strftime "%Y-%m-%d", localtime($date_unixtime - 86400 * 30);
       	 $interval      = "$activate_date/$ADMIN_REPORT{DATE}";
       	 $activate_date = "='$activate_date'";
        }
       
       my $report_list = $sessions->reports({ 
                     INTERVAL   => $interval,
                     TP_ID      => $TP_ID,
	   	              });
	  
	     foreach my $l (@$report_list) {
 	  	   $used_traffic{$l->[7]}=$l->[6];
        }
      }

     if ($abon_distrib) {
     	 $month_fee = $month_fee / $days_in_month;
      }    
     
	   my $ulist = $Ureports->list({ 
         ACTIVATE     => $activate_date,
         EXPIRE       => ">'$ADMIN_REPORT{DATE}'",
         STATUS       => 0,
         LOGIN_STATUS => 0,
         TP_ID        => $TP_ID,
         SORT         => 1,
         PAGE_ROWS    => 1000000,
         TP_CREDIT    => '>=0',
         %DV_LIST_PARAMS
 	   	 });
 
     my $extfield_count = $Ureports->{SEARCH_FIELDS_COUNT};

     foreach my $u (@$ulist) {
       my %user = (
            LOGIN      => $u->[0],  
            UID        => $u->[6+ $extfield_count],
            BILL_ID    => ($line->[14] > 0) ? $u->[14 + $extfield_count] : $u->[12 + $extfield_count],
            REDUCTION  => $u->[13 + $extfield_count],
            ACTIVATE   => $u->[10 + $extfield_count],
            DEPOSIT    => $u->[2],
            CREDIT     => ($u->[3] > 0) ? $u->[3] : $line->[7],
            COMPANY_ID => $u->[7 + $extfield_count]
           );

       $debug_output .= " Login: $user{LOGIN} ($user{UID}) TP_ID: ". ($u->[9 +$extfield_count ]  ) ." Fees: $line->[6] REDUCTION: $user{REDUCTION} DEPOSIT: $u->[2] CREDIT $user{CREDIT} ACTIVE: $user{ACTIVATE} TP: $u->[11]\n" if ($debug > 3); 	

      
       if (($user{BILL_ID} && $user{BILL_ID} > 0) && defined($user{DEPOSIT})) {
         my %FEES_PARAMS = (
                            DATE     => $ADMIN_REPORT{DATE},
                            METHOD   => 1 );  

       
         my $sum = 0;
         
         #***************************************************************
         #Min use Makes only 1 of month
         if ($min_use_sum > 0) {
           
           next if ($d != $START_PERIOD_DAY && ! $conf{DV_MIN_USER_FULLPERIOD});
           #Check activation dae
           my $min_use = $min_use_sum;

           if ($user{REDUCTION} > 0) {
             $min_use = $min_use * (100 - $user{REDUCTION}) / 100;
            }

           #Min use Alignment
           if (! $conf{DV_MIN_USER_FULLPERIOD} && $user{ACTIVATE} ne '0000-00-00') {
             	 my ($activated_y, $activated_m, $activated_d)=split(/-/, $user{ACTIVATE}, 3);
             	 my $days_in_month=($activated_m!=2?(($activated_m%2)^($activated_m>7))+30:(!($activated_y%400)||!($activated_y%4)&&($activated_y%25)?29:28)); 
     	         $min_use = sprintf("%.2f", $min_use / $days_in_month * ($days_in_month - $activated_d + $START_PERIOD_DAY));
           	}

           my $used = ($used_traffic{$user{UID}}) ? $used_traffic{$user{UID}} : 0;
           $FEES_PARAMS{DESCRIBE}="$_MIN_USE"; 
           #summary for all company users with same tarif plan
           if ($user{COMPANY_ID}>0 && $processed_users{$user{COMPANY_ID}}) {
           	 next;
            }

           if ($user{COMPANY_ID} > 0) {
             my $company_users = $Ureports->list({ TP_ID      => $TP_ID,
                                             COMPANY_ID => $user{COMPANY_ID}
         	                                  });
             my @UIDS = ();
             foreach my $c_user ( @$company_users ) {
         	      push @UIDS, $c_user->[0];
         	      $used += $used_traffic{$user{UID}} if ($used_traffic{$user{UID}});
         	      $processed_users{$user{COMPANY_ID}}++;
              }

             $min_use = $min_use * $processed_users{$user{COMPANY_ID}};
             $FEES_PARAMS{DESCRIBE} .= "$_COMPANY $_LOGINS: ". join(', ', @UIDS);
            }

           #Get Fees sum for min_user
           if ($conf{MIN_USE_FEES_CONSIDE})	{
       	     $fees->list({ UID     => $user{UID},
       	     	             DATE    => ($user{ACTIVATE} ne '0000-00-00') ? ">=$user{ACTIVATE}" : $DATE,
       	     	             METHODS => "$conf{MIN_USE_FEES_CONSIDE}" 
       	     	             });
       	     $used += $fees->{SUM} if ($fees->{SUM});
            }

           $debug_output .=  "  USED: $used\n" if ($debug > 3);
           #Make payments
           next if ($used >= $min_use);

           $sum = $min_use - $used;
           if ($TP_INFO{REDUCTION} == 1 && $user{REDUCTION} > 0) {
             $sum = $sum * (100 - $user{REDUCTION}) / 100;
            }
           
           
           if($postpaid == 1 || $user{DEPOSIT} + $user{CREDIT} > 0 || $TP_INFO{POSTPAID_MONTHLY} == 1) {
              
              if ($d == $START_PERIOD_DAY) {
                if ($debug > 4) {
                  $debug_output .= " UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
                 }
                else {
                  $fees->take(\%user, $sum, { %FEES_PARAMS } );  

                  $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n" if ($debug > 0);
                  if ( $user{ACTIVATE} ne '0000-00-00') {
                    $users->change($user{UID}, { 
         	                        UID      => $user{UID},
        	                        ACTIVATE => '0000-00-00' });
        	          }
                 }
               }
             }
           
                  
 
          }
         #***************************************************************
         #Month Fee
         else {
           #Make sum 
           $sum = $month_fee;
    
           if ($TP_INFO{REDUCTION} == 1 && $user{REDUCTION} > 0) {
             $sum = $sum * (100 - $user{REDUCTION}) / 100;
            }


           #If deposit is above-zero or TARIF PALIN is POST PAID or PERIODIC PAYMENTS is POSTPAID
           
           if($postpaid == 1 || $user{DEPOSIT} + $user{CREDIT} > 0 || $TP_INFO{POSTPAID_MONTHLY} == 1){

              #take fees in first day of month
              $FEES_PARAMS{DESCRIBE}="$_MONTH_FEE ($TP_ID)";  
              
              $FEES_PARAMS{DESCRIBE} .= " - $_ABON_DISTRIBUTION" if ($abon_distrib);

             # If activation set to monthly fees taken throught 30 days
              if($user{ACTIVATE} ne '0000-00-00') {
   	            my ($activate_y, $activate_m, $activate_d)=split(/-/, $user{ACTIVATE}, 3);
                $activate_m--;
                my $active_unixtime =  mktime(0, 0, 0, $activate_d, $activate_m, $activate_y - 1900, 0, 0, 0);
                if ($date_unixtime - $active_unixtime > 30 * 86400) {
                  if ($debug > 4) {
                    $debug_output .= " $user{LOGIN} UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
                   }
                  else {
                    $fees->take(\%user, $sum, { %FEES_PARAMS } );
                    $debug_output .= " $user{LOGIN} UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION} CHANGE ACTIVATE\n" if ($debug > 0);
                    if ($fees->{errno}) {
                    	print "Error: [$fees->{errno}] $fees->{errstr} ";
                    	if ($fees->{errno} == 14 ) {
                 	 	    print "UID: $user{UID} LOGIN: $user{LOGIN} - Don't have money account";
               	       }
               	      print "\n";
               	     }
                    else {
                      $users->change($user{UID}, { 
                	                        UID      => $user{UID},
                	                        ACTIVATE => $ADMIN_REPORT{DATE} } 
                 	             );
                     }
                   }
                 }
                elsif ($abon_distrib) {
                	$fees->take(\%user, $sum, { %FEES_PARAMS } );
                  $debug_output .= " $user{LOGIN} UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION} CHANGE ACTIVATE\n" if ($debug > 0);
                 }
                 #print "   $user{LOGIN} $line->[6] $user{DEPOSIT} $USER{CREDIT} $u->[10] - $u->[11]\n"; 	
               }
              elsif (($user{ACTIVATE} eq '0000-00-00' and $d == $START_PERIOD_DAY) || $abon_distrib) {

                if ($debug > 4) {
                  $debug_output .= " UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n";
                 }
                else {
                  $fees->take(\%user, $sum, { %FEES_PARAMS } );  
                  $debug_output .= " $user{LOGIN}  UID: $user{UID} SUM: $sum REDUCTION: $user{REDUCTION}\n" if ($debug > 0);
                 }
               }

             }
         
          }
        }
       else {
       	 my $ext = ($line->[14] > 0) ? 'Ext bill' : '';
      	 print "UID: $user{UID} LOGIN: $user{LOGIN} Don't have $ext money account\n";
        }
 	  }
  }
}


#=====================================

#Make traffic recalculation for expration
if ($d == 1) {
  $list = $tariffs->list({ %LIST_PARAMS });
  $debug_output .= "Total month price\n";
  require Billing;
  Billing->import();
  my $Billing = Billing->new($db, $CONF);

  #my %$processed_users = ();
  
  foreach my $tp_line (@$list) {
     my $ti_list = $tariffs->ti_list({ TP_ID => $tp_line->[0] });
     next if ($tariffs->{TOTAL} != 1);

     foreach my $ti (@$ti_list) {

       my $tt_list = $tariffs->tt_list({ TI_ID => $ti->[0] });
       next if ($tariffs->{TOTAL} != 1);
       
       my %expr_hash = ();
     	 foreach my $tt ( @$tt_list ) {
     	 	 my $expression = $tt->[8];
     	 	 next if ($expression !~ /MONTH_TRAFFIC_/);
         
         $expression =~ s/MONTH_TRAFFIC/TRAFFIC/g;

         $debug_output .= "TP: $tp_line->[0] TI: $ti->[0] TT: $tt->[0]\n";
         $debug_output .= "  Expr: $expression\n" if ($debug > 3);
         
         $expr_hash{$tt->[0]} = $expression;
         

     	  }

       next if (! defined($expr_hash{0}));

   	   $ulist = $Ureports->list({ 
           ACTIVATE   => "<='$ADMIN_REPORT{DATE}'",
           EXPIRE     => ">'$ADMIN_REPORT{DATE}'",
           STATUS     => 0,
           LOGIN_STATUS => 0,
           TP_ID      => $tp_line->[0],
           SORT       => 1,
           PAGE_ROWS  => 1000000,
           TP_CREDIT  => '>=0',
           COMPANY_ID => '>=0',
 	     	 });

       my $extfield_count = $Ureports->{SEARCH_FIELDS_COUNT};
       foreach my $u (@$ulist) {

         %user = (
            LOGIN      => $u->[0],  
            UID        => $u->[6+ $extfield_count],
            BILL_ID    => ($tp_line->[13] > 0) ? $u->[14 + $extfield_count] : $u->[12 + $extfield_count],

            REDUCTION  => $u->[13 + $extfield_count],
            ACTIVATE   => $u->[10 + $extfield_count],
            DEPOSIT    => $u->[2],
            CREDIT     => ($u->[3] > 0) ? $u->[3] : $line->[7],
            COMPANY_ID => $u->[7 + $extfield_count]
           );

         $debug_output .= " Login: $u->[0] ($u->[8])  TP_ID: $u->[11] Fees: - REDUCTION: $u->[15] $u->[2] $u->[3] $u->[10] - $user{ACTIVATE}\n" if ($debug > 3); 	

#Summary for company users
#         my @UIDS  = ();
#         if ($$processed_users{$user{COMPANY_ID}}) {
#         	 next;
#          }
#
#         if ($user{COMPANY_ID}) {
#           my $company_users = $ulist = $Ureports->list({ TP_ID      => $tp_line->[0],
#                                                    COMPANY_ID => $user{COMPANY_ID}
#         	                                        });
#           $$processed_users{$user{COMPANY_ID}}=1;
#         
#           foreach my $c_user ( @$company_users ) {
#         	    push @UIDS, $c_user->[7];
#            }
#
#           print "$user{LOGIN} hello $user{COMPANY_ID} // ";
#           print @UIDS ,"\n";
#          }

         $Billing->{PERIOD_TRAFFIC}=undef;
         my $RESULT = $Billing->expression($user{UID}, \%expr_hash, 
                                                          { START_PERIOD => $user{ACTIVATE},
  	                                                        debug        => 0,
  	                                                        #UIDS         => ($#UIDS > -1) ? join(',', @UIDS) : '',
  	                                                        #ACCOUNTS_SUMMARY => $#UIDS+1
  	                                                        });
  	                                                        
         my $message = '';
         my $sum     = 0;
 
         my %FEES_PARAMS = (
                            DATE     => $ADMIN_REPORT{DATE},
                            METHOD   => 0 );  

         if ($RESULT->{TRAFFIC_IN}) {
         	 $FEES_PARAMS{DESCRIBE} = "$_USED $_TRAFFIC: $RESULT->{TRAFFIC_IN} SUM: $RESULT->{PRICE_IN}";
         	 $sum     = $RESULT->{TRAFFIC_IN} * $RESULT->{PRICE_IN};
          }

         if ($RESULT->{TRAFFIC_OUT}) {
         	 $FEES_PARAMS{DESCRIBE} = "$_USED $_TRAFFIC: $RESULT->{TRAFFIC_OUT} SUM: $RESULT->{PRICE_OUT}";
         	 $sum     = $RESULT->{TRAFFIC_OUT} * $RESULT->{PRICE_OUT};
          }
         elsif ($RESULT->{TRAFFIC_SUM}) {
         	 $FEES_PARAMS{DESCRIBE} = "$_USED $_TRAFFIC: $RESULT->{TRAFFIC_SUM} SUM: $RESULT->{PRICE}";
         	 $sum     = $RESULT->{TRAFFIC_SUM} * $RESULT->{PRICE};
          }

         $fees->take(\%user, $sum, { %FEES_PARAMS } );  
        }


      }
   } 	
  	
 }

  $DEBUG .= $debug_output;
  return $debug_output;
}


#**********************************************************
#
#**********************************************************
sub help () {
	
print << "[END]";
Ureports server.

  DEBUG=0..6         - Debug mode
  DATE="YYYY-MM-DD"  - Send date
  help               - this help
[END]
	
}



1


