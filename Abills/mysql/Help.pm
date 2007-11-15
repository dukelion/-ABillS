package Help;
# Help
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
my $MODULE='Help';


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $admin->{MODULE}=$MODULE;
  my $self = { };
  bless($self, $class);
  return $self;
}




#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  $WHERE =  "WHERE function='$attr->{FUNCTION}'";

  
  $self->query($db, "SELECT  function, title, help
     FROM help
     $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{FUNCTION},
   $self->{TITLE}, 
   $self->{HELP}
  )= @$ar;
  
  
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO help (function, title, help)
        VALUES ('$DATA{FUNCTION}', '$DATA{TITLE}', '$DATA{HELP}');", 'do');
  
  return $self if ($self->{errno});
 
#  $admin->action_add($DATA{UID}, "ACTIVE");
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (FUNCTION => 'function',
                TITLE    => 'title',
                HELP     => 'help'
               );



  $self->changes($admin, { CHANGE_PARAM => 'FUNCTION',
                   TABLE        => 'help',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->info({ FUNCTION => $attr->{FUNCTION} }),
                   DATA         => $attr
                  } );

  return $self->{result};
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;
  $self->query($db, "DELETE from help WHERE function='$self->{FUNCTION}';", 'do');
  return $self->{result};
}


1
