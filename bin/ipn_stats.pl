#!/usr/bin/perl -w
# Make ipn stats

use DBI;
use strict;

use vars  qw(%conf $db  $begin_time );

require "../libexec/config.pl";
require "../Abills/Base.pm";
Abills::Base->import();



my $attr = parse_arguments(\@ARGV);
my $VERSION = 0.10; # 2008.06.13
my $debug = $attr->{DEBUG} || 0;


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
	push @WHERE_RULES, "(src_addr=INET_ATON('$attr->{IP}') or dst_addr=INET_ATON('$attr->{IP}') )"; 
}

if ($attr->{START_DATE}) {
	push @WHERE_RULES, "s_time >= '$attr->{START_DATE}'";
	if ($attr->{START_DATE} =~ /(\d{4})-(\d{2})-(\d{2})/) {
	  $START_DATE = "$1$2$3";
	 }
}

if ($attr->{FINISH_DATE}) {
	push @WHERE_RULES, "s_time <= '$attr->{FINISH_DATE}'";
	if ($attr->{FINISH_DATE} =~ /(\d{4})-(\d{2})-(\d{2})/) {
	  $FINISH_DATE = "$1$2$3";
	 }
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
    $WHERE";

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
	IP          - SOME IP
	START_DATE  - Start Date (YYYY-MM-DD) 
	FINISH_DATE - Finish Date (YYYY-MM-DD) 

	FORMAT - Output format
	  tab_delimeter
	  standart (default)

	help        - This help
	
[END]

}