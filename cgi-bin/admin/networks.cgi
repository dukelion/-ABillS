#!/usr/bin/perl
# Network interface
# ~AsmodeuS~ (2005-01-05)


use Abwconf;
my $db=$Abwconf::db;
my $NSLOOKUP = "/usr/sbin/nslookup";              # nslookup binary

my @host_types = ('host', 'network');
my @scolors = ("#00FF00", "#FF0000", "#AAAAFF");

print "Content-Type: text/html\n\n";
header();
print "<center>";
require "../../language/$language.pl";


my %menu = ('1::', $_NETWORKS,
         '2::revision', $_REVISION,
         '3::domains',  _DOMAINS,
         '3:users.cgi:',  _BILLING,
        );


show_menu(0, 'op', "", \%menu);





if($op eq 'revision')   { revision(); }
elsif($op eq 'domains') { domains();  }
else {
  networks();
}



#**********************************************************
#
# domains();
#**********************************************************
sub domains {

use Data::Dumper;

$hostname = $ARGV[0]; #$FORM{hostname} || '';
@servers = qw(yes.ko.if.ua); # sky.yes.ko.if.ua ns.yes.ko.if.ua); # name of the name servers

foreach $server (@servers) {
    &lookupaddress($hostname,$server);              # populates %results
}

%inv = reverse %results;                            # invert the result hash
if (scalar(keys %inv) > 1) {                       
    print "There is a discrepancy between DNS servers:\n";
    print Data::Dumper->Dump([\%results],["results"]),"\n";
}

print << "[END]";
<FORM action=$SELF>
<input type=hidden name=op value=domains>
<Table>
<tr><td>Hostname:</td><td><input type=text name=hostname value='$hostname'></td></tr>
</Table>
<input type=submit name=show value=$_SHOW>
[END]
}


#********************************************************************
# ask the server to look up the IP address for the host
# passed into this program on the command line, add info to 
# the %results hash
# lookupaddress($hostname,$server);
#********************************************************************
sub lookupaddress {
    my($hostname,$server) = @_;


    open(NSLOOK,"$NSLOOKUP $hostname $server|") or
      die "Unable to start nslookup:$!\n";
    
     while (<NSLOOK>) {
        # ignore until we hit "Name: "
 	    next until (/^Name/);              
        print $_ ;
        # next line is Address: response
 	    chomp($results{$server} = <NSLOOK>); 
        # remove the field name
        #print "nslookup output error\n" unless /Address/;
	#    $results{$server} =~ s/Address(es)?:\s+//;	    
        # we're done with this nslookup 
        #last;    
    }
    close(NSLOOK);

}

#**********************************************************
# Network revision
#**********************************************************
sub revision {
 my $count = $FORM{count} || 0;
 my $begin_ip = $FORM{begin_ip} || '0.0.0.0';
 print "<h3>$_REVISION</h3>\n";


if ($FORM{revision}) {
  $bint_ip = ip2int($begin_ip);
  $eint_ip = ($count > 0) ? $bint_ip + $count : ip2int($FORM{end_ip});

use Net::Ping;
#$png = Net::Ping -> new('icmp');

=comments
$p = Net::Ping->new("icmp");
           foreach $host (@host_array)
           {
               print "$host is ";
               print "NOT " unless $p->ping($host, 2);
               print "reachable.\n";
               sleep(1);
           }
           $p->close();
=cut


print "<form action=$SELF>
<input type=hidden name=op value=revision>
<TABLE width=640 cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n";

for (my $sv = $bint_ip; $sv<$eint_ip; $sv++) {
  $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
  my $ip = int2ip($sv);
  print "<tr bgcolor=$bg><th><input type=checkbox name=cip value='$ip'></th><td>$ip</td><th bgcolor=$scolors[$status]>$status_types[$status]</th></tr>\n";
}

print "</table></td></tr></table>
<input type=submit name=add value='$_ADD'>
</form>\n";
	
}
elsif($FORM{add}) {
  message('info', $_INFO, "$FORM{cip}");	
}


print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=revision>
<table>
<tr><td>$_BEGIN IP:</td><td><input type=text name=begin_ip value='$begin_ip'></td></tr>
<tr><td>$_END IP:</td><td><input type=text name=end_ip value='$end_ip'></td></tr>
<tr><td>$_COUNT:</td><td><input type=text name=count value='$count'></td></tr>
</table>
<input type=submit name=revision value=revision>
</form>
[END]
}

#**********************************************************
# networks();
#**********************************************************
sub networks {
 my $ip = $FORM{ip} || '0.0.0.0';
 my $netmask = $FORM{netmask} || '255.255.255.255';
 my $domainname = $FORM{domainname} || '';
 my $hostname = $FORM{hostname} || '';
 my $descr = $FORM{descr} || '';
 my $type = $FORM{type} || 0;
 my $mac = $FORM{mac} || '';
 my $status = $FORM{status} || 0;


 show_networks();
 
my @action = ('add', "$_ADD");

if ($FORM{add}) {
  $sql = "INSERT INTO networks 
   (ip, netmask, domainname, hostname,  descr, changed, type, mac, status) values
   (INET_ATON('$ip'), INET_ATON('$netmask'), '$domainname', '$hostname', '$descr', now(), '$type', '$mac', '$status');";
  $q = $db->do($sql);
    
  if ($db->err == 1062) {
    message('err', "$_ERROR", "[$ip/$netmask] $_EXIST");
   }
  elsif($db->err > 0) {
    message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
   }
  else {
    message('info', $_INFO, "$_ADDED [$ip/$netmask]");
   }
}
elsif($FORM{change}) {
  my($chg_ip, $chg_netmask)=split(/ /, $FORM{chg});
  $sql = "UPDATE networks SET
   ip=INET_ATON('$ip'), 
   netmask=INET_ATON('$netmask'), 
   domainname='$domainname', 
   hostname='$hostname',  
   descr='$descr', 
   changed=now(), 
   type='$type', 
   mac='$mac',
   status='$status'
   WHERE id='$FORM{chg}';";
  $q = $db->do($sql);
	
  message('info', $_INFO, "$_CHANGED [$ip/$netmask]");
}
elsif($FORM{chg}) {

  $sql = "SELECT INET_NTOA(ip), INET_NTOA(netmask), domainname, hostname,  descr, changed, type, mac, status 
     FROM networks WHERE id='$FORM{chg}';";
  my $q = $db->prepare("$sql");

  $q->execute();
  ($ip, $netmask, $domainname, $hostname, $descr, $changed, $type, $mac, $status)  = $q->fetchrow_array();
  @action = ('change', "$_CHANGE");
  message('info', $_INFO, "$_CHANGING [$ip/$netmask]");
}
elsif($FORM{del}) {
  $sql = "DELETE FROM networks WHERE id='$FORM{del}';";
  $q = $db->do($sql);
  message('info', $_INFO, "$_DELTED [$ip/$netmask]");
}



print << "[END]";	
<p>
<form action=$SELF>
<input type=hidden name=op value=networks>
<input type=hidden name=chg value='$FORM{chg}'>
<Table width=400>
<tr><td colspan=2>IP:</td><td><input type=text name=ip value="$ip"></td></tr>
<tr><td colspan=2>NETMASK:</td><td><input type=text name=netmask value="$netmask"></td></tr>
<tr><td  colspan=2>$_TYPE:</td><td><select name=type> 
[END]

my $i=0;
foreach my $t (@host_types) {
 print "<option value=$i";
 print " selected" if ($i == $type);
 print ">$t\n";	
 $i++;
}

print "</select></td></tr>
<tr><td  colspan=2>$_STATUS:</td><td><select name=status>\n";


my $i=0;
foreach my $t (@status_types) {
 print "<option value=$i";
 print " selected" if ($i == $status);
 print ">$t\n";	
 $i++;
}



print << "[END]";
</select></td></tr>
<tr><td rowspan=2>DNS</td><td>name</td><td><input type=text name=hostname value="$hostname"></td></tr>
<tr><td>domain</td><td><input type=text name=domainname value="$domainname"></td></tr>
<tr><td colspan=2>MAC:</td><td><input type=text name=mac value="$mac"></td></tr>
<tr><td colspan=2>$_CHANGED:</td><td>$changed</td></tr>
<tr><th colspan=3 bgcolor=$_BG0>$_DESCRIBE:</th></tr>
<tr><td colspan=3><textarea name=descr cols=70 rows=10>$descr</textarea></td></tr>
</table>
<input type=submit name=$action[0] value=$action[1]>
</form>
</P>
[END]


}


#*******************************************************************
# show_networs()
#*******************************************************************
sub show_networks () {

my $sql = "SELECT id, INET_NTOA(ip), INET_NTOA(netmask), descr, 
     status, changed, type, mac 
     FROM networks WHERE type=1
     ORDER BY $sort $desc;";

my $q = $db->prepare("$sql");
$q->execute();
my $total = $q->rows;

print "<h3>$_NETWORKS</h3>
$_TOTAL: $total<br>
<TABLE width=90% cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <COLGROUP>
    <COL align=center span=1>
    <COL align=right span=2>
    <COL align=left span=1>
    <COL align=center span=4>
  </COLGROUP>\n";

 my @caption = ("-", "IP", "NETMASK", "$_DESCRIBE", "$_STATUS", "-", "-", "-");
 show_title($sort, $desc, "$pg", "$op&$qs", \@caption);

while(($id, $ip, $netmask, $descr, $status, $changed, $htype,) = $q->fetchrow_array()) {

  $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;  
  if ($FORM{net}) {
    my ($host, $netmask2)=split(/ /, $FORM{net});
    if (($host eq $ip) && ($netmask eq $netmask2)) {
      $bg=$_BG3;
     }
   }


  my $del_button = "<A href='$SELF?op=networks&del=$id'
    onclick=\"return confirmLink(this, '$_DELETE $host_types[$htype] $ip/$netmask?')\">$_DEL</a>";
  print "<tr bgcolor=$bg><th><img src='../img/$host_types[$htype].gif'></th><td>$ip</a></td><td>$netmask</td>".
   "<td>$descr</td><td bgcolor=$scolors[$status]>$status_types[$status]</td>".
   "<td><a href='$SELF?op=hosts&net=$ip+$netmask'>$_HOSTS</a></td>".
   "<td><a href='$SELF?op=networks&chg=$id'>$_CHANGE</a></td><td>$del_button</td></tr>\n";
}

print "</table>
</td></tr></table>
</p>\n";

if($op eq 'hosts') {
 my ($host, $netmask)=split(/ /, $FORM{net});
 show_hosts($host, $netmask);
}

print "<hr>\n";
}


#*******************************************************************
# Convert ip to int
# ip2int($ip);
#*******************************************************************
sub ip2int($){
  my $ip = shift;
  return unpack("N", pack("C4", split( /\./, $ip)));
}


#*******************************************************************
# Convert int to ip
# int2ip($int);
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
# show network hosts
# hosts();
#*******************************************************************
sub show_hosts () {
 my ($host, $netmask)=@_;

print "<h3>$_HOSTS</h3>\n";
$sql = "SELECT id, INET_NTOA(ip), INET_NTOA(netmask), hostname, domainname,   descr, 
     status, changed, type, mac 
     FROM networks WHERE ip>INET_ATON('$host') and ip<INET_ATON('$host')+4294967295-INET_ATON('$netmask')-1
     ORDER BY $sort $desc;";

my $q = $db->prepare("$sql");
$q->execute();
my $total = $q->rows;


print "$_TOTAL: $total<br>
<TABLE width=90% cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <COLGROUP>
    <COL align=center span=1>
    <COL align=right span=2>
    <COL align=left span=3>
    <COL align=center span=2>
  </COLGROUP>\n";

 my @caption = ("-", "IP", "NETMASK", "Hostname", "Domain", "$_DESCRIBE", "$_STATUS", "-", "-");
 show_title($sort, $desc, "$pg", "$op&$qs", \@caption);

while(($id, $ip, $netmask, $hostname, $domainname,  $descr, $status, $changed, $htype,) = $q->fetchrow_array()) {
  $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
  my $del_button = "<A href='$SELF?op=networks&del=$id'
        onclick=\"return confirmLink(this, '$_DELETE $host_types[$htype] $ip/$netmask?')\">$_DEL</a>";
  print "<tr bgcolor=$bg><th><img src='../img/$host_types[$htype].gif'></th><td>$ip</td><td>$netmask</td><td><b>$hostname</b></td><td>$domainname</td>".
   "<td>$descr</td><td bgcolor=$scolors[$status]>$status_types[$status]</td><td><a href='$SELF?op=networks&chg=$id'>$_CHANGE</a></td><td>$del_button</td></tr>\n";
}

print "</table>
</td></tr></table>
</p>\n";
	
	
}