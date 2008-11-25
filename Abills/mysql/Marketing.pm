package Marketing;
# Marketing  functions
#



use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");




my $uid;

my $MODULE='Marketing';

my %SEARCH_PARAMS = (TP_ID => 0, 
   SIMULTANEONSLY => 0, 
   STATUS        => 0, 
   IP             => '0.0.0.0', 
   NETMASK        => '255.255.255.255', 
   SPEED          => 0, 
   FILTER_ID      => '', 
   CID            => '', 
   REGISTRATION   => ''
);

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $admin->{MODULE}=$MODULE;
  my $self = { };
  
  bless($self, $class);
  
  if ($CONF->{DELETE_USER}) {
    $self->{UID}=$CONF->{DELETE_USER};
    $self->del({ UID => $CONF->{DELETE_USER} });
   }
  
  return $self;
}




#**********************************************************
# report1()
#**********************************************************
sub report1 {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 @WHERE_RULES = ( 'u.disable=0' );
 


 # Start letter 
 if ($attr->{FIRST_LETTER}) {
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }
 elsif ($attr->{LOGIN}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
  }
 # Login expresion
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
  }


 if ($attr->{DEPOSIT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DEPOSIT}, 'INT', 'u.deposit') };
  }



 $WHERE = ($#WHERE_RULES > -1) ? 'and '. join(' and ', @WHERE_RULES)  : '';



 
 $self->query($db, "SELECT 
      if (pi._c_address <> '', pi._c_address, pi.address_street),
      if (pi._c_build <> '', pi._c_build, pi.address_build),
      count(*) 
     FROM (users_pi pi, users u)
     WHERE u.uid=pi.uid $WHERE
     GROUP BY 1,2
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(*) FROM (users u, users_pi pi) 
    WHERE u.uid=pi.uid");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}





1
