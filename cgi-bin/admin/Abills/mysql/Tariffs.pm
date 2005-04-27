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

use main;
@ISA  = ("main");

my $db;


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
# Time_intervals
# ti_add
#**********************************************************
sub ti_del {
	my $self = shift;
	my ($id) = @_;
	$self->query($db, "DELETE FROM intervals WHERE id='$id';");
	return $self;
}


#**********************************************************
# Time_intervals
# ti_add
#**********************************************************
sub ti_add {
	my $self = shift;
	my ($attr) = @_;
	$self->query($db, "INSERT INTO intervals (vid, day, begin, end, tarif)
     values ('$self->{VID}', '$attr->{TI_DAY}', '$attr->{TI_BEGIN}', '$attr->{TI_END}', '$attr->{TI_TARIF}');");
	return $self;
}

#**********************************************************
# Time_intervals  list
# ti_list
#**********************************************************
sub ti_list {
	my $self = shift;
	my ($attr) = @_;
	
	$self->query($db, "SELECT vid, day, begin, end, tarif, id
    FROM intervals WHERE vid='$self->{VID}'");

	return $self->{list};
}


#**********************************************************
# Add
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  
  my %DATA;

  $DATA{VID} = (defined($attr->{VID})) ? $attr->{VID} : ''; 
  $DATA{NAME} = (defined($attr->{NAME})) ? $attr->{NAME} : '';  
  $DATA{BEGIN} = (defined($attr->{BEGIN})) ? $attr->{BEGIN} : '';
  $DATA{END}  = (defined($attr->{END})) ? $attr->{END} : '';    
  $DATA{TIME_TARIF}  = (defined($attr->{TIME_TARIF})) ? $attr->{TIME_TARID} : '';
  $DATA{DAY_FEE} = (defined($attr->{DAY_FEE})) ? $attr->{DAY_FEE} : '';
  $DATA{MONTH_FEE} = (defined($attr->{MONTH_FEE})) ? $attr->{MONTH_FEE} : '';
  $DATA{LOGINS} = (defined($attr->{SIMULTANEONSLY})) ? $attr->{SIMULTANEONSLY} : '';
  $DATA{AGE} = (defined($attr->{AGE})) ? $attr->{AGE} : '';
  $DATA{DAY_TIME_LIMIT} = (defined($attr->{DAY_TIME_LIMIT})) ? $attr->{DAY_TIME_LIMIT} : '';
  $DATA{WEEK_TIME_LIMIT} = (defined($attr->{WEEK_TIME_LIMIT})) ? $attr->{WEEK_TIME_LIMIT} : '';
  $DATA{MONTH_TIME_LIMIT} = (defined($attr->{MONTH_TIME_LIMIT})) ? $attr->{MONTH_TIME_LIMIT} : '';
  $DATA{DAY_TRAF_LIMIT} = (defined($attr->{DAY_TRAF_LIMIT})) ? $attr->{DAY_TRAF_LIMIT} : '';  
  $DATA{WEEK_TRAF_LIMIT} = (defined($attr->{WEEK_TRAF_LIMIT})) ? $attr->{WEEK_TRAF_LIMIT} : ''; 
  $DATA{MONTH_TRAF_LIMIT} = (defined($attr->{MONTH_TRAF_LIMIT})) ? $attr->{MONTH_TRAF_LIMIT} : '';
  $DATA{ACTIVE_PRICE} = (defined($attr->{ACTIVE_PRICE})) ? $attr->{ACTIVE_PRICE} : '';
  $DATA{CHANGE_PRICE} = (defined($attr->{CHANGE_PRICE})) ? $attr->{CHANGE_PRICE} : ''; 
  $DATA{CREDIT_TRESSHOLD} = (defined($attr->{CREDIT_TRESSHOLD})) ? $attr->{CREDIT_TRESSHOLD} : '';
  $DATA{ALERT} = (defined($attr->{ALERT})) ? $attr->{ALERT} : '';


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

  $self->query($db, "SELECT vrnt, name, dt, ut, hourp, df, abon, logins, age,
      day_time_limit, week_time_limit,  month_time_limit, 
      day_traf_limit, week_traf_limit,  month_traf_limit,
      activate_price, change_price, credit_tresshold, uplimit
    FROM variant
    WHERE vrnt='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $b = $self->{list}->[0];
  
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
  ) = @$b;


  return $self;
}


#**********************************************************
# list
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;
#$_NAME,  $_BEGIN,  $_END, $_HOUR_TARIF, $_BYTE_TARIF, $_DAY_FEE, $_MONTH_FEE, $_SIMULTANEOUSLY, 
  # "SELECT vrnt, name,  FROM variant;"

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

 $self->query($db, "SELECT v.vrnt, v.name, v.dt, v.ut, v.hourp, if(sum(tt.in_price + tt.out_price)> 0, 1, 0), 
    v.df, v.abon, v.logins, v.age
    FROM variant v
    LEFT JOIN trafic_tarifs tt ON (tt.vid=v.vrnt)
    GROUP BY v.vrnt
    ORDER BY $SORT $DESC;");
  return $self->{list};
}



#**********************************************************
# list_allow nass
#**********************************************************
sub nas_list {
  my $self = shift;
  $self->query($db, "SELECT nas_id FROM vid_nas WHERE vid='$self->{VID}';");
	return $self->{list};
}


#**********************************************************
# list_allow nass
#**********************************************************
sub nas_add {
 my $self = shift;
 my ($nas) = @_;
 
 $self->nas_del();
 foreach my $line (@$nas) {
   $self->query($db, "INSERT INTO vid_nas (nas_id, vid)
        VALUES ('$line', '$self->{VID}');");	
  }
  #$admin->action_add($uid, "NAS ". join(',', @$nas) );
  return $self;
}

#**********************************************************
# nas_del
#**********************************************************
sub nas_del {
  my $self = shift;
  $self->query($db, "DELETE FROM vid_nas WHERE vid='$self->{VID}';", 'do');
  #$admin->action_add($uid, "DELETE NAS");
  return $self;
}



1