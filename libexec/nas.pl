#!/usr/bin/perl
# NAS controlling functions
# get_acct_info
# hangup
# check_activity


my $PPPCTL = '/usr/sbin/pppctl';

my $NAS_INFO = nas_params();
my $nas_id = 0;
my $nas_type = '';
my $mng_user =  '';
my $mng_password = '';
my $mng_ip = '';
my $mng_port = 0;

#*******************************************************************
# Hangup active port
# hangup($NAS, $PORT, $USER);
#*******************************************************************

sub hangup {
 my ($NAS, $PORT, $USER, $SESSION_ID) = @_;

 $nas_id = $NAS_INFO->{$NAS};
 $nas_type = $NAS_INFO->{nt}{$nas_id};
 $mng_user =  $NAS_INFO->{mng_user}{$nas_id};
 $mng_password = $NAS_INFO->{mng_password}{$nas_id};
 $mng_ip= $NAS_INFO->{mng_ip}{$nas_id};
 $mng_port = $NAS_INFO->{mng_port}{$nas_id};

 if ($nas_type eq 'exppp') {
    hangup_exppp($NAS, $PORT);
  }
 elsif ($nas_type eq 'pm25') {
    hangup_pm25($NAS, $PORT);
  }
 elsif ($nas_type eq 'radpppd') {
    hangup_radpppd($NAS, $PORT);
  }
 elsif ($nas_type eq 'mpd') {
    hangup_mpd($NAS, $PORT);
  }
 else {
    return 1;
   }

 return 0;
}


#*******************************************************************
# Get stats
# get_stats($NAS, $PORT, $USER);
#*******************************************************************
sub get_stats {
 my ($NAS, $PORT, $attr) = @_;

 $nas_id = $NAS_INFO->{$NAS};
 $nas_type = $NAS_INFO->{nt}{$nas_id};
 $mng_user =  $NAS_INFO->{mng_user}{$nas_id};
 $mng_password = $NAS_INFO->{mng_password}{$nas_id};
 $mng_ip= $NAS_INFO->{mng_ip}{$id};
 $mng_port = $NAS_INFO->{mng_port}{$nas_id};

 if ($nas_type eq 'usr')       {
    %stats = stats_usr($NAS, $PORT);
  }
 elsif ($nas_type eq 'pm25')   {
    %stats = stats_pm25($NAS, $PORT);
  }
 elsif ($nas_type eq 'dslmax') {
    my $user_ip_address = $attr->{user_ip_address};
    %stats = stats_dslmax($NAS, $PORT, $user_ip_address);
  }
 else {
    return 0;
  }

 return %stats;
}



#*******************************************************************
#
# telnet_cmd($hostname, $login, $password, $commands)
#*******************************************************************
sub telnet_cmd {
 my($hostname, $commands)=@_;
 my $port = 23;

 if ($hostname =~ /:/) {
   ($hostname, $port)=split(/:/, $hostname, 2);
 }


 use Socket;
 socket(SH, PF_INET, SOCK_STREAM, getprotobyname('tcp')) || die $!;
 my $dest = sockaddr_in($port, inet_aton("$hostname"));
 connect(SH, $dest) || die $!;

 my $sock = \*SH;
 my $MAXBUF=512;

 my $input = '';
 my $len = 0;
 my $text = '';
 my $inbuf = '';
 my $res = '';

foreach my $line (@$commands) {
  my ($waitfor, $sendtext)=split(/\t/, $line, 2);

#print "$waitfor, $sendtext</br>";
  $input = '';
  do {
     recv($sock, $inbuf, $MAXBUF, 0);
     $input .= $inbuf;
     $len = length($inbuf);
     alarm 5;
    } while ($len == $MAXBUF);

  log_print('LOG_DEBUG', "Get: \"$input\"\nLength: $len");
  log_print('LOG_DEBUG', " Wait for: $waitfor");

  if ($input =~ /$waitfor/ig) {
    $text = $sendtext;
    log_print('LOG_DEBUG', "Send: $text");
    send($sock, "$text\r\n", 0, $dest) or die "Can't send: $!\n";
   };

 $res .= "$input\n";
}


 return $res;
# close(SH);
}



#####################################################################
# Nas functions 


#####################################################################
# Livingston Portmaster functions
#*******************************************************************
# Get stats from Livingston Portmaster
# stats_pm25($NAS, $PORT)
#*******************************************************************

sub stats_pm25 {
  my ($NAS, $PORT) = @_;

  my %stats = ();
  my $PM25_PORT=$PORT+2;
  my $SNMP_COM = $mng_password || '';

# $SNMPWALK -v 1 -c $SNMP_COM $SERVER interfaces.ifTable.ifEntry.ifInOctets.$PORT | awk '{print \$4}' `a=`$SNMPWALK -v 1 -c tstats 192.168.101.130 interfaces.ifTable.ifEntry.ifInOctets.$PORT | awk '{print \$4}'`; b=`cat /usr/abills/var/devices/$SERVER-$PORT.In`; c=`expr \$a - \$b + 0`; echo \$c`;  
  my $in  = `$SNMPWALK -v 1 -c $SNMP_COM $NAS IF-MIB::ifInOctets.$PM25_PORT | awk '{print \$4}'`;
  my $out = `$SNMPWALK -v 1 -c $SNMP_COM $NAS IF-MIB::ifOutOctets.$PM25_PORT  | awk '{print \$4}'`;


if ($in + $out > 0) {
  chomp($in);
  chomp($out);
  $stats{in} = $in;
  $stats{out} = $out;
}
else {
  $stats{in} = undef;
  $stats{in} = undef;
} 


  return %stats;
}

#*******************************************************************
# HANGUP pm25
# hangup_pm25($SERVER, $PORT)
#*******************************************************************
sub hangup_pm25 {
 my ($NAS, $PORT) = @_;

 push @commands, "login:\t$mng_user";
 push @commands, "Password:\t$mng_password";
 push @commands, ">\treset S$PORT";
 push @commands, ">exit";

 my $result = telnet_cmd("$NAS", \@commands);
 print $result;

 return 0;
}


#####################################################################
# USR Netserver 8/16
#*******************************************************************
# Get stats from USR Netserver 8/16
# get_usrns_stats($SERVER, $PORT)
#*******************************************************************
sub stats_usrns  {
  my ($NAS, $PORT) = @_;
  my $SNMP_COM = $mng_password || '';
  
#USR trafic taker
  my $in  = `a=\`$SNMPWALK -v 1 -c $SNMP_COM $NAS interfaces.ifTable.ifEntry.ifInOctets.$PORT  | awk '{print \$4}'\`; b=\`cat /usr/abills/var/devices/$SERVER-$PORT.In\`; c=\`expr \$a - \$b + 0\`; echo \$c`;
  my $out = `a=\`$SNMPWALK -v 1 -c $SNMP_COM $NAS interfaces.ifTable.ifEntry.ifOutOctets.$PORT  | awk '{print \$4}'\`; b=\`cat /usr/abills/var/devices/$SERVER-$PORT.Out\`; c=\`expr \$a - \$b + 0\`; echo \$c`;
# $SNMPWALK -v 1 -c $SNMP_COM $SERVER interfaces.ifTable.ifEntry.ifInOctets.$PORT | awk '{print \$4}' `a=`$SNMPWALK -v 1 -c tstats 192.168.101.130 interfaces.ifTable.ifEntry.ifInOctets.$PORT | awk '{print \$4}'`; b=`cat /usr/abills/var/devices/$SERVER-$PORT.In`; c=`expr \$a - \$b + 0`; echo \$c`;
#
  $stats{in} = $in;
  $stats{out} = $out;
}






####################################################################
# Standart FreeBSD ppp
#********************************************************************
# get accounting information from FreeBSD ppp using remove accountin 
# scrips
# stats_ppp($NAS)
#********************************************************************
sub stats_ppp {
 my ($NAS, $PORT) = @_;
 use IO::Socket;
 my $port = 30006;
 
 my $port =  $mng_port || 0;
 
 my $remote = IO::Socket::INET -> new(Proto => "tcp", PeerAddr => "$NAS",
                                  PeerPort => "$port")
 or print "cannot connect to pppcons port at $NAS:$port $!\n";

while ( <$remote> ) {
      ($radport, $in, $out, $tun) = split(/ +/, $_);
#      print "--$port, $user, $time, $in, $out, $ip";
      $stats{$NAS}{$radport}{in} = $in;
      $stats{$NAS}{$radport}{out} = $out;
      $stats{$NAS}{$radport}{tun} = $tun;
 }
}


####################################################################
# ASCEND DSL Max
#*******************************************************************
# Get stats from DSLMax
# get_dslmax_stats($SERVER, $PORT, $IP)
#*******************************************************************
sub stats_dslmax {
  my ($NAS, $PORT, $IP) = @_;
  my %stats = ();
  my $SNMP_COM = $mng_password || '';

  my $output = `id=\`$SNMPWALK -c $SNMP_COM -v1 $NAS RFC1213-MIB::ipRouteIfIndex.$IP | awk '{ print \$4 }'\`; a=\`$SNMPWALK -c $SNMP_COM -v1 $NAS IF-MIB::ifInOctets.\$id | awk '{print \$4}'\`; b=\`$SNMPWALK -c $SNMP_COM -v1 $NAS IF-MIB::ifOutOctets.\$id | awk '{print \$4}'\`; echo \$a \$b`;

  my ($in, $out)=split(/ /, $out);
  $stats{in} = $in;
  $stats{out} = $out;
  return %stats;
}

#*******************************************************************
# HANGUP dslmax
# hangup_dslmax($SERVER, $PORT)
#*******************************************************************

sub hangup_dslmax {
 my ($NAS, $PORT) = @_;

#cotrol
 my @commands = ();
 push @commands, "word:\t$mng_password";
 push @commands, ">\treset S$PORT";
 push @commands, ">exit";

 my $result = telnet_cmd("$NAS", \@commands);

 print $result;

 return 0;
}




#####################################################################
# Exppp functions
#*******************************************************************
# HANGUP ExPPP
# hangup_exppp($SERVER, $PORT)
#*******************************************************************
sub hangup_exppp {
 my ($NAS, $PORT) = @_;

 my $ctl_port = $mng_port + $PORT;
 my $out =`$PPPCTL -p "$mng_password" $NAS:$ctl_port down`;

 return 0;
}

#*******************************************************************
# Get stats from exppp
# get_exppp_stats($SERVER, $PORT)
#*******************************************************************
sub stats_exppp {
 my ($NAS, $PORT) = @_;

 my $ctlport = $mng_port + $PORT;
 my $out  = `$PPPCTL -p "$mng_password" $NAS:$ctlport ! echo OCTETSIN OCTETSOUT USER`;
 my ($in, $out, $user) = split(/ +/, $out);
   
 $stats{in} = $in;
 $stats{out} = $out;
}


#####################################################################
# MPD functions
#*******************************************************************
# HANGUP MPD
# hangup_mpd($SERVER, $PORT)
#*******************************************************************
sub hangup_mpd {
 my ($NAS, $PORT) = @_;


 my $ctl_port = "pptp$PORT";
 my @commands = ();
 
 push @commands, "\]\tlink $ctl_port";
 push @commands, "\]\tlink $ctl_port";
 push @commands, "\]\tclose";
 push @commands, "\] exit";

 my $result = telnet_cmd("$mng_ip:$mng_port", \@commands);
 print $result;


 return 0;
}

#*******************************************************************
# Get stats from MPD
# stats_mpd($SERVER, $PORT)
#*******************************************************************
sub stats_mpd {
 my ($NAS, $PORT) = @_;

 my $ctlport = $mng_port + $PORT;
 my $out  = `$PPPCTL -p "$mng_password" $NAS:$ctlport ! echo OCTETSIN OCTETSOUT USER`;
 my ($in, $out, $user) = split(/ +/, $out);
   
 $stats{in} = $in;
 $stats{out} = $out;
}


sub log_print2 {
 my ($type, $text) = @_;
 print "$type - $text\n";

}


#####################################################################
# radppp functions
#*******************************************************************
# HANGUP radpppd
# hangup_radpppd($SERVER, $PORT)
#*******************************************************************
sub hangup_radpppd {
 my ($NAS, $PORT) = @_;

my $RUN_DIR='/var/run';
my $AWK='/bin/awk';
my $CAT='/bin/cat';
my $GREP='/bin/grep';
my $ROUTE='/sbin/route';
my $KILL='/bin/kill';
#my $PPP_ID=`$ROUTE -n | $GREP ppp$PORT | $AWK {'print $8'}`;
my $PID_FILE="$RUN_DIR/PPP$NAS_PORT.pid";
my $PPP_PID=`$CAT $PID_FILE`;
my $a = `$KILL -1 $PPP_PID`;

 return 0;
}


#*******************************************************************
# Get stats for pppd connection from firewall
# 
# get_pppd_stats ($SERVER, $PORT, $IP)
#*******************************************************************
sub stats_pppd  {
  my ($NAS, $PORT, $IP) = @_;	

  my $firstnumber = 1000;
  my $step = 10;
  my $innum = $firstnumber + $PORT * $step;
  my $outnum = $firstnumber + $PORT * $step + 5;

  $stats{$NAS}{$PORT}{in} = 0;
  $stats{$NAS}{$PORT}{out} = 0;

  # 01000    369242     53878162 count ip from any to any in via 217.196.163.253
  open(FW, "/usr/sbin/ipfw $innum $outnum") || die "Can't open '/usr/sbin/ipfw' $!\n";
    while(<FW>) {
        ($num, $bbyte, $bytes, $trash)=split(/ +/, $_, 4);
    	if($innum  == $num) {
    	   $stats{$SERVER}{$PORT}{in} = $bytes;
    	 }
        elsif($outnum == $num) {
           $stats{$SERVER}{$PORT}{in} = $bytes;
         }
      }
  close(FW);

}


1
