#!/usr/bin/perl
# NAS controlling functions
# get_acct_info
# hangup
# check_activity
#
#
#*******************************************************************


use BER;
use SNMP_Session;
use SNMP_util;
use Radius;

my $PPPCTL = '/usr/sbin/pppctl';
my $SUDO = '/usr/local/bin/sudo';

#my $NAS_INFO = nas_params();
my $NAS;
my $nas_type = '';


my %stats = ();





#*******************************************************************
# Hangup active port
# hangup($NAS_HASH_REF, $PORT, $USER, $attr);
#*******************************************************************
sub hangup {
 my ($Nas, $PORT, $USER, $attr) = @_;

 $NAS = $Nas;
 $nas_type = $NAS->{NAS_TYPE};

 if ($nas_type eq 'exppp') {
   hangup_exppp($NAS, $PORT, $attr);
  }
 elsif ($nas_type eq 'pm25') {
   hangup_pm25($NAS, $PORT, $attr);
  }
 elsif ($nas_type eq 'radpppd') {
   hangup_radpppd($NAS, $PORT, $attr);
  }
 elsif ($nas_type eq 'mikrotik') {
   hangup_radius($NAS, $PORT, $USER);
   #hangup_mikrotik_telnet($NAS, $PORT, $USER);
  }
 elsif ($nas_type eq 'chillispot') {
   hangup_radius($NAS, $PORT, $USER);
  }
 elsif ($nas_type eq 'usr') {
   hangup_snmp($NAS, $PORT, { OID   => '.1.3.6.1.4.1.429.4.10.13.'. $PORT,
   	                          TYPE  => 'integer',
   	                          VALUE => 9 });
  }
 elsif ($nas_type eq 'cisco')  {
 	 hangup_cisco($NAS, $PORT, { USER => $USER, %$attr });
  }
 elsif ($nas_type eq 'mpd') {
   hangup_mpd($NAS, $PORT);
  }
 elsif ($nas_type eq 'mpd4') {
   hangup_mpd4($NAS, $PORT, $attr);
  }
 elsif ($nas_type eq 'mpd5') {
   hangup_mpd5($NAS, $PORT, $attr);
  }
 elsif ($nas_type eq 'openvpn') {
   hangup_openvpn($NAS, $PORT, $USER);
  } 
 elsif ($nas_type eq 'ipcad') {
   hangup_ipcad($NAS, $PORT, $USER, $attr);
  }
 elsif ($nas_type eq 'patton')  {
 	 hangup_patton29xx($NAS, $PORT, $attr);
  }
 elsif ($nas_type eq 'pppd' || $nas_type eq 'lepppd') {
   hangup_pppd($NAS, $PORT, $attr);
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
 my ($Nas, $PORT, $attr) = @_;
 
 $NAS = $Nas;
 $nas_type = $NAS->{NAS_TYPE};

 if ($nas_type eq 'usr')       {
    %stats = stats_usrns($NAS, $PORT);
  }
 elsif ($nas_type eq 'patton')   {
    %stats = stats_patton29xx($NAS, $PORT);
  }
 elsif ($nas_type eq 'pm25')   {
    %stats = stats_pm25($NAS, $PORT);
  }
 elsif ($nas_type eq 'dslmax') {
    my $user_ip_address = $attr->{user_ip_address};
    %stats = stats_dslmax($NAS, $PORT, $user_ip_address);
  }
 else {
    return undef;
  }


 return \%stats;
}



#*******************************************************************
#
# telnet_cmd($hostname, $login, $password, $commands)
#*******************************************************************
sub telnet_cmd {
 my($hostname, $commands, $attr)=@_;
 my $port = 23;


 if ($hostname =~ /:/) {
   ($hostname, $port)=split(/:/, $hostname, 2);
 }

# my $debug   = (defined($attr->{debug})) ? 1 : 0;
 my $timeout = defined($attr->{'TimeOut'}) ? $attr->{'TimeOut'} : 5;
 


 use Socket;
 my $dest = sockaddr_in($port, inet_aton("$hostname"));

 if(! socket(SH, PF_INET, SOCK_STREAM, getprotobyname('tcp'))) {
 	 print "ERR: Can't init '$hostname:$port' $!";
   return 0;
  }

 

 if(! CORE::connect(SH, $dest) ) { 
   print "ERR: Can't connect to '$hostname:$port' $!";
   return 0;
  }

 log_print('LOG_DEBUG', "Connected to $hostname:$port");

 my $sock  = \*SH;
 my $MAXBUF= 512;
 my $input = '';
 my $len   = 0;
 my $text  = '';
 my $inbuf = '';
 my $res   = '';


 my $old_fh = select($SH); $| = 1; select($old_fh);

 SH->autoflush(1);



foreach my $line (@$commands) {

  my ($waitfor, $sendtext)=split(/\t/, $line, 2);

  $input = '';
  
  if ($waitfor eq '-') {
    #send($sock, "$sendtext\r\n", 0, $dest) or die log_print('LOG_INFO', "Can't send: '$text' $!");
    send($sock, "$sendtext\n", 0, $dest) or die log_print('LOG_INFO', "Can't send: '$text' $!");
   }

  do {
     recv($sock, $inbuf, $MAXBUF, 0);
     $input .= $inbuf;
     $len = length($inbuf);
     alarm 5;
    } while ($len >= $MAXBUF || $len < 4);


 
  log_print('LOG_DEBUG', "Get: \"$input\"\nLength: $len");
  log_print('LOG_DEBUG', " Wait for: '$waitfor'");

  if ($input =~ /$waitfor/ig){ # || $waitfor eq '') {
    $text = $sendtext;
    log_print('LOG_DEBUG', "Send: $text");
    #send($sock, "$text\r\n", 0, $dest) or die log_print('LOG_INFO', "Can't send: '$text' $!");
    send($sock, "$text\n", 0, $dest) or die log_print('LOG_INFO', "Can't send: '$text' $!");
    #"Can't send: $!\n";
   };

 $res .= "$input\n";
 
 #print "<pre>$res</pre>";

}


 #print "<pre>$res</pre>";
 close(SH);
 return $res;

}


#**********************************************************
#
#**********************************************************
sub telnet_cmd2 {
 my($host, $commands, $attr)=@_;
 my $port = 23;

 if ($host =~ /:/) {
   ($host, $port)=split(/:/, $host, 2);
 }

 use IO::Socket;
 use IO::Select;
 my $data;
 my $res;

 my $timeout = defined($attr->{'TimeOut'}) ? $attr->{'TimeOut'} : 5;
 my	$socket = new IO::Socket::INET(
				PeerAddr => $host,
				PeerPort => $port,
				Proto    => 'tcp',
				TimeOut  => $timeout
	) or log_print('LOG_DEBUG', "ERR: Can't connect to '$host:$port' $!");
  log_print('LOG_DEBUG', "Connected to $host:$port"); 

	#my $sh = new IO::Select($socket) or return "Can't read";
	#$sh->can_read($timeout) or return "Time Out";

#$s = IO::Select->new();
#           $s->add(\*STDIN);
#           $s->add($socket);
#@read_from = $s->can_read($timeout) or print "Time Out";
#
#foreach $line (@read_from) {
#    print $line;
#    # read the pending data from $socket
#    
#}




foreach my $line (@$commands) {
  my ($waitfor, $sendtext)=split(/\t/, $line, 2);
#
  $socket->send("$sendtext");
  while(<$socket>) {
    $res .= $_;
  }
}

 close($socket);

 return $res;

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

  my %stats = (in  => 0,
               out => 0);

  my $PM25_PORT=$PORT+2;
  my $SNMP_COM = $NAS->{NAS_MNG_PASSWORD} || '';
  #my $in  = `$SNMPWALK -v 1 -c "$SNMP_COM" $NAS->{NAS_IP} IF-MIB::ifInOctets.$PM25_PORT | awk '{print \$4}'`;
  #my $out = `$SNMPWALK -v 1 -c "$SNMP_COM" $NAS->{NAS_IP} IF-MIB::ifOutOctets.$PM25_PORT  | awk '{print \$4}'`;


  my ($in) = snmpget($SNMP_COM .'@'. $NAS->{NAS_IP},  ".1.3.6.1.2.1.2.2.1.10.$PM25_PORT");
  my ($out) = snmpget($SNMP_COM .'@'.$NAS->{NAS_IP}, ".1.3.6.1.2.1.2.2.1.16.$PM25_PORT");

 
if (! defined($in)) {
  $stats{error}=1;
} 
elsif (int($in) + int($out) > 0) {
  $stats{in}  = int($in);
  $stats{out} = int($out);
}


  return %stats;
}

#*******************************************************************
# HANGUP pm25
# hangup_pm25($SERVER, $PORT)
#*******************************************************************
sub hangup_pm25 {
 my ($NAS_IP, $PORT) = @_;

 push @commands, "login:\t$NAS->{NAS_MNG_USER}";
 push @commands, "Password:\t$NAS->{NAS_MNG_PASSWORD}";
 push @commands, ">\treset S$PORT";
 push @commands, ">exit";

 my $result = telnet_cmd("$NAS->{NAS_IP}", \@commands);
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
  my $SNMP_COM = $NAS->{NAS_MNG_PASSWORD} || '';
  
#USR trafic taker
  my $in  = `a=\`$SNMPWALK -v 1 -c "$SNMP_COM" $NAS->{NAS_IP} interfaces.ifTable.ifEntry.ifInOctets.$PORT  | awk '{print \$4}'\`; b=\`cat /usr/abills/var/devices/$NAS->{NAS_IP}-$PORT.In\`; c=\`expr \$a - \$b + 0\`; echo \$c`;
  my $out = `a=\`$SNMPWALK -v 1 -c "$SNMP_COM" $NAS->{NAS_IP} interfaces.ifTable.ifEntry.ifOutOctets.$PORT  | awk '{print \$4}'\`; b=\`cat /usr/abills/var/devices/$NAS->{NAS_IP}-$PORT.Out\`; c=\`expr \$a - \$b + 0\`; echo \$c`;
# $SNMPWALK -v 1 -c $SNMP_COM $SERVER interfaces.ifTable.ifEntry.ifInOctets.$PORT | awk '{print \$4}' `a=`$SNMPWALK -v 1 -c tstats 192.168.101.130 interfaces.ifTable.ifEntry.ifInOctets.$PORT | awk '{print \$4}'`; b=`cat /usr/abills/var/devices/$SERVER-$PORT.In`; c=`expr \$a - \$b + 0`; echo \$c`;
#
  $stats{in} = int($in);
  $stats{out} = int($out);
  
  return %stats;
}






####################################################################
# Standart FreeBSD ppp
#********************************************************************
# get accounting information from FreeBSD ppp using remove accountin 
# scrips
# stats_ppp($NAS)
#********************************************************************
sub stats_ppp {
 my ($NAS_IP, $PORT) = @_;
 use IO::Socket;
 my $port = 30006;

 my ($ip, $mng_port)=split(/:/, $NAS->{NAS_MNG_IP_PORT}, 2);
 $port =  $mng_port || 0;
 
 my $remote = IO::Socket::INET -> new(Proto    => "tcp", 
                                      PeerAddr => "$NAS",
                                      PeerPort => "$port")
 or print "cannot connect to pppcons port at $NAS->{NAS_IP}:$port $!\n";

while ( <$remote> ) {
      ($radport, $in, $out, $tun) = split(/ +/, $_);
#      print "--$port, $user, $time, $in, $out, $ip";
      $stats{$NAS->{NAS_IP}}{$radport}{in} = $in;
      $stats{$NAS->{NAS_IP}}{$radport}{out} = $out;
      $stats{$NAS->{NAS_IP}}{$radport}{tun} = $tun;
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
  my $SNMP_COM = $NAS->{NAS_MNG_PASSWORD} || '';

  my $output = `id=\`$SNMPWALK -c "$SNMP_COM" -v1 $NAS->{NAS_IP} RFC1213-MIB::ipRouteIfIndex.$IP | awk '{ print \$4 }'\`; a=\`$SNMPWALK -c "$SNMP_COM" -v1 $NAS IF-MIB::ifInOctets.\$id | awk '{print \$4}'\`; b=\`$SNMPWALK -c "$SNMP_COM" -v1 $NAS IF-MIB::ifOutOctets.\$id | awk '{print \$4}'\`; echo \$a \$b`;

  my ($in, $out)=split(/ /, $out);
  $stats{in} = $in;
  $stats{out} = $out;
  return %stats;
}

#**********************************************************
# Base SNMP set hangup function
#**********************************************************
sub hangup_snmp {
	my ($NAS, $PORT, $attr) = @_;

	my $oid  = $attr->{OID};
  my $type = $attr->{TYPE} || 'integer';
  my $value  = $attr->{VALUE};

  log_print('LOG_DEBUG', "SNMPSET: $NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP} $oid $type $value");  
	my $result = snmpset("$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", "$oid", "$type", $value);

  if ($SNMP_Session::errmsg) {
    log_print('LOG_ERR', "$SNMP_Session::errmrnings / $SNMP_Session::errmsg");
   }

	
  return $result;
}

#*******************************************************************
# hangup_hangup_radius
# 
# Radius-Disconnect messages
# rfc2882
#*******************************************************************
sub hangup_radius {
  my ($NAS, $PORT, $USER, $attr) = @_;
 
  my ($ip, $mng_port)=split(/:/, $NAS->{NAS_MNG_IP_PORT}, 2);
  log_print('LOG_DEBUG', " HANGUP: User-Name=$USER NAS_MNG: $ip:$mng_port '$NAS->{NAS_MNG_PASSWORD}' \n"); 

  my %RAD_PAIRS = ();
  my $type;
  my $r = new Radius(Host   => "$NAS->{NAS_MNG_IP_PORT}", 
                     Secret => "$NAS->{NAS_MNG_PASSWORD}") or return "Can't connect '$NAS->{NAS_MNG_IP_PORT}' $!";

  $conf{'dictionary'}='/usr/abills/Abills/dictionary' if (! $conf{'dictionary'});

  $r->load_dictionary($conf{'dictionary'});

  $r->add_attributes ({ Name => 'User-Name', Value => "$USER" });
  $r->send_packet (POD_REQUEST) and $type = $r->recv_packet;

  if( ! defined $type ) {
    # No responce from POD server
    die('No responce from POD server');
   }
  
  return $result;
}


#*******************************************************************
# hangup_mikrotik_telnet
#*******************************************************************
sub hangup_mikrotik_telnet {
  my ($NAS_IP, $PORT, $USER) = @_;

 
 push @commands, "Login:\t$NAS->{NAS_MNG_USER}";
 push @commands, "Password:\t$NAS->{NAS_MNG_PASSWORD}";
 push @commands, ">/interface pptp-server remove [find user=$USER]";
 push @commands, ">quit";

  my $result = telnet_cmd_new("$NAS->{NAS_IP}", \@commands);
 
  print $result;
}


#*******************************************************************
# hangup_ipcad
#*******************************************************************
sub hangup_ipcad {
  my ($NAS_IP, $PORT, $USER_NAME, $attr) = @_;

  require Ipn;
  Ipn->import();
  my $Ipn      = Ipn->new($db, \%conf);
  
  $Ipn->acct_stop({ %$attr, SESSION_ID => $attr->{ACCT_SESSION_ID} });

  my $cmd     = $conf{IPN_FW_STOP_RULE};
  my $ip      = $attr->{FRAMED_IP_ADDRESS};
  my $netmask = $attr->{NETMASK} || 32;
  
  my $num = 0;
  if ($attr->{UID} && $conf{IPN_FW_RULE_UID}) {
  	$num = $attr->{UID};
   }
  else {
    my @ip_array = split(/\./, $ip, 4);
    $num = $ip_array[3];
   }

  my $rule_num = $conf{IPN_FW_FIRST_RULE} || 20000;
  $rule_num = $rule_num + 10000 + $num;


  $cmd =~ s/\%IP/$ip/g;
  $cmd =~ s/\%MASK/$netmask/g;
  $cmd =~ s/\%NUM/$rule_num/g;
  $cmd =~ s/\%LOGIN/$USER_NAME/g;

  log_print('LOG_DEBUG', "$cmd");
  if ($attr->{debug} &&  $attr->{debug} > 4) {
  	print $cmd."\n";
   }
  print $cmd."\n";
  my $result = system($cmd);

  print $result;
}


#*******************************************************************
# hangup_openvpn 
#*******************************************************************
sub hangup_openvpn {
  my ($NAS, $PORT, $USER, $attr) = @_;

 my @commands=(">INFO:OpenVPN Management Interface Version 1 -- type 'help' for more info\tkill $USER",
               "SUCCESS: common name '$USER' found, 1 client(s) killed\texit");

 my $result = telnet_cmd("$NAS->{NAS_MNG_IP_PORT}", \@commands);
 log_print('LOG_DEBUG', "$result");

 return 0; 
}


#*******************************************************************
# HANGUP Cisco
# hangup_cisco($SERVER, $PORT)
#
# Cisco config  for rsh functions:
#
# ip rcmd rcp-enable
# ip rcmd rsh-enable
# no ip rcmd domain-lookup
# ! ip rcmd remote-host имя_юзера_на_cisco IP_address_или_имя_компа_с_которого_запускается_скрипт имя_юзера_от_чьего_имени_будет_запукаться_скрипт enable
# ! например
# ip rcmd remote-host admin 192.168.0.254 root enable
#
#*******************************************************************
sub hangup_cisco {
 my ($NAS, $PORT, $attr) = @_;
 my $exec;
 my $command = '';
 my $user = $attr->{USER};

 my ($ip, $mng_port)=split(/:/, $NAS->{NAS_MNG_IP_PORT}, 2);

#POD Version
if ($mng_port == 1700) {
	hangup_radius($NAS, $PORT, "$user", $attr);
 }
#Rsh version
elsif ($NAS->{NAS_MNG_USER}) {
# имя юзера на циско котрому разрешен rsh и хватает привелегий для сброса
  my $cisco_user=$NAS->{NAS_MNG_USER};
# использование: NAS-IP-Address NAS-Port SQL-User-Name

  if ($PORT > 0) {
    $|=1;
    $command = "(/bin/sleep 5; /bin/echo 'y') | /usr/bin/rsh -4 -l $cisco_user $NAS->{NAS_IP} clear line $PORT";
    log_print('LOG_DEBUG', "$command");
    $exec = `$command`;
    return $exec;
   }

  $command = "/usr/bin/rsh -l $cisco_user $NAS->{NAS_IP} show users | grep -i \" $user \" ";
#| awk '{print \$1}';";
  log_print('LOG_DEBUG', "$command");
  my $out=`$command`;

  if ( $out eq '') {
    print 'Can\'t get VIRTUALINT. Check permissions';
    return 'Can\'t get VIRTUALINT. Check permissions';
   }


  my $VIRTUALINT;

  if ($out =~ /\s+(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+(\S+)/) { 
    $VIRTUALINT=$1; 
    $tty=$2; 
    $line=$3;
    $cuser=$4;
    $chost=$5;

    print "$VIRTUALINT, $tty, $line, $cuser, $chost";
  }

  $command = "echo $VIRTUALINT echo  | sed -e \"s/[[:alpha:]]*\\([[:digit:]]\\{1,\\}\\)/\\1/\"";
  log_print('LOG_DEBUG', "$command");
  $PORT=`$command`;
  $command = "/usr/bin/rsh -4 -n -l $cisco_user $NAS->{NAS_IP} clear interface Virtual-Access $PORT";
  log_print('LOG_DEBUG', "$command");
  $exec = `$command`; 
 }
else {
#SNMP version
  my $SNMP_COM = $NAS->{NAS_MNG_PASSWORD} || '';

  #$command = "$SNMPWALK -On -v 1 -c \"$SNMP_COM\" $NAS->{NAS_IP} .1.3.6.1.2.1.4.21.1.2.$attr->{FRAMED_IP_ADDRESS} | awk '{print \$4 }'";
  #log_print('LOG_DEBUG', "$command");
  #my $INTNUM=`$command`;
  
  my $INTNUM = snmpget("$SNMP_COM\@$NAS->{NAS_IP}", ".1.3.6.1.2.1.4.21.1.2.$attr->{FRAMED_IP_ADDRESS}");
  log_print('LOG_DEBUG', "SNMP: $SNMP_COM\@$NAS->{NAS_IP} .1.3.6.1.2.1.4.21.1.2.$attr->{FRAMED_IP_ADDRESS}");
  
  #$INTNUM =~ s/\n//;
  #$command = "$SNMPSET -v 1 -c \"$SNMP_COM\" $NAS->{NAS_IP} .1.3.6.1.2.1.2.2.1.7.$INTNUM i 2 > /dev/null 2>\&1";
  $exec = snmpset("$SNMP_COM\@$NAS->{NAS_IP}", ".1.3.6.1.2.1.2.2.1.7.$INTNUM", 'integer', 2);
  log_print('LOG_DEBUG', "SNMP: $SNMP_COM\@$NAS->{NAS_IP} .1.3.6.1.2.1.2.2.1.7.$INTNUM integer 2");
  #$exec=`$command`;
}

 return $exec;
}

#*******************************************************************
# HANGUP dslmax
# hangup_dslmax($SERVER, $PORT)
#*******************************************************************
sub hangup_dslmax {
 my ($NAS_IP, $PORT) = @_;

#cotrol
 my @commands = ();
 push @commands, "word:\t$NAS->{NAS_MNG_PASSWORD}";
 push @commands, ">\treset S$NAS->{PORT}";
 push @commands, ">exit";

 my $result = telnet_cmd("$NAS->{NAS_IP}", \@commands);

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
 my ($ip, $mng_port)=split(/:/, $NAS->{NAS_MNG_IP_PORT}, 2);
  
 my $ctl_port = $mng_port + $PORT;

# print "$PPPCTL -p \"$NAS->{NAS_MNG_PASSWORD}\" $NAS->{NAS_IP}:$ctl_port down";

 my $out=`$PPPCTL -p "$NAS->{NAS_MNG_PASSWORD}" $NAS->{NAS_IP}:$ctl_port down`;

  
 return 0;
}

#*******************************************************************
# Get stats from exppp
# get_exppp_stats($SERVER, $PORT)
#*******************************************************************
sub stats_exppp {
 my ($NAS, $PORT) = @_;
 my %stats = ();

 my ($ip, $mng_port)=split(/:/, $NAS->{NAS_MNG_IP_PORT}, 2);
 my $ctlport = $mng_port + $PORT;
 my $std_out  = `$PPPCTL -p "$NAS->{NAS_MNG_PASSWORD}" $NAS->{NAS_IP}:$ctlport ! echo OCTETSIN OCTETSOUT USER`;
 my ($in, $out, $user) = split(/ +/, $out);
   
 $stats{in} = $in;
 $stats{out} = $out;
 
 return %stats;
}



#*******************************************************************
# HANGUP MPD
# hangup_mpd4($SERVER, $PORT)
#*******************************************************************
sub hangup_mpd4 {
  my ($NAS, $PORT, $attr) = @_;

  my $ctl_port = "pptp$PORT";
  if ($attr->{ACCT_SESSION_ID}) {
  	if($attr->{ACCT_SESSION_ID} =~ /\d+\-(.+)/) {
  	  $ctl_port = $1;

  	 }
   } 
  
  my @commands=("\t",
                "Username: \t$NAS->{NAS_MNG_USER}",
                "Password: \t$NAS->{NAS_MNG_PASSWORD}",
                "\] \tbundle $ctl_port",
                "\] \tclose",
                "\] \texit");

  my $result = telnet_cmd("$NAS->{NAS_MNG_IP_PORT}", \@commands);
  return 0;
}

#*******************************************************************
# HANGUP MPD
# hangup_mpd5($SERVER, $PORT)
#*******************************************************************
sub hangup_mpd5 {
  my ($NAS, $PORT, $attr) = @_;

  my $ctl_port = "L-$PORT";
  if ($attr->{ACCT_SESSION_ID}) {
        if($attr->{ACCT_SESSION_ID} =~ /^\d+\-(.+)/) {
          $ctl_port = $1;
         }
   }

  log_print('LOG_DEBUG', " HANGUP: SESSION: $ctl_port NAS_MNG: $NAS->{NAS_MNG_IP_PORT} '$NAS->{NAS_MNG_PASSWORD}'\n");

  my @commands=("\t",
                "Username: \t$NAS->{NAS_MNG_USER}",
                "Password: \t$NAS->{NAS_MNG_PASSWORD}",
                "\] \tlink $ctl_port",
                "\] \tclose",
                "\] \texit");

  my $result = telnet_cmd("$NAS->{NAS_MNG_IP_PORT}", \@commands, { debug => 1 });

  return 0;
}

#*******************************************************************
# HANGUP MPD
# hangup_mpd($SERVER, $PORT)
#*******************************************************************
sub hangup_mpd {
 my ($NAS_IP, $PORT) = @_;

 my $ctl_port = "pptp$PORT";
 my @commands=("\]\tlink $ctl_port",
               "\]\tlink $ctl_port",
               "\]\tclose",
               "\]\texit");

 my $result = telnet_cmd("$NAS->{NAS_MNG_IP_PORT}", \@commands);
 print $result;
 return 0;
}

#*******************************************************************
# Get stats from MPD
# stats_mpd($SERVER, $PORT)
#*******************************************************************
sub stats_mpd {
 my ($NAS, $PORT) = @_;
 
 my ($ip, $mng_port)=split(/:/, $NAS->{NAS_MNG_IP_PORT}, 2);
 my $ctlport = $mng_port + $PORT;
 
 my $std_out  = `$PPPCTL -p "$NAS->{NAS_MNG_PASSWORD}" $NAS->{NAS_IP}:$ctlport ! echo OCTETSIN OCTETSOUT USER`;
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
 my ($NAS_IP, $PORT) = @_;

my $RUN_DIR='/var/run';
my $AWK='/bin/awk';
my $CAT='/bin/cat';
my $GREP='/bin/grep';
my $ROUTE='/sbin/route';
my $KILL='/bin/kill';

#my $PPP_ID=`$ROUTE -n | $GREP ppp$PORT | $AWK {'print $8'}`;
my $PID_FILE="$RUN_DIR/PPP$PORT.pid";
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

  $stats{$NAS->{NAS_IP}}{$PORT}{in} = 0;
  $stats{$NAS->{NAS_IP}}{$PORT}{out} = 0;

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


#******************************************************************* 
# HANGUP pppd 
# hangup_pppd($SERVER, $PORT) 
# add next string to  /etc/sudoers: 
# 
# apache   ALL = NOPASSWD: /usr/abills/misc/pppd_kill 
# 
#******************************************************************* 
sub hangup_pppd { 
 my ($NAS, $id, $attr) = @_; 
 my $IP =  $attr->{FRAMED_IP_ADDRESS} ; 
 my $result =  '';
 
 if ($NAS->{NAS_MNG_IP_PORT} =~ /:/) {
   my ($ip, $mng_port)=split(/:/, $NAS->{NAS_MNG_IP_PORT}, 2);	
   use IO::Socket;

   my $remote = IO::Socket::INET -> new(Proto    => "tcp", 
                                        PeerAddr => "$ip",
                                        PeerPort => $mng_port 
                                        )
    or die "cannot connect to rmstats port at $ip:$mng_port $!\n";

   print $remote "$IP\n";
   $result =  <$remote> ;
  }
 else {
   $result = system ("/usr/bin/sudo /usr/abills/misc/pppd_kill $IP"); 
  }


 return $result; 
} 




#*******************************************************************
# HANGUP Patton 29xx
#*******************************************************************
sub hangup_patton29xx {
 my ($NAS, $PORT, $attr) = @_;
 my $exec = '';
 
 
  # Get active sessions
  my %active = ();
  my @arr = snmpwalk("$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.3");
  foreach my $line (@arr) {
	  if ($line =~ /(\d+):6/) {
		  $active{$1}=1;
	   }
   }
  
  #Get iface
  @arr = snmpwalk("$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.9");
  foreach my $line (@arr) {
	  if ($line =~ /(\d+):(\d+)/) {
		  if ($2 == $PORT && $active{$1} ) {
		    $exec = snmpset("$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.3.$1", 'integer', 10);
		    #print " IFACE: $iface INDEX $1 IN: $in OUT: $out\n";
		    last;
       }
	   }
  }

  
  
 


 return $exec;
}


#*******************************************************************
# Get stats from Patton RAS 29xx
# 
#*******************************************************************
sub stats_patton29xx {
  my ($NAS, $PORT) = @_;

  my %stats = (in  => 0,
               out => 0);

  # Get active sessions
  my %active = ();
  my @arr = snmpwalk("$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.3");
  foreach my $line (@arr) {
	  if ($line =~ /(\d+):6/) {
		  $active{$1}=1;
	   }
   }

  #Get iface
  @arr = snmpwalk("$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.9");
  foreach my $line (@arr) {
	  if ($line =~ /(\d+):(\d+)/) {
		  if ($2 == $PORT && $active{$1} ) {
		    $stats{out} = snmpget("$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.36.$1");
		    $stats{in} = snmpget("$NAS->{NAS_MNG_PASSWORD}\@$NAS->{NAS_IP}", ".1.3.6.1.4.1.1768.5.100.1.37.$1");

        log_print('LOG_DEBUG', "IFACE: $line INDEX $1 IN: $stats{in} OUT: $stats{out}");
		    last;
       }
	   }
  }

  return %stats;
}




1
