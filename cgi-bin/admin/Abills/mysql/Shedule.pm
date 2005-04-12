package Shedule;



use vars qw ($db);
use strict;

my $db;
my $admin;

sub new {
  my $class = shift;
  ($db, $admin) = @_;
  my $self = { };
  bless($self, $class);
  return $self;
}




#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 my $WHERE  = '';
 my @list = (); 

 if ($attr->{UID}) {
    $WHERE .= ($WHERE ne '') ?  " and s.uid='$attr->{UID}' " : "WHERE s.uid='$attr->{UID}' ";
  }
 
 if ($attr->{AID}) {
    $WHERE .= ($WHERE ne '') ?  " and s.aid='$attr->{AID}' " : "WHERE s.aid='$attr->{AID}' ";
  }

 if ($attr->{TYPE}) {
    $WHERE .= ($WHERE ne '') ?  " and s.type='$attr->{TYPE}' " : "WHERE s.type='$attr->{TYPE}' ";
  }


 my $q = $db->prepare("SELECT count(*) FROM shedule s $WHERE");
 
 $q ->execute(); 
 ($self->{TOTAL}) = $q->fetchrow();

 my $sql = "SELECT s.h, s.d, s.m, s.y, s.counts, u.id, s.action, a.id, s.date, a.aid, s.uid, s.id  
    FROM shedule s
    LEFT JOIN users u ON (u.uid=s.uid)
    LEFT JOIN admins a ON (a.aid=s.aid) $WHERE  ";
 $q = $db->prepare($sql); 
 $q ->execute(); 
 
 while(my @row = $q->fetchrow()) {
   push @list, \@row;
  }

  $self->{list} = \@list;
  return $self->{list};
}





#**********************************************************
# Add new shedule
# add($self)
#**********************************************************
sub add {
 my $self = shift;
 my ($attr) = @_;

 my $DESCRIBE=(defined($attr->{DESCRIBE})) ? $attr->{DESCRIBE} : '';
 my $H=(defined($attr->{H})) ? $attr->{H} : '*';
 my $D=(defined($attr->{D})) ? $attr->{D} : '*';
 my $M=(defined($attr->{M})) ? $attr->{M} : '*';
 my $Y=(defined($attr->{Y})) ? $attr->{Y} : '*';
 my $COUNT=(defined($attr->{COUNT})) ? int($attr->{COUNT}): 0;
 my $UID=(defined($attr->{UID})) ? int($attr->{UID}) : 0;
 my $TYPE=(defined($attr->{TYPE})) ? $attr->{TYPE} : '';
 my $ACTION=(defined($attr->{ACTION})) ? $attr->{ACTION} : '';
  
 my $sql = "INSERT INTO shedule (h, d, m, y, uid, type, action, aid, date) 
        VALUES ('$H', '$D', '$M', '$Y', '$UID', '$TYPE', '$ACTION', '$admin->{AID}', now());";
#print $sql;
 my $q = $db->do($sql);

 if ($db->err == 1062) {
     $self->{errno} = 7;
     $self->{errstr} = 'ERROR_DUBLICATE';
     return $self;
   }
 elsif($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
  }

 return $self;	
}





#**********************************************************
# Add new shedule
# add($self)
#**********************************************************
sub del {
 my $self = shift;
 my ($id) = @_;

 my $sql = "DELETE FROM shedule WHERE id='$id';";
 
 my $q = $db->do($sql) || die $db->strerr;
 
 if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
  }

# $admin->action_add($user->{UID}, "DELETE SHEDULE $id");
 return $self;	
}


1