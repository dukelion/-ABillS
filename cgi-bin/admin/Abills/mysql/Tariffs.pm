package Tariffs;
# Tarif plans functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw(
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();


use Accounts;

my $db;
# Customer id
my $cid; 


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  my $self = { };
  bless($self, $class);
  return $self;
}






#**********************************************************
# Add
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

#  my $sql = "INSERT INTO accounts (name, tax_number, bank_account, bank_name, cor_bank_account, bank_bic) 
#     VALUES ('$name', '$tax_number', '$bank_account', '$bank_name', '$cor_bank_account', '$bank_bic');";

#  print $sql;

  return $self;
}



#**********************************************************
# Info
#**********************************************************
sub info {
  my $self = shift;
  my ($id) = @_;

  my $sql = "SELECT vrnt, name, dt, ut, hourp, df, abon, logins, age,
      day_time_limit, week_time_limit,  month_time_limit, 
      day_traf_limit, week_traf_limit,  month_traf_limit,
      activate_price, change_price, credit_tresshold, uplimit
    FROM variant
    WHERE vrnt='$id';";
  print $sql;

  my $q = $db->prepare($sql);
  $q ->execute(); 


  if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }
  elsif ($q->rows < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{VID}, 
   $self->{NAME}, 
   $self->{BEGIN}, 
   $self->{END}, 
   $self->{TIME_TARIF}, 
   $self->{DAY_FEE}, 
   $self->{MONTH_FEE}, 
   $self->{LOGINS}, 
   $self->{AGE},
   $self->{DAY_TIME_LIMIT}, 
   $self->{WEEK_TIME_LIMIT}, 
   $self->{MONTH_TIME_LIMIT}, 
   $self->{DAY_TRAF_LIMIT}, 
   $self->{WEEK_TRAF_LIMIT}, 
   $self->{MONTH_TRAF_LIMIT}, 
   $self->{ACTIVE_PRICE},    
   $self->{CHANGE_PRICE}, 
   $self->{CREDIT_TRESSHOLD},
   $self->{ALERT}
  )= $q->fetchrow();

  return $self;
}


#**********************************************************
# list
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;
  my @list = ();

#$_NAME,  $_BEGIN,  $_END, $_HOUR_TARIF, $_BYTE_TARIF, $_DAY_FEE, $_MONTH_FEE, $_SIMULTANEOUSLY, 
  # "SELECT vrnt, name,  FROM variant;"

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';


  my $q = $db->prepare("SELECT v.vrnt, v.name, v.dt, v.ut, v.hourp, if(sum(tt.in_price + tt.out_price)> 0, 1, 0), 
     v.df, v.abon, v.logins, v.age
    FROM variant v
    LEFT JOIN trafic_tarifs tt ON (tt.vid=v.vrnt)
    GROUP BY v.vrnt
    ORDER BY $SORT $DESC;");
  $q ->execute();

  $self->{TOTAL} = $q->rows;

  my @list = ();
  while(my @row = $q->fetchrow()) {
    push @list, \@row;
   }


  $self->{list} = \@list;
  return $self->{list};
}



1