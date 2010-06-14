# billd plugin
#
# DESCRIBE: Check dublicate logins and hangup it
#
#**********************************************************

check_dublicates();


#**********************************************************
#
#
#**********************************************************
sub check_dublicates {

print "Check dublicates\n" if ($debug > 1);

# TOTAL : SAME CID
$conf{DV_SIM_CONTROL} = "1:2" if (! $conf{DV_SIM_CONTROL});

my ($UNIQUE_CIDS, $SAME_CIDS) = split(/:/, $conf{DV_SIM_CONTROL});

$admin->query($db, "SELECT c.user_name, INET_NTOA(framed_ip_address), c.nas_port_id, 
   if (dv.logins > 0, dv.logins, tp.logins), c.acct_session_id, c.uid,
   nas.id,
   nas.ip,
   nas.nas_type,
   mng_host_port,
   mng_user,
   mng_password,
   c.CID
                  FROM dv_calls c, dv_main dv, tarif_plans tp, nas
                  WHERE c.uid=dv.uid 
                  AND c.status<11
                  AND dv.tp_id=tp.id AND tp.domain_id=0
                  AND c.nas_id=nas.id
                  ;");	

my %logins = ();
my %CIDS   = ();

foreach my $line ( @{ $admin->{list} } ) {
  print "$line->[0] $line->[1] $line->[2] $line->[3]\n" if ($debug > 1);	

  my %NAS = ( 
   NAS_ID           => $line->[6],
   NAS_IP           => $line->[7],
   NAS_TYPE         => $line->[8],
   NAS_MNG_IP_PORT  => $line->[9],
   NAS_MNG_USER     => $line->[10], 
   NAS_MNG_PASSWORD => $line->[11]
  );
	
	$logins{$line->[0]}{TOTAL}++;
  if ($CIDS{$line->[0]}{$line->[12]}) {
    $logins{$line->[0]}{SAME_CID}++;
   }
  else {
  	$logins{$line->[0]}{UNIQUE_CID}++;
   }

  $CIDS{$line->[0]}{$line->[12]}++;


	#if ($logins{$line->[0]} > $line->[3] || $CIDS{$line->[0]}{$line->[12]} > $conf{DV_SIM_CID}) {
	if (int($logins{$line->[0]}{UNIQUE_CID}) > $UNIQUE_CIDS || int($CIDS{$line->[0]}{$line->[12]}) > $SAME_CIDS) {
		 print "Hangap dublicate '$line->[0]'\n";
		 my $ret = hangup(\%NAS, "$line->[2]", "$line->[0]", { ACCT_SESSION_ID      => $line->[4],
        	                                                 FRAMED_IP_ADDRESS    => $line->[1],
           	                                               UID                  => $line->[5],
           	                                               debug                => $debug
        	                                                  }); 
	 }
	
}
	
	
}


1
