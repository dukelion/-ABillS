#!/usr/bin/perl -w
# Provision 





use vars qw( $db $DATE $TIME $var_dir %log_levels );
#use strict;

BEGIN {
 my $libpath = '../';
 
 my $sql_type='mysql';
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, $libpath ."Abills/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');

 

# eval { require Time::HiRes; };
# if (! $@) {
#    Time::HiRes->import(qw(gettimeofday));
#    $begin_time = gettimeofday();
#   }
# else {
#    $begin_time = 0;
#  }
}



require "config.pl";
use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Nas;

my $html = Abills::HTML->new( { IMG_PATH => 'img/',
	                           NO_PRINT => 1,
	                           CONF     => \%conf,
	                           CHARSET  => $conf{default_charset},
	                       });

my $sql = Abills::SQL->connect($conf{dbtype}, 
                               $conf{dbhost}, 
                               $conf{dbname}, 
                               $conf{dbuser}, 
                               $conf{dbpasswd},
                               { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
$db = $sql->{db};

my $version  = '0.3';
my $debug    = 6;
my $log_file = $var_dir."log/wrt_configure.log";

if ($FORM{test}) {
	print "Content-Type: text/plain\n\n";
	print "Test OK $DATE $TIME";
	exit;
}

require "Abills/templates.pl";
my $Nas = Nas->new($db, \%conf);

print "Content-Type: text/xml\n\n";


print $html->tpl_show(_include('voip_provision_xml', 'Voip'), \%FORM);