package Bills;
# Bill accounts manage functions
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


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
#  $self->{debug}=1;
  return $self;
}



#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
   DEPOSIT        => 0.00, 
   COMPANY_ID     => 0
  );

 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# Bill
#**********************************************************
sub create {
	my $self = shift;
	my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => defaults() }); 

  $self->query($db, "INSERT INTO bills (deposit, uid, company_id, registration) 
    VALUES ('$DATA{DEPOSIT}', '$DATA{UID}', '$DATA{COMPANY_ID}', now());", 'do');	

  $self->{BILL_ID} = $self->{INSERT_ID} if (! $self->{errno});

#  $admin->action_add($uid, "ADD BILL [$self->{INSERT_ID}]");
    

	return $self;
}

#**********************************************************
# Bill add sum to bill
# Type:
#  add
#  take
#**********************************************************
sub action {
	my $self = shift;
	my ($type, $BILL_ID, $SUM, $attr) = @_;
  my $value = '';
  
  if ($type eq 'take') {
  	 $value = "-$SUM";
   }
  elsif($type eq 'add') {
     $value = "+$SUM";
   }

  $self->query($db, "UPDATE bills SET deposit=deposit$value WHERE id='$BILL_ID';", 'do');	


#  return $self if($db->err > 0);
#  $admin->action_add($uid, "ADD BILL [$self->{INSERT_ID}]");
	
	return $self;
}


#**********************************************************
# Bill
#**********************************************************
sub change {
	my $self = shift;
	my ($attr) = @_;

	my %FIELDS = (BILL_ID    => 'id',
	              UID        => 'uid', 
	              COMPANY_ID => 'company_id',
	              SUM        => 'sum'); 

 	$self->changes($admin, { CHANGE_PARAM => 'BILL_ID',
		                TABLE        => 'bills',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->bill_info($attr->{BILL_ID}),
		                DATA         => $attr
		              } );


	
	return $self;
}


#**********************************************************
# Bill
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;
	
	if(defined($attr->{COMPANY_ONLY})) {
		$WHERE  = "WHERE b.company_id>0";
		if(defined($attr->{UID})) {
			 $WHERE .= " or b.uid='$attr->{UID}'";
		 }
	}
	
  $self->query($db, "SELECT b.id, b.deposit, u.id,  c.name, b.uid, b.company_id
     FROM bills b
     LEFT JOIN users u ON  (b.uid=u.uid) 
     LEFT JOIN companies c ON  (b.company_id=c.id) 
     $WHERE 
     GROUP BY 1
     ORDER BY $SORT $DESC;");

 #LIMIT $PG, $PAGE_ROWS
	 
	return $self->{list};
}


#**********************************************************
# Bill
#**********************************************************
sub del {
	my $self = shift;
	my ($attr) = @_;

  $self->query($db, "DELETE FROM bills
    WHERE id='$attr->{BILL_ID}';", 'do');	
  return $self if($db->err > 0);
	
	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub info {
	my $self = shift;
	my ($attr) = @_;

  $self->query($db, "SELECT b.id, b.deposit, u.id, b.uid, b.company_id
    FROM bills b
    LEFT JOIN users u ON (u.uid = b.uid)
    WHERE b.id='$attr->{BILL_ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{BILL_ID}, 
   $self->{DEPOSIT}, 
   $self->{LOGIN}, 
   $self->{UID}, 
   $self->{COMPANY_ID}, 
  )= @{ $self->{list}->[0] };
	

	return $self;
}


1
