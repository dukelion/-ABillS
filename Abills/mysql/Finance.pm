package Finance;
# Finance module
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
use Bills;



#**********************************************************
# Init Finance module
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
# fees
#**********************************************************
sub fees {
  my $class = shift;
  ($db, $admin) = @_;


  use Fees;
  my $fees = Fees->new($db, $admin, $CONF);
  return $fees;
}


#**********************************************************
# Init 
#**********************************************************
sub payments {
  my $class = shift;
  ($db, $admin) = @_;

  use Payments;
  my $payments = Payments->new($db, $admin, $CONF);
  return $payments;
}

#**********************************************************
# exchange_list
#**********************************************************
sub exchange_list {
	my $self = shift;
  my ($attr) = @_;
  
 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

 $self->query($db, "SELECT money, short_name, rate, iso, changed, id 
    FROM exchange_rate
    ORDER BY $SORT $DESC;");

 return $self->{list};
}


#**********************************************************
# exchange_add
#**********************************************************
sub exchange_add {
	my $self = shift;
  my ($attr) = @_;
  
  my $money = (defined($attr->{ER_NAME})) ? $attr->{ER_NAME} :  '';
  my $short_name = (defined($attr->{ER_SHORT_NAME})) ? $attr->{ER_SHORT_NAME} :  '';
  my $rate = (defined($attr->{ER_RATE})) ? $attr->{ER_RATE} :  '0';
  
  $self->query($db, "INSERT INTO exchange_rate (money, short_name, rate, iso, changed) 
   values ('$money', '$short_name', '$rate', '$attr->{ISO}', now());", 'do');

  $self->exchange_log_add({ RATE_ID => $self->{INSERT_ID}, 
  	                        RATE    => $rate
  	                       });



  $admin->{MODULE}='';
  $admin->system_action_add("$money/$short_name/$rate", { TYPE => 41 });

	return $self;
}




#**********************************************************
# exchange_del
#**********************************************************
sub exchange_del {
	my $self = shift;
  my ($id) = @_;
  $self->query($db, "DELETE FROM exchange_rate WHERE id='$id';", 'do');

  $admin->system_action_add("$id", { TYPE => 42 });
	return $self;
}


#**********************************************************
# exchange_change
#**********************************************************
sub exchange_change {
	my $self = shift;
  my ($id, $attr) = @_;
 
  my $money = (defined($attr->{ER_NAME})) ? $attr->{ER_NAME} :  '';
  my $short_name = (defined($attr->{ER_SHORT_NAME})) ? $attr->{ER_SHORT_NAME} :  '';
  my $rate = (defined($attr->{ER_RATE})) ? $attr->{ER_RATE} :  '0';

 
  $self->query($db, "UPDATE exchange_rate SET
    money='$money', 
    short_name='$short_name', 
    rate='$rate',
    iso='$attr->{ISO}',
    changed=now()
   WHERE id='$id';", 'do');

  $self->exchange_log_add({ RATE_ID => $id, 
  	                        RATE    => $rate
  	                       });

  $admin->system_action_add("$money/$short_name/$rate", { TYPE => 41 });

	return $self;
}


#**********************************************************
# exchange_info
#**********************************************************
sub exchange_info {
	my $self = shift;
  my ($id, $attr) = @_;


  my $WHERE = '';
  if ($attr->{SHORT_NAME}) {
  	$WHERE = "short_name='$attr->{SHORT_NAME}'";
   }
  elsif ($attr->{ISO}) {
  	$WHERE = "iso='$attr->{ISO}'";
   }
  else {
  	$WHERE = "id='$id'";
   }

  $self->query($db, "SELECT money, short_name, rate, iso, changed FROM exchange_rate WHERE $WHERE;");
  
  return $self if ($self->{TOTAL} < 1);
  
  ($self->{ER_NAME}, 
   $self->{ER_SHORT_NAME}, 
   $self->{ER_RATE},
   $self->{ISO},
   $self->{CHANGED})=@{ $self->{list}->[0]};


	return $self;
}







#**********************************************************
# exchange_log_list
#**********************************************************
sub exchange_log_list {
	my $self = shift;
  my ($attr) = @_;
  
 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 my $WHERE = '';
 undef @WHERE_RULES;
 
  if ($attr->{DATE}) { 
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{DATE}, 'DATE', 'rl.date') }; 
 	}

  if ($attr->{ID}) { 
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{ID}, 'INT', 'r.id') }; 
 	}


 $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : '';

 $self->query($db, "SELECT rl.date, r.money, rl.rate, rl.id, r.iso
    FROM exchange_rate_log rl
    LEFT JOIN exchange_rate  r ON (r.id=rl.exchange_rate_id)
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");

 return $self->{list};
}


#**********************************************************
# exchange_add
#**********************************************************
sub exchange_log_add {
	my $self = shift;
  my ($attr) = @_;  
 
  $self->query($db, "INSERT INTO exchange_rate_log (date, exchange_rate_id, rate) 
   values (now(), $attr->{RATE_ID}, '$attr->{RATE}');", 'do');

	return $self;
}

#**********************************************************
# exchange_del
#**********************************************************
sub exchange_log_del {
	my $self = shift;
  my ($id) = @_;
  $self->query($db, "DELETE FROM exchange_rate_log WHERE id='$id';", 'do');

  $admin->system_action_add("$id", { TYPE => 42 });
	return $self;
}


1
