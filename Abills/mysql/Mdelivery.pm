package Mdelivery;
# Users manage functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");


my $uid;
#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  
  my $self = { };
  bless($self, $class);
  
  #$self->{debug}=1;
  return $self;
}



#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
     DATE      => '0000-00-00', 
     SUBJECT   => '',
     AID       => 0, 
     FROM      => '', 
     TEXT      => '',
     UID       => 0,
     GID       => 0,
     PRIORITY  => 3
    );
 
  $self = \%DATA;
  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($id) = @_;

  my $WHERE;

  $self->query($db, "SELECT 
     md.id,  
     md.date, 
     md.subject, 
     md.sender, 
     a.id, 
     md.added, 
     md.text,
     md.priority,
     u.id,
     g.name
     FROM mdelivery_list md
     LEFT JOIN admins a ON (md.aid=a.aid)
     LEFT JOIN groups g ON (md.gid=g.gid)
     LEFT JOIN users u ON (md.uid=u.uid)
     WHERE md.id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID},
   $self->{DATE},
   $self->{SUBJECT},
   $self->{SENDER}, 
   $self->{ADMIN}, 
   $self->{ADDED}, 
   $self->{TEXT},
   $self->{PRIORITY},
   $self->{USER}, 
   $self->{GROUP}
 )= @{ $self->{list}->[0] };
  
  
  return $self;
}


#**********************************************************
# User information
# info()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "UPDATE mdelivery_list SET STATUS=1
     WHERE id='$attr->{ID}';");
  
  return $self;
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query($db, "DELETE from mdelivery_list WHERE id='$id';", 'do');

#  $admin->action_add($self->{UID}, "DELETE $self->{UID}:$self->{LOGIN}");
  return $self->{result};
}


#**********************************************************
# User information
# info()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  my $DATA = defaults();
  %DATA = $self->get_data($attr, { default => $DATA });




  $self->query($db, "INSERT INTO mdelivery_list (date, added, subject, sender, aid, text, uid, gid,
     priority)
     values ('$DATA{DATE}', now(), '$DATA{SUBJECT}', 
     '$DATA{FROM}', 
     '$admin->{AID}', 
     '$DATA{TEXT}', 
     '$DATA{UID}',
     '$DATA{GID}',
     '$DATA{PRIORITY}');", 'do');



  return $self;
}


#**********************************************************
# User information
# info()
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();
  
 if (defined($attr->{STATUS})) {
    push @WHERE_RULES, "md.status='$attr->{STATUS}'";
  }

 if ($attr->{DATE}) {
    my $value = $self->search_expr($attr->{DATE}, 'INT');
    push @WHERE_RULES, "md.date$value";
  }



  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

  $self->query($db, "SELECT 
    md.id,  md.date, md.subject, md.sender, a.id, md.added, length(md.text), md.status
     FROM mdelivery_list md
     LEFT JOIN admins a ON (md.aid=a.aid)
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");


  my $list = $self->{list};
  
  if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*)
     FROM mdelivery_list md
     LEFT JOIN admins a ON (md.aid=a.aid) $WHERE;");

    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }
  return $list;
}


1
