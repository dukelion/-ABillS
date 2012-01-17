#!/usr/bin/perl -w
# Auto configure service for mpd5


use vars  qw(%conf 
  $DATE $TIME
  $begin_time
 );


use strict;
use FindBin '$Bin';

my $VERSION     = 2.0;
my $config_file = $Bin . '/../../libexec/config.pl';
my $debug       = 0;
my $mpd_main_tpl = qq{
#ABillS Vlan MPD config
startup:
        # enable TCP-Wrapper (hosts_access(5)) to block unfriendly clients
        set global enable tcp-wrapper
        # configure the console
        set console self %NAS_IP% 5005
        set user admin mpdsecret admin
        set console open
        #WEB managment
        #set web self 0.0.0.0 5006
        #set web open
        #Netflow options
        #set netflow peer %MPD_NETFLOW_IP% %MPD_NETFLOW_PORT%
        #set netflow self %MPD_NETFLOW_SOURCE_IP% %MPD_NETFLOW_SOURCE_PORT%
        #set netflow timeouts 15 15
        #set netflow hook 9000
        #set netflow node netflow
        log -echo -radius -rep


default:
#  load pptp_server
  load pppoe_server

  
pppoe_server:
      create link template L pppoe
      set link enable multilink
      set link disable pap eap chap
      set link enable chap-md5
      load radius
      set pppoe service *
      set link enable peer-as-calling
      set ippool add pool12 192.168.16.2 192.168.19.254
%PPPOE_LINKS%


server_common:
      set link no pap eap
      set link yes chap-md5
      set link keep-alive 20 60
      set link enable incoming
      set link no acfcomp protocomp
      load radius


radius:
     #IP, пароль и порты RADIUS-сервера
     set radius server %RADIUS_AUTH_SERVER% %RADIUS_SECRET% 1812 1813
     #set radius config /etc/radius.conf
     set radius retries 3
     set radius timeout 10
     set auth acct-update 300
     set auth enable radius-auth
     set auth enable radius-acct
     set auth disable internal

};

my $mpd_pppoe_tpl = qq{ #%PPPOE_INTERFACE% %DESCRIBE%
      create bundle template %PPPOE_INTERFACE%
      set iface up-script   "/usr/abills/libexec/linkupdown mpd up"
      set iface down-script "/usr/abills/libexec/linkupdown mpd down"
      set ipcp dns %DNS_SERVER%
      set ipcp ranges 10.10.0.1 ippool pool1
      create link template %PPPOE_INTERFACE% L
      set link action bundle %PPPOE_INTERFACE%
      set pppoe iface %PPPOE_INTERFACE%
      set link enable incoming
};


require $Bin . '/../../Abills/Base.pm';
Abills::Base->import();


my $ARGV = parse_arguments(\@ARGV);

my $mpd_conf = $ARGV->{OUTPUT_FILE} || '/usr/local/etc/mpd5/mpd.conf';

if ($ARGV->{debug}) {
  $debug=int($ARGV->{debug});
  print "Debug mode: $debug\n";
}

if(defined($ARGV->{help})) {
	help();
	exit;
}



if ($ARGV->{INTERFACES}) {
  while(my($key, $val)=each %$ARGV) {
  	$conf{$key}=$val;
   }

	my $pppoe_tpl = '';
	my @ifaces_arr = split(/,/, $ARGV->{INTERFACES});
  foreach my $if (@ifaces_arr) {
    my $tmp_tpl = $mpd_pppoe_tpl;

    $tmp_tpl = tpl_parse($tmp_tpl, { %conf, %$ARGV, PPPOE_INTERFACE => $if });
    $pppoe_tpl .= $tmp_tpl;
   }	

  $mpd_main_tpl = tpl_parse($mpd_main_tpl, { %$ARGV, PPPOE_LINKS => $pppoe_tpl });

  if ($debug > 1) {
    print $mpd_main_tpl;
   }
  else{
  	open(FILE, ">$mpd_conf") or die "Can't open file '$mpd_conf' $!\n";
  	  print FILE $mpd_main_tpl;
  	close(FILE);
   }
}



#**********************************************************
#
#**********************************************************
sub help {
	
print << "[END]";
  MPD_MAIN_TPL   - main mpd.tpl
  MPD_PPPOE_TPL  - pppoe section
  OUTPUT_FILE    - MPD Output config
  INTERFACES     - PPPoE interfaces
  help           -

[END]

	
	
}


1