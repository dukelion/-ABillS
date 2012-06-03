package Abills::PDF;
#PDF outputs


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
use PDF::API2;
use FindBin '$Bin';

$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw(
   @_COLORS
   %err_strs
   %FORM
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




my $row_number      = 0;
my $tmp_path        = '/tmp/';
my $pdf_result_path = '../cgi-bin/admin/';




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
  $PG   = $FORM{pg} || 0;
  $OP   = $FORM{op} || '';
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
  else {
    $self->{pdf_output}=1;
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
      ($name = $columns[0]) =~ s/^name=\"([^"]+)\"$/$1/g;
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
# header off main page
# header()
#*******************************************************************
sub header {
 my $self = shift;
 my($attr)=@_;
 my $admin_name=$ENV{REMOTE_USER};
 my $admin_ip=$ENV{REMOTE_ADDR};

 if ($FORM{debug}) {
 	 $self->{header} = "Content-Type: text/plain\n\n";
   $self->{debug}=1;
 	 return $self->{header};
  }

 my $filename = ($attr->{NAME}) ? $attr->{NAME}.'pdf' : int(rand(32768)).'.pdf';
 $self->{header} = "Content-type: application/pdf; filename=$filename\n";
 $self->{header}.= "Cache-Control: no-cache\n";
# $self->{header}.= "Content-disposition: inline; name=\"$filename\"\n\n";
 $self->{header}.= "Content-disposition: inline; name=\"$filename\"\n\n";

 return $self->{header};
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

  $bg = ($bg eq $_COLORS[1]) ? $_COLORS[2] : $_COLORS[1];
  foreach my $val (@row) {
   }

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

	return '';
}

#*******************************************************************
# Extendet add rows
# td()
#*******************************************************************
sub td {
  my $self = shift;
  my ($value, $attr) = @_;

  return '';
}


#*******************************************************************
# title_plain($caption)
# $caption - ref to caption array
#*******************************************************************
sub table_title_plain {
  my $self = shift;
  my ($caption)=@_;
  return '';
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

 return '';
}


#*******************************************************************
# Preformated test
#*******************************************************************
sub pre {
 my $self = shift;
 my ($message) = @_;
  
 my $output = '';
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

 my $output = "";

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

#*******************************************************************
# Make data field
# date_fld($base_name)
#*******************************************************************
sub date_fld2  {
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
}


#**********************************************************
# 
# get_pdf
# 
# template
# variables_ref
# atrr [EX_VARIABLES]
#**********************************************************
sub get_pdf {
  my $self = shift;
  my ($filename) = @_;
  
  $filename        = $filename.'.pdf';
  $self->{FILENAME}= $filename;
  my $pdf          = PDF::API2->open($filename);


  return $pdf;
}


#**********************************************************
#
#**********************************************************
sub multi_tpls {
	my ($tpl, $MULTI_ARR, $attr) = @_;	

  my $multi_pdf          = PDF::API2->new;

  $tmp_path        = $attr->{TMP_PATH}       if ($attr->{TMP_PATH});
  $pdf_result_path = $attr->{PDF_RESULT_PATH}if ($attr->{PDF_RESULT_PATH});

  for(my $i=0; $i <= 10; $i++ ) {
    push @{ $MULTI_ARR }, { FIO     => 'fio'.$i,
                       DEPOSIT => '00.00'.$i,
                       CREDIT  => 0.00+$i,
                       SUM     => 10.00+$i
                     };

   }

  my $num = 0;
  my $rand_num = rand(32768);
  foreach my $line (@$MULTI_ARR) {
    my $single_tpl = tpl_show($tpl, { DOC_NUMBER => $num }, 
                                    { MULTI_DOCS => $MULTI_ARR, 
  	                                       }); 

    my $page_count  = $single_tpl->pages;
  	$single_tpl->saveas($tmp_path .'/single.'.$rand_num.'.pdf');
    
    ##Multidocs section
    print "Document: $num Pages: $page_count ================================\n" if ($debug > 0);
    $num++;
    my $main_tpl = PDF::API2->open($tmp_path.'/single'.$rand_num.'.pdf');

    for(my $i=1; $i<=$page_count; $i++) {
      my $page = $multi_pdf->importpage($main_tpl, $i);
     }
   }
  $multi_pdf->saveas($pdf_result_path.'/'. $tpl.'.pdf');
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
  my ($filename, $variables_ref, $attr) = @_;	

  $debug = 0;
  $filename        =~ s/\.[a-z]{3}$//;
  my $tpl_describe = tpl_describe($filename, { debug => $self->{debug} });
  $filename        = $filename.'.pdf';
  my $pdf          = PDF::API2->open($filename);
  my $tpl;

  my $moddate.= '';
  $attr->{DOCS_IN_FILE} = 0 if (! $attr->{DOCS_IN_FILE});

  $pdf->info(
        'Author'       => "ABillS pdf manager",
        'CreationDate' => "D:20020911000000+01'00'",
        'ModDate'      => "D:$moddate". "+02'00'",
        'Creator'      => ($attr->{ADMIN}) ? $attr->{ADMIN} : "ABillS pdf manager",
        'Producer'     => "ABillS pdf manager",
        'Title'        => "Account",
        'Subject'      => "Account",
        'Keywords'     => ""
       ); 

my $multi_doc_count = 0;
my $page_count      = $pdf->pages;
my $font_name       = 'Verdana';
my $encode          = $self->{CHARSET} || 'windows-1251';
my $font;

if ($encode =~ /utf-8/) {
	$font_name  = '/usr/abills/Abills/templates/fonts/FreeSerif.ttf';
  $font       = $pdf->ttfont($font_name, -encode => "$encode");
 }
else {
  $font = $pdf->corefont($font_name, -encode => "$encode");
 }

MULTIDOC_LABEL:

for my $key (sort keys %$tpl_describe) { 
  my @patterns = ();

  if ( $tpl_describe->{$key}{PARAMS} =~ /\((.+)\)/ ) {
    @patterns = split(/,/,  $1);
   }
  else {
    push @patterns, $tpl_describe->{$key}{PARAMS};
   }

  my $x         = 0; 
  my $y         = 0;
  my $doc_page  = 1;
  my $font_size = 10;
  my $font_color;
  my $align     = '';
  my $text_file = '';

  foreach my $pattern (@patterns) {
    $x          = $1 if ($pattern =~ /x=(\d+)/);
    $y          = $1 if ($pattern =~ /y=(\d+)/);
    next if ($x == 0 && $y == 0);

    my $text = '';
    $doc_page     = ($pattern =~ /page=(\d+)/) ? $1 : 1;
    my $work_page = ($attr->{DOCS_IN_FILE}) ? $doc_page + $page_count * int($multi_doc_count - 1) - ($page_count * $attr->{DOCS_IN_FILE} * int( ($multi_doc_count - 1) / $attr->{DOCS_IN_FILE})) : $doc_page + (($multi_doc_count) ? $page_count * $multi_doc_count - $page_count : 0);
    my $page      = $pdf->openpage($work_page);
    if (! $page) {
    	print "Content-Type: text/plain\n\n";
    	print "Can't open page: $work_page ($pattern) '$!' / $doc_page + $page_count * $multi_doc_count\n";
     }

    #Make img_insertion
    if ($pattern =~ /img=([0-9a-zA-Z_\.]+)/) {
    	my $img_file = $1;
      if (! -f "$CONF->{TPL_DIR}/$img_file") {
      	$text = "Img file not exists '$CONF->{TPL_DIR}/$img_file'\n";
      	next;
       }
      else {  
    	  print "make image '$CONF->{TPL_DIR}/$img_file'\n" if ($debug > 0);
        my $img_height  = ($pattern =~ /img_height=([0-9a-zA-Z_\.]+)/) ? $1 : 100; 
        my $img_width   = ($pattern =~ /img_width=([0-9a-zA-Z_\.]+)/) ? $1 : 100;

    	  my $gfx = $page->gfx;
    	  my $img = $pdf->image_jpeg("$CONF->{TPL_DIR}/$img_file"); #, 200, 200);
        $gfx->image($img, $x, ($y - $img_height + 10), $img_width, $img_height); #, 596, 842);
        $gfx->close;
        $gfx->stroke;
    	  next;
    	 }
     }
    $align      = '';
    $text_file  = $1 if ($pattern =~ /text=([0-9a-zA-Z_\.]+)/);
    $font_size  = $1 if ($pattern =~ /font_size=(\d+)/);
    $font_color = $1 if ($pattern =~ /font_color=(\S+)/);
    $encode     = $1 if ($pattern =~ /encode=(\S+)/);
    $align      = $1 if ($pattern =~ /align=([a-z]+)/i);
    if ($pattern =~ /font_name=(\S+)/) {
    	$font_name  = $1;
      if($font_name =~ /\.ttf$/) {
        $font = $pdf->ttffont($font_name, -encode => "$encode");
       }
      else {
      	$font = $pdf->corefont($font_name, -encode => "$encode");
       } 
     }
    
    my $txt = $page->text;
    $txt->font($font,$font_size);
    if ($font_color) {
      $txt->fillcolor($font_color);
      $txt->fillstroke($font_color);
     }
    
    $txt->translate($x,$y);

    if (defined($variables_ref->{$key})) {
    	
    	$text = $variables_ref->{$key};
    	if($tpl_describe->{$key}->{EXPR}) {
    		my @expr_arr = split(/\//, $tpl_describe->{$key}->{EXPR}, 2);
    		print "Expration: $key >> $text=~s/$expr_arr[0]/$expr_arr[1]/;\n" if ($attr->{debug});
    		$text=~s/$expr_arr[0]/$expr_arr[1]/g;
    	 }
     }
    #else {
    #	$text = ''; #"'$key: $x/$y'";
    # }

    if ($text_file ne '') {
        my $text_height  = ($pattern =~ /text_height=([0-9a-zA-Z_\.]+)/) ? $1 : 100; 
        my $text_width   = ($pattern =~ /text_width=([0-9a-zA-Z_\.]+)/) ? $1 : 100;

        if (! -f "$CONF->{TPL_DIR}/$text_file") {
        	$text = "Text file not exists '$CONF->{TPL_DIR}/$text_file'\n";
         }
        else {
          my $content = '';
          open(FILE, "$CONF->{TPL_DIR}/$text_file") or die "Can't open file '$text_file' $!\n";;
            while(<FILE>) {
          	  $content .= $_;
             }
          close(FILE);

          my $string_height = 15;
          $txt->lead($string_height);
          my ($idt,$y2)=$txt->paragraph($content , $text_width, $text_height,
                      -align     => $align || 'justified',
                      -spillover => 2 ); # ,400,14,@text);
          next;
        }
     }

    if ($pattern =~ /step=(\S+)/) {
    	my $step = $1;
    	my $len  = length($pattern);
    	for(my $i = 0; $i <= $len; $i++) {
        $txt->translate($x + $i*$step,$y);
        my $char = substr($text, $i, 1);
    		$txt->text( $char );
    	 }
     }
    else {
      if ($align) {
        my $text_height  = ($pattern =~ /text_height=([0-9a-zA-Z_\.]+)/) ? $1 : 100; 
        my $text_width   = ($pattern =~ /text_width=([0-9a-zA-Z_\.]+)/) ? $1 : 100;
        my ($idt,$y2)    = $txt->paragraph($text, $text_width, $text_height,
                      -align     => $align,
                      -spillover => 2 );
       }
      else {
        $txt->text($text, -align  => $align || 'justified');
       }

     }
  }
}


if ($attr->{MULTI_DOCS} && $multi_doc_count <= $#{ $attr->{MULTI_DOCS} }) {
  if ($attr->{DOCS_IN_FILE} && $multi_doc_count > 0 && $multi_doc_count % $attr->{DOCS_IN_FILE} == 0) {
  	my $outfile = $attr->{SAVE_AS};
  	my $filenum = int($multi_doc_count / $attr->{DOCS_IN_FILE});

  	$outfile =~ s/\.pdf/$filenum\.pdf/;

  	print "Save to: $outfile\n" if ($self->{debug});

  	$pdf->saveas("$outfile") ;
  	$pdf->end;
    
    $pdf = PDF::API2->open($filename);
    
    if ($encode =~ /utf-8/) {
    	$font_name  = '/usr/abills/Abills/templates/fonts/FreeSerif.ttf';
      $font       = $pdf->ttfont($font_name, -encode => "$encode");
     }
    else {
      $font = $pdf->corefont($font_name, -encode => "$encode");
     }
   }

  $variables_ref = $attr->{MULTI_DOCS}[$multi_doc_count];
  print "Doc: $multi_doc_count\n" if ($attr->{debug});

  if ($multi_doc_count > 0) {
    for(my $i=1; $i<=$page_count; $i++) {
      my $page = $pdf->importpage($pdf, $i);
     }
   }

  $multi_doc_count++;
  goto MULTIDOC_LABEL;
}



if ($attr->{SAVE_AS}) {
  $pdf->saveas("$attr->{SAVE_AS}") ;
  $pdf->end;
  return 0;
}

  $tpl = $pdf->stringify();
  $pdf->end;
 
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
  while(my($k, $v)=each %FORM) {
  	$output .= "$k | $v\n" if ($k ne '__BUFFER');

   }
 $output .= "\n";
 while(my($k, $v)=each %COOKIES) {
    $output .= "$k | $v\n";
   }
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
}

#**********************************************************
# Get template describe. Variables and other
# tpl describe file format
# TPL_VARIABLE:TPL_VARIABLE_DESCRIBE:DESCRIBE_LANG:PARAMS
#**********************************************************
sub tpl_describe {
	my ($tpl_name, $attr) = @_;

	my $filename   = $tpl_name.'.dsc';
	my $content    = '';

  #print $tpl_name.'.dsc';
  my %TPL_DESCRIBE = ();

  if (! -f $filename) {
  	return \%TPL_DESCRIBE;
   }

	open(FILE, "$filename") or die "Can't open file '$filename' $!\n";
	  while(<FILE>) {
	  	$content .= $_;
	   }
	
 	my @rows = split(/[\r]{0,1}\n/, $content);
  
  foreach my $line (@rows) {
  	if ($line =~ /^#/) {
  		next;
  	 }
  	else { #if($line =~ /^(\S+):([\W ]+):(\w+):([\w \(\);=,]{0,500}):?([\w]{0,200}):?(.{0,200})$/) {
    	my ($name, $describe, $lang, $params, $default, $expr)=split(/:/, $line);
    	next if ($attr->{LANG} && $attr->{LANG} ne $lang);
    	$TPL_DESCRIBE{$name}{DESCRIBE}=$describe;
    	$TPL_DESCRIBE{$name}{LANG}    =$lang;
    	$TPL_DESCRIBE{$name}{PARAMS}  =$params;
    	$TPL_DESCRIBE{$name}{DEFAULT} =$default;
    	$TPL_DESCRIBE{$name}{EXPR}    =$expr;
    	print "$name Descr '$describe' Params '$params' Expr '$expr' Def '$default'\n" if ($attr->{debug});
     }
   }

   return \%TPL_DESCRIBE;
}

#**********************************************************
# Break line
#
#**********************************************************
sub br () {
        my $self = shift;
        my ($attr) = @_;

        return '';
}

1
