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
my %DATA;

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
# Default values
#**********************************************************

sub defaults {
  my $self = shift;

  $DATA{VID} = 0; 
  $DATA{NAME} = '';  
  $DATA{BEGIN} = '00:00:00';
  $DATA{END}  = '24:00:00';    
  $DATA{TIME_TARIF}  = 0;
  $DATA{DAY_FEE} = 0;
  $DATA{MONTH_FEE} = 0;
  $DATA{SIMULTANEONSLY} = 0;
  $DATA{AGE} = 0;
  $DATA{DAY_TIME_LIMIT} = 0;
  $DATA{WEEK_TIME_LIMIT} = 0;
  $DATA{MONTH_TIME_LIMIT} = 0;
  $DATA{DAY_TRAF_LIMIT} = 0;  
  $DATA{WEEK_TRAF_LIMIT} = 0; 
  $DATA{MONTH_TRAF_LIMIT} = 0;
  $DATA{ACTIV_PRICE} = 0.00;
  $DATA{CHANGE_PRICE} = 0.00; 
  $DATA{CREDIT_TRESSHOLD} = 0.00;
  $DATA{ALERT} = 0;
 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# Add
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  
  $DATA{VID} = $attr->{VID} if (defined($attr->{VID})); 
  $DATA{NAME} = $attr->{NAME} if (defined($attr->{NAME}));  
  $DATA{BEGIN} = $attr->{BEGIN} if (defined($attr->{BEGIN}));
  $DATA{END}  = $attr->{END} if (defined($attr->{END}));    
  $DATA{TIME_TARIF}  =  $attr->{TIME_TARID} if (defined($attr->{TIME_TARIF}));
  $DATA{DAY_FEE} = $attr->{DAY_FEE} if (defined($attr->{DAY_FEE}));
  $DATA{MONTH_FEE} = $attr->{MONTH_FEE} if (defined($attr->{MONTH_FEE}));
  $DATA{SIMULTANEONSLY} = $attr->{SIMULTANEONSLY} if (defined($attr->{SIMULTANEONSLY}));
  $DATA{AGE} = $attr->{AGE} if (defined($attr->{AGE}));
  $DATA{DAY_TIME_LIMIT} = $attr->{DAY_TIME_LIMIT} if (defined($attr->{DAY_TIME_LIMIT}));
  $DATA{WEEK_TIME_LIMIT} = $attr->{WEEK_TIME_LIMIT} if (defined($attr->{WEEK_TIME_LIMIT}));
  $DATA{MONTH_TIME_LIMIT} = $attr->{MONTH_TIME_LIMIT} if (defined($attr->{MONTH_TIME_LIMIT}));
  $DATA{DAY_TRAF_LIMIT} = $attr->{DAY_TRAF_LIMIT} if (defined($attr->{DAY_TRAF_LIMIT}));  
  $DATA{WEEK_TRAF_LIMIT} = $attr->{WEEK_TRAF_LIMIT} if (defined($attr->{WEEK_TRAF_LIMIT})); 
  $DATA{MONTH_TRAF_LIMIT} = $attr->{MONTH_TRAF_LIMIT} if (defined($attr->{MONTH_TRAF_LIMIT}));
  $DATA{ACTIV_PRICE} = $attr->{ACTIV_PRICE} if (defined($attr->{ACTIV_PRICE}));
  $DATA{CHANGE_PRICE} = $attr->{CHANGE_PRICE} if (defined($attr->{CHANGE_PRICE})); 
  $DATA{CREDIT_TRESSHOLD} = $attr->{CREDIT_TRESSHOLD} if (defined($attr->{CREDIT_TRESSHOLD}));
  $DATA{ALERT} = $attr->{ALERT} if (defined($attr->{ALERT}));

  $self->query($db, "INSERT INTO variant (vrnt, hourp, uplimit, name, ut, dt, abon, df, logins, 
     day_time_limit, week_time_limit,  month_time_limit, 
     day_traf_limit, week_traf_limit,  month_traf_limit,
     activate_price, change_price, credit_tresshold, age)
    values ('$DATA{VID}', '$DATA{TIME_TARIF}', '$DATA{ALERT}', \"$DATA{NAME}\", '$DATA{END}', '$DATA{BEGIN}', 
     '$DATA{MONTH_FEE}', '$DATA{DAY_FEE}', '$DATA{SIMULTANEONSLY}', 
     '$DATA{DAY_TIME_LIMIT}', '$DATA{WEEK_TIME_LIMIT}',  '$DATA{MONTH_TIME_LIMIT}', 
     '$DATA{DAY_TRAF_LIMIT}', '$DATA{WEEK_TRAF_LIMIT}',  '$DATA{MONTH_TRAF_LIMIT}',
     '$DATA{ACTIV_PRICE}', '$DATA{CHANGE_PRICE}', '$DATA{CREDIT_TRESSHOLD}', '$DATA{AGE}');", 'do' );

  return $self;
}

#**********************************************************
# change
#**********************************************************
sub change {
  my $self = shift;
  my ($vid, $attr) = @_;
	
  $DATA{VID} = $attr->{VID} if (defined($attr->{VID})); 
  $DATA{NAME} = $attr->{NAME} if (defined($attr->{NAME}));  
  $DATA{BEGIN} = $attr->{BEGIN} if (defined($attr->{BEGIN}));
  $DATA{END}  = $attr->{END} if (defined($attr->{END}));    
  $DATA{TIME_TARIF}  =  $attr->{TIME_TARID} if (defined($attr->{TIME_TARIF}));
  $DATA{DAY_FEE} = $attr->{DAY_FEE} if (defined($attr->{DAY_FEE}));
  $DATA{MONTH_FEE} = $attr->{MONTH_FEE} if (defined($attr->{MONTH_FEE}));
  $DATA{SIMULTANEONSLY} = $attr->{SIMULTANEONSLY} if (defined($attr->{SIMULTANEONSLY}));
  $DATA{AGE} = $attr->{AGE} if (defined($attr->{AGE}));
  $DATA{DAY_TIME_LIMIT} = $attr->{DAY_TIME_LIMIT} if (defined($attr->{DAY_TIME_LIMIT}));
  $DATA{WEEK_TIME_LIMIT} = $attr->{WEEK_TIME_LIMIT} if (defined($attr->{WEEK_TIME_LIMIT}));
  $DATA{MONTH_TIME_LIMIT} = $attr->{MONTH_TIME_LIMIT} if (defined($attr->{MONTH_TIME_LIMIT}));
  $DATA{DAY_TRAF_LIMIT} = $attr->{DAY_TRAF_LIMIT} if (defined($attr->{DAY_TRAF_LIMIT}));  
  $DATA{WEEK_TRAF_LIMIT} = $attr->{WEEK_TRAF_LIMIT} if (defined($attr->{WEEK_TRAF_LIMIT})); 
  $DATA{MONTH_TRAF_LIMIT} = $attr->{MONTH_TRAF_LIMIT} if (defined($attr->{MONTH_TRAF_LIMIT}));
  $DATA{ACTIV_PRICE} = $attr->{ACTIV_PRICE} if (defined($attr->{ACTIV_PRICE}));
  $DATA{CHANGE_PRICE} = $attr->{CHANGE_PRICE} if (defined($attr->{CHANGE_PRICE})); 
  $DATA{CREDIT_TRESSHOLD} = $attr->{CREDIT_TRESSHOLD} if (defined($attr->{CREDIT_TRESSHOLD}));
  $DATA{ALERT} = $attr->{ALERT} if (defined($attr->{ALERT}));

	
	my %FIELDS = ( VID => 'vrnt', 
                 NAME => 'name',  
                 BEGIN => 'ut',
                 END  => 'dt',  
                 TIME_TARIF  => 'hourp',
                 DAY_FEE => 'df',
                 MONTH_FEE => 'abon',
                 SIMULTANEONSLY => 'logins',
                 AGE => 'age',
                 DAY_TIME_LIMIT => 'day_time_limit',
                 WEEK_TIME_LIMIT => 'week_time_limit',
                 MONTH_TIME_LIMIT => 'month_time_limit',
                 DAY_TRAF_LIMIT => 'day_traf_limit',  
                 WEEK_TRAF_LIMIT => 'week_traf_limit',
                 MONTH_TRAF_LIMIT => 'month_traf_limit',
                 ACTIV_PRICE => 'activate_price',
                 CHANGE_PRICE => 'change_price', 
                 CREDIT_TRESSHOLD => 'credit_tresshold',
                 ALERT => 'uplimit'
             );


  my $CHANGES_QUERY = "";
  my $CHANGES_LOG = "Tarif plan:";
  
  my $OLD = $self->info($vid);

  while(my($k, $v)=each(%DATA)) {
    if ($OLD->{$k} ne $DATA{$k}){
          $CHANGES_LOG .= "$k $OLD->{$k}->$DATA{$k};";
          $CHANGES_QUERY .= "$FIELDS{$k}='$DATA{$k}',";

     }
   }

if ($CHANGES_QUERY eq '') {
  return $self->{result};	
}

# print $CHANGES_LOG;

  chop($CHANGES_QUERY);
  my $sql = "UPDATE users SET $CHANGES_QUERY
    WHERE vrnt='$vid'";

  print "$sql";

#my $q = $db->do($sql);  
#  $admin->action_add(0, "$CHANGES_LOG");

	
	
	return $self;
}

#**********************************************************
# del
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;
  	
  $self->query($db, "DELETE FROM variant WHERE vrnt='$id';", 'do');

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
   $self->{SIMULTANEONSLY}, 
   $self->{AGE},
   $self->{DAY_TIME_LIMIT}, 
   $self->{WEEK_TIME_LIMIT}, 
   $self->{MONTH_TIME_LIMIT}, 
   $self->{DAY_TRAF_LIMIT}, 
   $self->{WEEK_TRAF_LIMIT}, 
   $self->{MONTH_TRAF_LIMIT}, 
   $self->{ACTIV_PRICE},    
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