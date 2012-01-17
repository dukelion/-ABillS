package Dunes;
# 
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

my $MODULE='Dunes';


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
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
  my ($id, $attr) = @_;

  $WHERE =  "WHERE err_id='$id'";

  $self->query($db, "SELECT err_id, 
     win_err_handle, 
     translate, 
     error_text, 
     solution
     FROM dunes WHERE err_id='$id'
    ;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ERR_ID},
   $self->{WIN_ERR_HANDLE}, 
   $self->{TRANSLATE}, 
   $self->{ERROR_TEXT}, 
   $self->{SOLUTION}
  )= @{ $self->{list}->[0] };
  
  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 undef @WHERE_RULES;
 if ($attr->{ID}) {
   push @WHERE_RULES, "err_id='$attr->{ID}'"; 
 }
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT err_id, win_err_handle, translate, error_text, solution  
     FROM dunes
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});



 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(*) FROM dunes $WHERE");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

  return $list;
}


1