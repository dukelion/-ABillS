package Abills::HTML;
#HTML 

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
$VERSION = 2.00;
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
   $secure
   $web_path
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

my $bg='';
my $debug;
my %log_levels;
my $IMG_PATH;
my $CONF;


my $row_number = 0;




#**********************************************************
# Create Object
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;
  
  
  $IMG_PATH = (defined($attr->{IMG_PATH})) ? $attr->{IMG_PATH} : '../img/';
  $CONF = $attr->{CONF} if (defined($attr->{CONF}));

  my $self = { };
  bless($self, $class);

  if ($attr->{NO_PRINT}) {
     $self->{NO_PRINT}=1;
   }
 
  $self->{OUTPUT}='';

  $self->{colors} = $attr->{colors} if (defined($attr->{colors}));
 
  %FORM = form_parse();
  %COOKIES = getCookies();

  $SORT = $FORM{sort} || 1;
  $DESC = ($FORM{desc}) ? 'DESC' : '';
  $PG = $FORM{pg} || 0;
  $OP = $FORM{op} || '';
  $self->{CHARSET}=(defined($attr->{CHARSET})) ? $attr->{CHARSET} : 'windows-1251';
   
  if ($FORM{PAGE_ROWS}) {
  	$PAGE_ROWS = $FORM{PAGE_ROWS};
   }
  elsif ($attr->{PAGE_ROWS}) {
  	$PAGE_ROWS = int($attr->{PAGE_ROWS});
   }
  else {
 	$PAGE_ROWS = 25;
   }

  if ($attr->{PATH}) {
    $self->{PATH}=$attr->{PATH};
    $IMG_PATH = $self->{PATH}.'img';
   }

  $domain = $ENV{SERVER_NAME};
  $web_path = '';
  $secure = '';
  my $prot = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http' ;
  $SELF_URL = (defined($ENV{HTTP_HOST})) ? "$prot://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}" : '';

  $SESSION_IP = $ENV{REMOTE_ADDR} || '0.0.0.0';

  
  @_COLORS = ('#FDE302',  # 0 TH
            '#FFFFFF',  # 1 TD.1
            '#eeeeee',  # 2 TD.2
            '#dddddd',  # 3 TH.sum, TD.sum
            '#E1E1E1',  # 4 border
            '#FFFFFF',  # 5
            '#FF0000',  # 6
            '#000088',  # 7 vlink
            '#0000A0',  # 8 Link
            '#000000',  # 9 Text
            '#FFFFFF',  #10 background
           ); #border
  
  %LIST_PARAMS = ( SORT      => $SORT,
	                 DESC      => $DESC,
	                 PG        => $PG,
	                 PAGE_ROWS => $PAGE_ROWS,
	                );

  %functions = ();
  
  $pages_qs = '';
  $index = $FORM{index} || 0;
  
  
  if ($attr->{language}) {
    $self->{language}=$attr->{language};
   }
  elsif ($COOKIES{language}) {
  	$self->{language}=$COOKIES{language};
   }
  else {
    $self->{language} = $CONF->{default_language} || 'english';
   }

  if (defined($FORM{xml})) {
    require Abills::XML;
    $self = Abills::XML->new( { IMG_PATH  => $IMG_PATH,
	                        NO_PRINT  => defined($attr->{'NO_PRINT'}) ? $attr->{'NO_PRINT'} : 1 
	                            
	                            });
  }
  

  return $self;
}






#*******************************************************************
# Parse inputs from query
# form_parse()
# return HASH
#
# For upload file: Content-Type
#                  Contents
#                  filename
#                  Size
#*******************************************************************
sub form_parse {
  my $self = shift;
  my %FORM = ();
  my($boundary, @pairs);
  my($buffer, $name);
  return %FORM if (! defined($ENV{'REQUEST_METHOD'}));


if ($ENV{'REQUEST_METHOD'} eq "GET") {
   $buffer= $ENV{'QUERY_STRING'};
 }
elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
   read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
 }

if (! defined($ENV{CONTENT_TYPE}) || $ENV{CONTENT_TYPE} !~ /boundary/ ) {

  @pairs = split(/&/, $buffer);
  $FORM{__BUFFER}=$buffer if ($#pairs > -1);

  foreach my $pair (@pairs) {
    my ($side, $value) = split(/=/, $pair);
    if (defined($value)) {
      $value =~ tr/+/ /;
      $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
      $value =~ s/<!--(.|\n)*-->//g;
      $value =~ s/<([^>]|\n)*>//g;

      #Check quotes
      $value =~ s/"/\\"/g;
      $value =~ s/'/\\'/g;
    }
    else {
      $value = '';
     }

    if (defined($FORM{$side})) {
      $FORM{$side} .= ", $value";
     }
    else {
      $FORM{$side} = $value;
     }
   }
 }
else {
 ($boundary = $ENV{CONTENT_TYPE}) =~ s/^.*boundary=(.*)$/$1/;
 
 @pairs = split(/--$boundary/, $buffer);
 @pairs = splice(@pairs,1,$#pairs-1);

 for my $part (@pairs) {
      $part =~ s/[\r]\n$//g;
      my ($dump, $firstline, $datas) = split(/[\r]\n/, $part, 3);
      next if $firstline =~ /filename=\"\"/;
      $firstline =~ s/^Content-Disposition: form-data; //;
      my (@columns) = split(/;\s+/, $firstline);
      ($name = $columns[0]) =~ s/^name="([^"]+)"$/$1/g;
      my $blankline;
      if ($#columns > 0) {
	      if ($datas =~ /^Content-Type:/) {
	        ($FORM{"$name"}->{'Content-Type'}, $blankline, $datas) = split(/[\r]\n/, $datas, 3);
           $FORM{"$name"}->{'Content-Type'} =~ s/^Content-Type: ([^\s]+)$/$1/g;
	       }
	      else {
	        ($blankline, $datas) = split(/[\r]\n/, $datas, 2);
	        $FORM{"$name"}->{'Content-Type'} = "application/octet-stream";
	       }
       }
      else {
	     ($blankline, $datas) = split(/[\r]\n/, $datas, 2);
        if (grep(/^$name$/, keys(%FORM))) {
          if (@{$FORM{$name}} > 0) {
            push(@{$FORM{$name}}, $datas);
           }
          else {
            my $arrvalue = $FORM{$name};
            undef $FORM{$name};
            $FORM{$name}[0] = $arrvalue;
            push(@{$FORM{$name}}, $datas);
           }
         }
        else {
	        next if $datas =~ /^\s*$/;
           $FORM{"$name"} = $datas;
         }
        next;
       }
      for my $currentColumn (@columns) {
        my ($currentHeader, $currentValue) = $currentColumn =~ /^([^=]+)="([^"]+)"$/;
        if ($currentHeader eq 'filename') {
        	 if ( $currentValue =~ /(\S+)\\(\S+)$/ ){
        	   $currentValue = $2;
            }
          }
        $FORM{"$name"}->{"$currentHeader"} = $currentValue;
       }

      $FORM{"$name"}->{'Contents'} = $datas;
      $FORM{"$name"}->{'Size'} = length($FORM{"$name"}->{'Contents'});
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


  my $type  = 'text';
  my $class = '';
  my $ex_params = '';
  
  if ($attr->{EX_PARAMS}) {
  	$ex_params = $attr->{EX_PARAMS};
   }
  
  if (defined($attr->{TYPE})) {
  	$type=$attr->{TYPE};
    if ($type =~ /submit/i) {
    	$class=' class="button"';
     }
   }  

  my $state = (defined($attr->{STATE})) ? ' checked ' : ''; 
  my $size  = (defined($attr->{SIZE})) ? " SIZE=\"$attr->{SIZE}\"" : '';
  

  
  $self->{FORM_INPUT}="<input type=\"$type\" name=\"$name\" value=\"$value\"$state$size$class$ex_params/>";

  if (defined($self->{NO_PRINT}) && ( !defined($attr->{OUTPUT2RETURN}) )) {
  	$self->{OUTPUT} .= $self->{FORM_INPUT};
  	$self->{FORM_INPUT} = '';
  }
	
	return $self->{FORM_INPUT};
}


#*******************************************************************
# form_main
#*******************************************************************
sub form_main {
  my $self = shift;
  my ($attr)	= @_;
	
	my $METHOD = ($attr->{METHOD}) ? $attr->{METHOD} : 'POST';
	$self->{FORM} =  "<FORM ";
	$self->{FORM} .= "name=\"$attr->{NAME}\" " if ($attr->{NAME});
	$self->{FORM} .= "action=\"$SELF_URL\" METHOD=\"$METHOD\">\n";
	

	
	
  if (defined($attr->{HIDDEN})) {
  	my $H = $attr->{HIDDEN};
  	while(my($k, $v)=each( %$H)) {
      $self->{FORM} .= "<input type=\"hidden\" name=\"$k\" value=\"$v\">\n";
  	}
  }

	if (defined($attr->{CONTENT})) {
	  $self->{FORM}.=$attr->{CONTENT};
	}


  if (defined($attr->{SUBMIT})) {
  	my $H = $attr->{SUBMIT};
  	while(my($k, $v)=each( %$H)) {
      $self->{FORM} .= "<input type=\"submit\" name=\"$k\" value=\"$v\" class=\"button\">\n";
  	}
  }


	$self->{FORM}.="</form>\n";
	
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
     $self->{SELECT} .=' selected' if (defined($attr->{SELECTED}) && $k eq $attr->{SELECTED});
     $self->{SELECT} .= ">$v\n";	
     }
   }
  
  
  if (defined($attr->{SEL_ARRAY})){
	  my $H = $attr->{SEL_ARRAY};
	  my $i=0;
	  foreach my $v (@$H) {
      my $id = (defined($attr->{ARRAY_NUM_ID})) ? $i : $v;
      $self->{SELECT} .= "<option value='$id'";
      $self->{SELECT} .= ' selected' if ($attr->{SELECTED} && ( ($i eq $attr->{SELECTED}) || ($v eq $attr->{SELECTED}) ) );
      $self->{SELECT} .= ">$v\n";
      $i++;
     }
   }
  elsif (defined($attr->{SEL_MULTI_ARRAY})){
    my $key   = $attr->{MULTI_ARRAY_KEY};
    my $value = $attr->{MULTI_ARRAY_VALUE};
	  my $H = $attr->{SEL_MULTI_ARRAY};

	  foreach my $v (@$H) {
      $self->{SELECT} .= "<option value='$v->[$key]'";
      $self->{SELECT} .= ' selected' if (defined($attr->{SELECTED}) && $v->[$key] eq $attr->{SELECTED});
      $self->{SELECT} .= '>';
      $self->{SELECT} .= "$v->[$key]:" if (! $attr->{NO_ID});
      $self->{SELECT} .= "$v->[$value]\n";
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
      $self->{SELECT} .=' selected' if (defined($attr->{SELECTED}) && $k eq $attr->{SELECTED});

      $self->{SELECT} .= ">";
      $self->{SELECT} .= "$k:" if (! $attr->{NO_ID});
      $self->{SELECT} .= "$attr->{SEL_HASH}{$k}\n";	
     }
   }
	
	$self->{SELECT} .= "</select>\n";

	return $self->{SELECT};
}


sub dirname {
    my($x) = @_;
    if ( $x !~ s@[/\\][^/\\]+$@@ ) {
     	$x = '.';
    }
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


#
# 
# 
sub menu () {
 my $self = shift;
 my ($menu_items, $menu_args, $permissions, $attr) = @_;

 my $menu_navigator = '';
 my $root_index = 0;
 my %tree = ();
 my %menu = ();
 my $sub_menu_array;
 my $EX_ARGS = (defined($attr->{EX_ARGS})) ? $attr->{EX_ARGS} : '';

 # make navigate line 
 if ($index > 0) {
  $root_index = $index;	
  my $h = $menu_items->{$root_index};

  while(my ($par_key, $name) = each ( %$h )) {

    my $ex_params = (defined($menu_args->{$root_index}) && defined($FORM{$menu_args->{$root_index}})) ? '&'."$menu_args->{$root_index}=$FORM{$menu_args->{$root_index}}" : '';
    
    $menu_navigator =  " ". $self->button($name, "index=$root_index$ex_params"). '/' . $menu_navigator;
    $tree{$root_index}=1;
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

 my $menu_text = "<div class='menu'>
 <table border='0' width='100%'>\n";

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

 	     $name = (defined($tree{$ID})) ? "<b>$name</b>" : "$name";
       if(! defined($menu_args->{$ID}) || (defined($menu_args->{$ID}) && defined($FORM{$menu_args->{$ID}})) ) {
       	   my $ext_args = "$EX_ARGS";
       	   if (defined($menu_args->{$ID})) {
       	     $ext_args = "&$menu_args->{$ID}=$FORM{$menu_args->{$ID}}";
       	     $name = "<b>$name</b>" if ($name !~ /<b>/);
       	    }

       	   my $link = $self->button($name, "index=$ID$ext_args");
    	       if($parent == 0) {
 	        	   $menu_text .= "<tr><td bgcolor=\"$_COLORS[3]\" align=left>$prefix$link</td></tr>\n";
	            }
 	           elsif(defined($tree{$ID})) {
   	           $menu_text .= "<tr><td bgcolor=\"$_COLORS[2]\" align=left>$prefix>$link</td></tr>\n";
 	            }
 	           else {
 	             $menu_text .= "<tr><td bgcolor=\"$_COLORS[1]\">$prefix$link</td></tr>\n";
 	            }
         }
        else {
          #next;
          #$link = "<a href='$SELF_URL?index=$ID&$menu_args->{$ID}'>$name</a>";	
         }

 	      	     
 	     if(defined($tree{$ID})) {
 	     	 $level++;
 	     	 $prefix .= "&nbsp;&nbsp;&nbsp;";
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
 
 
 $menu_text .= "</table>\n</div>\n";
 
 return ($menu_navigator, $menu_text);
}

#*******************************************************************
# menu($type, $main_para,_name, $ex_params, \%menu_hash_ref);
#
# $type
#   0 - horizontal  
#   1 - vertical
# $ex_params - extended params
# $mp_name - Menu parameter name
# $params - hash of menu items
# menu($type, $mp_name, $ex_params, $menu, $sub_menu, $attr);
#*******************************************************************
sub menu2 {
 my $self = shift;
 my ($type, $mp_name, $ex_params, $menu, $sub_menu, $attr)=@_;
 my @menu_captions = sort keys %$menu;

 $self->{menu} = "<TABLE width=\"100%\">\n";

if ($type == 1) {

  foreach my $line (@menu_captions) {
    my($n, $file, $k)=split(/:/, $line);
    my $link = ($file eq '') ? "$SELF_URL" : "$file";
    $link .= '?'; 
    $link .= "$mp_name=$k&" if ($k ne '');


#    if ((defined($FORM{$mp_name}) && $FORM{$mp_name} eq $k) && $file eq '') {
     if ((defined($FORM{root_index}) && $FORM{root_index} eq $k) && $file eq '') {
      $self->{menu} .= "<tr><td bgcolor=\"$_COLORS[3]\"><a href='$link$ex_params'><b>". $menu->{"$line"} ."</b></a></td></TR>\n";
      while(my($k, $v)=each %$sub_menu) {
      	 $self->{menu} .= "<tr><td bgcolor=\"$_COLORS[1]\">&nbsp;&nbsp;&nbsp;<a href='$SELF_URL?index=$k'>$v</a></td></TR>\n";
       }
     }
    else {
      $self->{menu} .= "<tr><td><a href='$link'>". $menu->{"$line"} ."</a></td></TR>\n";
     }
   }
}
else {
  $self->{menu} .= "<tr bgcolor=\"$_COLORS[0]\">\n";
  
  foreach my $line (@menu_captions) {
    my($n, $file, $k)=split(/:/, $line);
    my $link = ($file eq '') ? "$SELF_URL" : "$file";
    $link .= '?'; 
    $link .= "$mp_name=$k&" if ($k ne '');

    $self->{menu} .= "<th";
    if ($FORM{$mp_name} eq $k && $file eq '') {
      $self->{menu} .= " bgcolor=\"$_COLORS[3]\"><a href='$link$ex_params'>". $menu->{"$line"} ."</a></th>";
     }
    else {
      $self->{menu} .= "><a href='$link'>". $menu->{"$line"} ."</a></th>\n";
     }

 }
  $self->{menu} .= "</TR>\n"; 
}

 $self->{menu} .= "</TABLE>\n";


 return $self->{menu};
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
 $self->{header} = "Content-Type: text/html\n\n";


 if ($self->{colors}) {
   @_COLORS = split(/, /, $self->{colors});
  }
 elsif (defined($COOKIES{colors}) && $COOKIES{colors} ne '') {
   @_COLORS = split(/, /, $COOKIES{colors});
  }

 my $JAVASCRIPT = "functions.js"; 
 my $PRINTCSS = "print.css";

 if($self->{PATH}) {
   $JAVASCRIPT = "$self->{PATH}$JAVASCRIPT";
   $PRINTCSS = "$self->{PATH}$PRINTCSS";
  }


 my $css = css();
 my $title = ($CONF->{WEB_TITLE}) ? $CONF->{WEB_TITLE} : "~AsmodeuS~ Billing System";
 my $REFRESH = ($FORM{REFRESH}) ? "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"$FORM{REFRESH}; URL=$ENV{REQUEST_URI}\"/>\n" : '';

$self->{header} .= qq{
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
 $REFRESH
 <META HTTP-EQUIV="Cache-Control" content="no-cache,no-cache,no-store,must-revalidate"/>
 <META HTTP-EQUIV="Expires" CONTENT="-1"/>
 <META HTTP-EQUIV="Pragma" CONTENT="no-cache"/>
 <meta http-equiv="Content-Type" content="text/html; charset=$self->{CHARSET}"/>
 <meta name="Author" content="~AsmodeuS~"/>
};

$self->{header} .= $css;
$self->{header} .= " <link rel=\"stylesheet\" media=\"print\" type=\"text/css\" href=\"$PRINTCSS\" />
  <script src=\"$JAVASCRIPT\" type=\"text/javascript\" language=\"javascript\"></script>
<title>$title</title>
</head>
<body style=\"margin: 0\" bgcolor=\"$_COLORS[10]\" text=\"$_COLORS[9]\" link=\"$_COLORS[8]\"  vlink=\"$_COLORS[7]\">\n";

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
  background-color: $_COLORS[2];
  color: $_COLORS[9];
  font-size: 12px;
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


# if (@ISA && $proto->SUPER::can('table')) {
# 	  $self = $proto->SUPER::table(@_);
#  }
# else {
  $self = {};
#  bless($self, $proto);
# }


# while(my($k, $v)=each %$proto) {
#   print "$k, $v <br>";	
# }
 
 bless($self);


 $self->{prototype} = $proto;
 $self->{NO_PRINT} = $proto->{NO_PRINT};

 my($attr)=@_;
 $self->{rows}='';

 
 my $width = (defined($attr->{width})) ? "width=\"$attr->{width}\"" : '';
 my $border = (defined($attr->{border})) ? "border=\"$attr->{border}\"" : '';
 my $table_class = (defined($attr->{class})) ? "class=\"$attr->{class}\"" : '';

 if (defined($attr->{rowcolor})) {
    $self->{rowcolor} = $attr->{rowcolor};
   }  
 else {
    $self->{rowcolor} = undef;
  }

 if (defined($attr->{rows})) {
    my $rows = $attr->{rows};
    foreach my $line (@$rows) {
      $self->addrow(@$line);
     }
  }

 $self->{table} = "<TABLE $width cellspacing=\"0\" cellpadding=\"0\" border=\"0\"$table_class>\n";
 
 if (defined($attr->{caption})) {
   $self->{table} .= "<TR><TD bgcolor=\"$_COLORS[1]\" align=\"right\" class=\"tcaption\"><b>$attr->{caption}</b></td></TR>\n";
  }

 $self->{table} .= "<tr><td bgcolor=\"$_COLORS[1]\">$attr->{header}</td></tr>\n" if( $attr->{header});

 $self->{table} .= "<TR><TD bgcolor=\"$_COLORS[4]\">
               <TABLE width=\"100%\" cellspacing=\"1\" cellpadding=\"0\" border=\"0\">\n";

 

 if (defined($attr->{title})) {
   #print "--- $SORT // | $FORM{sort} | $LIST_PARAMS{SORT} //";
   $SORT = $LIST_PARAMS{SORT};
 	 $self->{table} .= $self->table_title($SORT, $DESC, $PG, $OP, $attr->{title}, $attr->{qs});
  }
 elsif(defined($attr->{title_plain})) {
   $self->{table} .= $self->table_title_plain($attr->{title_plain});
  }

 if (defined($attr->{cols_align})) {
   $self->{table} .= "<COLGROUP>";
   my $cols_align = $attr->{cols_align};
   my $i=0;
   foreach my $line (@$cols_align) {
     my $class = '';
     if ($line =~ /:/) {
       ($line, $class) = split(/:/, $line,  2);
       $class = " class=\"$class\"";
      }
     my $width = (defined($attr->{cols_width}) && defined(@{$attr->{cols_width}}[$i])  ) ? " width=\"@{$attr->{cols_width}}[$i]\"" : '';
     $self->{table} .= " <COL align=\"$line\"$class$width>\n";
     $i++;
    }
   $self->{table} .= "</COLGROUP>\n";
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

  if ($self->{rowcolor}) {
    $bg = $self->{rowcolor};
   }  
  else {
  	$bg = ($bg eq $_COLORS[1]) ? $_COLORS[2] : $_COLORS[1];
   }
  
  my $extra=($self->{extra}) ? $self->{extra} : '';

  $row_number++;
  
  $self->{rows} .= "<tr bgcolor=\"$bg\"  onmouseover=\"setPointer(this, $row_number, 'over', '$bg', '$_COLORS[3]', '$_COLORS[0]');\" onmouseout=\"setPointer(this, $row_number, 'out', '$bg', '$_COLORS[3]', '$_COLORS[0]');\" onmousedown=\"setPointer(this, $row_number, 'click', '$bg', '$_COLORS[3]', '$_COLORS[0]');\">";
  
  foreach my $val (@row) {
     $self->{rows} .= "<TD bgcolor=\"$bg\" $extra>";
     $self->{rows} .= $val if(defined($val));
     $self->{rows} .= "</TD>";
   }

  $self->{rows} .= "</TR>\n";
  return $self->{rows};
}

#*******************************************************************
# addrows()
#*******************************************************************
sub addtd {
  my $self = shift;
  my (@row) = @_;

  if (defined($self->{rowcolor})) {
    $bg = $self->{rowcolor};
   }  
  else {
  	$bg = ($bg eq $_COLORS[1]) ? $_COLORS[2] : $_COLORS[1];
   }
  
  my $extra=(defined($self->{extra})) ? $self->{extra} : '';


  $self->{rows} .= "<tr bgcolor=\"$bg\">";
  foreach my $val (@row) {
     $self->{rows} .= "$val";
   }

  $self->{rows} .= "</TR>\n";
  return $self->{rows};
}




#*******************************************************************
# Extendet add rows
# th()
#*******************************************************************
sub th {
	my $self = shift;
	my ($value, $attr) = @_;
	
	return $self->td($value, { TH => 1, ($attr) ? %$attr : undef  } );
}

#*******************************************************************
# Extendet add rows
# td()
#*******************************************************************
sub td {
  my $self = shift;
  my ($value, $attr) = @_;
  my $extra='';
  
  while(my($k, $v)=each %$attr ) {
    next if ($k eq 'TH');
    $extra.=" $k=$v";
   }
  my $td = '';

  if ($attr->{TH}) {
  	$td = "<TH $extra>";
  	$td .= $value if (defined($value));
  	$td .= "</TH>";
   }
  else {
    $td = "<TD $extra>";
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
  $self->{table_title} = "<tr bgcolor=\"$_COLORS[0]\">";
	
  foreach my $line (@$caption) {
    $self->{table_title} .= "<th class='table_title'>$line</th>";
   }
	
  $self->{table_title} .= "</TR>\n";
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

  #print "$FORM{sort} // SORT: $sort, DESC: $desc, PAGE: $pg, $op, $caption, $qs--";

  $self->{table_title} = "<tr bgcolor=\"$_COLORS[0]\">";
  my $i=1;
  foreach my $line (@$caption) {
     $self->{table_title} .= "<th class='table_title'>$line ";
     if ($line ne '-') {
         if ($sort != $i) {
             $img = 'sort_none.png';
           }
         elsif ($desc eq 'DESC') {
             $img = 'down_pointer.png';
             $desc='';
           }
         elsif($sort > 0) {
             $img = 'up_pointer.png';
             $desc='DESC';
           }
         
         if ($FORM{index}) {
         	  $op="index=$FORM{index}";
          }
         
         if ($FORM{index}) {
         	  $op="index=$FORM{index}";
         	}
         else {
         	  $op="op=$get_op";
          }

         $self->{table_title} .= $self->button("<img src=\"$IMG_PATH/$img\" width=\"12\" height=\"10\" border=\"0\" alt=\"Sort\" title=\"Sort\" class=\"noprint\">", "$op$qs&pg=$pg&sort=$i&desc=$desc");
       }
     else {
         $self->{table_title} .= "$line";
       }

     $self->{table_title} .= "</th>\n";
     $i++;
   }
 $self->{table_title} .= "</TR>\n";

 return $self->{table_title};
}



#**********************************************************
# show
#**********************************************************
sub show  {
  my $self = shift;	
  my ($attr) = shift;
  
  
  $self->{show} = $self->{table};
  $self->{show} .= $self->{rows}; 
  $self->{show} .= "</TABLE></TD></TR></TABLE>\n";

  if (defined($self->{pages})) {
 	   $self->{show} =  '<br>'.$self->{pages} . $self->{show} . $self->{pages} .'<br>';
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
  $params =~ s/\*/&#42;/g;
 
  return $params;
}

#**********************************************************
#
# del_button($op, $del, $message, $attr)
#**********************************************************
sub button {
  my $self = shift;
  my ($name, $params, $attr)=@_;

  my $ex_attr = ($attr->{ex_params}) ? $attr->{ex_params} : '';

  
  $params = ($attr->{GLOBAL_URL})? $attr->{GLOBAL_URL} : "$SELF_URL?$params";
  $params = $attr->{JAVASCRIPT} if (defined($attr->{JAVASCRIPT}));
  $params = $self->link_former($params);

  
  $ex_attr=" TITLE='$attr->{TITLE}'" if (defined($attr->{TITLE}));
  
  $ex_attr .= " onclick=\"window.open('$attr->{NEW_WINDOW}', null,
            'toolbar=0,location=0,directories=0,status=1,menubar=0,'+
            'scrollbars=1,resizable=1,'+
            'width=640, height=480');\"" if ( $attr->{NEW_WINDOW} );

  
  my $message = ($attr->{MESSAGE}) ? " onclick=\"return confirmLink(this, '$attr->{MESSAGE}')\"" : '';
  my $button = "<a href=\"$params\"$ex_attr$message>$name</a>";

  return $button;
}

#*******************************************************************
# Show message box
# message($self, $type, $caption, $message)
# $type - info, err
#*******************************************************************
sub message {
 my $self = shift;
 my ($type, $caption, $message, $head) = @_;
 
 if ($type eq 'err') {
   $head = "<tr><th bgcolor=\"#FF0000\">$caption</th></TR>\n";
  }
 elsif ($type eq 'info') {
   $head = "<tr><th bgcolor=\"$_COLORS[0]\">$caption</th></TR>\n";
  }  
 
my $output = qq{
<br>
<TABLE width="400" border="0" cellpadding="0" cellspacing="0" class="noprint">
<tr><TD bgcolor="$_COLORS[9]">
<TABLE width="100%" border=0 cellpadding="2" cellspacing="1">
<tr><TD bgcolor="$_COLORS[1]">

<TABLE width="100%">
$head
<tr><TD bgcolor="$_COLORS[1]">$message</TD></TR>
</TABLE>

</TD></TR>
</TABLE>
</TD></TR>
</TABLE>
<br>
};



  if (defined($self->{NO_PRINT})) {
  	$self->{OUTPUT}.=$output;
  	#print "aaaaaa $self->{OUTPUT}";
  	return $output;
   }
	else { 
 	  print $output;
	 }

}


#*******************************************************************
# Preformated test
#*******************************************************************
sub pre {
 my $self = shift;
 my ($message) = @_;
 
 
my $output = qq{
<pre>
 $message
</pre>
};

  if (defined($self->{NO_PRINT})) {
  	$self->{OUTPUT}.=$output;
  	return $output;
   }
	else { 
 	  print $output;
	 }

}

#*******************************************************************
# Mark Bold
#*******************************************************************
sub b {
 my $self = shift;
 my ($message) = @_;
 
 
 my $output = "<b>$message</b>";

 return $output;
}

#*******************************************************************
# Mark text
#*******************************************************************
sub color_mark {
 my $self = shift;
 my ($message, $color) = @_;
 
 my $output = "<font color=$color>$message</font>";

 return $output;
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


 $self->{pages} = '';
 $begin = ($PG - $PAGE_ROWS * 3 < 0) ? 0 : $PG - $PAGE_ROWS * 3;

 $argument .= "&sort=$FORM{sort}" if ($FORM{sort});
 $argument .= "&desc=$FORM{desc}" if ($FORM{sort});

 return $self->{pages} if ($count < $PAGE_ROWS);
 
for(my $i=$begin; ($i<=$count && $i < $PG + $PAGE_ROWS * 10); $i+=$PAGE_ROWS) {
   $self->{pages} .= ($i == $PG) ? "<b>$i</b>:: " : $self->button($i, "$argument&pg=$i"). ':: ';
}
 
 return $self->{pages};
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
 
 if ($attr->{DATE}) {
 	 my ($y, $m, $d)=split(/-/, $attr->{DATE});
 	 $mday=$d;
  }
 else {
   $mday=1;
  }
 
 my $day = $FORM{$base_name.'D'} || $mday;
 my $month = $FORM{$base_name.'M'} || $mon;
 my $year = $FORM{$base_name.'Y'} || $curyear + 1900;


my $result  = "<SELECT name=". $base_name ."D>";
for (my $i=1; $i<=31; $i++) {
   $result .= sprintf("<option value=%.2d", $i);
   $result .= ' selected' if($day == $i ) ;
   $result .= ">$i\n";
 }	
$result .= '</select>';


$result  .= "<SELECT name=". $base_name ."M>";

my $i=0;
foreach my $line (@$MONTHES) {
   $result .= sprintf("<option value=%.2d", $i);
   $result .= ' selected' if($month == $i ) ;
   
   $result .= ">$line\n";
   $i++
}
$result .= '</select>';

$result  .= "<SELECT name=". $base_name ."Y>";
for ($i=2002; $i<=$curyear + 1900+2; $i++) {
   $result .= "<option value=$i";
   $result .= ' selected' if($year eq $i ) ;
   $result .= ">$i\n";
 }	
$result .= '</select>'."\n";

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
<TABLE width="640" border="0" cellpadding="0" cellspacing="0">
<tr><TD bgcolor="#00000">
<TABLE width="100%" border="0" cellpadding="2" cellspacing="1">
<tr><TD bgcolor="FFFFFF">

<TABLE width="100%">
<tr bgcolor="$_COLORS[3]"><th>
$level
</th></TR>
<tr><TD>
$text
</TD></TR>
</TABLE>

</TD></TR>
</TABLE>
</TD></TR>
</TABLE>
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
  

  while($tpl =~ /\%(\w+)\%/g) {
#    print "-$1-<br>\n";
    my $var = $1;
    if (defined($variables_ref->{$var})) {
    	$tpl =~ s/\%$var\%/$variables_ref->{$var}/g;
    }
    else {
      $tpl =~ s/\%$var\%//g;
    }
  }

  if($attr->{OUTPUT2RETURN}) {
		return $tpl;
	 }
  elsif ($attr->{notprint} || $self->{NO_PRINT}) {
  	$self->{OUTPUT} .= $tpl;
  	return $tpl;
   }
	else { 
 	  print $tpl;
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

#print "<TABLE border=1>
#<tr><TD colspan=2>FORM</TD></TR>
#<tr><TD>index</TD><TD>$index</TD></TD></TR>
#<tr><TD>root_index</TD><TD>root_index</TD></TD></TR>\n";	
  while(my($k, $v)=each %FORM) {
  	$output .= "$k | $v\n" if ($k ne '__BUFFER');
    #print "<tr><TD>$k</TD><TD>$v</TD></TR>\n";	
   }
#print "</TABLE>\n";
 $output .= "\n";
#print "<br><TABLE border=1>
#<tr><TD colspan=2>COOKIES</TD></TR>
#<tr><TD>index</TD><TD>$index</TD></TD></TR>\n";	
  while(my($k, $v)=each %COOKIES) {
    $output .= "$k | $v\n";
    #print "<tr><TD>$k</TD><TD>$v</TD></TR>\n";	
   }
#print "</TABLE>\n";


#print "<br><TABLE border=1>\n";
#  while(my($k, $v)=each %ENV) {
#    print "<tr><TD>$k</TD><TD>$v</TD></TR>\n";	
#   }
#print "</TABLE>\n";

#print "<br><TABLE border=1>\n";
#  while(my($k, $v)=each %conf) {
#    print "<tr><TD>$k</TD><TD>$v</TD></TR>\n";	
#   }
#print "</TABLE>\n";
#

#print "<a href='#' onclick=\"document.write ( 'answer' )\">aaa</a>";

#print "<a href='#' onclick=\"open('aaa','help', 
# 'height=550,width=450,resizable=0, scrollbars=yes, menubar=no, status=yes');\"><font color=$_COLORS[1]>Debug</font></a>";

print "<a href='#' title='$output' class='noprint'><font color=$_COLORS[1]>Debug</font></a>\n";

}





#**********************************************************
# letters_list();
#**********************************************************
sub letters_list {
 my ($self, $attr) = @_;
 
 my $pages_qs = $attr->{pages_qs} if (defined($attr->{pages_qs}));
 my @alphabet = ('a-z');
#'97-123'
 if ($attr->{EXPR}) {
  push @alphabet, $attr->{EXPR};
  }

my $letters = $self->button('All ', "index=$index"). '::';

foreach my $line (@alphabet) {
  $line=~/(\S)-(\S)/;
  my $first = ord($1);
  my $last  = ord($2);

  for (my $i=$first; $i<=$last; $i++) {
    my $l = chr($i);
    if ($FORM{letter} && $FORM{letter} eq $l) {
      $letters .= "<b>$l </b>\n";
     }
    else {
      $letters .= $self->button("$l", "index=$index&letter=$l$pages_qs") . " \n";
    }
   }

  $letters.="<br>\n";
}
  if (defined($self->{NO_PRINT})) {
  	$self->{OUTPUT}.=$letters;
  	return '';
   }
	else { 
 	  return $letters;
	 }
}

#**********************************************************
# Using some flash from http://www.maani.us
#
#**********************************************************
sub make_charts {
	my $self = shift;
	my ($attr) = @_;


  my $PATH='';
  if ($IMG_PATH ne '') {
	  $PATH = $IMG_PATH;
	  $PATH =~ s/img//;
   }

#  if (! -f $PATH. "charts.swf") {
#     return 0;
#   }
  
  my $suffix = ($attr->{SUFFIX}) ? $attr->{SUFFIX} : '';

  my @chart_transition = ('dissolve', 'drop', 'spin', 'scale', 'zoom', 'blink', 'slide_right', 'slide_left', 'slide_up', 'slide_down', 'none');
  my $DATA = $attr->{DATA};
  my $ex_params = '';


  return  if(scalar keys  %$DATA == 0);

  if ($attr->{TRANSITION} && $CONF->{CHART_ANIMATION}) {
    my $random = int(rand(@chart_transition));
    $ex_params = " <chart_transition type=\"$chart_transition[$random]\" delay=\"1\" duration=\"2\" order=\"series\" />\n";
   }

 	my $AXIS_CATEGORY_skip = (defined($attr->{AXIS_CATEGORY_skip})) ? $attr->{AXIS_CATEGORY_skip} : 2 ;
  my $CHART_RECT_width   = ($attr->{CHART_RECT_width}) ? $attr->{CHART_RECT_width} : 400 ;  
  my $CHART_RECT_height  = ($attr->{CHART_RECT_height}) ? $attr->{CHART_RECT_height} : 200 ;  
  my $CHART_RECT_x = ($attr->{CHART_RECT_x}) ? $attr->{CHART_RECT_x} : 30 ;  
  my $CHART_RECT_y = ($attr->{CHART_RECT_y}) ? $attr->{CHART_RECT_y} : 50 ;  
  
  
  my $data = '<chart>'.
  $ex_params

	.'<series_color>
		<value>ff8800</value>
		<value>00FF00</value>
	 </series_color>

  	<chart_grid_h alpha="10" color="0066FF" thickness="1"  />
	  <chart_grid_v alpha="10" color="0066FF" thickness="1" />

	<axis_category font="arial" bold="1" size="11" color="000000" alpha="50" skip="'. $AXIS_CATEGORY_skip. '" />
	<axis_ticks value_ticks="" category_ticks="1" major_thickness="2" minor_thickness="1" minor_count="3" major_color="000000" minor_color="888888" position="outside" />

  <axis_value font="arial" bold="1" size="9" color="000000" alpha="75" 
  steps="4" prefix="" suffix="'. $suffix .'" 
  decimals="0" 
  separator="" 
  show_min="1" 
  orientation="diagonal_up"
  />

 
	<chart_border color="000000" top_thickness="1" bottom_thickness="2" left_thickness="0" right_thickness="0" />
  <chart_rect x="'. $CHART_RECT_x .'" y="'. $CHART_RECT_y .'" width="'. $CHART_RECT_width .'" height="'. $CHART_RECT_height .'" positive_color="FFFFFF" positive_alpha="40" />
  ';

  $data .= "<chart_data>\n";

  if ($attr->{PERIOD} eq 'month_stats') {
    $data .= "<row>\n".   	
    "<string></string>\n";
    for(my $i=1; $i<=31; $i++) {
    	 $data .= "<string>$i</string>\n";
     }
   $data .= "</row>\n";
  }
  elsif ($attr->{PERIOD} eq 'day_stats') {
    $data .= "<row>\n".   	
    "<string></string>\n";
    for(my $i=0; $i<=23; $i++) {
    	 $data .= "<string>$i</string>\n";
     }
   $data .= "</row>\n";
  }
  elsif ($attr->{X_TEXT}) {
    $data .= "<row>\n".   	
    "<string></string>\n";
    foreach my $i (@{ $attr->{X_TEXT} }) {
    	 $data .= "<string>$i</string>\n";
     }
   $data .= "</row>\n";
  }
  


  while(my($name, $value)=each %$DATA ){
    next if ($name eq 'MONEY');

    my $midle=0;
    $data .= "<row>\n".
    "<string>$name</string>\n";
    if (defined($attr->{AVG}{$name}) && $attr->{AVG}{$name} > 0) {
    	 $midle = 100 / $attr->{AVG}{$name};
      }

    shift @$value;
    foreach my $line (@$value) {
    	 $data .= "<number>";
    	 $data .= ($midle > 0) ? $line * $midle : $line; 
    	 $data .="</number>\n";
     }
   $data .= "</row>\n";
  }

#Make money graffic
  if (defined($DATA->{MONEY})) { 
    $data .= "<row>\n".
    "<string>MONEY</string>\n";
    my $name = 'MONEY';
    my $value = $DATA->{$name};
    my $midle = 0;
    if (defined($attr->{AVG}{$name}) && $attr->{AVG}{$name} > 0) {
    	 $midle = 100 / $attr->{AVG}{$name};
     }
    
    shift @$value;
    foreach my $line (@$value) {
    	 $data .= "<number>";
    	 $data .= ($midle > 0 && defined($line)) ? $line * $midle : $line; 
    	 $data .="</number>\n";
     }
    $data .= "</row>\n";
  }   

  $data .= "</chart_data>\n";

  if ($attr->{TYPE}) {
    $data .= "<chart_type>";
		my $type_array_ref = $attr->{TYPE};
		foreach my $line (@$type_array_ref) {
		  if ($line eq 'bar') {
		  	$data .= "$line";
		  	last;
		   }
		  else {
		    $data .= " <value>$line</value>";
		   }
     }
   	$data .= "</chart_type>\n";
   }
  
  


    #Make right text
    if (defined($attr->{AVG}{MONEY}) && $attr->{AVG}{MONEY} > 0) {
     	my $part = $attr->{AVG}{MONEY} / 4;
    	$data .= "<draw>\n";
   	  foreach(my $i=0; $i<=4; $i++) {
     	   $data .= "<text size=\"9\" x=\"435\" y=\"". (242-$i*45) ."\" color=\"000000\">". int($i * $part) ."</text>\n";
   	   }
   	  $data .= "</draw>\n";
    }
 
$data .= "</chart>\n";

 
 my $file_xml = 'charts';
 if (! defined($self->{CHART_NUM})) {
   $self->{CHART_NUM}=0; 	
  }
 else {
 	 $self->{CHART_NUM}++; 	
 	 $file_xml='charts'. $self->{CHART_NUM};
  }
 
 open(FILE, ">$file_xml".'.xml') || $self->message('err', 'ERROR', "Can't create file '$file_xml.xml' $!");
   print FILE $data;
 close(FILE);
 	


my $output = "
<br>
<OBJECT classid='clsid:D27CDB6E-AE6D-11cf-96B8-444553540000' 
codebase='http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0' 
WIDTH=". ($CHART_RECT_width + 100). " 
HEIGHT=". ($CHART_RECT_height + 100). "
id='$file_xml' ALIGN=''>
<PARAM NAME=movie VALUE='". $PATH. "charts.swf?library_path=". $PATH. "charts_library&amp;php_source=". $file_xml .".xml'> 
<PARAM NAME=quality VALUE=high> <PARAM NAME=bgcolor VALUE=#EEEEEE> 
<EMBED src='". $PATH. "charts.swf?library_path=". $PATH. "charts_library&amp;php_source=". $file_xml .".xml' 
quality=high 
bgcolor='#EEEEEE' 
WIDTH=". ($CHART_RECT_width + 100). "
HEIGHT=". ($CHART_RECT_height + 100). "
NAME='$file_xml' 
ALIGN='' 
swLiveConnect='true' 
TYPE='application/x-shockwave-flash' 
PLUGINSPAGE='http://www.macromedia.com/go/getflashplayer'>
</EMBED></OBJECT>
<br>
";

  if (defined($self->{NO_PRINT})) {
  	$self->{OUTPUT}.=$output;
  	return $output;
   }
	elsif ($attr->{OUTPUT2RETURN}) {
		 return $output;
   }

  print $output;

}




1
