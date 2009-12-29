package Abills::HTML;
#HTML visualisation functions

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


#require "Abills/templates.pl";


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
 
  %FORM    = form_parse();
  %COOKIES = getCookies();

  $SORT    = $FORM{sort} || 1;
  $DESC    = ($FORM{desc}) ? 'DESC' : '';
  $PG      = $FORM{pg} || 0;
  $OP      = $FORM{op} || '';
  $self->{CHARSET}=(defined($attr->{CHARSET})) ? $attr->{CHARSET} : 'windows-1251';
   
  if ($FORM{PAGE_ROWS}) {
  	$PAGE_ROWS = $FORM{PAGE_ROWS};
   }
  elsif ($attr->{PAGE_ROWS}) {
  	$PAGE_ROWS = int($attr->{PAGE_ROWS});
   }
  else {
 	  $PAGE_ROWS = $CONF->{list_max_recs} || 25;
   }

  if ($attr->{METATAGS}) {
  	$self->{METATAGS} = $attr->{METATAGS};
   }

  if ($attr->{PATH}) {
    $self->{PATH} = $attr->{PATH};
    $IMG_PATH     = $self->{PATH}.'img';
   }

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
 
  #Make  PDF output
  if ($FORM{pdf} || $attr->{pdf}) {
    $FORM{pdf}=1;

    eval { require PDF::API2; };
    if (! $@) {
      PDF::API2->import();
      require Abills::PDF;
      $self = Abills::PDF->new( { IMG_PATH  => $IMG_PATH,
      	                          NO_PRINT  => defined($attr->{'NO_PRINT'}) ? $attr->{'NO_PRINT'} : 1,
      	                          CONF      => $CONF
      	                          
	                            
	                            });
     }
    else {
      print "Can't load 'PDF::API2'. Get it from http://cpan.org $@";
      exit; #return 0;
     }

   }
  elsif (defined($FORM{xml})) {
    require Abills::XML;
    $self = Abills::XML->new( { IMG_PATH  => $IMG_PATH,
	                              NO_PRINT  => defined($attr->{'NO_PRINT'}) ? $attr->{'NO_PRINT'} : 1 ,
	                              CONF      => $CONF 
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
 
 $FORM{__BUFFER}=$buffer;
 @pairs = split(/--$boundary/, $buffer);
 @pairs = splice(@pairs,1,$#pairs-1);

 for my $part (@pairs) {
      $part =~ s/[\r]\n$//g;
      my ($dump, $firstline, $datas) = split(/[\r]\n/, $part, 3);
      next if $firstline =~ /filename=\"\"/;
      $firstline =~ s/^Content-Disposition: form-data; //;
      my (@columns) = split(/;\s+/, $firstline);
      ($name = $columns[0]) =~ s/^name=\"([^\"]+)\"$/$1/g;
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
        	print "Content-Type: text/html\n\n";
        	print "/$name // $FORM{$name}<br>";
        	
          if (@{ $FORM{$name} } > 0) {
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
	        $datas =~ s/"/\\"/g;
          $datas =~ s/'/\\'/g;
          $FORM{"$name"} = $datas;
         }
        next;
       }
      for my $currentColumn (@columns) {
        my ($currentHeader, $currentValue) = $currentColumn =~ /^([^=]+)="([^\"]+)"$/;
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
  

  
  $self->{FORM_INPUT}="<input type=\"$type\" name=\"$name\" value=\"$value\"$state$size$class$ex_params ID=\"$name\"/>";

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

  if($attr->{OUTPUT2RETURN}) {
		return $self->{FORM};
	 }
	elsif (defined($self->{NO_PRINT})) {
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
			
	$self->{SELECT} = "<select name=\"$name\" $ex_params ID=\"$name\">\n";
  
  if (defined($attr->{SEL_OPTIONS})) {
    foreach my $k (keys ( %{ $attr->{SEL_OPTIONS} } ) ) {
      $self->{SELECT} .= "<option value='$k'";
      $self->{SELECT} .=' selected' if (defined($attr->{SELECTED}) && $k eq $attr->{SELECTED});
      $self->{SELECT} .= ">". $attr->{SEL_OPTIONS}->{$k} ."\n";	
     }
   }
  
  
  if (defined($attr->{SEL_ARRAY})){
	  my $H = $attr->{SEL_ARRAY};
	  my $i=0;
	  
  
	  foreach my $v (@$H) {
      my $id = (defined($attr->{ARRAY_NUM_ID})) ? $i : $v;
      $self->{SELECT} .= "<option value='$id'";
      $self->{SELECT} .= " style='COLOR:$attr->{STYLE}->[$i];' " if ($attr->{STYLE});
      $self->{SELECT} .= ' selected' if (defined($attr->{SELECTED}) && ( ($i eq $attr->{SELECTED}) || ($v eq $attr->{SELECTED}) ) );
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
      #Value
      $self->{SELECT} .= "$v->[$key]:" if (! $attr->{NO_ID});

      if ($value =~ /,/) {
      	my @values = split(/,/, $value);
      	foreach my $val_keys (@values) {
      	  $self->{SELECT} .= $v->[int($val_keys)]."; ";	
      	 }
       }
      else {
        $self->{SELECT} .= "$v->[$value]";
       }
     
      $self->{SELECT} .= "\n";


     }
   }
  elsif (defined($attr->{SEL_HASH})) {
    my @H = ();

	  if ($attr->{SORT_KEY}) {
	  	@H = sort keys %{ $attr->{SEL_HASH} };
	  }
	  else {
	    @H = sort {
             $attr->{SEL_HASH}->{$a} cmp $attr->{SEL_HASH}->{$b}
           } keys %{ $attr->{SEL_HASH} }; 
     }
    
    
    foreach my $k (@H) {
      $self->{SELECT} .= "<option value='$k'";
      $self->{SELECT} .= " style='COLOR:$attr->{STYLE}->[$k];' " if ($attr->{STYLE});
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


#**********************************************************
# 
#**********************************************************
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
	  $self->{ERROR} = "Access deny $ri";
	  return '', '';
   }
}


my @s = sort {
  $b <=> $a
} keys %$menu_items;


foreach my $ID (@s) {
 	my $VALUE_HASH = $menu_items->{$ID};
 	foreach my $parent (keys %$VALUE_HASH) {
 		#print "$parent, $ID<br>";
    push( @{$menu{$parent}},  "$ID:$VALUE_HASH->{$parent}" );
   }
}
 
 my @last_array = ();

 my $menu_text = "
 <div class='menu_top'></div>
 <div class='menu_main'>
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
 	     next if((! defined($attr->{ALL_PERMISSIONS})) && (! defined($permissions->{$ID-1})) && $parent == 0);

 	     $name = (defined($tree{$ID})) ? $self->b($name) : "$name";
       if(! defined($menu_args->{$ID}) || (defined($menu_args->{$ID}) && defined($FORM{$menu_args->{$ID}})) ) {
       	   my $ext_args = "$EX_ARGS";
       	   if (defined($menu_args->{$ID})) {
       	     $ext_args = "&$menu_args->{$ID}=$FORM{$menu_args->{$ID}}";
       	     $name = "<b>$name</b>" if ($name !~ /<b>/);
       	    }

       	   my $link = $self->button($name, "index=$ID$ext_args");
    	       if($parent == 0) {
 	        	   $menu_text .= "<tr><td bgcolor=\"$_COLORS[3]\" align=left class=menu_cel_main>$prefix$link</td></tr>\n";
	            }
 	           elsif(defined($tree{$ID})) {
   	           $menu_text .= "<tr><td bgcolor=\"$_COLORS[2]\" align=left class=menu_cel>$prefix>$link</td></tr>\n";
 	            }
 	           else {
 	             $menu_text .= "<tr><td bgcolor=\"$_COLORS[1]\" class=menu_cel>$prefix$link</td></tr>\n";
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
 
 $menu_text .= "</table>\n</div>
 <div class='menu_bot'></div>\n";
 
 return ($menu_navigator, $menu_text);
}

#*******************************************************************
# heder off main page
# header()
#*******************************************************************
sub header {
 my $self = shift;
 my($attr)=@_;
 my $admin_name  = $ENV{REMOTE_USER};
 my $admin_ip    = $ENV{REMOTE_ADDR};
 $self->{header} = "Content-Type: text/html\n\n";


 if ($self->{colors}) {
   @_COLORS = split(/, /, $self->{colors});
  }
 elsif (defined($COOKIES{colors}) && $COOKIES{colors} ne '') {
   @_COLORS = split(/, /, $COOKIES{colors});
  }



 my %info = (
  JAVASCRIPT => 'functions.js',
  PRINTCSS   => 'print.css'
 );

 if($self->{PATH}) {
   $info{JAVASCRIPT} = "$self->{PATH}$info{JAVASCRIPT}";
   $info{PRINTCSS}   = "$self->{PATH}$info{PRINTCSS}";
  }
 
 my $i=0;
 foreach my $color (@_COLORS) {
 	 $info{'_COLOR_'.$i}=$color;
 	 $i++;
  }

 $CONF->{WEB_TITLE}=$self->{WEB_TITLE} if ($self->{WEB_TITLE});


 $info{title}   = ($CONF->{WEB_TITLE}) ? $CONF->{WEB_TITLE} : "~AsmodeuS~ Billing System";
 $info{REFRESH} = ($FORM{REFRESH}) ? "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"$FORM{REFRESH}; URL=$ENV{REQUEST_URI}\"/>\n" : '';
 $info{CHARSET} = $self->{CHARSET};

 $self->{header} .= $self->tpl_show($self->{METATAGS}, \%info, { OUTPUT2RETURN => 1  });
 return $self->{header};

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


 $self->{MAX_ROWS}=$parent->{MAX_ROWS};

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

 if( $attr->{header}) {
   $self->{table} .= "<tr><td bgcolor=\"$_COLORS[1]\"><div id=\"rules\"><ul><li class=\"center\"> $attr->{header} </li></ul></div></td></tr>\n";
  }

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
     $self->{table} .= " <COL align=\"$line\"$class$width />\n";
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

  $self->{show} = "<div class='table_top'></div>\n"
  . "<div class='table_cont'>$self->{show}</div>\n"
  . "<div class='table_bot'></div>\n";


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
  
  if ( $attr->{NEW_WINDOW} ) {
    my $x = 640;
    my $y = 480;

    if ($attr->{NEW_WINDOW_SIZE}) {
    	($x, $y)=split(/:/, $attr->{NEW_WINDOW_SIZE});
     }
   
    $ex_attr .= " onclick=\"window.open('$attr->{NEW_WINDOW}', null,
            'toolbar=0,location=0,directories=0,status=1,menubar=0,'+
            'scrollbars=1,resizable=1,'+
            'width=$x, height=$y');\"";

    $params = '#';
   }
  
  my $message = '';
  
  if ($attr->{MESSAGE}) {
  	$attr->{MESSAGE} =~ s/\'/\\'/g;
  	$attr->{MESSAGE} =~ s/"/\\'/g;
  	$attr->{MESSAGE} =~ s/\n//g;
  	$attr->{MESSAGE} =~ s/\r//g;
  	
  	$message = " onclick=\"return confirmLink(this, '$attr->{MESSAGE}')\"";
   }

  my $button = ($attr->{BUTTON}) ? "<a class='link_button' href=\"$params\"$ex_attr$message>$name</a>" : "<a href=\"$params\"$ex_attr$message>$name</a>";

  return $button;
}

#*******************************************************************
# Show message box
# message($self, $type, $caption, $message)
# $type - info, err
#*******************************************************************
sub message {
 my $self = shift;
 my ($type, $caption, $message, $attr) = @_;
 
 my $head = '';
 $caption .= ': '. $attr->{ID} if ($attr->{ID});
 if ($type eq 'err') {
   $head = "<tr><th bgcolor=\"#FF0000\" class=err_message>$caption</th></TR>\n";
  }
 elsif ($type eq 'info') {
   $head = "<tr><th bgcolor=\"$_COLORS[0]\" class=info_message>$caption</th></TR>\n";
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
 my ($message, $attr) = @_;
 
 
my $output = qq{
<pre>
 $message
</pre>
};

  if ($self->{NO_PRINT} || $attr->{OUTPUT2RETURN}) {
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

 return '' if ($self->{MAX_ROWS});

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
   $self->{pages} .= ($i == $PG) ? "<b>$i</b> " : $self->button($i, "$argument&pg=$i") .' ';
}
 
 
 return "<div id=\"rules\"><ul><li class=\"center\">". 
         $self->{pages}.
        "</li></ul></div>\n";
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
 


 my $month = $FORM{$base_name.'M'} || $mon;
 my $year  = $FORM{$base_name.'Y'} || $curyear + 1900;
 my $day;
 
 if ($FORM{$base_name.'D'}) {
   $day   = $FORM{$base_name.'D'};
  }
 else {
 	 if ($base_name =~ /to/i) {
 	 	 my $m = $month+1;
 	   $day   = ($m!=2?(($m%2)^($m>7))+30:(!($year%400)||!($year%4)&&($year%25)?29:28));
 	  }
   else {
   	 $day   = $mday;
    }
  }

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

  if (! $attr->{SOURCE}) {
  while($tpl =~ /\%(\w+)(\=?)([A-Za-z0-9]{0,50})\%/g) {
    my $var       = $1;
    my $delimiter = $2; 
    my $default   = $3;
#    if ($var =~ /$\{exec:.+\}$/) {
#    	my $exec = $1;
#    	if ($exec !~ /$\/usr/abills\/\misc\/ /);
#    	my $exec_content = system("$1");
#    	$tpl =~ s/\%$var\%/$exec_content/g;
#     }
#    els
    
    if ($attr->{SKIP_VARS} && $attr->{SKIP_VARS} =~ /$var/) {
     }
    elsif (defined($variables_ref->{$var})) {
    	$tpl =~ s/\%$var$delimiter$default%/$variables_ref->{$var}/g;
     }
    else {
      $tpl =~ s/\%$var$delimiter$default\%/$default/g;
     }
  }
}




  if($attr->{OUTPUT2RETURN}) {
		return $tpl;
	 }
  elsif ($attr->{MAIN}) {
		$self->{OUTPUT} .= "$tpl";
  	return $tpl;
   }
  elsif ($attr->{notprint} || $self->{NO_PRINT}) {
		$self->{OUTPUT} .= "<div class='table_top'></div>\n"
     . "<div class='table_cont'>$tpl</div>"
     . "<div class='table_bot'></div>\n";

  	return $tpl;
   }
	else { 
		print "<div class='table_top'></div>\n"
     . "<div class='table_cont'>$tpl</div>\n"
     . "<div class='table_bot'></div>\n";
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
 return 0 if (! $CONF->{WEB_DEBUG});
 
 my $output = '';
  while(my($k, $v)=each %FORM) {
  	$output .= "$k | $v\n" if ($k ne '__BUFFER');
   }
 $output .= "\n";
 while(my($k, $v)=each %COOKIES) {
   $output .= "$k | $v\n";
  }
 print "<a href='#' title='$output' class='noprint'><font color=$_COLORS[1]>Debug</font></a>\n";
}

#**********************************************************
# letters_list();
#**********************************************************
sub letters_list {
 my ($self, $attr) = @_;
 
 my $pages_qs = $attr->{pages_qs} if (defined($attr->{pages_qs}));
 my @alphabet = ('a-z');

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
 	  return "<div id=\"rules\"><ul><li class=\"center\">
 	  $letters
 	  </li></ul></div>\n";
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

  $PATH .= 'charts';
  
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
  my $CHART_RECT_width   = ($attr->{CHART_RECT_width}) ? $attr->{CHART_RECT_width} : 500 ;  
  my $CHART_RECT_height  = ($attr->{CHART_RECT_height}) ? $attr->{CHART_RECT_height} : 280 ;  
  my $CHART_RECT_x = ($attr->{CHART_RECT_x}) ? $attr->{CHART_RECT_x} : 50 ;  
  my $CHART_RECT_y = ($attr->{CHART_RECT_y}) ? $attr->{CHART_RECT_y} : 70 ;  

  my $data = '<chart>'
  .$ex_params

	.'
	<series_color>
	  <color>00EE00</color>
		<color>FF8844</color>
		<color>7e6cee</color>
		<color>BBBBFF</color>
		<color>E8AC71</color>
		<color>99FB5E</color>
	 </series_color>

  <chart_grid_h alpha="10" color="0066FF" thickness="1"  />
	<chart_grid_v alpha="10" color="0066FF" thickness="1" />
  <chart_label shadow="low" color="000000" alpha="95" size="10" position="inside" as_percentage="true" />
  <chart_border color="000000" top_thickness="1" bottom_thickness="2" left_thickness="0" right_thickness="0" />
  <chart_rect x="'. $CHART_RECT_x .'" y="'. $CHART_RECT_y .'" width="'. $CHART_RECT_width .'" height="'. $CHART_RECT_height .'" positive_color="FFFFFF" positive_alpha="40" />
  <chart_pref select="true" />

	<axis_category font="arial" bold="1" size="11" color="000000" alpha="50" skip="'. $AXIS_CATEGORY_skip. '" />
	<axis_ticks value_ticks="" category_ticks="1" major_thickness="2" minor_thickness="1" minor_count="3" major_color="000000" minor_color="888888" position="outside" />

  <axis_value font="arial" size="7" color="000000" alpha="75" steps="4" prefix="" suffix="'. $suffix .'" 
  decimals="0" separator="" show_min="1" orientation="diagonal_up" />


  <legend shadow="low" fill_color="0" fill_alpha="5" line_alpha="0" line_thickness="0" bullet="circle" size="12" color="111111" alpha="75" margin="10" />




	<draw>
		<text layer="background" shadow="low" color="ffffff" alpha="5" size="30" x="0" y="0" width="400" height="150" >|||||||||||||||||||||||||||||||||||||||||||||||</text>
		<text layer="background"  shadow="low" color="ffffff" alpha="5" size="30" x="0" y="140" width="400" height="150" v_align="bottom">|||||||||||||||||||||||||||||||||||||||||||||||</text>
	</draw>

	<filter>
		<shadow id="low" distance="2" angle="45" color="0" alpha="50" blurX="5" blurY="5" />
		<bevel id="data" angle="45" blurX="10" blurY="10" distance="3" highlightAlpha="5" highlightColor="ffffff" shadowColor="000000" shadowAlpha="50" type="full" />
		<bevel id="bg" angle="10" blurX="20" blurY="20" distance="10" highlightAlpha="25" highlightColor="ff8888" shadowColor="8888ff" shadowAlpha="25" type="full" />
		<glow id="glow1" color="ff88ff" alpha="75" blurX="30" blurY="30" inner="false" />
	</filter>


  ';

  $data .= "<chart_data>\n";


  if ($attr->{X_TEXT}) {
    $data .= "<row>\n".   	
    "<null/>\n";
    foreach my $i (@{ $attr->{X_TEXT} }) {
    	 $data .= "<string>$i</string>\n";
     }
    $data .= "</row>\n";
   }
  elsif ($attr->{PERIOD} eq 'month_stats') {
    $data .= "<row>\n".   	
    "<null/>\n";
    for(my $i=1; $i<=31; $i++) {
    	 $data .= "<string>$i</string>\n";
     }
    $data .= "</row>\n";
   }
  elsif ($attr->{PERIOD} eq 'day_stats') {
    $data .= "<row>\n".   	
    "<null/>\n";
    for(my $i=0; $i<=23; $i++) {
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
    	 $data .= "<number bevel='data'>";
    	 $data .= ($midle > 0) ? $line * $midle : ( ($line eq '') ? 0 : $line); 
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
		
		if ( $#{ $type_array_ref } == 0) {
			$data .= $type_array_ref->[0];
		 }
		else {
		 foreach my $line (@$type_array_ref) {
		    if ($line eq 'bar') {
		  	  $data .= "$line";
		  	  last;
		     }
		    else {
		      $data .= " <value>$line</value>";
		     }
      }
     }

   	$data .= "</chart_type>\n";
   }
  
  


    #Make right text
    if (defined($attr->{AVG}{MONEY}) && $attr->{AVG}{MONEY} > 0) {
     	my $part = $attr->{AVG}{MONEY} / 4;
    	$data .= "<draw>\n";
   	  foreach(my $i=0; $i<=4; $i++) {
     	   $data .= "<text size=\"9\" x=\"552\" y=\"". (342-$i*69) ."\" color=\"000000\">". int($i * $part) ."</text>\n";
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
 	

$CHART_RECT_width += 80;
$CHART_RECT_height += 90;
my $output = qq { 
	
<!-- charts start -->
<script language="javascript">AC_FL_RunContent = 0;</script>
<script language="javascript">DetectFlashVer = 0; </script>
<script src="$PATH/AC_RunActiveContent.js" language="javascript"></script>
<script language="JavaScript" type="text/javascript">
<!--
var requiredMajorVersion = 9;
var requiredMinorVersion = 0;
var requiredRevision     = 45;
-->
</script>

<br>
<script language="JavaScript" type="text/javascript">
<!--
if (AC_FL_RunContent == 0 || DetectFlashVer == 0) {
	alert("This page requires AC_RunActiveContent.js.");
} else {
	var hasRightVersion = DetectFlashVer(requiredMajorVersion, requiredMinorVersion, requiredRevision);
	if(hasRightVersion) { 
		AC_FL_RunContent(
			'codebase', 'http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,45,0',
			'width', '$CHART_RECT_width',
			'height', '$CHART_RECT_height',
			'scale', 'noscale',
			'salign', 'TL',
			'bgcolor', '#EEEEEE',
			'wmode', 'opaque',
			'movie', 'charts',
			'src', 'charts',
			'FlashVars', 'library_path=$PATH/charts_library&xml_source=$file_xml.xml', 
			'id', 'my_chart',
			'name', 'my_chart',
			'menu', 'true',
			'allowFullScreen', 'true',
			'allowScriptAccess','sameDomain',
			'quality', 'high',
			'align', 'middle',
			'pluginspage', 'http://www.macromedia.com/go/getflashplayer',
			'play', 'true',
			'devicefont', 'false'
			); 
	} else { 
		var alternateContent = 'This content requires the Adobe Flash Player. '
		+ '<u><a href=http://www.macromedia.com/go/getflash/>Get Flash</a></u>.';
		document.write(alternateContent); 
	}
}
// -->
</script>
<noscript>
	<P>This content requires JavaScript.</P>
</noscript>
<!-- charts end -->
<br>	
	};

	if ($attr->{OUTPUT2RETURN}) {
		 return $output;
   }
  elsif (defined($self->{NO_PRINT})) {
  	$self->{OUTPUT}.=$output;
  	return $output;
   }

  print $output;
}

1
