package Abills::Base;

use strict;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
 %intervals 
 %int
 %variants
 %conf
 %trafic
);

use Exporter;


$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw( &radius_log
  &session_spliter
  &int2ip
  &ip2int
  &int2byte
  &sec2time
  &int2ml
  &show_log
  &mk_unique_value
  &decode_base64
  %variants
  %intervals
  %int
 );

@EXPORT_OK = ();
%EXPORT_TAGS = ();

my $dif = 79200;







#*******************************************************************
# show log
# show_log($uid, $type, $logfile, $records)
#*******************************************************************
sub show_log {
  my ($uid, $type, $logfile, $records) = @_;
  my $output = ''; 
  my @err_recs = ();
  
  open(FILE, "$logfile") || die "Can't open log file '$logfile' $!\n";
   while(<FILE>) {

      my ($date, $time, $log_type, $action, $user, $message)=split(/ /, $_, 6);
      
      $user =~ s/\[|\]//g;
      if ($uid ne "") {
        if($uid eq $user) {
      	  push @err_recs, $_;
         }
       }
      else {
      	 push @err_recs, $_;
       }
     }
 close(FILE);

 my $total  = 0;
 $total = $#err_recs;
 my $i = 0;
 my @list;
 for ($i = $total; $i>=$total - $records; $i--) {
    #$output .= $err_recs[$i];
    push @list, $err_recs[$i];
   }
 
 #print "$output";

 return \@list;
} 


#*******************************************************************
# Make unique value
# mk_unique_value($size)
#*******************************************************************
sub mk_unique_value {
   my ($passsize) = @_;
   my $symbols = "qwertyupasdfghjikzxcvbnmQWERTYUPASDFGHJKLZXCVBNM23456789";

   my $value = '';
   my $random = '';
   my $i=0;
   
   my $size = length($symbols);
   srand();
   for ($i=0;$i<$passsize;$i++) {
     $random = int(rand($size));
     $value .= substr($symbols,$random,1);
    }
  return $value; 
}


#********************************************************************
# Split session to intervals
# session_spliter($login, $logout, $variant);
#********************************************************************
sub session_spliter {
 my ($lin, $lout, $variant) = shift;

# $day_begin - unix time
# $day_of_year
# $day_of_week

 my %res = ();
 %int = ();
 #undef (%int);
 
 my $i=0;
 foreach my $line (@{$intervals{$variant}}) {
    my ($b, $e, $t)=split(/ /, $line);
    my @ba = split(/:/, $b);
    my @ea = split(/:/, $e);
    $int{$i}{b}=($ba[0] * 3600) + ($ba[1] * 60) + $ba[2];
    $int{$i}{e}=($ea[0] * 3600) + ($ea[1] * 60) + $ea[2];
    $int{$i}{tk}=$t;
    $i++;
  }

 
 my (%login);
 my (%logout);

 $login{ut} = $lin;
 $logout{ut} = $lout;  

 my $day = 86400; #24 * 60 * 60
 my $dif = 75600; #79200;

# Day begin
# $day_begin
$login{d}=int(($login{ut} - $dif) / $day);

#Login time
$login{t} = $login{ut} - ($login{d} * $day + $dif);
#Logout time
$logout{t} = $logout{ut} - ($login{d} * $day + $dif);

 my $s_duration = $logout{t} - $login{t};

 $i = 0;

begin:
  while(my($key, $val) = each(%int)) {
  #print "$int{$key}{b} <= $login{t}";
#    log_print('LOG_DEBUG', "Login: $login{t}/$logout{t} / $int{$key}{b} $int{$key}{e}");
    if(($int{$key}{b} <= $login{t}) && ($logout{t} < $int{$key}{e})) {
#       log_print('DEBUG',  "$key - $int{$key}{b}:$int{$key}{e} $login{t}"); 
       $res{$key}+=$logout{t}-$login{t}; 
       $login{t}+=$res{$key};
       last;
     }
    elsif(($int{$key}{b} <= $login{t}) && ($login{t} < $int{$key}{e})) {
#       log_print('DEBUG', "$key - $int{$key}{b}:$int{$key}{e} $login{t}");
       my $sub_duration = ($logout{t}-$login{t}) - ($logout{t} - $int{$key}{e});  
       $res{$key}+=$sub_duration;
       $login{t}+=$sub_duration;
     }
   }
$i++;


if ($login{t} < $logout{t}) {
 $login{t}=0;
 $logout{t}=$logout{t}-86400;
 goto begin;
}

return %res;
}

#*******************************************************************
# Convert integer value to ip
# int2ip($i);
#*******************************************************************
sub int2ip {
my $i = shift;
my (@d);
$d[0]=int($i/256/256/256);
$d[1]=int(($i-$d[0]*256*256*256)/256/256);
$d[2]=int(($i-$d[0]*256*256*256-$d[1]*256*256)/256);
$d[3]=int($i-$d[0]*256*256*256-$d[1]*256*256-$d[2]*256);
 return "$d[0].$d[1].$d[2].$d[3]";
}


#*******************************************************************
# Convert ip to int
# ip2int($ip);
#*******************************************************************
sub ip2int($){
  my $ip = shift;
  return unpack("N", pack("C4", split( /\./, $ip)));
}



#********************************************************************
# Second to date
# sec2time()
# return $sec,$minute,$hour,$day
#********************************************************************
sub sec2time {
   my($a,$b,$c,$d);

    $a=int($_[0] % 60);
    $b=int(($_[0] % 3600) / 60);
    $c=int(($_[0] % (24*3600)) / 3600);
    $d=int($_[0] / (24 * 3600));
    return($a,$b,$c,$d);
}

#********************************************************************
# Convert Integer to byte definision
# int2byte($val)
#********************************************************************
sub int2byte {
 my $val = shift;
 if($val > 1073741824){ $val = sprintf("%.2f GB", $val / 1073741824);}  # 1024 * 1024 * 1024
 elsif($val > 1048576){ $val = sprintf("%.2f MB", $val / 1048576);   }  # 1024 * 1024
 elsif($val > 1024)   { $val = sprintf("%.2f Kb", $val / 1024);      }
 else { $val .= " Bt"; }
 return $val;
}


#********************************************************************
# integet to money in litteral format
# int2ml($array);
#********************************************************************
sub int2ml {
 my $array = shift;
 my $ret = '';

 my @ones = ('гривн€', 'тис€ча', 'м≥льйон', 'м≥ль€рд', 'трильйон');
 my @twos = ('гривн≥', 'тис€ч≥', 'м≥льйони', 'м≥ль€рди', 'трильйони');
 my @fifth = ('гривень', 'тис€ч', 'м≥льйон≥в', 'м≥ль€рд≥в', 'трильйон≥в');

 my @one = ('', 'один', 'два', 'три', 'чотири', 'п\'€ть', 'ш≥сть', 'с≥м', 'в≥с≥м', 'дев\'€ть');
 my @onest = ('', 'одна', 'дв≥');
 my @ten = ('', '', 'двадц€ть', 'тридц€ть', 'сорок', 'п\'€тдес€т', 'ш≥стдес€т', 'с≥мдес€т', 'в≥с≥мдес€т', 'дев\'€носто');
 my @tens = ('дес€ть', 'одинадц€ть', 'дванадц€ть', 'тринадц€ть', 'чотирнадц€ть', 'п\'€тнадц€ть', 'ш≥стнадц€ть', 'с≥мнадц€ть', 'в≥с≥мнадц€ть', 'дев\'€тнадц€ть');
 my @hundred = ('', 'сто', 'дв≥ст≥', 'триста', 'чотириста', 'п\'€тсот', 'ш≥стсот', 'с≥мсот', 'в≥с≥мсот', 'дев\'€тсот');

 $array =~ tr/0-9,.//cd;
 my $tmp = $array;
 my $count = ($tmp =~ tr/.,//);

#print $array,"\n";
if ($count > 1) {
  $ret .= "i2s.pl: bad integer format\n";
  return 1;
}

my $second = "00";
my ($first, $i, @first, $j);

if (!$count) {
  $first = $array;
} else {
  $first = $second = $array;
  $first =~ s/(.*)(\..*)/$1/;
  $second =~ s/(.*)(\.)(\d\d)(.*)/$3/;
}

$count = int ((length $first) / 3);
my $first_length = length $first;

for ($i = 1; $i <= $count; $i++) {
  $tmp = $first;
  $tmp =~ s/(.*)(\d\d\d$)/$2/;
  $first =~ s/(.*)(\d\d\d$)/$1/;
  $first[$i] = $tmp;
}

if ($count < 4 && $count * 3 < $first_length) {
  $first[$i] = $first;
  $first_length = $i;
} else {
  $first_length = $i - 1;
}

for ($i = $first_length; $i >=1; $i--) {
  $tmp = 0;
  for ($j = length ($first[$i]); $j >= 1; $j--) {
    if ($j == 3) {
      $tmp = $first[$i];
      $tmp =~ s/(^\d)(\d)(\d$)/$1/;
      $ret .= $hundred[$tmp];
      if ($tmp > 0) {
        $ret .= " ";
      }
    }
    if ($j == 2) {
      $tmp = $first[$i];
      $tmp =~ s/(.*)(\d)(\d$)/$2/;
      if ($tmp != 1) {  
        $ret .= $ten[$tmp];
        if ($tmp > 0) {
          $ret .= " ";
        }
      }
    }
    if ($j == 1) {
      if ($tmp != 1) {
        $tmp = $first[$i];
        $tmp =~ s/(.*)(\d$)/$2/;
        if ((($i == 1) || ($i == 2)) && ($tmp == 1 || $tmp == 2)) {
          $ret .= $onest[$tmp];
          if ($tmp > 0) {
            $ret .= " ";
          }
        } else {
            $ret .= $one[$tmp];
            if ($tmp > 0) {
              $ret .= " ";
            }
        }
      } else {
        $tmp = $first[$i];
        $tmp =~ s/(.*)(\d$)/$2/;
        $ret .= $tens[$tmp];
        if ($tmp > 0) {
          $ret .= " ";
        }
        $tmp = 5;
      }
    }
    
  }

  if ($tmp == 1) {
    $ret .= $ones[$i - 1] . " ";
  }
  elsif ($tmp > 1 && $tmp < 5) {
    $ret .= $twos[$i - 1] . " ";
  }
  elsif ($tmp > 4) {
    $ret .= $fifth[$i - 1] . " ";
  }
  else {
    $ret .= $fifth[0] . " ";
  }
}

if ($second ne '') {
 $ret .= "$second коп.\n";
} else {
 $ret .= "\n";
}
 
 return $ret;
}


##get recs from radwtmp
#
#=commnent
#struct radutmp {
#        char login[RUT_NAMESIZE];       /* Loginname (maybe modified) */
#        char orig_login[RUT_NAMESIZE];  /* Original loginname */
#        int  nas_port;                  /* Port on the terminal server */
#        char session_id[RUT_IDSIZE];    /* Radius session ID */
#                                        /* (last RUT_IDSIZE bytes at least)*/
#        unsigned int nas_address;       /* IP of portmaster. */
#        unsigned int framed_address;    /* SLIP/PPP address or login-host. */
#        int proto;                      /* Protocol. */
#        time_t time;                    /* Time the entry was last updated. */
#        time_t delay;                   /* Delay time of request */
#        int type;                       /* Type of entry (login/logout) */
#        char porttype;         /* Porttype (I=ISDN A=Async T=Async-ISDN) */
#        char res1,res2,res3;            /* Fills up to one int */
#        time_t duration;
#        char caller_id[RUT_PNSIZE];      /* calling station ID */
#        unsigned int realm_address;
#        char reserved[10];
#};
#=cut
#	
#my $packstring = "a32a32La16NNiIIiaaaaIa24La12";
#my $reclength = length(pack($packstring));
#open(D,"<$RADWTMP") or die "Couldn't open '$RADWTMP', $!";
#
#my %wtmp_info;
#while(sysread(D,my $rec,$reclength)) {
# my ($login, $orig_login, $nas_port, $session_id, $nas_address, $framed_address, $proto, $time, $delay, $type, 
#  $porttype, $res1, $res2, $res3, $duration, $caller_id, $realm_address, $reserved) = unpack($packstring,$rec);
# # 0 - logout; 1 - login
# if ($type == 1) {
#   $wtmp_info{"$session_id"}{login}=$login;
#   $wtmp_info{"$session_id"}{orig_login}=$orig_login;
#   $wtmp_info{"$session_id"}{nas_port}=$nas_port;
#   $wtmp_info{"$session_id"}{nas_address}=$nas_address;
#   $wtmp_info{"$session_id"}{framed_address}=$framed_address;
#   $wtmp_info{"$session_id"}{proto}=$proto;
#   $wtmp_info{"$session_id"}{time}=$time;
#   $wtmp_info{"$session_id"}{delay}=$delay;
#   $wtmp_info{"$session_id"}{type}=$type;
#   $wtmp_info{"$session_id"}{porttype}=$porttype;
#   $wtmp_info{"$session_id"}{res1}=$res1;
#   $wtmp_info{"$session_id"}{res2}=$res2;
#   $wtmp_info{"$session_id"}{res3}=$res3;
#   $wtmp_info{"$session_id"}{duration}=time-$time;
#   $wtmp_info{"$session_id"}{caller_id}=$caller_id;
#   $wtmp_info{"$session_id"}{realm_address}=$realm_address;
#   $wtmp_info{"$session_id"}{reserved}=$reserved;
#  }
# elsif ($type == 0) {
#  undef($wtmp_info{"$session_id"});
#=comment
#   $wtmp_info{$session_id}{login}=$login;
#   $wtmp_info{$session_id}{orig_login}=$orig_login;
#   $wtmp_info{$session_id}{nas_port}=$nas_port;
#   $wtmp_info{$session_id}{nas_address}=$nas_address;
#   $wtmp_info{$session_id}{framed_address}=$framed_address;
#   $wtmp_info{$session_id}{proto}=$proto;
#   $wtmp_info{$session_id}{time}=$time;
#   $wtmp_info{$session_id}{delay}=$delay;
#   $wtmp_info{$session_id}{type}=$type;
#   $wtmp_info{$session_id}{porttype}=$porttype;
#   $wtmp_info{$session_id}{res1}=$res1;
#   $wtmp_info{$session_id}{res2}=$res2;
#   $wtmp_info{$session_id}{res3}=$res3;
#   $wtmp_info{$session_id}{duration}=$duration;
#   $wtmp_info{$session_id}{caller_id}=$caller_id;
#   $wtmp_info{$session_id}{realm_address}=$realm_address;
#   $wtmp_info{$session_id}{reserved}=$reserved;
#=cut
#  }
#}
#
#close(D) or die "Couldn't close wtmp, $!";
# return %wtmp_info;
#}

#Get pppacct information
sub ppp_acct {
 my $ifc = shift;
 my $ppphost = shift;
 my $pppport = shift;
 $ifc =~ m/(\d+)/;
 
 print "$ifc - $1\n";
 my %res = ();
 $res{ifc}=$ifc;
 
 #print "pppctl -p 'c)ntro1' $ppphost:$pppport ! echo UPTIME OCTETSIN OCTETSOUT";
 my $result = `pppctl -p 'c)ntro1' $ppphost:$pppport ! echo USER UPTIME OCTETSIN OCTETSOUT`;
 
 ($res{name}, $res{uptime}, $res{in}, $res{out})=split(/ /, $result);
 return %res;
}


#**********************************************************
# decode_base64()
#**********************************************************
sub decode_base64 {
    local($^W) = 0; # unpack("u",...) gives bogus warning in 5.00[123]
    my $str = shift;
    my $res = "";

    $str =~ tr|A-Za-z0-9+=/||cd;            # remove non-base64 chars
    $str =~ s/=+$//;                        # remove padding
    $str =~ tr|A-Za-z0-9+/| -_|;            # convert to uuencoded format
    while ($str =~ /(.{1,60})/gs) {
        my $len = chr(32 + length($1)*3/4); # compute length byte
        $res .= unpack("u", $len . $1 );    # uudecode
    }

    return $res;
}




1;
