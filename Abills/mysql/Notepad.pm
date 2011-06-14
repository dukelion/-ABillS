package Notepad;


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


#**********************************************************
# Init Notepad module
#**********************************************************
sub new {
	my $class = shift;
	($db, $admin, $CONF) = @_;
	my $self = { };
	bless($self, $class);
	
	return $self;
}


#**********************************************************
# Notepad list notes
#**********************************************************
sub notepad_list_notes {
	my $self = shift;
	my ($attr) = @_;

	my @WHERE_RULES  = ();	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';

	if(defined($attr->{ID})) {
		push @WHERE_RULES, "id='$attr->{ID}'";
	} 
	if(defined($attr->{AID})) {
		push @WHERE_RULES, "n.aid='$attr->{AID}'";
	}
	if(defined($attr->{NOTE_STATUS})) {
		push @WHERE_RULES, "n.status='$attr->{NOTE_STATUS}'";
	}    

	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT 	n.id, 
								n.notified, 
								n.create_date,
								n.status,
								n.subject,
								n.text,
								n.aid,
								adm.name
								FROM notepad AS n
							LEFT JOIN admins adm ON ( adm.aid = n.aid )
								$WHERE
								ORDER BY $SORT $DESC;");

	return $self->{list};
}



#**********************************************************
# Notepad  note info
#**********************************************************
sub notepad_note_info {
	my $self = shift;
	my ($attr) = @_;

	%DATA = $self->get_data($attr);
	my @WHERE_RULES  = ();	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	if(defined($attr->{ID})) {
		push @WHERE_RULES, "n.id='$attr->{ID}'";
	} 
	if(defined($attr->{AID})) {
		push @WHERE_RULES, "n.aid='$attr->{AID}'";
	}   

	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT 	n.id, 
								n.notified, 
								n.create_date,
								n.status,
								n.subject,
								n.text,
								n.aid,
								adm.name
								FROM notepad AS n
							LEFT JOIN admins adm ON ( adm.aid = n.aid )
								$WHERE
								ORDER BY $SORT $DESC;");

	(	$self->{ID},
 		$self->{NOTIFIED},
 		$self->{CREATE_DATE},
 		$self->{STATUS},
 		$self->{SUBJECT},
 		$self->{TEXT},
 		$self->{AID}, 
	)= @{ $self->{list}->[0] };

	
	return $self;	
}







#**********************************************************
# Add note
#**********************************************************
sub notepad_add_note {
	my $self = shift;
	my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

 	$self->query($db, "INSERT INTO notepad (	notified, 
												create_date, 
												status, 
												subject, 
												text,
												aid
													)
												VALUES 
													(
														'$DATA{NOTIFIED}', 
														NOW(), 
														'$DATA{STATUS}', 
														'$DATA{SUBJECT}', 
														'$DATA{TEXT}', 
														'$admin->{AID}'
													);", 'do'
													);
	return 0;	
}

#**********************************************************
# Change note
#**********************************************************


sub notepad_note_change {
	my $self = shift;
	my ($attr) = @_; 
 
	my %FIELDS = (	ID	=> 'id',
					NOTIFIED	  => 'notified', 
					CREATE_DATE	=> 'create_date',
					STATUS		  => 'status', 
					SUBJECT		  => 'subject',
					TEXT		    => 'text',
					AID			    => 'aid'
	);

	$self->changes($admin,	{	CHANGE_PARAM => 'ID',
								TABLE        => 'notepad',
								FIELDS       => \%FIELDS,
								OLD_INFO     => $self->notepad_note_info({ ID => $attr->{ID} }),
								DATA         => $attr,
   							} 
   	);
	return $self;
}

#**********************************************************
# Del Storage incoming articles
#**********************************************************
sub notepad_del_note {
	my $self = shift;
	my ($attr) = @_;

	$WHERE = '';
	my @WHERE_RULES  = ();	
	

	if ($attr->{ID}) {
		push @WHERE_RULES,  "id='$attr->{ID}' ";
	}

	if ($#WHERE_RULES > -1) {
		$WHERE = join(' and ', @WHERE_RULES);
		$self->query($db, "DELETE from notepad WHERE $WHERE;", 'do');
	}
	return $self->{result};
}



#**********************************************************
# notepad_new
#**********************************************************
sub notepad_new {
  my $self = shift;
  my ($attr) = @_;
  my @WHERE_RULES = ();
  push @WHERE_RULES, "n.aid='$attr->{AID}'"; 


 my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE '. join(' and ', @WHERE_RULES)  : '';

 $self->query($db,   "SELECT sum(if(DATE_FORMAT(notified, '%Y-%m-%d') = curdate(), 1, 0)), sum(if(status = 0, 1, 0))
    FROM (notepad n)
   $WHERE;");


if ($self->{TOTAL}){
  ($self->{TODAY}, $self->{ACTIVE}) = @{ $self->{list}->[0] };
  return $self->{TODAY}, $self->{ACTIVE};
}

  return $self;	
}


1