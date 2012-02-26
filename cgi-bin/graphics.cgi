#!/usr/bin/perl
# Trafiic grapher
#
#

#use strict;
use vars qw($begin_time $debug $DATE $TIME %conf $dbh $base_dir $db);

BEGIN {
  my $libpath = '../';
  my $sql_type='mysql';
  unshift(@INC, $libpath ."Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  eval { require Time::HiRes; };
  if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
   }
  else {
    $begin_time = 0;
  }
}


BEGIN {
  my %MODS = ('RRDs' => "Graphic module");
  while(my($mod, $desc)=each %MODS) {

    if (eval "require $mod") {
      $mod->import();         # if needed
      $MODS{"$mod"}=1;
     }
    else {
    	print "Content-Type: text/html\n\n";
      print "Can't load '$mod' ($desc); Plesae install RRDs. http://search.cpan.org/dist/RRD-Simple/";
      exit;
     }
   }
}

my $VERSION = 0.09;
require "config.pl";

use POSIX qw(strftime);
use Abills::SQL;
use Abills::HTML;
use Admins;

my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef  });

$db = $sql->{db};
$sql->{db}->{debug}=1;
$admin = Admins->new($db, \%conf);

use Abills::Base;
my $workdir    = "./graphics";
my $ERROR;
#begin
$FORM{session_id}='';

my $html = Abills::HTML->new({ CONF     => \%conf, 
                            NO_PRINT => 0, 
                            PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
                            CHARSET  => $conf{default_charset},
	                           });

$html->{language}=$FORM{language} if (defined($FORM{language}) && $FORM{language} =~ /[a-z_]/);
require "../language/$html->{language}.pl";
#Count of graphics
my %ids          = ();


if ($RRDs::VERSION < 1.3003) {
        print "Content-Type: text/plain\n\n";
	print "Current version: $RRDs::VERSION
 	Please Update RRDs tools to 1.3000 or lates";
 	exit;
 } 


if ($FORM{SHOW_GRAPH}) {
	print "Content-Type: image/png\n\n";
 }
else {
  print "Content-Type: text/html\n\n";
 }

if (scalar %FORM > 0) {
  mk_graffic(\%FORM);
  show_page();
 } 
else {
  print "Put session or user id:<br>\n";
}

if ($begin_time > 0) {
  my  $end_time = gettimeofday();
  my $gen_time = $end_time - $begin_time;
  print "<font size=-2><hr size=1>" . "Version: $VERSION (GT: ". sprintf("%.6f", $gen_time). ")</font>";
}



#********************************************************
#
# show_page()
#********************************************************
sub show_page {

print << "[END]";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<HTML>
<HEAD>
    <TITLE>ABillS Users Traffic</TITLE>
    <meta http-equiv="content-type" content="text/html; charset=windows-1251" >
    <META HTTP-EQUIV="Refresh" CONTENT="300" >
    <META HTTP-EQUIV="Cache-Control" content="no-cache" >

    <META HTTP-EQUIV="Pragma" CONTENT="no-cache" >
    <META HTTP-EQUIV="Expires" CONTENT="Mon, 15 Mar 2010 10:39:51 GMT" >
    <LINK HREF="favicon.ico" rel="shortcut icon" >
</HEAD>


<style type="text/css">

body {
  background-color: #FFFFFF;
  color: #000000;
  font-family: Arial, Tahoma, Verdana, Helvetica, sans-serif;
  font-size: 14px;
  /* this attribute sets the basis for all the other scrollbar colors (Internet Explorer 5.5+ only) */
}


A:hover {text-decoration: none; color: #000000;}
.link_button {
  font-family:  Arial, Tahoma,Verdana, Helvetica, sans-serif;
  background-color: #eeeeee;
  color: #000000;
  border-color : #9F9F9F;
  font-size: 11px;
  border: 1px outset;
  text-decoration: none;
  padding:1px 5px;
}

a.link_button:hover {
  background:#ccc;
  background-color: #dddddd;
  border:1px solid #666;
  cursor: pointer;
}

</style>


<BODY bgcolor="#ffffff" text="#000000" link="#000000" vlink="#000000" alink="#000000">
  <hr size=1>
[END]

 
if ($FORM{LOGIN}) {  
  print "<b>$_USER:</b> <a href='index.cgi?LOGIN_EXPR=$FORM{LOGIN}'>$FORM{LOGIN}</a><br>";
 }
elsif ($FORM{SESSION_ID}) {
	print "<b>Session_id:</b> $FORM{SESSION_ID}<br>";
 }  
elsif ($FORM{TP_ID}) {
	print "<b>$_TARIF_PLAN:</b> $FORM{TP_ID}<br>";
 }  
elsif ($FORM{NAS_ID}) {
	print "<b>NAS:</b> $FORM{NAS_ID}<br>";
 }  
elsif ($FORM{GID}) {
	print "<b>$_GROUP:</b>$FORM{GID}<br>";
 }  

print  "<b>DATE:</b> $DATE $TIME ";

$FORM{type}='bits' if (! $FORM{type});

foreach my $name ( 'bits', 'bytes' ) {
	if ($FORM{type} && $FORM{type} eq "$name") {
	  print $html->b($name). ' ';	
	 }
	else {
		$ENV{QUERY_STRING} =~ s/\&type=\S+//g;
	  print "<a href='$SELF_URL?$ENV{QUERY_STRING}&type=$name' class=link_button>$name</a> \n";	
	 }
	
}	
	
my $i=0;
foreach my $key (sort keys %ids) {
  $i++;
  print "<p><img src='$workdir/graphic-daily_".$i.".png'></p>\n";
  if (! $FORM{DAILY}) {
    print "<p><img src='$workdir/graphic-weekly_".$i.".png'></p>
    <p><img src='$workdir/graphic-monthly_".$i.".png'></p>\n";
   }
}
 
print << "[END]";
</BODY>
</HTML>
[END]

}

#********************************************************
# Make graphic
# mk_graffic($type, $value);
#********************************************************
sub mk_graffic {
  my ($attr) = @_;
  my $rdb          = "$workdir/main.rrd";
  my $now          = time(  );
  my $period 	     = ($attr->{DAILY}) ? 86400 * 1 : 86400 * 30;
  my $start        = $now - $period;
  my @traffic_type = ('IN','OUT','IN_EX', 'OUT_EX');
  my @stock_prices = (0,0,0,0);
  my @raw          = ();
  my $WHERE        = '';
  my $GROUP_BY     = 1;
  my $AS_5MIN      = '';
  my $CAPTION      = '';
  my $EXT_TABLE    = '';
   
  if ($attr->{'ACCT_SESSION_ID'}) {
    $WHERE = "acct_session_id='$attr->{ACCT_SESSION_ID}'";
    $CAPTION="ACCT_SESSION_ID";
    %ids=($attr->{'ACCT_SESSION_ID'} => $attr->{'ACCT_SESSION_ID'});
   }
  elsif($attr->{'LOGIN'}) {
    $WHERE = "l.id='$attr->{LOGIN}'";
    $CAPTION="LOGIN";
    %ids=($attr->{'LOGIN'} => $attr->{'LOGIN'});
   }
  elsif($attr->{'UID'}) {
    $WHERE = "l.uid='$attr->{UID}'";
    $CAPTION="USER UID";
    %ids=($attr->{'UID'} => $attr->{'UID'});
   }
  elsif($attr->{'NAS_ID'}) {
    $CAPTION="NAS_ID";
  	if ($attr->{'NAS_ID'}eq 'all') {
  		$admin->query($db, "SELECT id, name FROM nas WHERE disable=0 ORDER BY id;");
  		foreach my $line (@{ $admin->{list} }) {
  		  $ids{$line->[0]}=convert($line->[1], { win2utf8 => 1 });
  		 }
     }
    else { 
      %ids=($attr->{'NAS_ID'} => $attr->{'NAS_ID'});
     }
    $WHERE = "l.nas_id='$attr->{NAS_ID}'";
    $GROUP_BY = "5min";
    $AS_5MIN = ", last_update DIV 300 AS 5min";

   }
  elsif($attr->{'TP_ID'}) {
    $CAPTION="TP_ID";
  	if ($attr->{'TP_ID'}eq 'all') {
   		$admin->query($db, "SELECT id, name FROM tarif_plans ORDER BY id;");
  		foreach my $line (@{ $admin->{list} }) {
 	  	  $ids{$line->[0]}=convert($line->[1], { win2utf8 => 1 });
		   }
     }
    else { 
      %ids=($attr->{'TP_ID'} => $attr->{'TP_ID'});
     }

    $WHERE = "dv.tp_id='$attr->{TP_ID}'";
    $EXT_TABLE="INNER JOIN users u ON (u.id=l.id)
    INNER JOIN dv_main dv ON (dv.uid=u.uid) ";
   }
  elsif($attr->{'GID'}) {
    $CAPTION="GROUP ID";
  	if ($attr->{'GID'}eq 'all') {
   		$admin->query($db, "SELECT gid, name FROM groups ORDER BY gid;");
  		foreach my $line (@{ $admin->{list} }) {
 	  	  $ids{$line->[0]}=convert($line->[1], { win2utf8 => 1 });
		   }
     }
    else { 
      %ids=($attr->{'GID'} => $attr->{'GID'});
     }
    $WHERE = "u.gid='$attr->{GID}'";
    $EXT_TABLE="INNER JOIN users u ON (u.id=l.id) ";
   }

  
  if (! -d $workdir) {
  	mkdir("$workdir");
   }
  
my $i=0;

foreach my $key (sort keys %ids) {
  RRDs::create ($rdb, "--start", $start,
          "DS:IN:DERIVE:900:0:U",
          "DS:OUT:DERIVE:900:0:U",
          "DS:IN_EX:DERIVE:900:0:U",
          "DS:OUT_EX:DERIVE:900:0:U",
          "RRA:AVERAGE:0.5:1:4800",
          "RRA:AVERAGE:0.5:4:4800",
          "RRA:AVERAGE:0.5:24:3000",
          "RRA:AVERAGE:0.5:24:3000"
    );

  $ERROR=RRDs::error();
  if ($ERROR) {
    print "$0: unable to create: $ERROR\n";
    return 0;
   }


  $i++;
  $WHERE =~ s/'(.+)'/'$key'/;
  $admin->{debug}=1 if ($FORM{DEBUG} > 2);
  $admin->query($db, "SELECT l.last_update, SUM(l.sent1),SUM(l.recv1), l.sent2, l.recv2 $AS_5MIN FROM s_detail l
    $EXT_TABLE
    WHERE $WHERE and l.last_update > UNIX_TIMESTAMP() - $period
    GROUP BY $GROUP_BY
    order BY last_update;");


  my @last = (0,0,0,0,0,0);
  foreach my $line (@{ $admin->{list} }) {
    #RRDs::update($rdb, 
               #"--template=", 
               #join(':', @traffic_type),
               #$line->[0].':'.$line->[1].':'.$line->[2].':'.$line->[3].':'.$line->[4] );
               #$line->[0].':'.int($line->[1]-$last[1]).':'.int($line->[2]-$last[2]).':'. int($line->[3]-$last[3]).':'.int($line->[4]-$last[4]) );
  
    RRDs::update($rdb, 
               $line->[0].':'.int($line->[1]-$last[1]).':'.int($line->[2]-$last[2]).':'. int($line->[3]-$last[3]).':'.int($line->[4]-$last[4]) );

    print $line->[0].':'.int($line->[1]-$last[1]).':'.int($line->[2]-$last[2]).':'. int($line->[3]-$last[3]).':'.int($line->[4]-$last[4])."<br>" if ($FORM{DEBUG});

    #@last = @$line;
    $ERROR=RRDs::error();
    if ($ERROR)  {
      print "$0: unable to update': $ERROR\n";
      return 0;
     }
  }

my $title = "Traffic Graphic For '$CAPTION: ". $key ." "; #. "$ids{$key}'";

if (! $attr->{WEEKLY}) {


  my @params = (
    "CDEF:in_bit=in,8,*",
    "CDEF:out_bit=out,8,*",
    "VDEF:in_avg=in_bit,LAST",
    "VDEF:out_avg=out_bit,LAST",
    "AREA:in_bit#00DD00:in_bit",
    "LINE1:out_bit#FF0000:out_bit",
    "AREA:in_ex#FF0000:in_ex",
    "LINE1:out_ex#0561FA:out_ex",
    "GPRINT:in_avg:Speed IN\\: \%6.2lf\%sbit/sec",
    "GPRINT:out_avg: OUT\\: \%6.2lf\%sbit/sec",
    );

  if ($FORM{type} eq 'bytes') {
    @params = ("VDEF:in_avg=in,LAST",
    "VDEF:out_avg=out,LAST",
    "AREA:in#00DD00:in",
    "LINE1:out#F15500:out",
    "AREA:in_ex#FF0000:in_ex",
    "LINE1:out_ex#0561FA:out_ex",
    "GPRINT:in_avg:Speed IN\\: \%6.2lf\%sbyte",
    "GPRINT:out_avg: OUT\\: \%6.2lf\%sbyte",
    );
   }


  # Generate daily graph.
  my $return_hash = RRDs::graphv( ($attr->{SHOW_GRAPH}) ? undef : "$workdir/graphic-daily_".$i.".png", 
    "-w500",
    "-h100",
    "-b 1024",
    "--title",     "Daily $title",
    "--start",     "-12h",
    "--end",       $now,
    "--imgformat", "PNG",
    "--interlace",
    "DEF:in=$rdb:IN:AVERAGE",
    "DEF:out=$rdb:OUT:AVERAGE",
    "DEF:in_ex=$rdb:IN_EX:AVERAGE",
    "DEF:out_ex=$rdb:OUT_EX:AVERAGE",
    #"COMMENT:Cure Speed ". sprintf("%s", int($last[1]/1024/300)). '/'.sprintf("%s", int($last[2]/1024/300)).' KBits',
    @params
    );

 $ERROR=RRDs::error();
 if ($ERROR) {
   print "$0: unable to create '$workdir/graphic-daily.png': $ERROR\n";
   return 0;
  }

 if ($attr->{SHOW_GRAPH}) {
	 print $return_hash->{image};
	 exit;
 }
 next if ($attr->{DAILY}) ;
}

$return_hash = RRDs::graphv(($attr->{SHOW_GRAPH}) ? undef : "$workdir/graphic-weekly_".$i.".png", "-w500","-h100",
  "--title",     "Weekly $title",
  "--start",     "-1w",
  "--end",       $now,
  "--imgformat", "PNG",
  "--interlace",
  "DEF:in=$rdb:IN:AVERAGE",
  "DEF:out=$rdb:OUT:AVERAGE",
  "DEF:in_ex=$rdb:IN_EX:AVERAGE",
  "DEF:out_ex=$rdb:OUT_EX:AVERAGE",
  "AREA:in#00DD00:in",
  "LINE1:out#F15500:out",
  "AREA:in_ex#FF0000:in_ex",
  "LINE1:out_ex#0561FA:out_ex",
); 

if ($attr->{SHOW_GRAPH}) {
	print $return_hash->{image};
	exit;
}

 $ERROR=RRDs::error();
 if ($ERROR) {
   print "$0: unable to create '$workdir/graphic-daily.png': $ERROR\n";
   return 0;
  }


RRDs::graphv("$workdir/graphic-monthly_".$i.".png",
  "--title",     "Monthly $title", "-w500","-h100",
  "--start",     "-1m",
  "--end",       $now,
  "--imgformat", "PNG",
  "--interlace",
  "DEF:in=$rdb:IN:AVERAGE",
  "DEF:out=$rdb:OUT:AVERAGE",
  "DEF:in_ex=$rdb:IN_EX:AVERAGE",
  "DEF:out_ex=$rdb:OUT_EX:AVERAGE",
  "AREA:in#00DD00:in",
  "LINE1:out#F15500:out",
  "AREA:in_ex#FF0000:in_ex",
  "LINE1:out_ex#0561FA:out_ex",
); 

 $ERROR=RRDs::error();
 if ($ERROR) {
   print "$0: unable to create '$workdir/graphic-daily.png': $ERROR\n";
   return 0;
  }
}

## $hash = RRDs::info "$db";
## foreach my $key (keys %$hash){
##   print "--- $key = $$hash{$key}<br>\n";
## }
#
##
## my ($start, $step, $names, $data) = RRDs::fetch ...
##  print "Start:       ", scalar localtime($start), " ($start)<br>\n";
##  print "Step size:   $step seconds<br>\n";
##  print "DS names:    ", join (", ", @$names)."<br>\n";
##  print "Data points: ", $#$data + 1, "<br>\n";
##  print "Data:<br>\n";
##  foreach my $line (@$data) {
##    print "  ", scalar localtime($start), " ($start) ";
##    $start += $step;
##    foreach my $val (@$line) {
##      printf "%12.1f ", $val;
##    }
##    print "<br>\n";
##  }


 return 0;
}



