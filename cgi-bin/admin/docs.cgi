#!/usr/bin/perl
# Docs
#

$debug = 1;
use Abwconf;
use Base;
print "Content-Type: text/html\n\n";
$path = '../';
require 'Abdocs.pm';
require "$path../language/$language.pl";


%FORM = form_parse2();
$sort = $FORM{sort} || 1;
$desc = $FORM{desc} || '';
$docs = $FORM{docs} || '';

#$uid  = $FORM{uid} || '';
if ($FORM{uid}) {
  $uid = $FORM{uid};
  $login = get_login($uid);
  $login_link = "<a href=\"users.cgi?op=users&chg=$uid\">$login</a>";
}



if ($docs eq 'print') {
  print_version("$FORM{d}");	
  exit 0;
}

header();

print "<table width=100% border=0 cellspacing=0 cellpadding=0>
<tr><td bgcolor=000000>
<table width=100% border=0 cellspacing=1 cellpadding=1>
<tr><td bgcolor=FFFFFF>&nbsp;<b>$_DATE:</b> $DATE $TIME /<b>Admin:</b> $admin_name <i>($admin_ip)</i>/\n</td></tr>
</table>
</td></tr></table>\n";

%main_menu = ('1::accts', $_ACCOUNTS,
              '2::templates', $_TEMPLATES,
              '3::params', $_PARAMS, 
              '4:users.cgi:', $_BILLING
             );

show_menu(0, 'docs', "", \%main_menu);

print "<center>\n";


if ($docs eq 'templates') {  templates({ PATH => $path }); }
elsif ($docs eq 'accts')  {  accounts("$uid", "$login"); }
elsif ($docs eq 'params') {  params(); }
else  { params();  }


