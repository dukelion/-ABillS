package Abills::XML;
#XML Functions

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION %h2
   @_COLORS
   %FORM
   %LIST_PARAMS
   %COOKIES
   %functions
   $index
   $pages_qs
   $domain
   $web_path
   $secure
   $SORT
   $DESC
   $PG
   $PAGE_ROWS
   $OP
   $SELF_URL
   $SESSION_IP
   @MONTHES
);

use Exporter;
$VERSION = 2.01;
@ISA = ('Exporter');

@EXPORT = qw(
   &message
   @_COLORS
   %err_strs
   %FORM
   %LIST_PARAMS
   %COOKIES
   %functions
   $index
   $pages_qs
   $domain
   $web_path
   $secure
   $SORT
   $DESC
   $PG
   $PAGE_ROWS
   $OP
   $SELF_URL
   $SESSION_IP
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();

my $bg;
my $debug;
my %log_levels;
my $IMG_PATH;
my $row_number = 0;
#Hash of url params


#**********************************************************
# Create Object
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;
  
  $IMG_PATH = (defined($attr->{IMG_PATH})) ? $attr->{IMG_PATH} : '../img/';

  my $self = { };
  bless($self, $class);

  if ($attr->{NO_PRINT}) {
     $self->{NO_PRINT}=1;
   }


  %FORM     = form_parse();
  %COOKIES  = getCookies();
  $SORT     = $FORM{SORT} || 1;
  $DESC     = ($FORM{desc}) ? 'DESC' : '';
  $PG       = $FORM{pg} || 0;
  $OP       = $FORM{op} || '';
  $PAGE_ROWS = $FORM{PAGE_ROWS} || 25;
  $domain   = $ENV{SERVER_NAME};
  $web_path = '';
  $secure   = '';
  my $prot  = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http' ;
  $SELF_URL = (defined($ENV{HTTP_HOST})) ? "$prot://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}" : '';
  $SESSION_IP = $ENV{REMOTE_ADDR} || '0.0.0.0';
  
  @_COLORS = ('#FDE302',  # 0 TH
            '#FFFFFF',  # 1 TD.1
            '#eeeeee',  # 2 TD.2
            '#dddddd',  # 3 TH.sum, TD.sum
            '#E1E1E1',  # 4 border
            '#FFFFFF',  # 5
            '#FFFFFF',  # 6
            '#000088',  # 7 vlink
            '#0000A0',  # 8 Link
            '#000000',  # 9 Text
            '#FFFFFF',  #10 background
           ); #border
  
  %LIST_PARAMS = ( SORT      => $SORT,
	                 DESC      => $DESC,
	                 PG        => $PG,
	                 PAGE_ROWS => $PAGE_ROWS
	                );

  %functions = ();
  
  $pages_qs = '';
  $index = $FORM{index} || 0;  
  
  
  if (defined($COOKIES{language}) && $COOKIES{language} ne '') {
    $self->{language}=$COOKIES{language};
   }
  else {
    $self->{language} = 'english';
   }

  return $self;
}




#*******************************************************************
# Parse inputs from query
# form_parse()
#*******************************************************************
sub form_parse {
  my $self = shift;
  my $buffer = '';
  my $value='';
  my %FORM = ();
  
  return %FORM if (! defined($ENV{'REQUEST_METHOD'}));

if ($ENV{'REQUEST_METHOD'} eq "GET") {
   $buffer= $ENV{'QUERY_STRING'};
 }
elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
   read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
 }

my @pairs = split(/&/, $buffer);
$FORM{__BUFFER}=$buffer;

foreach my $pair (@pairs) {
   my ($side, $value) = split(/=/, $pair);
   $value =~ tr/+/ /;
   $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
   $value =~ s/<!--(.|\n)*-->//g;
   $value =~ s/<([^>]|\n)*>//g;
   if (defined($FORM{$side})) {
     $FORM{$side} .= ", $value";
    }
   else {
     $FORM{$side} = $value;
    }
 }

  return %FORM;
}


#*******************************************************************
# form_input
#*******************************************************************
sub form_input {
	my $self = shift;
	my ($name, $value, $attr)=@_;


  my $type  = (defined($attr->{TYPE})) ? $attr->{TYPE} : 'text';
  my $state = (defined($attr->{STATE})) ? ' checked="1"' : ''; 
  my $size  = (defined($attr->{SIZE})) ? " SIZE=\"$attr->{SIZE}\"" : '';


  
  $self->{FORM_INPUT}="<input type=\"$type\" name=\"$name\" value=\"$value\"$state$size/>";

  if (defined($self->{NO_PRINT}) && ( !defined($attr->{OUTPUT2RETURN}) )) {
  	$self->{OUTPUT} .= $self->{FORM_INPUT};
  	$self->{FORM_INPUT} = '';
  }
	
	return $self->{FORM_INPUT};
}



sub form_main {
  my $self = shift;
  my ($attr)	= @_;
	
	$self->{FORM}="<FORM action=\"$SELF_URL\" METHOD=\"POST\">\n";
	
  if (defined($attr->{HIDDEN})) {
  	my $H = $attr->{HIDDEN};
  	while(my($k, $v)=each( %$H)) {
      $self->{FORM} .= "<input type=\"hidden\" name=\"$k\" value=\"$v\"/>\n";
  	}
  }

	if (defined($attr->{CONTENT})) {
	  $self->{FORM}.=$attr->{CONTENT};
	}


  if (defined($attr->{SUBMIT})) {
  	my $H = $attr->{SUBMIT};
  	while(my($k, $v)=each( %$H)) {
      $self->{FORM} .= "<input type=\"submit\" name=\"$k\" value=\"$v\"/>\n";
  	}
  }


	$self->{FORM}.="</FORM>\n";
	
	if (defined($self->{NO_PRINT})) {
  	$self->{OUTPUT} .= $self->{FORM};
  	$self->{FORM} = '';
  }
	
	return $self->{FORM};
}

#**********************************************************
#
#**********************************************************
sub form_select {
  my $self = shift;
  my ($name, $attr)	= @_;
	
	my $ex_params =  (defined($attr->{EX_PARAMS})) ? $attr->{EX_PARAMS} : '';
			
	$self->{SELECT} = "<select name=\"$name\" $ex_params>\n";
  
  if (defined($attr->{SEL_OPTIONS})) {
 	  my $H = $attr->{SEL_OPTIONS};
	  while(my($k, $v) = each %$H) {
     $self->{SELECT} .= "<option value='$k'";
     $self->{SELECT} .=' selected="1"' if (defined($attr->{SELECTED}) && $k eq $attr->{SELECTED});
     $self->{SELECT} .= ">$v</option>\n";	
     }
   }
  
  
  if (defined($attr->{SEL_ARRAY})){
	  my $H = $attr->{SEL_ARRAY};
	  my $i=0;
	  foreach my $v (@$H) {
      my $id = (defined($attr->{ARRAY_NUM_ID})) ? $i : $v;
      $self->{SELECT} .= "<option value='$id'";
      $self->{SELECT} .= ' selected="1"' if (defined($attr->{SELECTED}) && ( ($i eq $attr->{SELECTED}) || ($v eq $attr->{SELECTED}) ) );
      $self->{SELECT} .= ">$v</option>\n";
      $i++;
     }
   }
  elsif (defined($attr->{SEL_MULTI_ARRAY})){
    my $key   = $attr->{MULTI_ARRAY_KEY};
    my $value = $attr->{MULTI_ARRAY_VALUE};
	  my $H = $attr->{SEL_MULTI_ARRAY};

	  foreach my $v (@$H) {
      $self->{SELECT} .= "<option value='$v->[$key]'";
      $self->{SELECT} .= ' selected="1"' if (defined($attr->{SELECTED}) && $v->[$key] eq $attr->{SELECTED});
      $self->{SELECT} .= '>';
      $self->{SELECT} .= "$v->[$key]:" if (! $attr->{NO_ID});
      $self->{SELECT} .= "$v->[$value]</option>\n";
     }
   }
  elsif (defined($attr->{SEL_HASH})) {
    my @H = ();

	  if ($attr->{SORT_KEY}) {
	  	@H = sort keys %{ $attr->{SEL_HASH} };
	  }
	  else {
	    @H = keys %{ $attr->{SEL_HASH} };
     }
    
    
    foreach my $k (@H) {
      $self->{SELECT} .= "<option value='$k'";
      $self->{SELECT} .=' selected="1"' if (defined($attr->{SELECTED}) && $k eq $attr->{SELECTED});

      $self->{SELECT} .= ">";
      $self->{SELECT} .= "$k:" if (! $attr->{NO_ID});
      $self->{SELECT} .= "$attr->{SEL_HASH}{$k}</option>\n";	
     }
   }
	
	$self->{SELECT} .= "</select>\n";

	return $self->{SELECT};
}


#**********************************************************
#
#**********************************************************
sub dirname {
    my($x) = @_;
    #print STDERR "dirname('$x') = ";
    if ( $x !~ s@[/\\][^/\\]+$@@ ) {
     	$x = '.';
    }
    #print STDERR "'$x'\n";
    $x;
}


#*******************************************************************
#Set cookies
# setCookie($name, $value, $expiration, $path, $domain, $secure);
#*******************************************************************
sub setCookie {
	# end a set-cookie header with the word secure and the cookie will only
	# be sent through secure connections
	my $self = shift;
	my($name, $value, $expiration, $path, $domain, $secure) = @_;
	
	#$path = dirname($ENV{SCRIPT_NAME}) if ($path eq '');


	print "Set-Cookie: ";
	print $name, "=$value; expires=\"", $expiration,
		"\"; path=$path; domain=", $domain, "; ", $secure, "\n";
}



#********************************************************************
# get cookie values and return hash of it
#
# getCookies()
#********************************************************************
sub getCookies {
  my $self = shift;
	# cookies are seperated by a semicolon and a space, this will split
	# them and return a hash of cookies
	my(%cookies);

  if (defined($ENV{'HTTP_COOKIE'})) {
 	  my(@rawCookies) = split (/; /, $ENV{'HTTP_COOKIE'});
	  foreach(@rawCookies){
	     my ($key, $val) = split (/=/,$_);
	     $cookies{$key} = $val;
	  } 
   }

	return %cookies; 
}


#**********************************************************
# Functions list
#**********************************************************
sub menu {
 my $self = shift;
 my ($menu_items, $menu_args, $permissions, $attr) = @_;
 

 return 0 if ($FORM{index} > 0);
 
 my $menu_navigator='';
 my $menu_text='';
 $menu_text="<SID>$self->{SID}</SID>\n" if ($self->{SID});

 return $menu_navigator, $menu_text if ($FORM{NO_MENU});

 my $EX_ARGS = (defined($attr->{EX_ARGS})) ? $attr->{EX_ARGS} : '';
 my $fl = $attr->{FUNCTION_LIST};


 
my  %new_hash = ();
while((my($findex, $hash)=each(%$menu_items))) {
   while(my($parent, $val)=each %$hash) {
     #print "$parent $findex $val<br>\n";
     $new_hash{$parent}{$findex}=$val;
    }
}



my $h = $new_hash{0};
my @last_array = ();

my @menu_sorted = sort {
   $h->{$b} <=> $h->{$a}
     ||
   length($a) <=> length($b)
     ||
   $a cmp $b
} keys %$h;

for(my $parent=1; $parent<$#menu_sorted + 1; $parent++) { 
  my $val = $h->{$menu_sorted[$parent]};
  my $level = 0;
  my $prefix = '';
  my $ID = $menu_sorted[$parent];
  

  next if((! defined($attr->{ALL_PERMISSIONS})) && (! $permissions->{$parent-1}) && $parent == 0);
#  next if (! defined($permissions->{($parent-1)}));  
  $menu_text .= "<MENU NAME=\"$fl->{$ID}\" ID=\"$ID\" EX_ARGS=\"". $self->link_former($EX_ARGS) ."\" DESCRIBE=\"$val\" TYPE=\"MAIN\"/>\n ";

  #next;
  if (defined($new_hash{$ID})) {
    $level++;
    $prefix .= "   ";
    label:
      my $mi = $new_hash{$ID};

      while(my($k, $val)=each %$mi) {
         $menu_text .= "$prefix<MENU NAME=\"$fl->{$k}\" ID=\"$k\" EX_ARGS=\"". $self->link_former("$EX_ARGS") ."\" DESCRIBE=\"$val\" TYPE=\"SUB\" PARENT=\"$ID\"/>\n ";

        if (defined($new_hash{$k})) {
      	   $mi = $new_hash{$k};
      	   $level++;
           $prefix .= "    ";
           push @last_array, $ID;
           $ID = $k;
         }
        delete($new_hash{$ID}{$k});
      }
    
    if ($#last_array > -1) {
      $ID = pop @last_array;	
      $level--;
      
      $prefix = substr($prefix, 0, $level * 1 * 3);
      goto label;
    }
    delete($new_hash{0}{$parent});
   }

# return 0;
}


 return ($menu_navigator, $menu_text);
}

sub menu2 () {
 my $self = shift;
 my ($menu_items, $menu_args, $permissions, $attr) = @_;

 my $menu_navigator = '';
 my $root_index     = 0;
 my %tree           = ();
 my %menu           = ();
 my $sub_menu_array;
 my $EX_ARGS = (defined($attr->{EX_ARGS})) ? $attr->{EX_ARGS} : '';
 my $fl = $attr->{FUNCTION_LIST};
 
# if (defined($attr->{FUNCTION_LIST}) && $attr->{ALL_PERMISSIONS}) {
#   
#   my $qmenu_text = "<NAVIGATOR>\n";
#  
# 	 while(my($k, $v)=each %{ $attr->{FUNCTION_LIST} } ){
# 	 	 $qmenu_text .= "<MENU NAME=\"$v\" ID=\"$k\" DESCRIBE=\"\" EX_ARGS=\"". $self->link_former($EX_ARGS) ."\"/>\n";
# 	  }
#   $qmenu_text .= "</NAVIGATOR>\n";
#
#   return  '', $qmenu_text;
#  }



 # make navigate line 
 if ($index > 0) {
   $root_index = $index;
   my $h = $menu_items->{$root_index};

   while(my ($par_key, $name) = each ( %$h )) {

     my $ex_params = (defined($FORM{$menu_args->{$root_index}})) ? '&'."$menu_args->{$root_index}=$FORM{$menu_args->{$root_index}}" : '';
    
     $menu_navigator =  " ". $self->button($name, "index=$root_index$ex_params"). '/' . $menu_navigator;
     $tree{$root_index}='y';
     if ($par_key > 0) {
        $root_index = $par_key;
        $h = $menu_items->{$par_key};
      }
    }
}

$FORM{root_index} = $root_index;
if ($root_index > 0) {
  my $ri = $root_index-1;
  if (defined($permissions) && (! defined($permissions->{$ri}))) {
	  $self->{ERROR} = "Access deny";
	  return '', '';
   }
}


my @s = sort {
   length($a) <=> length($b)
     ||
   $a cmp $b
} keys %$menu_items;



foreach my $ID (@s) {
 	my $VALUE_HASH = $menu_items->{$ID};
 	foreach my $parent (keys %$VALUE_HASH) {
# 		print "$parent, $ID<br>";
    push( @{$menu{$parent}},  "$ID:$VALUE_HASH->{$parent}" );
   }
}

 my @last_array = ();

    my $menu_text = "\n<NAVIGATOR>\n";
 	  my $level  = 0;
 	  my $prefix = '';
    
    my $parent = 0;

 	  label:
 	  $sub_menu_array =  \@{$menu{$parent}};
 	  my $m_item='';
 	  
 	  my %table_items = ();
 	  
 	  while(my $sm_item = pop @$sub_menu_array) {
 	     my($ID, $name)=split(/:/, $sm_item, 2);
 	     next if((! defined($attr->{ALL_PERMISSIONS})) && (! $permissions->{$ID-1}) && $parent == 0);

       if(! defined($menu_args->{$ID}) || (defined($menu_args->{$ID}) && defined($FORM{$menu_args->{$ID}})) ) {
       	   my $ext_args = "$EX_ARGS";
       	   if (defined($menu_args->{$ID})) {
       	     $ext_args = "&$menu_args->{$ID}=$FORM{$menu_args->{$ID}}";
       	     $name = "<b>$name</b>" if ($name !~ /<b>/);
       	    }

       	   #my $link = $self->button($name, "index=$ID$ext_args");
    	       if($parent == 0) {
 	        	   $menu_text .= "<ITEM NAME=\"$fl->{$ID}\" ID=\"$ID\" DESCRIBE=\"$name\" EX_ARGS=\"". $self->link_former($EX_ARGS) ."\" TYPE=\"MAIN\" />\n";
 	        	   #$menu_text .= "<ITEM NAME=\"$fl->{$ID}\" TYPE=\"MAIN\" ID=\"$ID\">$prefix$link</ITEM>\n";
	            }
 	           elsif(defined($tree{$ID})) {
   	           $menu_text .= "<ITEM NAME=\"$fl->{$ID}\" ID=\"$ID\" DESCRIBE=\"$name\" EX_ARGS=\"". $self->link_former($EX_ARGS) ."\" TYPE=\"TREE\" />\n"; 
#   	           $menu_text .= "<ITEM TYPE=\"TREE\" ID=\"$ID\">$prefix$link</ITEM>\n";
 	            }
 	           else {
 	             $menu_text .= "  <ITEM NAME=\"$fl->{$ID}\" ID=\"$ID\" DESCRIBE=\"$name\" EX_ARGS=\"". $self->link_former($EX_ARGS) ."\" TYPE=\"SUB\" PARENT=\"$parent\" />\n"; 
 	             #$menu_text .= "<ITEM TYPE=\"SUB\" PARENT=\"$parent\" ID=\"$ID\">$prefix$link</ITEM>\n";
 	            }
         }
        else {
          #next;
          #$link = "<a href='$SELF_URL?index=$ID&$menu_args->{$ID}'>$name</a>";	
         }

 	      	     
 	     if(defined($tree{$ID})) {
 	     	 $level++;
 	     	 $prefix .= "&#160;&#160;&#160;";
         push @last_array, $parent;
         $parent = $ID;
 	     	 $sub_menu_array = \@{$menu{$parent}};
 	      }
 	   }

    if ($#last_array > -1) {
      $parent = pop @last_array;	
      #print "POP/$#last_array/$parent/<br>\n";
      $level--;
      $prefix = substr($prefix, 0, $level * 6 * 3);
      goto label;
     }


 	  
#  }
 
 
 $menu_text .= "</NAVIGATOR>\n";
 
 return ($menu_navigator, $menu_text);
}


#*******************************************************************
# heder off main page
# make_charts()
#*******************************************************************
sub make_charts () {
	
	
}

#*******************************************************************
# heder off main page
# header()
#*******************************************************************
sub header {
 my $self = shift;
 my($attr)=@_;
 my $admin_name=$ENV{REMOTE_USER};
 my $admin_ip=$ENV{REMOTE_ADDR};
 $self->{header} = "Content-Type: text/xml\n\n";
# my @_C;
 if ($COOKIES{colors} && $COOKIES{colors} ne '') {
   @_COLORS = split(/, /, $COOKIES{colors});
#    @_C = split(/, /, $COOKIES{colors});
  }

  my $JAVASCRIPT = ($attr->{PATH}) ? "$attr->{PATH}functions.js" : "functions.js";

  
 my $css = ''; #css();


my $CHARSET=(defined($attr->{CHARSET})) ? $attr->{CHARSET} : 'windows-1251';
$CHARSET=~s/ //g;
$self->{header} .= qq{<?xml version="1.0"  encoding="$CHARSET" ?>};
#<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN"
#              "http://my.netscape.com/publish/formats/rss-0.91.dtd">
#
#<html>
#<head>
#};

#$self->{header} .= $css;
#$self->{header} .= 
#"<script src=\"$JAVASCRIPT\" type=\"text/javascript\" language=\"javascript\"></script>\n".
#q{ 
#<title>~AsmodeuS~ Billing System</title>
#</head>} .


 return $self->{header};
}

#********************************************************************
#
# css()
#********************************************************************
sub css { 

my $css = "
<style type=\"text/css\">

body {
  background-color: $_COLORS[10];
  color: $_COLORS[9];
  font-family: Arial, Tahoma, Verdana, Helvetica, sans-serif;
  font-size: 14px;
  /* this attribute sets the basis for all the other scrollbar colors (Internet Explorer 5.5+ only) */
}

th.small {
  color: $_COLORS[9];
  font-size: 10px;
  height: 10;
}

td.small {
  color: $_COLORS[9];
  height: 1;
}

th, li {
  color: $_COLORS[9];
  height: 24;
  font-family: Arial, Tahoma, Verdana, Helvetica, sans-serif;
  font-size: 12px;
}

td {
  color: $_COLORS[9];
  font-family: Arial, Tahoma, Verdana, Helvetica, sans-serif;
  height: 20;
  font-size: 14px;
}

form {
  font-family: Tahoma,Verdana,Arial,Helvetica,sans-serif;
  font-size: 12px;
}

.button {
  font-family:  Arial, Tahoma,Verdana, Helvetica, sans-serif;
  background-color: #003366;
  color: #fcdc43;
  font-size: 12px;
  font-weight: bold;
}

input, textarea {
	font-family : Verdana, Arial, sans-serif;
	font-size : 12px;
	color : $_COLORS[9];
	border-color : #9F9F9F;
	border : 1px solid #9F9F9F;
	background : $_COLORS[2];
}

select {
	font-family : Verdana, Arial, sans-serif;
	font-size : 12px;
	color : $_COLORS[9];
	border-color : #C0C0C0;
	border : 1px solid #C0C0C0;
	background : $_COLORS[2];
}

TABLE.border {
  border-color : #99CCFF;
  border-style : solid;
  border-width : 1px;
}
</style>";

 return $css;
}


#**********************************************************
# table
#**********************************************************
sub table {
 my $proto = shift;
 my $class = ref($proto) || $proto;
 my $parent = ref($proto)  && $proto;
 my $self;
 $self = {};

 bless($self);

 $self->{prototype} = $proto;
 $self->{NO_PRINT} = $proto->{NO_PRINT};

 my($attr)=@_;
 $self->{rows}='';
 
 if (defined($attr->{rowcolor})) {
     $self->{rowcolor} = $attr->{rowcolor};
   }  


 if (defined($attr->{rows})) {
    my $rows = $attr->{rows};
    foreach my $line (@$rows) {
      $self->addrow(@$line);
     }
  }


 

 $self->{table} = "<TABLE";

 if (defined($attr->{caption})) {
   $self->{table} .= " CAPTION=\"$attr->{caption}\" ";
  }

 if (defined($attr->{ID})) {
   $self->{table} .= " ID=\"$attr->{ID}\" ";
  }
  
 $self->{table} .= ">\n";

 if (defined($attr->{title})) {
 	 $self->{table} .= $self->table_title($SORT, $DESC, $PG, $OP, $attr->{title}, $attr->{qs});
  }
 elsif(defined($attr->{title_plain})) {
   $self->{table} .= $self->table_title_plain($attr->{title_plain});
  }

 if (defined($attr->{pages})) {
 	   my $op;
 	   if($FORM{index}) {
 	   	 $op = "index=$FORM{index}";
 	    }
 	   else {
 	   	 $op = "op=$OP";
 	    }
 	   my %ATTR = ();
 	   if (defined($attr->{recs_on_page})) {
 	   	 $ATTR{recs_on_page}=$attr->{recs_on_page};
 	     }
 	   $self->{pages} =  $self->pages($attr->{pages}, "$op$attr->{qs}", { %ATTR });
	 } 

  return $self;
}

#*******************************************************************
# addrows()
#*******************************************************************
sub addrow {
  my $self = shift;
  my (@row) = @_;
 
  my $extra=(defined($self->{extra})) ? " $self->{extra}" : '';

  $row_number++;
  
  $self->{rows} .= "  <ROW>";
  foreach my $val (@row) {
     $self->{rows} .= "<TD$extra>". $self->link_former($val, { SKIP_SPACE => 1 }) ."</TD>";
   }

  $self->{rows} .= "</ROW>\n";
  return $self->{rows};
}

#*******************************************************************
# addrows()
#*******************************************************************
sub addtd {
  my $self = shift;
  my (@row) = @_;
 
  my $extra=(defined($self->{extra})) ? $self->{extra} : '';


  $self->{rows} .= "<ROW>";
  foreach my $val (@row) {
     $self->{rows} .= "$val";
   }

  $self->{rows} .= "</ROW>\n";

  return $self->{rows};
}



#*******************************************************************
# Extendet add rows
# th()
#*******************************************************************
sub th {
	my $self = shift;
	my ($value, $attr) = @_;
	
	return $self->td($value, { TH => 1 } );
}


#*******************************************************************
# Extendet add rows
# td()
#
#*******************************************************************
sub td {
  my $self = shift;
  my ($value, $attr) = @_;
  my $extra='';
  
  while(my($k, $v)=each %$attr ) {
    $extra.=" $k=\"$v\"";
   }

  my $td = '';
  if ($attr->{TH}) {
  	$td = "<TH $extra>";
   	$td .= $value if (defined($value));
  	$td .= "</TH>";

   }
  else {
    $td = "<TD$extra>";
   	$td .= $value if (defined($value));
  	$td .= "</TD>";
   }
  return $td;
}


#*******************************************************************
# title_plain($caption)
# $caption - ref to caption array
#*******************************************************************
sub table_title_plain {
  my $self = shift;
  my ($caption)=@_;

  $self->{table_title} = "<TITLE columns=\"". ($#{ @$caption } + 1) ."\">\n";
	my $i = 0;
  foreach my $line (@$caption) {
    $self->{table_title} .= "  <COLUMN_".$i." NAME=\"$line\"/>\n";
    $i++;
   }
	
  $self->{table_title} .= "</TITLE>\n";
  return $self->{table_title};
}

#*******************************************************************
# Show table column  titles with wort derectives
# Arguments 
# table_title($sort, $desc, $pg, $get_op, $caption, $qs);
# $sort - sort column
# $desc - DESC / ASC
# $pg - page id
# $caption - array off caption
#*******************************************************************
sub table_title  {
  my $self = shift;
  my ($sort, $desc, $pg, $get_op, $caption, $qs)=@_;
  my ($op);
  my $img='';

#  print "$sort, $desc, $pg, $op, $caption, $qs";

  $self->{table_title} = "<TITLE columns=\"". ($#{ @$caption } + 1) ."\">\n";
  my $i=1;
  foreach my $line (@$caption) {
     $self->{table_title} .= " <COLUMN_".$i." NAME=\"$line\" ";
     if ($line ne '-') {
         if ($sort != $i) {
           }
         elsif ($desc eq 'DESC') {
             $desc='';
             $self->{table_title} .= " SORT=\"ASC\"";
           }
         elsif($sort > 0) {
             $self->{table_title} .= " SORT=\"DESC\"";
             $desc='DESC';
           }
         
         #$self->{table_title} .= $self->button("<img src=\"$IMG_PATH/$img\" width=\"12\" height=\"10\" border=\"0\" alt=\"Sort\" title=\"sort\"/>", "$op$qs&pg=$pg&sort=$i&desc=$desc");
       }

     $self->{table_title} .= "/>\n";
     $i++;
   }
 $self->{table_title} .= "</TITLE>\n";
 return $self->{table_title};
}



#**********************************************************
# show
#**********************************************************
sub show  {
  my $self = shift;	
  my ($attr) = @_;
  
  $self->{show} = $self->{table};
  $self->{show} .= "<DATA>\n";
  $self->{show} .= $self->{rows}; 
  $self->{show} .= "</DATA>\n"; 
  $self->{show} .= "</TABLE>\n";

  if (defined($self->{pages})) {
 	   $self->{show} =  $self->{show} . $self->{pages}
 	 } 

  if ((defined($self->{NO_PRINT})) && ( !defined($attr->{OUTPUT2RETURN}) )) {
  	$self->{prototype}->{OUTPUT}.= $self->{show};
  	#$self->{OUTPUT} .= $self->{show};
  	$self->{show} = '';
   }




  return $self->{show};
}

#**********************************************************
#
#**********************************************************
sub link_former {
  my ($self) = shift;
  my ($params, $attr) = @_;

  $params =~ s/ /%20/g if (! $attr->{SKIP_SPACE});
  $params =~ s/&/&amp;/g;
  $params =~ s/>/&gt;/g;
  $params =~ s/</&lt;/g;
  $params =~ s/\"/&quot;/g;
 
  return $params;
}



#**********************************************************
#
# del_button($op, $del, $message, $attr)
#**********************************************************
sub button {
  my $self = shift;
  my ($name, $params, $attr)=@_;
  my $ex_params = (defined($attr->{ex_params})) ? $attr->{ex_params} : '';
  my $ex_attr = '';
  
  $params = ($attr->{GLOBAL_URL})? $attr->{GLOBAL_URL} : "$params";

  $params = $attr->{JAVASCRIPT} if (defined($attr->{JAVASCRIPT}));
  $params = $self->link_former($params);
  
  $ex_attr=" TITLE='$attr->{TITLE}'" if (defined($attr->{TITLE}));
  my $message = (defined($attr->{MESSAGE})) ? "onclick=\"return confirmLink(this, '$attr->{MESSAGE}')\"" : '';


  my $button = "<BUTTON VALUE=\"$params\" $ex_attr>$name</BUTTON>";

  return $button;
}

#*******************************************************************
# Show message box
# message($self, $type, $caption, $message)
# $type - info, err
#*******************************************************************
sub message {
 my $self = shift;
 my ($type, $caption, $message) = @_;	
 my $output = "<MESSAGE TYPE=\"$type\" CAPTION=\"$caption\">$message</MESSAGE>\n";
 
  if (defined($self->{NO_PRINT})) {
  	$self->{OUTPUT}.=$output;
  	return $output;
   }
	else {
 	  print $output;
	 }

}


#*******************************************************************
# Make pages and count total records
# pages($count, $argument)
#*******************************************************************
sub pages {
 my $self = shift;
 my ($count, $argument, $attr) = @_;

 if (defined($attr->{recs_on_page})) {
 	 $PAGE_ROWS = $attr->{recs_on_page};
  }

 my $begin=0;   

 return '' if ($count < $PAGE_ROWS);

 $self->{pages} = '';
 $begin = ($PG - $PAGE_ROWS * 3 < 0) ? 0 : $PG - $PAGE_ROWS * 3;

for(my $i=$begin; ($i<=$count && $i < $PG + $PAGE_ROWS * 10); $i+=$PAGE_ROWS) {
   $self->{pages} .= ($i == $PG) ? "<b>$i</b>" : $self->button($i, "$argument&pg=$i"). '';
}
 
 return "<PAGES>". $self->{pages} ."</PAGES>\n";
}



#*******************************************************************
# Make data field
# date_fld($base_name)
#*******************************************************************
sub date_fld  {
 my $self = shift;
 my ($base_name, $attr) = @_;
 
 my $MONTHES = $attr->{MONTHES};

 my($sec,$min,$hour,$mday,$mon,$curyear,$wday,$yday,$isdst) = localtime(time);

 my $day = $FORM{$base_name.'D'} || 1;
 my $month = $FORM{$base_name.'M'} || $mon;
 my $year = $FORM{$base_name.'Y'} || $curyear + 1900;



# print "$base_name -";
my $result  = "<SELECT name=\"". $base_name ."D\">";
for (my $i=1; $i<=31; $i++) {
   $result .= sprintf("<option value=\"%.2d\"", $i);
   $result .= ' selected="1"' if($day == $i ) ;
   $result .= ">$i</option>\n";
 }	
$result .= '</SELECT>';


$result  .= "<SELECT name=\"". $base_name ."M\">";

my $i=0;
foreach my $line (@$MONTHES) {
   $result .= sprintf("<option value=\"%.2d\"", $i);
   $result .= ' selected="1"' if($month == $i ) ;
   
   $result .= ">$line</option>\n";
   $i++
}

$result .= '</SELECT>';

$result  .= "<SELECT name=\"". $base_name ."Y\">";
for ($i=2001; $i<=$curyear + 1900; $i++) {
   $result .= "<option value=\"$i\"";
   $result .= ' selected="1"' if($year eq $i ) ;
   $result .= ">$i</option>\n";
 }	
$result .= '</SELECT>';

return $result ;
}

#**********************************************************
# log_print()
#**********************************************************
sub log_print {
 my $self = shift;
 my ($level, $text) = @_;	

 if($debug < $log_levels{$level}) {
     return 0;	
  }

print << "[END]";
<LOG_PRINT level="$level">
$text
</LOG_PRINT>
[END]
}

#**********************************************************
# show tamplate
# tpl_show
# 
# template
# variables_ref
# atrr [EX_VARIABLES]
#**********************************************************
sub tpl_show {
  my $self = shift;
  my ($tpl, $variables_ref, $attr) = @_;	
  
  my $tpl_name = '';
  
  my $xml_tpl = "<INFO name=\"$tpl_name\">\n";  
  
  while($tpl =~ /\%(\w+)\%/g) {
    my $var = $1;
    if ($var =~ /ACTION_LNG/) {
       next;
     }
    elsif (defined($variables_ref->{$var})) {
 	   	$xml_tpl .= "<$var>$variables_ref->{$var}</$var>\n";
     }
    else {
      $xml_tpl .= "<$var/>";
     }


  }

  $tpl =~ s/&nbsp;/&#160;/g;

  $xml_tpl .= "</INFO>\n";
  if($attr->{OUTPUT2RETURN}) {
		return $xml_tpl;
	 }
#  elsif (defined($attr->{notprint}) || ($self->{NO_PRINT} && $self->{NO_PRINT} == 1)) {
  elsif ($attr->{notprint} || defined($self->{NO_PRINT})) {
  	$self->{OUTPUT}.=$xml_tpl;
  	return $xml_tpl;
   }
	else { 
	 print $xml_tpl; 
	}
}

#**********************************************************
# test function
#  %FORM     - Form
#  %COOKIES  - Cookies
#  %ENV      - Enviropment
# 
#**********************************************************
sub test {
 my $output = '';

 while(my($k, $v)=each %FORM) {
  	$output .= "$k | $v\n" if ($k ne '__BUFFER');
  }

 $output .= "\n";
  while(my($k, $v)=each %COOKIES) {
    $output .= "$k | $v\n";
   }
}


#**********************************************************
# b();
#**********************************************************
sub b {
 my ($self) = shift; 
 my ($text) = @_;

 return $text;
}

#**********************************************************
# b();
#**********************************************************
sub p {
 my ($self) = shift; 
 my ($text) = @_;

 return $text;
}


#**********************************************************
# letters_list();
#**********************************************************
sub letters_list {
 my ($self, $attr) = @_;
 
 my $pages_qs = $attr->{pages_qs} if (defined($attr->{pages_qs}));

  
my $output = $self->button('All ', "index=$index");
for (my $i=97; $i<123; $i++) {
  my $l = chr($i);
  if ($FORM{letter} && $FORM{letter} eq $l) {
     $output .= "<b>$l </b>";
   }
  else {
     $output .= $self->button("$l", "index=$index&letter=$l$pages_qs") . "\n";
   }
 }

  if (defined($self->{NO_PRINT})) {
  	$self->{OUTPUT}.=$output;
  	return '';
   }
	else {
 	  print $output;
	 }

}

1
