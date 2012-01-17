#!/usr/bin/perl
# Help systems
#
BEGIN {
 my $libpath = '../../';
 
 $sql_type='mysql';
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');

 eval { require Time::HiRes; };
 if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
   }
 else {
    $begin_time = 0;
  }
}



require "config.pl";
require "Abills/defs.conf";
require "Abills/templates.pl";


#
#==== End config








#use FindBin '$Bin2';
use Abills::SQL;
use Abills::HTML;
use Help;
use Abills::Base;

my $html = Abills::HTML->new();
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};
require "../../language/$html->{language}.pl";
print $html->header({ 
	 PATH    => '../',
	 CHARSET => $CHARSET }). '<center>';

help();


sub help {
 my $Help = Help->new($db);


if ($FORM{add}) {
	$Help->add({ %FORM });
	$html->message('info', $_ADDED, "$_ADDED");
}
elsif ($FORM{change}) {
	$Help->change({ %FORM });
	$html->message('info', $_CHANGED, "$_CHANGED");
}
elsif ($FORM{del}) {
	$Help->del({ %FORM });
	$html->message('info', $_DELETED, "$_DELETED ''");
}




if (defined($FORM{FUNCTION})){
  $Help->info({ FUNCTION => "$FORM{FUNCTION}" });


  if($Help->{TOTAL}>0) {
    $Help->{HELP2}=$Help->{HELP};
    $Help->{HELP}=convert($Help->{HELP}, { text2html => 1 });
    $html->tpl_show(templates('help_info'), $Help);
  	$Help->{ACTION}='change';
  	$Help->{LNG_ACTION}=$_CHANGE;

  }
 else {
 	 $html->message('info', $_INFO, "$_NOT_EXIST");
 	 $Help->{ACTION}='add';
 	 $Help->{LNG_ACTION}=$_ADD;
  }
}


if ($conf{HELP_EDIT}) {
  $Help->{HELP}=$Help->{HELP2};
  $html->tpl_show(templates('help_form'), $Help);
}


}

