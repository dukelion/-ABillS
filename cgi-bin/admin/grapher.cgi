#!/usr/bin/perl
#trafiic grapher

use strict;
use vars qw($begin_time $debug $names $data @names @data);

print "Content-Type: text/html\n\n";

BEGIN {
  my %MODS = ('RRDs' => "Graphic module");
  while(my($mod, $desc)=each %MODS) {

    if (eval "require $mod") {
      $mod->import();         # if needed
      $MODS{"$mod"}=1;
     }
    else {
      print "Can't load '$mod' ($desc);";
     }
   }
# Modules Time::HiRes
 eval { require Time::HiRes; };
 if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday(); 
   }
 else {
    $begin_time = 0;
  }
}

use Abwconf;
use POSIX qw(strftime);
$DATE = strftime "%Y-%m-%d", localtime(time);
$TIME = strftime "%H:%M:%S", localtime(time);


my $dbh        = $Abwconf::db;
my $workdir    = "./graphics";
#begin

#$FORM{session_id}='s-457312767';

if ($FORM{session_id}) {
   mk_graffic('acct_session_id', "$FORM{session_id}");
   show_page();
 } 
elsif ($FORM{user}) {
   if (mk_graffic('user', "$FORM{user}") == 0) {
     show_page();
    }  
 } 
else {
  print "Put session or user id:<br>\n";
}

#********************************************************
#
# show_page()
#********************************************************
sub show_page {

print << "[END]";
  <hr>
  <b>USER:</b> <a href='users.cgi?op=users&login=$FORM{user}'>$FORM{user}</a><br>
  <b>Session_id:</b> $FORM{session_id}<br>
  <b>DATE:</b> $DATE $TIME
  <hr>
  <p><img src='$workdir/graphic-daily.png'></p>
  <p><img src='$workdir/graphic-weekly.png'></p>
  <p><img src='$workdir/graphic-monthly.png'></p>
[END]

}

#********************************************************
# Make graphic
# mk_graffic($type, $value);
#********************************************************
sub mk_graffic {
  my ($type, $value) = @_;
  my $db           = "$workdir/main.rrd";
  my $now          = time(  );
  my $period 	   = 86400 * 30;
  my $start        = $now - $period;
  my @traffic_type       = ('IN','OUT','IN_EX', 'OUT_EX');
  my $title = "Traffic Graphic For '$value'";
  my @stock_prices = (0,0,0,0);
  my @raw = ();
  my $WHERE = '';
  
  if ($type eq 'acct_session_id') {
      $WHERE = "acct_session_id='$value'";
    }
  elsif($type eq 'user') {
      $WHERE = "id='$value'";
   }
  
#if (!-f $db) {
    RRDs::create ($db, "--start", $start,
          "DS:IN:ABSOLUTE:900:0:U",
          "DS:OUT:ABSOLUTE:900:0:U",
          "DS:IN_EX:ABSOLUTE:900:0:U",
          "DS:OUT_EX:ABSOLUTE:900:0:U",
          "RRA:AVERAGE:0.5:1:4800",
          "RRA:AVERAGE:0.5:4:4800",
          "RRA:AVERAGE:0.5:24:3000",
          "RRA:AVERAGE:0.5:24:3000"
    );

    if (my $ERROR = RRDs::error) { die "$ERROR\n"; }
#}

  my $sql = "SELECT last_update, sent1, recv1,  sent2, recv2 FROM  `s_detail` 
  WHERE $WHERE and last_update > UNIX_TIMESTAMP() - $period
  order BY last_update;";

  #$debug=10;
  #log_print('LOG_SQL', $sql);
  my $q = $dbh->prepare($sql) || die $db->strerr;
  $q ->execute();

while(@raw = $q->fetchrow()) {
#  print "@raw[0]:@raw[1]:@raw[2]:@raw[3]:\n"; 
  RRDs::update($db, "--template=" . join(':',@traffic_type),
                  "@raw[0]:@raw[1]:@raw[2]:@raw[3]:" );
  if (my $ERROR = RRDs::error) { die "$ERROR\n"; }
# Generate daily graph.
}



RRDs::graph("$workdir/graphic-daily.png",
  "--title",     "Daily $title",
  "--start",     "-12h",
  "--end",       $now,
  "--imgformat", "PNG",
  "--interlace", "--width=550",
  "DEF:in=$db:IN:AVERAGE",
  "DEF:out=$db:OUT:AVERAGE",
  "DEF:in_ex=$db:IN_EX:AVERAGE",
  "DEF:out_ex=$db:OUT_EX:AVERAGE",
  "LINE1:in#FF0000:in\\l",
  "LINE1:out#0000FF:out\\l",
  "LINE1:in_ex#008000:in_ex\\l",
  "LINE1:out_ex#022001:out_ex\\l",
); if (my $ERROR = RRDs::error) { die "$ERROR\n"; }


RRDs::graph("$workdir/graphic-weekly.png",
  "--title",     "Weekly $title",
  "--start",     "-1w",
  "--end",       $now,
  "--imgformat", "PNG",
  "--interlace", "--width=550",
  "DEF:in=$db:IN:AVERAGE",
  "DEF:out=$db:OUT:AVERAGE",
  "DEF:in_ex=$db:IN_EX:AVERAGE",
  "DEF:out_ex=$db:OUT_EX:AVERAGE",
  "LINE1:in#FF0000:in\\l",
  "LINE1:out#0000FF:out\\l",
  "LINE1:in_ex#008000:in_ex\\l",
  "LINE1:out_ex#022001:out_ex\\l",
); if (my $ERROR = RRDs::error) { die "$ERROR\n"; }


RRDs::graph("$workdir/graphic-monthly.png",
  "--title",     "Monthly $title",
  "--start",     "-1m",
  "--end",       $now,
  "--imgformat", "PNG",
  "--interlace", "--width=550",
  "DEF:in=$db:IN:AVERAGE",
  "DEF:out=$db:OUT:AVERAGE",
  "DEF:in_ex=$db:IN_EX:AVERAGE",
  "DEF:out_ex=$db:OUT_EX:AVERAGE",
  "LINE1:in#FF0000:in\\l",
  "LINE1:out#0000FF:out\\l",
  "LINE1:in_ex#008000:in_ex\\l",
  "LINE1:out_ex#022001:out_ex\\l",
); if (my $ERROR = RRDs::error) { die "$ERROR\n"; }



# $hash = RRDs::info "$db";
# foreach my $key (keys %$hash){
#   print "--- $key = $$hash{$key}<br>\n";
# }

#
# my ($start, $step, $names, $data) = RRDs::fetch ...
#  print "Start:       ", scalar localtime($start), " ($start)<br>\n";
#  print "Step size:   $step seconds<br>\n";
#  print "DS names:    ", join (", ", @$names)."<br>\n";
#  print "Data points: ", $#$data + 1, "<br>\n";
#  print "Data:<br>\n";
#  foreach my $line (@$data) {
#    print "  ", scalar localtime($start), " ($start) ";
#    $start += $step;
#    foreach my $val (@$line) {
#      printf "%12.1f ", $val;
#    }
#    print "<br>\n";
#  }


 return 0;
}



if ($begin_time > 0) {
  my  $end_time = gettimeofday();
  my $gen_time = $end_time - $begin_time;
  print "<hr>Generation time: $gen_time\n";
}
