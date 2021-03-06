package Tariffs;
# Tarif plans functions
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

my %FIELDS = ( ID               => 'id', 
               TP_ID            => 'tp_id', 
               NAME             => 'name',  
               DAY_FEE          => 'day_fee',
               ACTIVE_DAY_FEE   => 'active_day_fee',
               MONTH_FEE        => 'month_fee',
               REDUCTION_FEE    => 'reduction_fee',
               POSTPAID_DAY_FEE     => 'postpaid_daily_fee',
               POSTPAID_MONTH_FEE   => 'postpaid_monthly_fee',
               EXT_BILL_ACCOUNT => 'ext_bill_account',
               SIMULTANEOUSLY   => 'logins',
               AGE              => 'age',
               DAY_TIME_LIMIT   => 'day_time_limit',
               WEEK_TIME_LIMIT  => 'week_time_limit',
               MONTH_TIME_LIMIT => 'month_time_limit',
               TOTAL_TIME_LIMIT => 'total_time_limit',
               DAY_TRAF_LIMIT   => 'day_traf_limit',  
               WEEK_TRAF_LIMIT  => 'week_traf_limit',
               MONTH_TRAF_LIMIT => 'month_traf_limit',
               TOTAL_TRAF_LIMIT => 'total_traf_limit',
               ACTIV_PRICE      => 'activate_price',
               CHANGE_PRICE     => 'change_price', 
               CREDIT_TRESSHOLD => 'credit_tresshold',
               ALERT            => 'uplimit',
               OCTETS_DIRECTION => 'octets_direction',
               MAX_SESSION_DURATION => 'max_session_duration',
               FILTER_ID        => 'filter_id',
               PAYMENT_TYPE     => 'payment_type',
               MIN_SESSION_COST => 'min_session_cost',
               RAD_PAIRS        => 'rad_pairs',
               TRAFFIC_TRANSFER_PERIOD => 'traffic_transfer_period',
               NEG_DEPOSIT_FILTER_ID   => 'neg_deposit_filter_id',
               TP_GID           => 'gid',
               MODULE           => 'module',
               CREDIT           => 'credit',
               IPPOOL           => 'ippool',
               PERIOD_ALIGNMENT => 'period_alignment',
               MIN_USE          => 'min_use',
               ABON_DISTRIBUTION=> 'abon_distribution',
               DOMAIN_ID        => 'domain_id',
               PRIORITY         => 'priority',
               SMALL_DEPOSIT_ACTION => 'small_deposit_action',
               COMMENTS        => 'comments',
               BILLS_PRIORITY  => 'bills_priority',
               FINE            => 'fine',
               NEG_DEPOSIT_IPPOOL => 'neg_deposit_ippool',
               NEXT_TARIF_PLAN => 'next_tp_id',
               FEES_METHOD     => 'fees_method'
              );

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $CONF, $admin) = @_;
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
	$self->query($db, "DELETE FROM intervals WHERE id='$id';", 'do');
	$self->query($db, "DELETE FROM trafic_tarifs WHERE interval_id='$id';", 'do');
	
	$admin->system_action_add("TI:$id", { TYPE => 10 });
	return $self;
}

#**********************************************************
# Time_intervals
# ti_add
#**********************************************************
sub ti_add {
	my $self = shift;
	my ($attr) = @_;

	$self->query($db, "INSERT INTO intervals (tp_id, day, begin, end, tarif)
     values ('$self->{TP_ID}', '$attr->{TI_DAY}', '$attr->{TI_BEGIN}', '$attr->{TI_END}', '$attr->{TI_TARIF}');", 'do');
  
  $self->{INTERVAL_ID}=$self->{INSERT_ID};
  
  $admin->system_action_add("TI:$self->{INSERT_ID} TP:$self->{TP_ID}", { TYPE => 1 });  
	return $self;
}

#**********************************************************
# Time_intervals  list
# ti_list
#**********************************************************
sub ti_list {
	my $self = shift;
	my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : "2, 3";
  if ($SORT eq '1') { $SORT = "2, 3"; }  
  my $begin_end = "i.begin, i.end,";   
  my $TP_ID = $self->{TP_ID};  

  if (defined($attr->{TP_ID})) {
    $begin_end =  "TIME_TO_SEC(i.begin), TIME_TO_SEC(i.end), "; 
    $TP_ID = $attr->{TP_ID};
   }

  $self->query($db, "SELECT i.id, i.day, $begin_end
   i.tarif,
   count(tt.id),
   i.id
   FROM intervals i
   LEFT JOIN  trafic_tarifs tt ON (tt.interval_id=i.id)
   WHERE i.tp_id='$TP_ID'
   GROUP BY i.id
   ORDER BY $SORT $DESC");
 
	return $self->{list};
}

#**********************************************************
# Time intervals change
#**********************************************************
sub ti_change {
  my $self = shift;
  my ($ti_id, $attr) = @_;
  
  %DATA = $self->get_data($attr); 

  my %FIELDS = (
    TI_DAY   => 'day', 
    TI_BEGIN => 'begin', 
    TI_END   => 'end', 
    TI_TARIF => 'tarif',
    TI_ID    => 'id'
   );

	$self->changes($admin, 
	               { CHANGE_PARAM => 'TI_ID',
		               TABLE        => 'intervals',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->ti_info($ti_id),
		               DATA         => $attr
		              } );

  if ($ti_id == $DATA{TI_ID}) {
  	$self->ti_info($ti_id);
   }
  else {
  	$self->info($DATA{TI_ID});
   }

	return $self;
}


#**********************************************************
# Time_intervals  info
# ti_info();
#**********************************************************
sub ti_info {
	my $self = shift;
	my ($ti_id, $attr) = @_;

  $self->query($db, "SELECT day, begin, end, tarif, id
    FROM intervals 
    WHERE id='$ti_id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  $self->{TI_ID}=$ti_id;
  ($self->{TI_DAY}, 
   $self->{TI_BEGIN}, 
   $self->{TI_END}, 
   $self->{TI_TARIF}
  ) = @{ $self->{list}->[0] };

  return $self;
}


#**********************************************************
# ti_defaults
#**********************************************************
sub  ti_defaults {
	my $self = shift;
	
	my %TI_DEFAULTS = (
            TI_DAY   => 0,
            TI_BEGIN => '00:00:00',
            TI_END   => '24:00:00',
    	      TI_TARIF => 0
           );
	
  while(my($k, $v) = each %TI_DEFAULTS) {
    $self->{$k}=$v;
   }	
	
	return $self;
}


#**********************************************************
# TP GROUP
# 
#**********************************************************
sub tp_group_del {
	my $self = shift;
	my ($id) = @_;
	$self->query($db, "DELETE FROM tp_groups WHERE id='$id';", 'do');
	
	$admin->system_action_add("TP_GROUP:$id", { TYPE => 10 });  
	return $self;
}


#**********************************************************
# TP GROUP
# 
#**********************************************************
sub tp_group_add {
	my $self = shift;
	my ($attr) = @_;

	$self->query($db, "INSERT INTO tp_groups (id, name, user_chg_tp)
     values ('$attr->{GID}', '$attr->{NAME}', '$attr->{USER_CHG_TP}');", 'do');
  
  $admin->system_action_add("TP_GROUP:$attr->{GID}", { TYPE => 1 });  
	return $self;
}

#**********************************************************
# TP GROUP
# 
#**********************************************************
sub tp_group_list {
	my $self = shift;
	my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : "2, 3";

  $self->query($db, "SELECT tg.id, tg.name, tg.user_chg_tp, count(tp.id)
   FROM tp_groups tg
   LEFT JOIN tarif_plans tp ON (tg.id=tp.gid)
   GROUP BY tg.id
   ORDER BY $SORT $DESC");

	return $self->{list};
}

#**********************************************************
# TP GROUP
#
#**********************************************************
sub tp_group_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{USER_CHG_TP} = (defined($attr->{USER_CHG_TP}) && $attr->{USER_CHG_TP} == 1 ) ? 1 : 0;
  %DATA = $self->get_data($attr);   

  my %FIELDS = (
    ID          => 'id', 
    NAME        => 'name', 
    USER_CHG_TP => 'user_chg_tp',
    GID         => 'id'
   );

	$self->changes($admin, 
	               { CHANGE_PARAM => 'ID',
		               TABLE        => 'tp_groups',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->tp_group_info($DATA{ID}),
		               DATA         => $attr
		              } );

	$self->tp_group_info($DATA{GID});
	return $self;
}


#**********************************************************
# TP GROUP
# tp_group_info();
#**********************************************************
sub tp_group_info {
	my $self = shift;
	my ($tp_group_id, $attr) = @_;

  $self->query($db, "SELECT name, user_chg_tp
    FROM tp_groups 
    WHERE id='$tp_group_id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  $self->{GID}=$tp_group_id;
  ($self->{NAME}, 
   $self->{USER_CHG_TP}
   ) = @{ $self->{list}->[0] };

  return $self;
}


#**********************************************************
# tp_group_defaults
#**********************************************************
sub tp_group_defaults {
	my $self = shift;
	
	my %TG_DEFAULTS = (
            GID          => 0,
            NAME        => '',
    	      USER_CHG_TP => 0
           );

  while(my($k, $v) = each %TG_DEFAULTS) {
    $self->{$k}=$v;
   }	
	
	return $self;
}

#**********************************************************
# Default values
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = ( TP                 => 0, 
            NAME               => '',  
            TIME_TARIF         => '0.00000',
            DAY_FEE            => '0.00',
            MONTH_FEE          => '0.00',
            REDUCTION_FEE      => 0,
            POSTPAID_DAY_FEE   => 0,
            POSTPAID_MONTH_FEE => 0,
            EXT_BILL_ACCOUNT   => 0,
            SIMULTANEOUSLY     => 0,
            AGE                => 0,
            DAY_TIME_LIMIT     => 0,
            WEEK_TIME_LIMIT    => 0,
            MONTH_TIME_LIMIT   => 0,
            TOTAL_TIME_LIMIT   => 0,
            DAY_TRAF_LIMIT     => 0, 
            WEEK_TRAF_LIMIT    => 0, 
            MONTH_TRAF_LIMIT   => 0,
            TOTAL_TRAF_LIMIT   => 0,
            ACTIV_PRICE        => '0.00',
            CHANGE_PRICE       => '0.00',
            CREDIT_TRESSHOLD   => '0.00',
            ALERT              => 0,
            OCTETS_DIRECTION   => 0,
            MAX_SESSION_DURATION => 0,
            FILTER_ID            => '',
            PAYMENT_TYPE         => 0,
            MIN_SESSION_COST     => '0.00000',
            RAD_PAIRS            => '',
            TRAFFIC_TRANSFER_PERIOD => 0,
            NEG_DEPOSUT_FILTER_ID   => '',
            TP_GID           => 0,
            MODULE           => '',
            CREDIT           => 0,
            IPPOOL           => '0',
            PERIOD_ALIGNMENT => '0',
            MIN_USE          => '0.00',
            ABON_DISTRIBUTION=> 0,
            DOMAIN_ID        => 0,
            PRIORITY         => 0,
            SMALL_DEPOSIT_ACTION => 0,
            COMMENTS         => '',
            BILLS_PRIORITY   => 0,
            ACTIVE_DAY_FEE   => 0,
            NEG_DEPOSIT_IPPOOL => 0,
            NEXT_TARIF_PLAN  => 0,
            FEES_METHOD      => 0,
         );   
 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# Add
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA }); 
 
   if (! $DATA{ID}) {
     $self->query($db, "SELECT id FROM tarif_plans WHERE domain_id='$admin->{DOMAIN_ID}' ORDER BY 1 DESC LIMIT 1");
   	 $DATA{ID} = int($self->{list}->[0]->[0])+1;
    }
 

  $self->query($db, "INSERT INTO tarif_plans (id, uplimit, name, 
     month_fee, day_fee, active_day_fee, reduction_fee, 
     postpaid_daily_fee, 
     postpaid_monthly_fee,
     ext_bill_account,
     logins, 
     day_time_limit, week_time_limit,  month_time_limit, total_time_limit, 
     day_traf_limit, week_traf_limit,  month_traf_limit, total_traf_limit, 
     activate_price, change_price, credit_tresshold, age, octets_direction,
     max_session_duration, filter_id, payment_type, min_session_cost, rad_pairs, 
     traffic_transfer_period, neg_deposit_filter_id, gid, module, credit,
     ippool,
     period_alignment,
     min_use,
     abon_distribution,
     small_deposit_action,
     domain_id,
     priority,
     comments,
     bills_priority,
     fine,
     neg_deposit_ippool,
     next_tp_id,
     fees_method
     )
    values ('$DATA{ID}', '$DATA{ALERT}', \"$DATA{NAME}\", 
     '$DATA{MONTH_FEE}', '$DATA{DAY_FEE}', '$DATA{ACTIVE_DAY_FEE}', '$DATA{REDUCTION_FEE}', 
     '$DATA{POSTPAID_DAY_FEE}', 
     '$DATA{POSTPAID_MONTH_FEE}', 
     '$DATA{EXT_BILL_ACCOUNT}',
     '$DATA{SIMULTANEOUSLY}', 
     '$DATA{DAY_TIME_LIMIT}', '$DATA{WEEK_TIME_LIMIT}',  '$DATA{MONTH_TIME_LIMIT}', '$DATA{TOTAL_TIME_LIMIT}', 
     '$DATA{DAY_TRAF_LIMIT}', '$DATA{WEEK_TRAF_LIMIT}',  '$DATA{MONTH_TRAF_LIMIT}', '$DATA{TOTAL_TRAF_LIMIT}', 
     '$DATA{ACTIV_PRICE}', '$DATA{CHANGE_PRICE}', '$DATA{CREDIT_TRESSHOLD}', '$DATA{AGE}', '$DATA{OCTETS_DIRECTION}',
     '$DATA{MAX_SESSION_DURATION}', '$DATA{FILTER_ID}',
     '$DATA{PAYMENT_TYPE}', '$DATA{MIN_SESSION_COST}', '$DATA{RAD_PAIRS}', 
     '$DATA{TRAFFIC_TRANSFER_PERIOD}',
     '$DATA{NEG_DEPOSIT_FILTER_ID}',
     '$DATA{TP_GID}', '$DATA{MODULE}',
     '$DATA{CREDIT}',
     '$DATA{IPPOOL}',
     '$DATA{PERIOD_ALIGNMENT}', 
     '$DATA{MIN_USE}',
     '$DATA{ABON_DISTRIBUTION}',
     '$DATA{SMALL_DEPOSIT_ACTION}',
     '$admin->{DOMAIN_ID}',
     '$DATA{PRIORITY}',
     '$DATA{COMMENTS}',
     '$DATA{BILLS_PRIORITY}',
     '$DATA{FINE}',
     '$DATA{NEG_DEPOSIT_IPPOOL}',
     '$DATA{NEXT_TARIF_PLAN}',
     '$DATA{FEES_METHOD}'
     );", 'do' );
     
  $self->{TP_ID}=$self->{INSERT_ID};
  $admin->system_action_add("TP:$DATA{TP_ID}", { TYPE => 1 });
  return $self;
}



#**********************************************************
# change
#**********************************************************
sub change {
  my $self = shift;
  my ($tp_id, $attr) = @_;

  $attr->{REDUCTION_FEE}=0       if (! $attr->{REDUCTION_FEE});
  $attr->{POSTPAID_DAY_FEE}=0    if (! $attr->{POSTPAID_DAY_FEE});
  $attr->{POSTPAID_MONTH_FEE}=0  if (! $attr->{POSTPAID_MONTH_FEE});
  $attr->{EXT_BILL_ACCOUNT}=0    if (! $attr->{EXT_BILL_ACCOUNT});
  $attr->{PERIOD_ALIGNMENT}=0    if (! $attr->{PERIOD_ALIGNMENT});
  $attr->{ABON_DISTRIBUTION}=0   if (! $attr->{ABON_DISTRIBUTION});
  $attr->{SMALL_DEPOSIT_ACTION}=0 if (! $attr->{SMALL_DEPOSIT_ACTION});
  $attr->{BILLS_PRIORITY}=0      if (! $attr->{BILLS_PRIORITY});
  $attr->{ACTIVE_DAY_FEE}=0      if (! $attr->{ACTIVE_DAY_FEE});

	$self->changes($admin, { CHANGE_PARAM => 'TP_ID',
		                TABLE        => 'tarif_plans',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->info($tp_id, { MODULE => $attr->{MODULE} }),
		                DATA         => $attr,
		                EXTENDED     => ($attr->{MODULE}) ? "and module='$attr->{MODULE}'" : undef,
		                EXT_CHANGE_INFO  => "TP_ID:$tp_id"
		              } );

  $self->info($attr->{TP_ID}, { MODULE => $attr->{MODULE} });

	return $self;
}

#**********************************************************
# del
#**********************************************************
sub del {
  my $self = shift;
  my ($id, $attr) = @_;
  	
  my $WHERE = '';
  if ($attr->{MODULE}) {
  	$WHERE = " and module='$attr->{MODULE}'";
   }
  	
  $self->query($db, "DELETE FROM tarif_plans WHERE tp_id='$id'$WHERE;", 'do');
  $admin->system_action_add("TP:$id", { TYPE => 10 });    

 return $self;
}

#**********************************************************
# Info
#**********************************************************
sub info {
  my $self = shift;
  my ($id, $attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{MODULE}) {
    push @WHERE_RULES, "module='$attr->{MODULE}'"; 
   }

  if (defined($attr->{TP_ID})) {
    push @WHERE_RULES, "tp.tp_id='$attr->{TP_ID}'"; 
   }

  if($attr->{ID}) {
  	push @WHERE_RULES, "id='$attr->{ID}'";
   }
  elsif($attr->{NAME}) {
  	push @WHERE_RULES, "name='$attr->{NAME}'";
   }
  else {
  	push @WHERE_RULES, "tp_id='$id'";
   }

  my $WHERE = ($#WHERE_RULES > -1) ?  join(' and ', @WHERE_RULES)  : '';


  $self->query($db, "SELECT id, name,
      day_fee, active_day_fee, month_fee, reduction_fee, postpaid_daily_fee, postpaid_monthly_fee, 
      ext_bill_account,
      logins, age,
      day_time_limit, week_time_limit,  month_time_limit, total_time_limit, 
      day_traf_limit, week_traf_limit,  month_traf_limit, total_traf_limit, 
      activate_price, change_price, credit_tresshold, uplimit, octets_direction, 
      max_session_duration,
      filter_id,
      payment_type,
      min_session_cost,
      rad_pairs,
      traffic_transfer_period,
      gid,
      neg_deposit_filter_id,
      module,
      credit,
      ippool,
      period_alignment,
      min_use,
      abon_distribution,
      small_deposit_action,
      tp_id,
      domain_id,
      priority,
      comments,
      bills_priority,
      fine,
      neg_deposit_ippool,
      next_tp_id,
      fees_method
    FROM tarif_plans
    WHERE $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  
  ($self->{ID}, 
   $self->{NAME}, 
   $self->{DAY_FEE}, 
   $self->{ACTIVE_DAY_FEE},
   $self->{MONTH_FEE}, 
   $self->{REDUCTION_FEE}, 
   $self->{POSTPAID_DAY_FEE}, 
   $self->{POSTPAID_MONTH_FEE}, 
   $self->{EXT_BILL_ACCOUNT}, 
   $self->{SIMULTANEOUSLY}, 
   $self->{AGE},
   $self->{DAY_TIME_LIMIT}, 
   $self->{WEEK_TIME_LIMIT}, 
   $self->{MONTH_TIME_LIMIT}, 
   $self->{TOTAL_TIME_LIMIT}, 
   $self->{DAY_TRAF_LIMIT}, 
   $self->{WEEK_TRAF_LIMIT}, 
   $self->{MONTH_TRAF_LIMIT}, 
   $self->{TOTAL_TRAF_LIMIT}, 
   $self->{ACTIV_PRICE},    
   $self->{CHANGE_PRICE}, 
   $self->{CREDIT_TRESSHOLD},
   $self->{ALERT},
   $self->{OCTETS_DIRECTION},
   $self->{MAX_SESSION_DURATION},
   $self->{FILTER_ID},
   $self->{PAYMENT_TYPE},
   $self->{MIN_SESSION_COST},
   $self->{RAD_PAIRS},
   $self->{TRAFFIC_TRANSFER_PERIOD},
   $self->{TP_GID},
   $self->{NEG_DEPOSIT_FILTER_ID},
   $self->{MODULE},
   $self->{CREDIT},
   $self->{IPPOOL},
   $self->{PERIOD_ALIGNMENT}, 
   $self->{MIN_USE},
   $self->{ABON_DISTRIBUTION},
   $self->{SMALL_DEPOSIT_ACTION},
   $self->{TP_ID},
   $self->{DOMAIN_ID},
   $self->{PRIORITY},
   $self->{COMMENTS},
   $self->{BILLS_PRIORITY},
   $self->{FINE},
   $self->{NEG_DEPOSIT_IPPOOL},
   $self->{NEXT_TARIF_PLAN},
   $self->{FEES_METHOD},
  ) = @{ $self->{list}->[0] };

  return $self;
}


#**********************************************************
# list
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = (defined($attr->{SORT})) ? $attr->{SORT} : 1;
  $DESC = (defined($attr->{DESC})) ? $attr->{DESC} : '';
 
  my @WHERE_RULES = ();
  $self->{SEARCH_FIELDS} ='';

 if (defined($attr->{TP_GID})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{TP_GID}, 'INT', 'tp.gid') };
  }

 if (defined($attr->{TP_ID})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{TP_ID}, 'INT', 'tp.id') };
  }

 if ($attr->{COMMENTS}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{COMMENTS}, 'STR', 'tp.comments', { EXT_FIELD => 1 }) };
  }

 if (defined($attr->{MODULE})) {
   push @WHERE_RULES, "tp.module='$attr->{MODULE}'"; 
  }

 if (defined($attr->{MIN_USE})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{MIN_USE}, 'INT', 'tp.min_use') };  	
  }

 if ($admin->{DOMAIN_ID}) {
 	 push @WHERE_RULES, @{ $self->search_expr($admin->{DOMAIN_ID}, 'INT', 'tp.domain_id') };  	
  }
 elsif (defined($attr->{DOMAIN_ID})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DOMAIN_ID}, 'INT', 'tp.domain_id') };  	
  }

 if ($attr->{PAYMENT_TYPE}) {
 	 push @WHERE_RULES, @{ $self->search_expr("$attr->{PAYMENT_TYPE}", 'INT', 'tp.payment_type') };  	
  }

 if ($attr->{ACTIVE_DAY_FEE}) {
 	 push @WHERE_RULES, @{ $self->search_expr("$attr->{ACTIVE_DAY_FEE}", 'INT', 'tp.active_day_fee') };  	
  }

 if ($attr->{NEXT_TARIF_PLAN}) {
 	 push @WHERE_RULES, @{ $self->search_expr("$attr->{NEXT_TARIF_PLAN}", 'INT', 'tp.next_tp_id') };  	
  }


 if ($attr->{CHANGE_PRICE}) {
 	  my $sql = '';  	
 	  
 	  if (defined($attr->{PRIORITY})) {
      $sql = "tp.change_price$attr->{CHANGE_PRICE}+tp.credit";
 	    $sql = "($sql or (tp.priority > '$attr->{PRIORITY}'))";
      #Old
      # $sql = "($sql or (tp.change_price=0 AND tp.priority > '$attr->{PRIORITY}'))";
 	   }
    else {
      $sql = join('', @{ $self->search_expr("$attr->{CHANGE_PRICE}", 'INT', 'tp.change_price') });
     }
 	  push @WHERE_RULES, $sql;
  }


 my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT tp.id, 
    tp.name, 
    if(sum(i.tarif) is NULL or sum(i.tarif)=0, 0, 1), 
    if(sum(tt.in_price + tt.out_price)> 0, 1, 0), 
    tp.payment_type,
    tp.day_fee, tp.month_fee, 
    tp.logins, 
    tp.age,
    tp_g.name,
    tp.rad_pairs,
    tp.reduction_fee,
    tp.postpaid_daily_fee,
    tp.postpaid_monthly_fee,
    tp.ext_bill_account,
    tp.credit,
    tp.min_use,
    tp.abon_distribution,
    tp.tp_id,
    $self->{SEARCH_FIELDS}
    tp.small_deposit_action,
    tp.active_day_fee,
    tp.fine,
    tp.next_tp_id,
    tp.fees_method
    FROM (tarif_plans tp)
    LEFT JOIN intervals i ON (i.tp_id=tp.tp_id)
    LEFT JOIN trafic_tarifs tt ON (tt.interval_id=i.id)
    LEFT JOIN tp_groups tp_g ON (tp.gid=tp_g.id)
    $WHERE
    GROUP BY tp.id
    ORDER BY $SORT $DESC;");

 return $self->{list};
}



#**********************************************************
# list_allow nass
#**********************************************************
sub nas_list {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{NAS_ID}) {
    $self->query($db, "SELECT tp_id FROM tp_nas WHERE nas_id='$self->{NAS_ID}';");
   }
  else {
    $self->query($db, "SELECT nas_id FROM tp_nas WHERE tp_id='$self->{TP_ID}';");
   }
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
   $self->query($db, "INSERT INTO tp_nas (nas_id, tp_id)
        VALUES ('$line', '$self->{TP_ID}');", 'do');	
  }

  $admin->system_action_add("TP_NAS:$self->{TP_ID} NAS:". (join(',', @$nas)), { TYPE => 1 });    
  return $self;
}

#**********************************************************
# nas_del
#**********************************************************
sub nas_del {
  my $self = shift;
  $self->query($db, "DELETE FROM tp_nas WHERE tp_id='$self->{TP_ID}';", 'do');
  #$admin->action_add($uid, "DELETE NAS");
  return $self;
}


#**********************************************************
# tt_defaults
#**********************************************************
sub  tt_defaults {
	my $self = shift;
	
	my %TT_DEFAULTS = (
      TT_DESCRIBE   => '',
      TT_PRICE_IN   => '0.00000',
      TT_PRICE_OUT  => '0.00000',
      TT_NET_ID     => 0,
      TT_PREPAID    => 0,
      TT_SPEED_IN   => 0,
      TT_SPEED_OUT  => 0);

  while(my($k, $v) = each %TT_DEFAULTS) {
    $self->{$k}=$v;
   }	
	
	return $self;
}



#**********************************************************
# tt_info
#**********************************************************
sub  tt_list {
	my $self = shift;
	my ($attr) = @_;
	
	if (defined( $attr->{TI_ID} )) {
	  my $show_nets = ($attr->{SHOW_NETS}) ? ', tc.nets' : '';
	  
	  $self->query($db, "SELECT tt.id, in_price, out_price, prepaid, in_speed, 
	    out_speed, descr, tc.name, expression, tt.net_id $show_nets
     FROM trafic_tarifs  tt 
     LEFT JOIN  traffic_classes tc ON (tc.id=tt.net_id)
     WHERE tt.interval_id='$attr->{TI_ID}'
     ORDER BY tt.id DESC;");
   }	
	else {
	  $self->query($db, "SELECT id, in_price, out_price, prepaid, in_speed, out_speed, descr, net_id, expression
     FROM trafic_tarifs 
     WHERE tp_id='$self->{TP_ID}'
     ORDER BY tt.id;");
   }


if (defined($attr->{form})) {
  my $a_ref = $self->{list};

  foreach my $row (@$a_ref) {
      my ($id, $tarif_in, $tarif_out, $prepaid, $speed_in, $speed_out, $describe, $nets) = @$row;
      $self->{'TT_DESCRIBE_'. $id}   = $describe;
      $self->{'TT_PRICE_IN_' . $id}  = $tarif_in;
      $self->{'TT_PRICE_OUT_' . $id} = $tarif_out;
      $self->{'TT_NET_ID_'.  $id}      = $nets;
      $self->{'TT_PREPAID_' .$id}    = $prepaid;
      $self->{'TT_SPEED_IN' .$id}    = $speed_in;
      $self->{'TT_SPEED_OUT' .$id}   = $speed_out;
   }

  return $self;
}
	
	return $self->{list};
}



#**********************************************************
# tt_info
#**********************************************************
sub  tt_info {
	my $self = shift;
	my ($attr) = @_;

  $self->query($db, "SELECT id, interval_id, in_price, out_price, prepaid, in_speed, out_speed, 
	     descr, 
	     net_id,
	     expression
     FROM trafic_tarifs 
     WHERE 
     interval_id='$attr->{TI_ID}'
     and id='$attr->{TT_ID}';");

  return $self if ($self->{TOTAL} == 0);

  ($self->{TT_ID},
   $self->{TI_ID},
   $self->{TT_PRICE_IN},
   $self->{TT_PRICE_OUT},
   $self->{TT_PREPAID},
   $self->{TT_SPEED_IN},
   $self->{TT_SPEED_OUT},
   $self->{TT_DESCRIBE},
   $self->{TT_NET_ID},
   $self->{TT_EXPRASSION}
  ) = @{ $self->{list}->[0] };
	
	return $self;
}


#**********************************************************
# tt_add
#**********************************************************
sub  tt_add {
  my $self = shift;
	my ($attr) = @_; 
  
  %DATA = $self->get_data($attr, {default => $self->tt_defaults() }); 

  if($DATA{TT_ID} > 2 && $attr->{DV_EXPPP_NETFILES}) {
  	 $self->{errno}='1';
  	 $self->{errstr}='Max 3 network group for exppp';
  	 return $self;
   }
  
  $self->query($db, "INSERT INTO trafic_tarifs  
    (interval_id, id, descr,  in_price,  out_price,  net_id,  prepaid,  in_speed, out_speed, expression)
    VALUES 
    ('$DATA{TI_ID}', '$DATA{TT_ID}',   '$DATA{TT_DESCRIBE}', '$DATA{TT_PRICE_IN}',  '$DATA{TT_PRICE_OUT}',
     '$DATA{TT_NET_ID}', '$DATA{TT_PREPAID}', '$DATA{TT_SPEED_IN}', '$DATA{TT_SPEED_OUT}', '$DATA{TT_EXPRASSION}')", 'do');

  if ($attr->{DV_EXPPP_NETFILES} && $attr->{TT_NET_ID}) {
    $self->create_nets({ TI_ID => $DATA{TI_ID} });
   }

  $admin->system_action_add("TT:$self->{INSERT_ID} TI:$DATA{TI_ID}", { TYPE => 1 });    
  
  return $self;
}



#**********************************************************
# tt_change
#**********************************************************
sub  tt_change {
  my $self = shift;
	my ($attr) = @_; 
  
  my %DATA = $self->get_data($attr, { default => $self->tt_defaults() }); 

 
  $self->query($db, "UPDATE trafic_tarifs SET 
    descr='". $DATA{TT_DESCRIBE} ."', 
    in_price='". $DATA{TT_PRICE_IN}  ."',
    out_price='". $DATA{TT_PRICE_OUT} ."',
    net_id='". $DATA{TT_NET_ID} ."',
    prepaid='". $DATA{TT_PREPAID} ."',
    in_speed='". $DATA{TT_SPEED_IN} ."',
    out_speed='". $DATA{TT_SPEED_OUT} ."',
    expression = '". $DATA{TT_EXPRASSION} ."'
    WHERE 
    interval_id='$attr->{TI_ID}' and id='$DATA{TT_ID}';", 'do');

  $admin->system_action_add("TT: TI:$attr->{TI_ID}", { TYPE => 2 });    
  $self->tt_info({ TI_ID => $attr->{TI_ID}, TT_ID => $DATA{TT_ID}  });

  if ($attr->{DV_EXPPP_NETFILES} && $attr->{TT_NET_ID}) {
    $self->create_nets({ TI_ID => $attr->{TI_ID} });
   }

  return $self;
}


#**********************************************************
# Nets
# 
#**********************************************************
sub create_nets {
	my $self = shift;
  my ($attr) = @_;
  my $body = '';

  my $list = $self->tt_list({ TI_ID => $attr->{TI_ID}, SHOW_NETS => 1 });

  $/ = chr(0x0d);
  
  foreach my $line (@$list) {
     my @n = split(/\n|;/, $line->[10]);
     foreach my $ip (@n) {
       chomp($ip);
       $ip =~ s/ //g;
       if ($ip eq '') {
       	 next;
        }
       elsif ($ip !~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}$/) {
       	 $self->{errno} = 1;
       	 $self->{errstr} .= "Wrong Exppp date '$ip';\n";
       	 next;
        }

       $body .= "$ip $line->[0]\n";
     }
   }

  $self->create_tt_file("$attr->{TI_ID}.nets", "$body");
}


#**********************************************************
# Time_intervals
# ti_add
#**********************************************************
sub tt_del {
	my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => $self->tt_defaults() }); 

	$self->query($db, "DELETE FROM trafic_tarifs 
	 WHERE  interval_id='$attr->{TI_ID}'  and id='$attr->{TT_ID}' ;", 'do');

  if ($CONF->{DV_EXPPP_NETFILES} && -f "$CONF->{DV_EXPPP_NETFILES}/$attr->{TI_ID}.nets" && $attr->{NETS} ) {
     $self->create_nets({ TI_ID => $attr->{TI_ID} });
   }


  $admin->system_action_add("TT:$attr->{TT_ID} TI:$DATA{TI_ID}", { TYPE => 10 });    

	return $self;
}


#**********************************************************
# create_tt_file()
#**********************************************************
sub create_tt_file {
 my ($self, $file_name, $body) = @_;
 
 open(FILE, ">$CONF->{DV_EXPPP_NETFILES}/$file_name") || print "Can't create file '$CONF->{DV_EXPPP_NETFILES}/$file_name' $!\n";
   print FILE "$body";
 close(FILE);

 print "Created '$CONF->{DV_EXPPP_NETFILES}/$file_name'
 <pre>$body</pre>";
 
 return $self;
}


#**********************************************************
# holidays_list
#**********************************************************
sub holidays_list {
	my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $year = (defined($attr->{year})) ? $attr->{year} : 'YEAR(CURRENT_DATE)';
  my $format = (defined($attr->{format}) && $attr->{format} eq 'daysofyear') ? "DAYOFYEAR(CONCAT($year, '-', day)) as dayofyear" : 'day';
  $self->query($db, "SELECT $format, descr  FROM holidays ORDER BY $SORT $DESC;");

	return $self->{list};
}


#**********************************************************
# holidays_list
#**********************************************************
sub holidays_add {
	my $self = shift;
	my ($attr)=@_;
	
	$DATA{MONTH} = (defined($attr->{MONTH})) ? $attr->{MONTH} : 1;
	$DATA{DAY} = (defined($attr->{DAY})) ? $attr->{DAY} : 1;
	
	$self->query($db,"INSERT INTO holidays (day)
       VALUES ('$DATA{MONTH}-$DATA{DAY}');", 'do');

  $admin->system_action_add("HOLIDAYS:$self->{INSERT_ID} $DATA{MONTH}-$DATA{DAY}", { TYPE => 1 });    
  return $self;
}


#**********************************************************
# holidays_list
#**********************************************************
sub holidays_del {
	my $self = shift;
  my ($id) = @_;
	$self->query($db, "DELETE from holidays WHERE day='$id';", 'do');
	$admin->system_action_add("HOLIDAYS:$id", { TYPE => 10 });    
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub traffic_class_add {
  my $self = shift;
  my ($attr) = @_;
  
  my %DATA = $self->get_data($attr, { default => defaults() }); 


  $self->query($db,  "INSERT INTO traffic_classes (name, nets, comments)
        VALUES ('$DATA{NAME}', '$DATA{NETS}', '$DATA{COMMENTS}');", 'do');

  return $self if ($self->{errno});

  $admin->system_action_add("TRAFFIC_CLASS: $DATA{NAME}", { TYPE => 1 });
  return $self;
}


#**********************************************************
# change()
#**********************************************************
sub traffic_class_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ID        => 'id',
              NAME        => 'name',
              NETS        => 'nets',
              COMMENTS    => 'comments',
              CHANGED     => 'changed'
             );

  $self->changes($admin, { CHANGE_PARAM => 'ID',
                   TABLE        => 'traffic_classes',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->traffic_class_info($attr->{ID}),
                   DATA         => $attr
                  } );

  $self->traffic_class_info($attr->{ID});
  return $self;
}



#**********************************************************
#
#**********************************************************
sub traffic_class_del {
  my $self = shift;
  my ($attr) = @_;
 
  $self->query($db, "DELETE from traffic_classes WHERE id='$attr->{ID}';", 'do');

  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });
  return $self->{result};
}


#**********************************************************
# list()
#**********************************************************
sub traffic_class_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 @WHERE_RULES = ();
 
 if ($attr->{NETS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{NETS}, 'STR', 'nets') };
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT id, name, nets, comments, changed
     FROM traffic_classes;");

 return $self if($self->{errno});

 my $list = $self->{list};

 return $list;
}



#**********************************************************
# 
# traffic_class_info()
#**********************************************************
sub traffic_class_info {
  my $self = shift;
  my ($id, $attr) = @_;
  
  $WHERE =  "WHERE id='$id'";

  $self->query($db, "SELECT id, name, comments, nets
     FROM traffic_classes
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID},
   $self->{NAME}, 
   $self->{COMMENTS},
   $self->{NETS}, 
  )= @{ $self->{list}->[0] };

  return $self;
}

1
