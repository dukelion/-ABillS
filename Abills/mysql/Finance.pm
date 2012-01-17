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

 $self->query($db, "SELECT money, short_name, rate, changed, id 
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
  
  $self->query($db, "INSERT INTO exchange_rate (money, short_name, rate, changed) 
   values ('$money', '$short_name', '$rate', now());", 'do');

  $admin->action_add(0, "$money/$short_name/$rate");

	return $self;
}


#**********************************************************
# exchange_del
#**********************************************************
sub exchange_del {
	my $self = shift;
  my ($id) = @_;
  $self->query($db, "DELETE FROM exchange_rate WHERE id='$id';", 'do');

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
    changed=now()
   WHERE id='$id';", 'do');

  $admin->action_add(0, "$money/$short_name/$rate");

	return $self;
}


#**********************************************************
# exchange_info
#**********************************************************
sub exchange_info {
	my $self = shift;
  my ($id) = @_;

  $self->query($db, "SELECT money, short_name, rate FROM exchange_rate WHERE id='$id';");
  
  return $self if ($self->{TOTAL} < 1);
  
  ($self->{ER_NAME}, 
   $self->{ER_SHORT_NAME}, 
   $self->{ER_RATE})=@{ $self->{list}->[0]};


	return $self;
}

1
