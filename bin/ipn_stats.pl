#!/usr/bin/perl -w
# Make ipn stats

use DBI;
use strict;

use vars  qw(%conf $db  $begin_time $DATE $TIME );

require "../libexec/config.pl";
require "../Abills/Base.pm";
Abills::Base->import();



my $attr = parse_arguments(\@ARGV);
my $VERSION = 0.13; 
my $debug = $attr->{DEBUG} || 0;

my $PAGE_ROWS = $attr->{PAGE_ROWS} || 1000000;

if (defined($attr->{'help'})) {
   help();
   exit 0;
}

my @WHERE_RULES = ();
my %LIST_PARAMS = ();
my @tables      = ();
$LIST_PARAMS{IP}          = '';
$LIST_PARAMS{START_DATE}  = '';
$LIST_PARAMS{FINISH_DATE} = '';

my $FORMAT       = $attr->{FORMAT} || '';
my $START_DATE   = '00000000';
my $FINISH_DATE  = '99999999';



my $db = DBI->connect("dbi:mysql:dbname=$conf{dbname}", "$conf{dbuser}", "$conf{dbpasswd}") 
 || die "Unable connect to server '$conf{dbhost}'\n" . $DBI::errstr;

if ( $conf{dbcharset} ) {
  $db->do("set names $conf{dbcharset}");
}



if ($attr->{IP}) {
	my @ips_arr = split(/,/, $attr->{IP});
	my @ip_q = ();
	foreach my $ip (sort @ips_arr) {
    if ($ip =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})/) {
      my $ip   = $1;
      my $bits = $2;
      my $mask = 0b1111111111111111111111111111111;

      $mask = int(sprintf("%d", $mask >> ($bits - 1)));
      my $last_ip = ip2int($ip) | $mask;
      my $first_ip = $last_ip - $mask;
      print "IP FROM: ". int2ip($first_ip) ." TO: ". int2ip($last_ip). "\n" if ($debug > 2);
    	push @ip_q, "( 
    	              (src_addr>='$first_ip' and src_addr<='$last_ip' )
    	              or (dst_addr>='$first_ip' and dst_addr<='$last_ip' )  )"; 
     }
	  elsif ($ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
	    push @ip_q, "(src_addr=INET_ATON('$ip') or dst_addr=INET_ATON('$ip') )"; 
	   }
   }

   push @WHERE_RULES, '(' . join(' or ', @ip_q) . ')';
}

#Period
if ($attr->{START_DATE}) {
  my  $s_time = ($attr->{START_DATE} =~ /^\d{4}-\d{2}-\d{2}$/) ? 'DATE_FORMAT(s_time, \'%Y-%m-%d\')' : 's_time' ;
	push @WHERE_RULES, "$s_time >= '$attr->{START_DATE}'";
	if ($attr->{START_DATE} =~ /(\d{4})-(\d{2})-(\d{2})/) {
	  $START_DATE = "$1$2$3";
	 }
}
if (! $attr->{FINISH_DATE}) {
  $attr->{FINISH_DATE}=$DATE;
}

my  $s_time = ($attr->{FINISH_DATE} =~ /^\d{4}-\d{2}-\d{2}$/) ? 'DATE_FORMAT(s_time, \'%Y-%m-%d\')' : 's_time' ;

push @WHERE_RULES, "$s_time <= '$attr->{FINISH_DATE}'";
if ($attr->{FINISH_DATE} =~ /(\d{4})-(\d{2})-(\d{2})/) {
  $FINISH_DATE = "$1$2$3";
 }



my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

my $q = $db->prepare("SHOW TABLES");
$q->execute();

while (my ($table) = $q->fetchrow_array()) {
  if ($table =~ m/ipn_traf_detail_(\d{4})_(\d{2})_(\d{2})/) {
  	 my $table_date="$1$2$3";
  	 if ($table_date >= $START_DATE && $table_date <= $FINISH_DATE) {
  	 	  print $table."\n" if ($debug > 1);
  	 	  push @tables, $table;
  	  }
   }
}

if ($LIST_PARAMS{START_DATE} eq $DATE) {
  push @tables, 'ipn_traf_detail';
}

foreach my $table (@tables) {
  my $date ;
  if ($table =~ m/ipn_traf_detail_(\d{4})_(\d{2})_(\d{2})/) {
    $date = "$1-$2-$3";
   }
  
  my $sql = "SELECT INET_NTOA(src_addr),
    INET_NTOA(dst_addr),
    src_port,
    dst_port,
    protocol,
    size,
    f_time,
    s_time,
    nas_id,
    uid FROM $table 
    $WHERE
    LIMIT $PAGE_ROWS";

print "$sql\n" if ($debug > 0);  
print "DATE: $date =============================================\n";

my $q = $db->prepare($sql);
$q->execute();
my $total = 0;
while (my ($src_addr,$dst_addr,$src_port,$dst_port,$protocol,$size,
  $f_time,$s_time,$nas_id) = $q->fetchrow_array()) {

  if ($FORMAT eq 'tab_delimeter' ){
    print "$src_addr\t$src_port\t$dst_addr\t$dst_port\t$protocol\t$size\t$f_time\t$s_time\t$nas_id";
   }
  else {
    printf("%-15s|%-5s|%-15s|%-5s|%4s|%-8s|%-19s|%-19s|%-3s|\n", $src_addr, $src_port, $dst_addr, 
     $dst_port, $protocol, $size, $f_time, $s_time, $nas_id);
   }
  $total += $size;
}

print "=================SUM: $total\n";

}




#**********************************************************
# help
#**********************************************************
sub help {
	
print << "[END]";
	IP          - SOME IP (192.168.0.1,192.168,10.0/24,192.168.0.1,192.168.11,2)

	START_DATE  - Start Date (YYYY-MM-DD) 
	FINISH_DATE - Finish Date (YYYY-MM-DD) 

	FORMAT - Output format
	  tab_delimeter
	  standart (default)

        PAGE_ROWS   - Select row count
	help        - This help
        DEBUG=[1-5] - Debug mode
       
	
[END]

}
