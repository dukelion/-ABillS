#!/usr/bin/perl -w

$PROGRAM='~AsmodeuS~ Billing System';

#DB configuration
$conf{dbhost}='localhost';
$conf{dbname}='abills';
$conf{dbuser}='abills';
$conf{dbpasswd}='password';

#Mail configuration
$conf{ADMIN_MAIL}='info@your.domain';
$conf{USERS_MAIL_DOMAIN}='your.domain';
$conf{MAIL_CHARSET}='windows-1251';

#Periodic functions
$conf{p_admin_mails}=1;  # Send periodic admin reports
$conf{p_users_mails}=1;  # Send user warning  messages

# chap encryption decription key
$conf{secretkey}="test12345678901234567890";
$conf{s_detalization}='yes'; #make session detalization recomended for vpn leathed lines
$conf{version}='0.23b'; #23.02.2005

#Minimum session costs
$conf{MINIMUM_SESSION_TIME}=10; # minimum session time for push session to db
$conf{MINIMUM_SESSION_TRAF}=200; # minimum session trafic for push session to db
# Minimum pushed session cost.
# If MINIMUM_SESSION_COST > 0 session sum up to MINIMUM_SESSION_COST value.
$conf{MINIMUM_SESSION_COST}=0.01; 


# Exppp options
$conf{netsfilespath}='/usr/abills/cgi-bin/dmin/nets/';
$conf{config_file}='';

# Debug mod 
$conf{debug}=10;
$conf{debugmods}='LOG_DEBUG LOG_ALERT LOG_WARNING LOG_ERR LOG_INFO';
#show auth and accounting time need Time::HiRes module (available from CPAN)
$conf{time_check}=1;

$foreground=0;

# Log levels
%log_levels = ('LOG_EMERG' => 0,
'LOG_ALERT' => 0,
'LOG_CRIT' => 0,
'LOG_ERR' => 1,
'LOG_WARNING' => 0, 
'LOG_NOTICE' => 0,
'LOG_INFO' => 1,
'LOG_DEBUG' => 7,
'LOG_SQL' => 6);


#SNMP Communities For checker and other SNMP base function
$SNMPWALK = '/usr/local/snmp/bin/snmpwalk';

# Backup SQL data
$MYSQLDUMP = '/usr/local/mysql/bin/mysqldump';
$BACKUP_DIR='/usr/abills/backup';
$GZIP = '/usr/bin/gzip';

# Folders and files
$base_dir='/usr/abills/';
$lang_path=$base_dir . 'language/';
$lib_path=$base_dir .'libexec/';
$var_dir=$base_dir .'var/';
$spool_dir=$base_dir.'var/q';


$logdebug = $base_dir . 'var/log/abills.debug';
$logfile = $base_dir . 'var/log/abills.log';
$logacct = $base_dir . 'var/log/acct.log';

#For file auth type allow file
#$allow_list=$base_dir.'var/users.allow';
$extern_acct_dir=$base_dir.'libexec/ext_acct/';

#$start_dir=$base_dir.'libexec/start/';
#$stop_dir=$base_dir.'libexec/start/';

$MAILBOX_PATH='/var/mail/';

# Low bounds
#$low_free_bound=10;

use POSIX qw(strftime);
$DATE = strftime "%Y-%m-%d", localtime(time);
$TIME = strftime "%H:%M:%S", localtime(time);

$curtime = strftime("%F %H.%M.%S", localtime(time));
$year = strftime("%Y", localtime(time));

# Functions
######################################################################################


#*******************************************************************
# nas_params()
#*******************************************************************

sub nas_params {
 my ($attr) = @_;

 my %NAS_INFO = ();
 my $sql = "SELECT id, name, nas_identifier, descr, ip, nas_type, auth_type, mng_host_port, mng_user, 
 DECODE(mng_password, '$conf{secretkey}'), rad_pairs FROM nas;";

 log_print('LOG_SQL', "$sql");
 my $q = $db->prepare("$sql") || die $db->strerr;
 $q -> execute();
 while(my($id, $name, $nas_identifier, $describe, $ip, $nas_type, $auth_type, $mng_ip_port, 
     $mng_user, $mng_password, $rad_pairs)=$q->fetchrow()) {
     $NAS_INFO{$ip}=$id;
     $NAS_INFO{$ip}{$nas_identifier}=$id;

     $NAS_INFO{name}{$id}=$name || '';
     $NAS_INFO{nt}{$id}=$nas_type  || '';
     $NAS_INFO{at}{$id}=$auth_type || 0;
     $NAS_INFO{rp}{$id}=$rad_pairs || '';
     $NAS_INFO{mng_user}{$id}=$mng_user || '';
     $NAS_INFO{mng_password}{$id}=$mng_password || '';
     ($mip, $mport)=split(/:/, $mng_ip_port);
     $NAS_INFO{mng_ip}{$id}=$mip || '0.0.0.0';
     $NAS_INFO{mng_port}{$id}=$mport || 0;     
  }
 return \%NAS_INFO;
}


 
#*******************************************************************
# Get servers types
# servers_types()
#*******************************************************************
#sub servers_types {
# open(FILE, "$servers_conf") || die "Can't open file '$server_conf' $!";
#   while(<FILE>) {
#      next if (/^#|^\n/ );
#      ($number, $ip, $type, $model, $authtype, $assignaddr, $poolsize, $password, $commnets) = split(/ +|\t+/, $_, 8);
#      chop($type);
#      $NAS_TYPES{$number}=$type;
#      $NAS_MODEL{$number}=$model;
#      $NAS_SERVERS{$ip}=$number;
#      $NAS_AUTH{$number}=$authtype;
#      $NAS_ASSIGNADDR{$number}=$assignaddr   || '0.0.0.0';
#      $NAS_POOLSIZE{$number}=$poolsize  || 0;
#      $NAS_PASSWORD{$number}=clearquotes($password)  || '';
#    }
# close(FILE);
# return %NAS_TYPES;
#}


#*******************************************************************
# log_print ($level, $text)
# 
#*******************************************************************
sub log_print  {
 my ($level, $text) = @_;

 if ($conf{debugmods} =~ /$level/) {
   if ($foreground == 1) {
     print "$DATE $TIME $type: $text\n";
    }
   else {
     open(FILE, ">>$logfile") || die "Can't open file '$logfile' $!\n";
      print FILE "$DATE $TIME $level: $text\n";
     close(FILE);
    }
  }

#elsif($conf{debug} < $log_levels{$level}) {
#  print "level \n";
#  return 0;	
# }

#   write_log("$logfile", "$level", $text);


}


#********************************************************************
# Writing log file
# write_log ($filename, $type, $text)
#********************************************************************
#sub write_log  {
# my ($filename, $type, $text) = @_;
# 
#if ($foreground == 1) {
#  print "$DATE $TIME $type: $text\n";
# }
#else {
#  open(FILE, ">>$filename") || die "Can't open file '$filename' $!\n";
#   print FILE "$DATE $TIME $type: $text\n";
# close(FILE);
# }
#}

#*******************************************************************
# Get Argument params or Environment parameters  
# 
# FreeRadius enviropment parameters
#  CLIENT_IP_ADDRESS - 127.0.0.1
#  NAS_IP_ADDRESS - 127.0.0.1
#  USER_PASSWORD - xxxxxxxxx
#  SERVICE_TYPE - VPN
#  NAS_PORT_TYPE - Virtual
#  FRAMED_PROTOCOL - PPP
#  USER_NAME - andy
#  NAS_IDENTIFIER - media.intranet
#*******************************************************************
sub get_radius_params {
 if ($#ARGV > 1) {
    foreach my $pair (@ARGV) {
      my ($side, $value) = split(/=/, $pair);
      $RAD{$side} = clearquotes($value);
     }
  }
 else {
    while(my($k, $v)=each(%ENV)) {
      $RAD{$k}=clearquotes($v);
     }
  }
}


#*******************************************************************
# Make session log file
# mk_session_log(\$acct_info)
#*******************************************************************
sub mk_session_log  {
 my ($acct_info) = @_;
 my $filename="$acct_info->{USER_NAME}.$acct_info->{ACCT_SESSION_ID}";
 my %acct_hash = %$acct_info;
 open(FILE, ">$spool_dir/$filename") || die "Can't open file '$spool_dir/$filename' $!";
  while(my($k, $v)=each(%acct_hash)) {
     print FILE "$k:$v\n";
   }
 close(FILE);
}

#********************************************************************
# Split session to intervals
# session_splitter($login, $duration, $day_begin, $day_of_week, 
#                  $day_or_year, $intervals)
#********************************************************************
sub session_splitter {
 my ($login, $duration, $day_begin, $day_of_week, $day_of_year, $intervals) = @_;


 my %division_time = (); #return division time

# Test intervals
# while(my($day, $params)=each %$intervals) {
#     print "$day\n";
#     while(my($key, $v)=each %$params) {
#          print " $key $v\n";
#        }
#   }
 
 my $tarif_day = 0;
 my $count = 0;
 $login = $login - $day_begin;
  
 while($duration > 0 && $count < 200) {

    if (defined($intervals->{$day_of_week})) {
    	#print "Day tarif";
    	$tarif_day = $day_of_week;
     }
    elsif(defined($intervals->{$day_of_year})) {
    	#print "Holliday tarif '$day_of_year' ";
    	$tarif_day = 8;
     }
    else {
        #print "Normal tarif";
        $tarif_day = 0;
     }

     $count++;
#     print ": $tarif_day ($day_of_week / $day_of_year)\n";
#     print "------------- $login : $duration\n";
     

#     reset $int{$tarif_day};

     my $cur_int = $intervals->{$tarif_day};

     while(my($int_begin, $int_end)=each %$cur_int) {
#     	print "--";
     	
        if ($login >= $int_begin && $login < $int_end) {
#            print "\t==>$int_begin - $int_end:$price ($login)\n";
            if ($login + $duration < $int_end) {
            	if (defined($division_time{$tarif_day}{$int_begin})) {
            	   $division_time{$tarif_day}{$int_begin}+=$duration;
                 }
                else {
                   $division_time{$tarif_day}{$int_begin}=$duration;
                 }

            	$duration = 0;
            	last;
              }
             else {
             	$int_time = $int_end - $login;

            	if (defined($division_time{$tarif_day}{$int_begin})) {
            	   $division_time{$tarif_day}{$int_begin}+=$int_time;
                 }
                else {
                   $division_time{$tarif_day}{$int_begin}=$int_time;
                 }

             	$duration = $duration - $int_time;
             	$login = $login + $int_time;
             	if ($login == 86400) {
             	    $day_of_week = ($day_of_week + 1 > 7) ? 1 : $day_of_week+1;
             	    $day_of_year = ($day_of_year + 1 > 365) ? 1 : $day_of_year + 1;
             	    $login = 0;
             	    last;
            	  }
              }
            next;
          }
#        print "\t$int_begin - $int_end:$price\n";    
      }
  }

 return \%division_time;
}


#********************************************************************
# Calculate session sum
# Return 
# >= 0 - session sum
# -1 Less than minimun session trafic and time
# -2 Not found user in users db
# session_sum ($login, $s_start, $duration, \$trafic) 
#********************************************************************
sub session_sum {
 my ($login, $s_start, $duration, $trafic)=@_;
 my $sum = 0;
 my ($vid);
 my $sent = $trafic->{OUTBYTE} || 0; #from server
 my $recv = $trafic->{INBYTE} || 0;  #to server
 my $sent2 = $trafic->{OUTBYTE2} || 0; 
 my $recv2 = $trafic->{INBYTE2} || 0;


 if (($duration < $conf{MINIMUM_SESSION_TIME}) || 
    ($sent + $recv < $conf{MINIMUM_SESSION_TRAF})) {
    return -1;
   }

 my $sql = "select v.vrnt, v.hourp,
   if (traft.id IS NULL, 0, traft.id),
   if (traft.in_price IS NULL, 0, traft.in_price),
   if (traft.out_price IS NULL, 0, traft.out_price),
   v.prepaid_trafic,
   u.activate,
   v.abon,
   traft.prepaid,
   u.reduction,
   UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME($s_start), '%Y-%m-%d')),
   DAYOFWEEK(FROM_UNIXTIME($s_start)),
   DAYOFYEAR(FROM_UNIXTIME($s_start))
 FROM users u, variant v
 LEFt JOIN trafic_tarifs traft on traft.vid=v.vrnt
 WHERE u.variant=v.vrnt and u.id='$login';";

 log_print('LOG_SQL', "$sql");


 my $q = $db->prepare($sql) || die $db->errstr;
 $q ->execute();

 if ($q->rows() < 1) {
     return -2;	
   }
 
 
 my $time_tarif = 0;
 my $trafic_tarif = 0;
 my %traf_price = ();       # TRaffic  price

 $traf_price{in}{lo} = 0;
 $traf_price{out}{lo} = 0;
 $traf_price{in}{gl} = 0;
 $traf_price{out}{gl} = 0;

 my %prepaid = ();          # Prepaid traffic Mb
  $prepaid{gl} = 0;
  $prepaid{lo} = 0;
 
 my $reduction = 0;

 my $day_begin = 0; 
 my $day_of_week = 0;
 my $day_of_year = 0;

 while(my($variant, $time_t, $traf_id, $traf_in_price, $traf_out_price, $prepaid_traffic,
   $activate, $month_abon, $prepaid_div_traf, $red, $d_begin, $dow, $doy)=$q->fetchrow()) {
    
    $day_of_week = $dow || 0;
    $day_of_year = $doy || 0;
    $day_begin = $d_begin || 0;
    $vid = $variant;
    $time_tarif=$time_t if ($time_t > 0);

    if ($traf_id == 1) {
       $traf_price{in}{lo} = $traf_in_price;
       $traf_price{out}{lo} = $traf_out_price;
       $prepaid{lo} = $prepaid_div_traf || 0;
      }

    if ($traf_id == 0) {
       $traf_price{in}{gl} = $traf_in_price || 0;
       $traf_price{out}{gl} = $traf_out_price || 0;
       $prepaid{gl} = $prepaid_div_traf || 0;
      }

    $reduction = $red;
  }



=comments
#local Prepaid Traffic
# Separated local prepaid and global prepaid
#


#####################################################################
# Local and global in one prepaid tarif
#

 if ($prepaid{gl} + $prepaid{lo} > 0) {

    my %prepaid_price = ();

    $prepaid_price{'lo'} = $month_abon / $prepaid{lo} || 0; #  if ($prepaid{lo} > 0);
    $prepaid_price{'gl'} = $month_abon / $prepaid{gl} || 0; #  if ($prepaid{gl} > 0);

    # login>'$activate'
    #Get traffic from begin of month
    $sql = "SELECT sum(sent + recv) / 1024 / 1024, sum(sent2 + recv2) / 1024 / 1024
       FROM log WHERE id='$login' and (login>=DATE_FORMAT(curdate(), '%Y-%m-00'))
       GROUP BY id";


    my $q = $db->prepare($sql) || die $db->errstr;
    $q ->execute();

    if ($q->rows() > 1) {
       my($used_traffic, $used_traffic2)=$q->fetchrow() 
       
       if (($used_traffic   / 1024 / 1024) * $prepaid_price{'gl'} + ($used_traffic2  / 1024 / 1024) * $prepaid_price{'lo'} 
         + (($sent + $recv) / 1024 / 1024) * $prepaid_price{'gl'} + (($sent2 + $recv2) / 1024 / 1024) * $prepaid_price{'lo'} 
          < $month_abon) {
           return 0, $vid, 0, 0;
        }

     }
    elsif((($sent + $recv) / 1024 / 1024) * $prepaid_price{'lg'} + (($sent2 + $recv2) / 1024 / 1024) * $prepaid_price{'lo'} 
          < $month_abon) {
       return 0, $vid, 0, 0;
     }
    elsif((($sent + $recv) / 1024 / 1024) * $prepaid_price{'lg'} + (($sent2 + $recv2) / 1024 / 1024) * $prepaid_price{'lo'} 
          > $month_abon) {
       $sent = 0;
       $recv = 0;
       $sent2 = 0;
       $recv2  = 0;
     }


  }


####################################################################
# Global prepaid traffic
# And local calculate traffic

 if ($prepaid_traffic > 0) {
    $sql = "SELECT (sent + recv) / 1024 / 1024, (sent2 + recv2) / 1024 / 1024  
     FROM log WHERE id='$login' and login>'$activate'";

    my $q = $db->prepare($sql) || die $db->errstr;
    $q ->execute();


    if ($q->rows() > 1) {
       my($used_traffic, $used_traffic2)=$q->fetchrow();
       if ($prepaid_traffic > ($used_traffic + $sent + $recv) / 1024 / 1024 ) {
          return 0, $vid, 0, 0;
          # $sent = 0;
          # $recv = 0;
         }
       elsif(($prepaid_traffic > $used_traffic / 1024 / 1024) && 
         ($prepaid_traffic < ($used_traffic + $sent + $recv) / 1024 / 1024)) {
    	  my  $not_prepaid = ($used_traffic + $sent + $recv - $prepaid_traffic * 1024 * 1024) / 2;
    	  $sent = $not_prepaid;
          $recv = $not_prepaid;
#          my $sent2 = $trafic->{sent2} || 0; 
#          my $recv2 = $trafic->{recv2} || 0;
         }
     }
    elsif (($sent + $recv) / 1024 / 1024 < $prepaid_traffic) {
       	  return 0, $vid, 0, 0;
       	  #$sent = 0;
          #$recv = 0;
     }
    elsif($prepaid_traffic < ($sent + $recv) / 1024 / 1024) {
    	  my  $not_prepaid = ($sent + $recv - $prepaid_traffic * 1024 * 1024) / 2;
    	  $sent = $not_prepaid;
          $recv = $not_prepaid;
#          my $sent2 = $trafic->{sent2} || 0; 
#          my $recv2 = $trafic->{recv2} || 0;
     }

  }
=cut

####################################################################
# Prepaid local and global traffic separately
#log_print('LOG_DEBUG', "Etap 3 ---$uid");




 if ($prepaid{gl} + $prepaid{lo} > 0) {
    my $used_traffic=0;
    my $used_traffic2=0;
    # login>'$activate'
    #Get traffic from begin of month
    $sql = "SELECT sum(sent + recv), sum(sent2 + recv2)
       FROM log WHERE id='$login' and (DATE_FORMAT(login, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m'))
       GROUP BY id;";

    my $q = $db->prepare($sql) || die $db->errstr;
    $q ->execute();

    $a = `echo "$sql,\n $used_traffic, $used_traffic2,  $prepaid{gl}, $prepaid{lo} \n---\n" > /tmp/test`;

    if ($q->rows() > 0) {
       ($used_traffic, $used_traffic2)=$q->fetchrow() ;
     }
    
       # If left global prepaid traffic set traf price to 0
       if (($used_traffic + $sent + $recv) / 1024 / 1024 < $prepaid{gl}) {
          $traf_price{in}{gl} = 0;
          $traf_price{out}{gl} = 0;
        }
       # 
       elsif (($used_traffic + $sent + $recv) / 1024 / 1024 > $prepaid{gl} && $used_traffic / 1024 / 1024 < $prepaid{gl}) {
       	  $not_prepaid = ($used_traffic + $sent + $recv) - $prepaid{gl} * 1024 * 1024;
       	  $sent = $not_prepaid / 2;
       	  $recv = $not_prepaid / 2;
        }

       # If left local prepaid traffic set traf price to 0
       if (($used_traffic2 + $sent2 + $recv2) / 1024 / 1024 < $prepaid{lo}) { 
           $traf_price{in}{lo} = 0;
           $traf_price{out}{lo} = 0;
        }
       elsif ( (($used_traffic2 + $sent2 + $recv2) / 1024 / 1024 > $prepaid{lo}) && ( $used_traffic2 / 1024 / 1024 < $prepaid{lo}) ) {
       	  $not_prepaid = ($used_traffic2 + $sent2 + $recv2) - $prepaid{lo} * 1024 * 1024;
       	  $sent2 = $not_prepaid / 2;
       	  $recv2 = $not_prepaid / 2;
        }

     
}



#
##################################################################### 
# Time tarif payments

 my $time_sum = 0;
 if ($time_tarif > 0) {
   
   my ($intervals, $time_prices) = time_intervals($vid);   

   if (ref($intervals) eq 'HASH') {
     my $division_time = session_splitter("$s_start", "$duration", $day_begin, $day_of_week, 
      $day_of_year, $intervals);

     my $secsum = 0;
     while(my($tarif_day, $params)=each %$division_time) {
       my $period_sum = 0;
       while(my($interval, $secs)=each %$params) {
       	   $secsum += $secs;
           if ($time_prices->{$tarif_day}{$interval} =~ /%$/) {
             $time_prices->{$tarif_day}{$interval} =~ tr/\%//;
             $period_sum = ($time_tarif  / 60 / 60) * $secs * ($time_prices->{$tarif_day}{$interval} / 100);
           }
          else {
             $period_sum = $time_prices->{$tarif_day}{$interval} * ($secs / 60 / 60);
           }
       	   $time_sum += $period_sum;
         }
      }
    }
   else {
     $time_sum = $time_tarif * ($duration / 60 / 60);
    }

  }

#####################################################################
# TRafic payments
    my $traf_sum = 0;

    if ($traf_price{in}{lo} + $traf_price{out}{lo} + $traf_price{out}{gl} + $traf_price{in}{gl} > 0) {
       my $gl_in = $recv / 1024 / 1024 * $traf_price{in}{gl};
       my $gl_out  = $sent / 1024 / 1024 * $traf_price{out}{gl};
       my $lo_in = $recv2 / 1024 / 1024 * $traf_price{in}{lo};
       my $lo_out  = $sent2 / 1024 / 1024 * $traf_price{out}{lo};
       $traf_sum = $lo_in + $lo_out + $gl_in + $gl_out;
     }

   $sum = $time_sum + $traf_sum;
   $sum = $sum * (100 - $reduction) / 100 if ($reduction > 0);
   $sum = $conf{MINIMUM_SESSION_COST} if ($sum < $conf{MINIMUM_SESSION_COST} && $time_tarif + $traf_price{in}{lo} + $traf_price{out}{lo} + $traf_price{out}{gl} + $traf_price{in}{gl} > 0);

#log_print('LOG_DEBUG', "Etap 6 ---$uid");

   return $sum, $vid, $time_tarif, 0;
}



#*******************************************************************
# Get testing information
# test_radius_returns()
#*******************************************************************
sub test_radius_returns {
 my $test = " ==ARGV\n";
 
 foreach my $line (@ARGV) {
    $test .= "  $line\n";
  }

 $test .= "\n\n ==ENV\n";
 while(my($k, $v)=each(%ENV)){
   $test .= "  $k - $v\n";
  }

 $test .= "\n\n ==RAD\n";
 my @sorted_rad = sort keys %RAD; 

  foreach my $line (@sorted_rad) {
    $test .= "  $line - $RAD{$line}\n";
  }

 log_print('LOG_DEBUG', "$test");
}

#*******************************************************************
# For clearing quotes
# clearquotes( $text )
#*******************************************************************
sub clearquotes {
 my $text = shift;
 $text =~ s/"//g;
 return $text;
}


#*******************************************************************
# access_deny($user, $message);
#*******************************************************************
sub access_deny {
my ($user, $message, $nas_num) = @_;

 log_print('LOG_WARNING', "AUTH [$user] NAS: $nas_num $message");

exit 1;
}

#*******************************************************************
# get_uid($login)
#*******************************************************************
sub get_uid {
 my ($login) = @_;
 my $uid = 0;

 my $sql = "SELECT uid FROM users WHERE id='$login';";
 my $q = $db -> prepare($sql)  || die $db->strerr;
 $q -> execute();
 ($uid) = $q -> fetchrow();
 return $uid;
}


#*******************************************************************
# get_uid($uid)
#*******************************************************************
sub get_login {
 my ($uid) = @_;
 my $login = '';
 
 my $sql = "SELECT id FROM users WHERE uid='$uid';";
 my $q = $db -> prepare($sql)  || die $db->strerr;
 $q -> execute();
 ($login) = $q -> fetchrow();
 return $login;
}


#********************************************************************
# time intervals
#********************************************************************
sub time_intervals {
 my ($vid) = @_;

 my $sql = "SELECT day, TIME_TO_SEC(begin), TIME_TO_SEC(end), tarif  FROM intervals WHERE vid='$vid' ORDER BY 1;";
 my $q = $db->prepare($sql) || die $db->errstr;
 $q ->execute();

 if ($q->rows() < 1) {
     return 0;	
   }

 my %time_intervals = ();
 my %interval_tarifs = ();

 while(my($timet_day, $timet_begin, $timet_end, $timet_tarif)=$q->fetchrow()) {
     $time_intervals{$timet_day}{$timet_begin} = $timet_end;
     $interval_tarifs{$timet_day}{$timet_begin} = $timet_tarif;
   }

 return \%time_intervals, \%interval_tarifs; 
}



#********************************************************************
# remaining_time
#********************************************************************
sub holidays_show() {
 my ($attr) = @_;

 my $year = (defined($attr->{year})) ? $attr->{year} : 'YEAR(CURRENT_DATE)';
 my $format = (defined($attr->{format}) && $attr->{format} eq 'daysofyear') ? "DAYOFYEAR(CONCAT($year, '-', day)) as dayofyear" : 'day';

 my %hollidays = ();	
 my $sql = "SELECT $format, descr FROM holidays;";
 my $q = $db->prepare($sql) || die $db->errstr;
 $q ->execute();

 while(my($day, $describe)=$q->fetchrow()) {
   $hollidays{$day}=$describe;
  }

 \%hollidays;
}



#********************************************************************
# sendmail($from, $to, $subject, $message, $charset, $priority)
# MAil Priorities:
#
#
#
#
#********************************************************************
sub sendmail {
  my ($from, $to, $subject, $message, $charset, $priority) = @_;
  my $SENDMAIL='/usr/sbin/sendmail';

   open(MAIL, "| $SENDMAIL -t $to") || die "Can't open file '$SENDMAIL' $!";
     print MAIL "To: $to\n";
     print MAIL "From: $from\n";
     print MAIL "Content-Type: text/plain; charset=$charset\n";
     print MAIL "X-Priority: $priority\n" if ($priority ne '');
     print MAIL "Subject: $subject \n\n";     
     print MAIL "$message";
   close(MAIL);

  return 0;
}

#*******************************************************************
# time check function
# tc()
#*******************************************************************
sub check_time {
 return 0 if ($conf{time_check} == 0);

 my $begin_time = 0;
# BEGIN {
 #my $begin_time = 0;
 #Check the Time::HiRes module (available from CPAN)
   eval { require Time::HiRes; };
   if (! $@) {
     Time::HiRes->import(qw(gettimeofday));
     $begin_time = gettimeofday();
    }
#  }
 return $begin_time;
}


#*******************************************************************
# Read config file
# read_config($configfile);
#*******************************************************************
sub read_config {
 my ($config_file) = @_;


 return 0;
}
