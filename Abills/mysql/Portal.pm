package Portal;

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
# Init Portal module
#**********************************************************
sub new {
	my $class = shift;
	($db, $admin, $CONF) = @_;
	my $self = { };
	bless($self, $class);
	
	return $self;
}


#**********************************************************
# Add Portal menu
#**********************************************************
sub portal_menu_add {
	my $self = shift;
	my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

	$self->query($db, "INSERT INTO portal_menu			(	name,  
															url,
															date,
															status
														)	  
													VALUES 
														(	'$DATA{NAME}', 
															'$DATA{URL}',
															NOW(),
															'$DATA{STATUS}'
														);", 'do' );
	
	return 0;	
}

#**********************************************************
# Portal menu list
#**********************************************************
sub portal_menu_list {
	my $self = shift;
	my ($attr) = @_;

	my @WHERE_RULES  = ();	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	if(defined($attr->{ID})) {
		push @WHERE_RULES, "id='$attr->{ID}'";
	}
	if(defined($attr->{NOT_URL})) {
		push @WHERE_RULES, "url=''";
	}
	if(defined($attr->{MENU_SHOW})) {
		push @WHERE_RULES, "status = 1";
	}


	    

	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT 	id,
								name,
								url,
								DATE(date),
								status
								FROM portal_menu
								$WHERE
								ORDER BY $SORT $DESC;");

	return $self->{list};
}

#**********************************************************
# Del portal menu
#**********************************************************
sub portal_menu_del {
	my $self = shift;
	my ($attr) = @_;
  	my @WHERE_RULES  = ();
	$WHERE = '';

	if ($attr->{ID}) {
		push @WHERE_RULES,  " id='$attr->{ID}' ";
	}
	if ($#WHERE_RULES > -1) {
		$WHERE = join(' and ', @WHERE_RULES);
		$self->query($db, "DELETE from portal_menu WHERE $WHERE;", 'do');
	}
	return $self->{result};
}

#**********************************************************
# Portal menu info
#**********************************************************
sub portal_menu_info {
	 my $self = shift;
	 my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

	$self->query($db, "SELECT 	id,
								name,  
								url,
								DATE(date),
								status
								FROM portal_menu 
								WHERE id='$attr->{ID}';");

	(	$self->{ID},
		$self->{NAME},
		$self->{URL},
		$self->{DATE},
		$self->{STATUS},
	)= @{ $self->{list}->[0] };

	return $self;	
}

#**********************************************************
# Change portal menu
#**********************************************************
sub portal_menu_change {
	my $self = shift;
	my ($attr) = @_; 
 
	my %FIELDS = ( 	ID				=> 'id',
					NAME			=> 'name',
					STATUS			=> 'status',
					URL				=> 'url'   
	);

	$self->changes($admin,	{	CHANGE_PARAM => 'ID',
								TABLE        => 'portal_menu',
								FIELDS       => \%FIELDS,
								OLD_INFO     => $self->portal_menu_info({ ID => $attr->{ID} }),
								DATA         => $attr,
							});
return $self;
}


#**********************************************************
# Add Article
#**********************************************************
sub portal_article_add {
	my $self = shift;
	my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

	$self->query($db, "INSERT INTO portal_articles		(	
															title,
															short_description,  
															content,
															status,
															on_main_page,
															date,
															portal_menu_id
								
														)	  
													VALUES 
														(	'$DATA{TITLE}',
															'$DATA{SHORT_DESCRIPTION}', 	 
															'$DATA{CONTENT}',
															'$DATA{STATUS}',
															'$DATA{ON_MAIN_PAGE}',
															'$DATA{DATE}',
															'$DATA{PORTAL_MENU_ID}'
														);", 'do' );
	
	return 0;	
}



#**********************************************************
# Portal articles list
#**********************************************************
sub portal_articles_list {
	my $self = shift;
	my ($attr) = @_;

	my @WHERE_RULES  = ();	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	if(defined($attr->{ID})) {
		push @WHERE_RULES, "pa.id='$attr->{ID}'";
	}
	if(defined($attr->{ARTICLE_ID})) {
		push @WHERE_RULES, "pa.portal_menu_id='$attr->{ARTICLE_ID}' and pa.status = 1";
	} 
	if(defined($attr->{MAIN_PAGE})) {
		push @WHERE_RULES, "pa.on_main_page = 1 and pa.status = 1";
	}  

	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT 	pa.id,
								pa.title,  
								pa.short_description,
								pa.content,
								pa.status,
								pa.on_main_page,
								UNIX_TIMESTAMP(pa.date),
								pa.portal_menu_id,
								pm.name,
								DATE(pa.date)
								FROM portal_articles AS pa
							LEFT JOIN portal_menu pm ON (pm.id=pa.portal_menu_id)	 
								$WHERE
								ORDER BY $SORT $DESC;");

	return $self->{list};
}


#**********************************************************
# Del Portal article 
#**********************************************************
sub portal_article_del {
	my $self = shift;
	my ($attr) = @_;
  	my @WHERE_RULES  = ();
	$WHERE = '';

	if ($attr->{ID}) {
		push @WHERE_RULES,  " id='$attr->{ID}' ";
	}
	if ($#WHERE_RULES > -1) {
		$WHERE = join(' and ', @WHERE_RULES);
		$self->query($db, "DELETE from portal_articles WHERE $WHERE;", 'do');
	}
	return $self->{result};
}


#**********************************************************
# Portal article info
#**********************************************************
sub portal_article_info {
	 my $self = shift;
	 my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

	$self->query($db, "SELECT 	pa.id,
								pa.title,
								pa.short_description,
								pa.content,
								pa.status,
								pa.on_main_page,
								DATE(pa.date),
								pa.portal_menu_id
								FROM portal_articles AS pa 
								WHERE pa.id='$attr->{ID}';");

	(	$self->{ID},
		$self->{TITLE},
		$self->{SHORT_DESCRIPTION},
		$self->{CONTENT},
		$self->{STATUS},
		$self->{ON_MAIN_PAGE},
		$self->{DATE},
		$self->{PORTAL_MENU_ID},
	)= @{ $self->{list}->[0] };

	return $self;	
}

#**********************************************************
# Change portal article
#**********************************************************
sub portal_article_change {
	my $self = shift;
	my ($attr) = @_; 
 	
 	if(!$attr->{ON_MAIN_PAGE}) {
 		$attr->{ON_MAIN_PAGE} = 0;
 	}
 	
	my %FIELDS = ( 	ID								=> 'id',
					TITLE							=> 'title',
					SHORT_DESCRIPTION => 'short_description',
					CONTENT						=> 'content',
					STATUS						=> 'status',
					ON_MAIN_PAGE			=> 'on_main_page',
					DATE							=> 'date',  
					PORTAL_MENU_ID		=> 'portal_menu_id',  

	);

	$self->changes($admin,	{	CHANGE_PARAM => 'ID',
								TABLE        => 'portal_articles',
								FIELDS       => \%FIELDS,
								OLD_INFO     => $self->portal_article_info({ ID => $attr->{ID} }),
								DATA         => $attr,
							});
return $self;
}