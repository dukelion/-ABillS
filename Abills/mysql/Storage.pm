package Storage;

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
# Init Storage module
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
# Storage list articles
#**********************************************************
sub storage_articles_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';
	my $EXT_TABLES = '';
	
	if(defined($attr->{ID})) {
  		push @WHERE_RULES, "id='$attr->{ID}'";
	}
	if(defined($attr->{ARTICLE_TYPE})) {
  		push @WHERE_RULES, "s.article_type='$attr->{ARTICLE_TYPE}'";
	}	  
 
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	s.id, 
								s.name, 
								s.article_type, 
								s.measure,  
								s.add_date, 
								s.comments,
								t.name
								FROM storage_articles AS s
						LEFT JOIN storage_article_types t ON (t.id=s.article_type)
								$EXT_TABLES
								$WHERE
								ORDER BY $SORT $DESC;");
	return $self->{list};
}

#**********************************************************
# Storage articles info
#**********************************************************
sub storage_articles_info {
	my $self = shift;
	my ($attr) = @_;
 
 	%DATA = $self->get_data($attr); 

	$self->query($db, "SELECT 	id, 
								name, 
								article_type, 
								measure,  
								add_date, 
								comments
							FROM storage_articles 
							WHERE id='$attr->{ID}';");

	(	$self->{ID},
 		$self->{NAME},
 		$self->{ARTICLE_TYPE},
 		$self->{MEASURE},
 		$self->{ADD_DATE},
 		$self->{COMMENTS}  
	)= @{ $self->{list}->[0] };

	return $self;	
}

#**********************************************************
# Add Storage articles
#**********************************************************
sub storage_articles_add {
	my $self = shift;
	my ($attr) = @_;
	
	%DATA = $self->get_data($attr); 

$self->query($db, "INSERT INTO storage_articles(
													name, 
													article_type, 
													measure,  
													add_date, 
													comments
												)	  
											VALUES 
												(
													'$DATA{NAME}', 
													'$DATA{ARTICLE_TYPE}', 
													'$DATA{MEASURE}', 
													'$DATA{ADD_DATE}', 
													'$DATA{COMMENTS}'
												);", 'do' 																											
												);
	return 0;	
}

#**********************************************************
# Change storage articles
#**********************************************************
sub storage_articles_change {
	my $self = shift;
	my ($attr) = @_; 
 
	my %FIELDS = ( 	ID				=> 'id',
					NAME			=> 'name',
					ARTICLE_TYPE	=> 'article_type', 
					MEASURE			=> 'measure',
					ADD_DATE		=> 'add_date', 
					COUNT      		=> 'count',
					SUM        		=> 'sum',
					COMMENTS		=> 'comments'   
	);

	$self->changes($admin,	{
								CHANGE_PARAM => 'ID',
								TABLE        => 'storage_articles',
								FIELDS       => \%FIELDS,
								OLD_INFO     => $self->storage_articles_info({ ID => $attr->{ID} }),
								DATA         => $attr,
							}
	);
	return $self;
}

#**********************************************************
# Del storage articles
#**********************************************************
sub storage_articles_del {
	my $self = shift;
	my ($attr) = @_;
  	my @WHERE_RULES  = ();
	$WHERE = '';

	if ($attr->{ID}) {
		push @WHERE_RULES,  " id='$attr->{ID}' ";
	}

	if ($#WHERE_RULES > -1) {
    	$WHERE = join(' and ', @WHERE_RULES);
    	$self->query($db, "DELETE from storage_articles WHERE $WHERE;", 'do');
   	}
  	return $self->{result};
}





#**********************************************************
# Suppliers list
#**********************************************************
sub suppliers_list {
	my $self = shift;
	my ($attr) = @_;
	my @list = ();

	my @WHERE_RULES  = ();
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

	my $ext_fields = '';
	my $EXT_TABLES = '';
	
	if(defined($attr->{ID})) {
		push @WHERE_RULES, "id='$attr->{ID}'";
	}  

	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
	my $list;
	$self->query($db, "SELECT	sup.id, 
								sup.name, 
								sup.date, 
								sup.okpo,  
								sup.inn, 
								sup.inn_svid,
								sup.bank_name, 
								sup.mfo, 
								sup.account,
								sup.phone, 
								sup.phone2, 
								sup.fax, 
								sup.url, 
								sup.email,
								sup.icq,
								sup.accountant,
								sup.director,
								sup.managment
								$ext_fields
								FROM storage_suppliers AS sup
								$EXT_TABLES
								$WHERE
								ORDER BY $SORT $DESC;");
	$list = $self->{list}; 
	if ($self->{TOTAL} > 0) {
  		$self->query($db, "SELECT count(DISTINCT sup.id) FROM storage_suppliers sup
    	$WHERE ");

    	($self->{TOTAL}) = @{ $self->{list}->[0] };
 	}
	return $list;
}

#**********************************************************
# Suppliers info
#**********************************************************
sub suppliers_info {
	my $self = shift;
	my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

	$self->query($db, "SELECT 	id, 
								name, 
								date, 
								okpo,  
								inn, 
								inn_svid,
								bank_name, 
								mfo, 
								account,
								phone, 
								phone2, 
								fax, 
								url, 
								email,
								icq,
								accountant,
								director,
								managment
								FROM storage_suppliers 
								WHERE id='$attr->{ID}';");

	(	$self->{ID},
		$self->{NAME},
		$self->{DATE},
		$self->{OKPO},
		$self->{INN},
		$self->{INN_SVID},
		$self->{BANK_NAME},
		$self->{MFO},
		$self->{ACCOUNT},
		$self->{PHONE},
		$self->{PHONE2},   
		$self->{FAX},
		$self->{URL},
		$self->{EMAIL},
		$self->{ICQ},
		$self->{ACCOUNTANT},
		$self->{DIRECTOR},
		$self->{MANAGMENT},   
 	)= @{ $self->{list}->[0] };

	return $self;	
}

#**********************************************************
# Add suppliers
#**********************************************************
sub suppliers_add {
	my $self = shift;
	my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

 	$self->query($db, "INSERT INTO storage_suppliers (	name, 
														date, 
														okpo, 
														inn, 
														inn_svid, 
														bank_name, 
														mfo, 
														account, 
														phone, 
														phone2, 
														fax, 
														url, 
														email, 
														icq, 
														accountant, 
														director, 
														managment 
													)
												VALUES 
													(
														'$DATA{NAME}', 
														'$DATA{DATE}', 
														'$DATA{OKPO}', 
														'$DATA{INN}', 
														'$DATA{INN_SVID}', 
														'$DATA{BANK_NAME}',
														'$DATA{MFO}', 
														'$DATA{ACCOUNT}', 
														'$DATA{PHONE}',
														'$DATA{PHONE2}', 
														'$DATA{FAX}', 
														'$DATA{URL}',
														'$DATA{EMAIL}', 
														'$DATA{ICQ}', 
														'$DATA{ACCOUNTANT}', 
														'$DATA{DIRECTOR}', 
														'$DATA{MANAGMENT}'
													);", 'do'
													);
	return 0;	
}

#**********************************************************
# Del suppliers
#**********************************************************
sub suppliers_del {
	my $self = shift;
	my ($attr) = @_;
	my @WHERE_RULES  = ();
	$WHERE = '';

	if ($attr->{ID}) {
  		push @WHERE_RULES,  " id='$attr->{ID}' ";
 	}
	if ($#WHERE_RULES > -1) {
		$WHERE = join(' and ', @WHERE_RULES);
		$self->query($db, "DELETE from storage_suppliers WHERE $WHERE;", 'do');
	}
	return $self->{result};
}

#**********************************************************
# Change suppliers
#**********************************************************
sub suppliers_change {
	my $self = shift;
	my ($attr) = @_; 
 
	my %FIELDS = (	ID			=> 'id',
					NAME		=> 'name', 
					DATE		=> 'date',
					OKPO		=> 'okpo', 
					INN			=> 'inn',
					INN_SVID	=> 'inn_svid',
					BANK_NAME	=> 'bank_name',
					MFO			=> 'mfo',
					ACCOUNT		=> 'account',
					PHONE		=> 'phone',
					PHONE2		=> 'phone2',
					FAX			=> 'fax',
					URL			=> 'url',
					EMAIL		=> 'email', 
					ICQ			=> 'icq',
					ACCOUNTANT	=> 'accountant',    
					DIRECTOR	=> 'director',
					MANAGMENT	=> 'managment'
	);

	$self->changes($admin,	{	CHANGE_PARAM => 'ID',
								TABLE        => 'storage_suppliers',
								FIELDS       => \%FIELDS,
								OLD_INFO     => $self->suppliers_info({ ID => $attr->{ID} }),
								DATA         => $attr,
   							} 
   	);
	return $self;
}

#**********************************************************
# Storage storage incoming articles list 
#**********************************************************
sub storage_incoming_articles_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';
	my $EXT_TABLES = '';
	
	if(defined($attr->{ID})) {
		push @WHERE_RULES, "sia.id='$attr->{ID}'";
	}
	if(defined($attr->{ARTICLE_TYPES}) and $attr->{ARTICLE_TYPES} !='' ) {
		push @WHERE_RULES, "sat.id='$attr->{ARTICLE_TYPES}'";
	}  
	if(defined($attr->{ARTICLE_ID}) and $attr->{ARTICLE_ID} !='') {
		push @WHERE_RULES, "sia.article_id='$attr->{ARTICLE_ID}'";
	}
	if(defined($attr->{STORAGE_ID}) and $attr->{STORAGE_ID} !='') {
		push @WHERE_RULES, "si.storage_id='$attr->{STORAGE_ID}'";
	}
	if(defined($attr->{SUPPLIER_ID}) and $attr->{SUPPLIER_ID} !='') {
		push @WHERE_RULES, "si.supplier_id='$attr->{SUPPLIER_ID}'";
	}       



 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	sia.id, 
								sia.article_id,
								sia.count,
								sia.sum - ((sia.sum/sia.count) * (if(ssub.count IS NULL, 0, (SELECT sum(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )) + if(sr.count IS NULL, 0, (SELECT sum(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )))),		
								sia.sn,
								sia.storage_incoming_id,
								si.id,
								si.date,
								si.aid,
								INET_NTOA(si.ip),
								si.comments,
								si.supplier_id,
								si.storage_id,
								sa.id,
								sa.name,
								sa.measure,
								sat.id,
								sat.name,
								ss.name,
								a.name,
								ssub.count,
								sia.count - (if(ssub.count IS NULL, 0, (SELECT sum(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id )) + if(sr.count IS NULL, 0, (SELECT sum(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ))),
								sia.sum / sia.count,
								sia.sum,
								si.storage_id,
								(SELECT sum(count) FROM storage_accountability WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ),
								(SELECT sum(count) FROM storage_reserve WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ),
								(SELECT sum(count) FROM storage_discard WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ),
								(SELECT sum(count) FROM storage_installation WHERE storage_incoming_articles_id = sia.id GROUP BY storage_incoming_articles_id ),
								sia.sell_price, 	
								sia.rent_price								
								FROM storage_incoming_articles AS sia
							LEFT JOIN storage_incoming si ON ( si.id = sia.storage_incoming_id )
							LEFT JOIN storage_articles sa ON ( sa.id = sia.article_id )
							LEFT JOIN storage_article_types sat ON ( sat.id = sa.article_type )
							LEFT JOIN storage_suppliers ss ON ( ss.id = si.supplier_id )
							LEFT JOIN admins a ON ( a.aid = si.aid )
							LEFT JOIN storage_accountability ssub ON ( ssub.storage_incoming_articles_id = sia.id )
							LEFT JOIN storage_reserve sr ON ( sr.storage_incoming_articles_id = sia.id )					
								$EXT_TABLES
								$WHERE
								GROUP BY sia.id
								ORDER BY $SORT DESC;");
	
	return $self->{list};
}



#**********************************************************
# Storage storage incoming articles list 
#**********************************************************
sub storage_incoming_articles_list_lite {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';
	my $EXT_TABLES = '';
	
	if(defined($attr->{ID})) {
		push @WHERE_RULES, "sia.id='$attr->{ID}'";
	}
	
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	sia.id, 
								sia.article_id,
								sia.storage_incoming_id 	
								sia.sell_price 	
								sia.rent_price						
								FROM storage_incoming_articles AS sia					
								$EXT_TABLES
								$WHERE
								GROUP BY sia.id
								ORDER BY $SORT DESC;");
	
	return $self->{list};
}




#**********************************************************
# Storage incoming articles info
#**********************************************************
sub storage_incoming_articles_info {
	my $self = shift;
	my ($attr) = @_;
 	my @WHERE_RULES  = ();
	%DATA = $self->get_data($attr); 
	
	if(defined($attr->{ID})) {
		push @WHERE_RULES, "sia.id='$attr->{ID}'";
	}  
	if(defined($attr->{ARTICLE_ID})) {
		push @WHERE_RULES, "sia.article_id='$attr->{ARTICLE_ID}'";
	}
	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
	$self->query($db, "SELECT 	sia.id, 
								sia.article_id,
								sia.count,
								sia.sum,
								sia.sn,
								sia.storage_incoming_id,
								si.date,
								si.comments,
								si.storage_id,
								ss.id,
								sat.id,
								si.id,
								sia.sell_price,
								sia.rent_price
						FROM storage_incoming_articles sia
					LEFT JOIN storage_incoming si ON ( si.id = sia.storage_incoming_id )
					LEFT JOIN storage_articles sa ON ( sa.id = sia.article_id )
					LEFT JOIN storage_article_types sat ON ( sat.id = sa.article_type )
					LEFT JOIN storage_suppliers ss ON ( ss.id = si.supplier_id )
						$WHERE;");



	(	$self->{ID},
		$self->{ARTICLE_ID},
		$self->{COUNT},
		$self->{SUM},
		$self->{SN},
		$self->{STORAGE_INCOMING_ID},
		$self->{DATE},
		$self->{COMMENTS},
		$self->{STORAGE_ID},
		$self->{SUPPLIER_ID},
		$self->{ARTICLE_TYPE_ID},
		$self->{INCOMING_ID},
		$self->{SELL_PRICE},
		$self->{RENT_PRICE}
	)= @{ $self->{list}->[0] };




	return $self;	
}


#**********************************************************
# Add Storage incoming articles add
#**********************************************************
sub storage_incoming_articles_add {
	my $self = shift;
	my ($attr) = @_;
	if (! $self->{errno}) {
		$self->storage_income_add({ %$attr  })
	}
	 
	%DATA = $self->get_data($attr); 
	
	
	$self->query($db, "INSERT INTO storage_incoming_articles(	
			id, 
			article_id,
			count,
			sum,
			sn,
			storage_incoming_id,
			sell_price,
			rent_price
		)	  
		VALUES 
		(		
			'$DATA{ID}', 
			'$DATA{ARTICLE_ID}', 
			'$DATA{COUNT}', 
			'$DATA{SUM}',
			'$DATA{SN}', 
			'$self->{INSERT_ID}',
			'$DATA{SELL_PRICE}',
			'$DATA{RENT_PRICE}'	
		);", 'do' 																											
	);

	if (! $self->{errno}) {
		$self->storage_log_add({ %$attr, STORAGE_MAIN_ID => $self->{INSERT_ID}  })
	}

	return 0;	
}

#**********************************************************
# DIVIDE Storage incoming articles 
#**********************************************************
sub storage_incoming_articles_divide {
	my $self = shift;
	my ($attr) = @_;
	
	 	%DATA = $self->get_data($attr); 
	
	
	$self->query($db, "INSERT INTO storage_incoming_articles(	 
																article_id,
																count,
																sum,
																sn,
																main_article_id,
																storage_incoming_id
															)	  
														VALUES 
															(		
																 
																'$DATA{ARTICLE_ID}', 
																'1', 
																'$DATA{SUM}',
																'$DATA{SN}',
																'$DATA{MAIN_ARTICLE_ID}', 
																'$DATA{STORAGE_INCOMING_ID}');", 'do' 																											
															);

	my %UPDATE = (	ID    => $DATA{MAIN_ARTICLE_ID},
					COUNT => $DATA{COUNT} - 1,
					SUM   => $DATA{SUM_TOTAL} - ($DATA{SUM_TOTAL}/$DATA{COUNT}),
				);
	my %FIELDS = (	ID			=> 'id',
					COUNT      	=> 'count',
					SUM        	=> 'sum',
	);

   my %info = $self->storage_incoming_articles_info({ ID => $attr->{MAIN_ARTICLE_ID} });

	$self->changes($admin, {	CHANGE_PARAM => 'ID',
								TABLE        => 'storage_incoming_articles',
								FIELDS       => \%FIELDS,
								OLD_INFO     => \%info,
								DATA         => \%UPDATE,
							});

	#if (! $self->{errno}) {
	#	$self->storage_log_add({ %$attr, STORAGE_MAIN_ID => $self->{INSERT_ID}  })
	#}

	return $self;	
}

#**********************************************************
# Storage discard 
#**********************************************************
sub storage_discard {
	
my $self = shift;
my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

 	$self->query($db, "INSERT INTO storage_discard (	storage_incoming_articles_id, 
														count,
														aid, 
														date, 
														comments,
														sum
														 
													)
												VALUES 
													(
														'$DATA{ID}',
														'$DATA{COUNT}', 
														'$admin->{AID}', 
														NOW(), 
														'$DATA{COMMENTS}',
														(($DATA{SUM_TOTAL}/$DATA{COUNT_INCOMING}) * $DATA{COUNT} )
													);", 'do'
													);
	
													
	my %UPDATE = (	ID    => $attr->{ID},
					COUNT => (($DATA{COUNT_INCOMING} - $DATA{COUNT}) == 0) ? 'NULL' : $DATA{COUNT_INCOMING} - $DATA{COUNT},
					SUM   => (($DATA{COUNT_INCOMING} - $DATA{COUNT}) == 0) ? 'NULL' : $DATA{SUM_TOTAL} - (($DATA{SUM_TOTAL}/$DATA{COUNT_INCOMING}) * $DATA{COUNT} ),
					#SUM   => $DATA{SUM_TOTAL} - ($DATA{SUM_INCOMING} * $DATA{COUNT} ),
				);
	my %FIELDS = (	ID			=> 'id',
					COUNT      	=> 'count',
					SUM        	=> 'sum',
	);

   my %info = $self->storage_incoming_articles_info({ ID => $attr->{ID} });

	$self->changes($admin, {	CHANGE_PARAM => 'ID',
								TABLE        => 'storage_incoming_articles',
								FIELDS       => \%FIELDS,
								OLD_INFO     => \%info,
								DATA         => \%UPDATE,
							});
													
													
													
	if (! $self->{errno}) {
		$self->storage_log_add({ %$attr, STORAGE_MAIN_ID => $attr->{MAIN_ARTICLE_ID}, ACTION => 2  })
	}
		
								
	return 0;		
}



#**********************************************************
# Storage income add
#**********************************************************
sub storage_income_add {

	my $self = shift;
	my ($attr) = @_;
 
	$self->query($db, "INSERT INTO storage_incoming(	date, 
														aid,
														ip,
														comments,
														storage_id, 
														supplier_id  
													)	  
												VALUES 
													(	
														'$attr->{DATE}',
														'$admin->{AID}',
														INET_ATON('$admin->{SESSION_IP}'),	
														'$attr->{COMMENTS}',
														'$attr->{STORAGE_ID}',
														'$attr->{SUPPLIER_ID}' 
													);", 'do' 																											
											);
	return 0;	

}

#**********************************************************
# Change storage incoming articles
#**********************************************************
sub storage_incoming_articles_change {
	my $self = shift;
	my ($attr) = @_; 
 
	my %FIELDS = ( 	ID			=> 'id',
					ARTICLE_ID 	=> 'article_id', 
					COUNT      	=> 'count',
					SUM        	=> 'sum',
					SN        	=> 'sn',
					RENT_PRICE 	=> 'rent_price',
					SELL_PRICE	=> 'sell_price'
									  
	);
	
	my %FIELDS_INCOMING = (		INCOMING_ID => 'id',
								DATE 		=> 'date', 
								SUPPLIER_ID	=> 'supplier_id',
								DATE		=> 'date', 
								COMMENTS	=> 'comments',
								SUPPLIER_ID	=> 'supplier_id',
								STORAGE_ID	=> 'storage_id', 
	);

   my %info = $self->storage_incoming_articles_info({ ID => $attr->{ID} });

	$self->changes($admin, {	CHANGE_PARAM => 'ID',
								TABLE        => 'storage_incoming_articles',
								FIELDS       => \%FIELDS,
								OLD_INFO     => \%info,
								DATA         => $attr,
							});
	
	$self->changes($admin, {	CHANGE_PARAM => 'INCOMING_ID',
								TABLE        => 'storage_incoming',
								FIELDS       => \%FIELDS_INCOMING,
								OLD_INFO     => \%info,
								DATA         => $attr,
							});
				

	return $self;
}

#**********************************************************
# Del Storage incoming articles
#**********************************************************
sub storage_incoming_articles_del {
	my $self = shift;
	my ($attr) = @_;

	$WHERE = '';

	if ($attr->{ID}) {
		push @WHERE_RULES,  " id='$attr->{ID}' ";
	}

	if ($#WHERE_RULES > -1) {
		$WHERE = join(' and ', @WHERE_RULES);
		$self->query($db, "DELETE from storage_incoming_articles WHERE $WHERE;", 'do');
	}
	return $self->{result};
}


#*********************************************************************************************************************



#**********************************************************
# Storage list types
#**********************************************************
sub storage_types_list {
	my $self = shift;
	my ($attr) = @_;

	my @WHERE_RULES  = ();	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';

	if(defined($attr->{ID})) {
		push @WHERE_RULES, "id='$attr->{ID}'";
	}  

	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT 	dt.id, 
								dt.name, 
								dt.comments
								$ext_fields
								FROM storage_article_types AS dt
								$WHERE
								ORDER BY $SORT $DESC;");

	return $self->{list};
}

#**********************************************************
# Storage articles types info
#**********************************************************
sub storage_articles_types_info {
	 my $self = shift;
	 my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

	$self->query($db, "SELECT 	id,
								name, 
								comments
								FROM storage_article_types 
								WHERE id='$attr->{ID}';");

	(	$self->{ID},
		$self->{NAME},
		$self->{COMMENTS}  
	)= @{ $self->{list}->[0] };

	return $self;	
}

#**********************************************************
# Add Storage types
#**********************************************************
sub storage_types_add {
	my $self = shift;
	my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

	$self->query($db, "INSERT INTO storage_article_types(	name,  
															comments
														)	  
													VALUES 
														(	'$DATA{NAME}', 
															'$DATA{COMMENTS}'
														);", 'do' 
														);
	return 0;	
}

#**********************************************************
# Change Storage articles types
#**********************************************************
sub storage_types_change {
	my $self = shift;
	my ($attr) = @_; 
 
	my %FIELDS = ( 	ID				=> 'id',
					NAME			=> 'name',
					COMMENTS		=> 'comments'   
	);

	$self->changes($admin,	{	CHANGE_PARAM => 'ID',
								TABLE        => 'storage_article_types',
								FIELDS       => \%FIELDS,
								OLD_INFO     => $self->storage_articles_types_info({ ID => $attr->{ID} }),
								DATA         => $attr,
							});
return $self;
}



#**********************************************************
# Del Storage articles types
#**********************************************************
sub storage_types_del {
	my $self = shift;
	my ($attr) = @_;
  	my @WHERE_RULES  = ();
	$WHERE = '';

	if ($attr->{ID}) {
		push @WHERE_RULES,  " id='$attr->{ID}' ";
	}
	if ($#WHERE_RULES > -1) {
		$WHERE = join(' and ', @WHERE_RULES);
		$self->query($db, "DELETE from storage_article_types WHERE $WHERE;", 'do');
	}
	return $self->{result};
}


#**********************************************************
# list Storage log
#**********************************************************
sub storage_log_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';
	my $EXT_TABLES = '';
	
	if(defined($attr->{ID})) {
		push @WHERE_RULES, "id='$attr->{ID}'";
	}  

 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	sl.id, 
								sl.date,
								sl.aid, 
								sl.storage_main_id, 
								sl.storage_id,  
								sl.comments, 
								sl.action,
								INET_NTOA(sl.ip),
								adm.name,
								sm.article_id,
								sa.name,
								sl.count,
								sa.measure
								FROM storage_log AS sl
							LEFT JOIN admins adm ON ( adm.aid = sl.aid )
							LEFT JOIN storage_incoming_articles sm ON ( sm.id = sl.storage_main_id )
							LEFT JOIN storage_articles sa ON ( sa.id = sm.article_id )  
								$EXT_TABLES
								$WHERE
								ORDER BY $SORT DESC;");
	return $self->{list};
}




#**********************************************************
# add Storage log
#**********************************************************
sub storage_log_add {
	my $self = shift;
	my ($attr) = @_;
 
	#%DATA = $self->get_data($attr); 

	$self->query($db, "INSERT INTO storage_log(	date, 
												aid,
												storage_main_id,
												storage_id, 
												comments,  
												action,
												ip,
												count 

											)	  
										VALUES 
											(		
												NOW(), 
												'$admin->{AID}',
												'$attr->{STORAGE_MAIN_ID}', 
												'$attr->{STORAGE_ID}',
												'', 
												'$attr->{ACTION}', 
												INET_ATON('$admin->{SESSION_IP}'),
												'$attr->{COUNT}'
												);", 'do' 																											
											);
	return 0;	
}

#**********************************************************
# Storage admins list
#**********************************************************
sub storage_admins_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';
	my $EXT_TABLES = '';
	
	if(defined($attr->{ID})) {
  		push @WHERE_RULES, "id='$attr->{ID}'";
	} 
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	a.aid, 
								a.name 
								FROM admins AS a
								$WHERE
								ORDER BY $SORT $DESC;");
	return $self->{list};
}

#**********************************************************
# Storage districts list
#**********************************************************
sub storage_districts_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	if(defined($attr->{ID})) {
  		push @WHERE_RULES, "id='$attr->{ID}'";
	} 
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	d.id, 
								d.name 
								FROM districts AS d
								$WHERE
								ORDER BY $SORT $DESC;");
	return $self->{list};
}


#**********************************************************
# Storage streets list
#**********************************************************
sub storage_streets_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';
	my $EXT_TABLES = '';
	
	if(defined($attr->{ID})) {
  		push @WHERE_RULES, "id='$attr->{ID}'";
	} 
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	s.id, 
								s.name 
								FROM streets AS s
								$WHERE
								ORDER BY $SORT $DESC;");
	return $self->{list};
}


#**********************************************************
# Storage installation NAS list
#**********************************************************
sub storage_installation_nas_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';
	my $EXT_TABLES = '';
	
	if(defined($attr->{ID})) {
  		push @WHERE_RULES, "id='$attr->{ID}'";
	} 
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	n.id, 
								n.name 
								FROM nas AS n
								$WHERE
								ORDER BY $SORT $DESC;");
	return $self->{list};
}

#**********************************************************
# Storage accountability add
#**********************************************************
sub storage_accountability_add {
	my $self = shift;
	my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

	$self->query($db, "INSERT INTO storage_accountability(	aid, 
															storage_incoming_articles_id,
															count,
															date, 
															comments
	
														)	  
													VALUES 
														(		
															'$DATA{AID}',
															'$DATA{ID}',
															'$DATA{COUNT}', 
															NOW(),
															'$DATA{COMMENTS}' 
														);", 'do' 																											
														);
	if (! $self->{errno}) {
		$self->storage_log_add({ %$attr, STORAGE_MAIN_ID => $DATA{ID}, ACTION => 3  })
	}														
	return 0;	
}
#**********************************************************
# Storage accountability list 
#**********************************************************
sub storage_accountability_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';
	my $EXT_TABLES = '';
	
	if(defined($attr->{AID}) and $attr->{AID} != 0) {
  		push @WHERE_RULES, "sa.aid='$attr->{AID}'";
	}
	if(defined($attr->{ID}) and $attr->{ID} != 0) {
  		push @WHERE_RULES, "sa.id='$attr->{ID}'";
	}  
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	sa.id, 
								sa.aid, 
								sa.storage_incoming_articles_id, 
								sa.count,  
								sa.date, 
								sa.comments,
								adm.name,
								sta.name,
								sat.name,
								sa.count * (sia.sum / sia.count),
								sta.measure
								FROM storage_accountability AS sa
							LEFT JOIN admins adm ON ( adm.aid = sa.aid )
							LEFT JOIN storage_incoming_articles sia ON ( sia.id = sa.storage_incoming_articles_id )
							LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
							LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
								$WHERE
								ORDER BY $SORT DESC;");
	return $self->{list};
}


#**********************************************************
# Del Storage accountability
#**********************************************************
sub storage_accountability_del {
	my $self = shift;
	my ($attr) = @_;
  
  	my @WHERE_RULES  = ();
	$WHERE = '';

	if ($attr->{ID}) {
		push @WHERE_RULES,  "id='$attr->{ID}' ";
	}
	if ($#WHERE_RULES > -1) {
		$WHERE = join(' and ', @WHERE_RULES);
		$self->query($db, "DELETE from storage_accountability WHERE $WHERE;", 'do');
	}
	
	return $self->{result};
}


#**********************************************************
# Storage discard list 
#**********************************************************
sub storage_discard_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';
	my $EXT_TABLES = '';
	
	if(defined($attr->{AID})) {
  		push @WHERE_RULES, "sa.aid='$attr->{AID}'";
	}  
 
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	d.id, 
								d.storage_incoming_articles_id, 
								d.count, 
								d.aid,   
								d.date, 
								d.comments,
								adm.name,
								sta.name,
								sat.name,
								d.count * (sia.sum / sia.count),
								sta.measure,
								d.sum	
								FROM storage_discard AS d
							LEFT JOIN admins adm ON ( adm.aid = d.aid )
							LEFT JOIN storage_incoming_articles sia ON ( sia.id = d.storage_incoming_articles_id )
							LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
							LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
								$WHERE
								ORDER BY $SORT DESC;");
	return $self->{list};
}

#**********************************************************
# Storage installation list 
#**********************************************************
sub storage_installation_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';
	my $EXT_TABLES = '';
	
	if(defined($attr->{ID}) and $attr->{ID} != 0) {
  		push @WHERE_RULES, "i.id='$attr->{ID}'";
	}
	
	if(defined($attr->{AID}) and $attr->{AID} != 0) {
  		push @WHERE_RULES, "i.aid='$attr->{AID}'";
	}
	if(defined($attr->{UID}) and $attr->{UID} != 0) {
  		push @WHERE_RULES, "i.uid='$attr->{UID}'";
	}
	
	if(defined($attr->{STATUS}) and $attr->{STATUS} != 0) {
  		push @WHERE_RULES, "i.type='$attr->{STATUS}'";
	}
	
	
	if(defined($attr->{DISTRICTS}) and $attr->{DISTRICTS}  != 0) {
  		push @WHERE_RULES, "d.id='$attr->{DISTRICTS}'";
	}
	if(defined($attr->{STREETS})and $attr->{STREETS} != 0) {
  		push @WHERE_RULES, "str.id='$attr->{STREETS}'";
	}
	     
 
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	i.id, 
								i.storage_incoming_articles_id, 
								i.location_id, 
								i.aid,   
								i.uid, 
								i.nas_id,
								i.count,
								i.comments,
								adm.name,
								sta.name,
								sat.name,
								i.count * (sia.sum / sia.count),
								sta.measure,
								nas.name,
								b.number,
								str.name,
								d.name,
								d.id,
								str.id,
								i.sum,
								u.id,
								i.mac,
								i.grounds,
								i.date,
								sia.sn,
								i.type,
								sn.serial,
								inet_ntoa(dh.ip)
								FROM storage_installation AS i
							LEFT JOIN admins adm ON ( adm.aid = i.aid )
							LEFT JOIN storage_incoming_articles sia ON ( sia.id = i.storage_incoming_articles_id )
							LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
							LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
							LEFT JOIN nas nas ON ( nas.id = i.nas_id )
							LEFT JOIN builds b ON ( b.id = i.location_id )
							LEFT JOIN streets str ON ( str.id = b.street_id )
							LEFT JOIN districts d ON ( d.id = str.district_id )
							LEFT JOIN users u ON ( u.uid = i.uid )
							LEFT JOIN storage_sn sn ON ( i.id = sn.storage_installation_id )
							LEFT JOIN dhcphosts_hosts dh ON ( dh.mac = i.mac )
								$WHERE
								ORDER BY $SORT DESC;");
	return $self->{list};
}








#**********************************************************
# Storage installation add
#**********************************************************

sub storage_installation_add {
	my $self = shift;
	my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

	$self->query($db, "INSERT INTO storage_installation(	aid, 
															storage_incoming_articles_id,
															location_id,
															count, 
															comments,
															nas_id,
															sum
	
														)	  
													VALUES 
														(		
															'$admin->{AID}',
															'$DATA{MAIN_ARTICLE_ID}',
															'$DATA{LOCATION_ID}', 
															'$DATA{COUNT}',
															'$DATA{COMMENTS}',
															'$DATA{NAS}',
															(($DATA{SUM_TOTAL}/$DATA{COUNT_INCOMING}) * $DATA{COUNT}) 
														);", 'do' 																											
														);
	my %UPDATE = (	ID    => $DATA{MAIN_ARTICLE_ID},
					COUNT => (($DATA{COUNT_INCOMING} - $DATA{COUNT}) == 0) ? 'NULL' : $DATA{COUNT_INCOMING} - $DATA{COUNT},
					SUM   => (($DATA{COUNT_INCOMING} - $DATA{COUNT}) == 0) ? 'NULL' : $DATA{SUM_TOTAL} - (($DATA{SUM_TOTAL}/$DATA{COUNT_INCOMING}) * $DATA{COUNT} ),

				);
	my %FIELDS = (	ID			=> 'id',
					COUNT      	=> 'count',
					SUM        	=> 'sum',
	);

   my %info = $self->storage_incoming_articles_info({ ID => $attr->{MAIN_ARTICLE_ID} });

	$self->changes($admin, {	CHANGE_PARAM => 'ID',
								TABLE        => 'storage_incoming_articles',
								FIELDS       => \%FIELDS,
								OLD_INFO     => \%info,
								DATA         => \%UPDATE,
							});
							
							
							
	
	if (! $self->{errno}) {
		$self->storage_log_add({ %$attr, STORAGE_MAIN_ID => $attr->{MAIN_ARTICLE_ID}, ACTION => 1  })
	}
																																								
	return 0;	
}


#**********************************************************
# Storage installation info for hardware
#**********************************************************
sub storage_installation_info {
	my $self = shift;
	my ($attr) = @_;
 	my @WHERE_RULES  = ();
 	my $serial;
	%DATA = $self->get_data($attr); 
	
	if(defined($attr->{ID}) and $attr->{ID} != 0) {
  		push @WHERE_RULES, "i.id='$attr->{ID}'";
	}
	
	if(defined($attr->{AID}) and $attr->{AID} != 0) {
  		push @WHERE_RULES, "i.aid='$attr->{AID}'";
	}
	if(defined($attr->{UID}) and $attr->{UID} != 0) {
  		push @WHERE_RULES, "i.uid='$attr->{UID}'";
	}
		     
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	i.id, 
								i.storage_incoming_articles_id, 
								i.aid,   
								i.uid, 
								i.nas_id,
								i.count,
								i.comments,
								adm.name,
								sat.id,
								sta.name,
								i.count * (sia.sum / sia.count),
								sta.measure,
								nas.name,
								i.sum,
								u.id,
								i.mac,
								i.grounds,
								i.date,
								sn.serial,
								i.type,
								inet_ntoa(dh.ip),
								dh.hostname,
								i.mac,
								dh.network
								FROM storage_installation AS i
							LEFT JOIN admins adm ON ( adm.aid = i.aid )
							LEFT JOIN storage_incoming_articles sia ON ( sia.id = i.storage_incoming_articles_id )
							LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
							LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
							LEFT JOIN nas nas ON ( nas.id = i.nas_id )
							LEFT JOIN builds b ON ( b.id = i.location_id )
							LEFT JOIN users u ON ( u.uid = i.uid )
							LEFT JOIN storage_sn sn ON ( i.id = sn.storage_installation_id )
							LEFT JOIN dhcphosts_hosts dh ON ( dh.mac = i.mac )
								$WHERE
								ORDER BY $SORT DESC;");



	(	$self->{ID},
		$self->{ARTICLE_ID},
		$self->{AID},
		$self->{UID},
		$self->{nas_id},
		$self->{COUNT},
		$self->{COMMENTS},
		$self->{ADM},
		$self->{ARTICLE_TYPE_ID},
		$self->{ARTICLE_TYPE_IDS},
		$self->{CNT},
		$self->{MEASURE},
		$self->{NAS_NAME},
		$self->{SUM},
		$self->{LOGINS},
		$self->{MAC},
		$self->{GROUNDS},
		$self->{DATE},
		$self->{SERIAL},
		$self->{STATUS_ID},
		$self->{IP},
		$self->{HOSTNAME},
		$self->{OLD_MAC},
		$self->{NETWORK},
	)= @{ $self->{list}->[0] };

#
#	my $list = $self->query($db, "SELECT	serial
#								FROM storage_sn sn
#								WHERE storage_installation_id=$attr->{ID}");
#							
#	foreach my $line ( @{$list->{list}} ) {
#		
#		$serial .= $line->[0] . "\r\n";
#	}
#	
#	$serial =~ s/\r\n$//; 
#
#	
#	$self->{SERIAL} = $serial;
	

	
	
	return $self;	
}

#**********************************************************
# Storage get serial
#**********************************************************

#sub storage_get_serial {
#	my $self = shift;
#	my ($attr) = @_;
#
#	my @WHERE_RULES  = ();
#	
#	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
#	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
#	
#	my $ext_fields = '';
#	my $EXT_TABLES = '';
#	
#	if(defined($attr->{AID}) and $attr->{AID} != 0) {
#  		push @WHERE_RULES, "sr.aid='$attr->{AID}'";
#	}  
#
#	$self->query($db, "SELECT	serial
#								FROM storage_sn sn
#								");
#
#}

#**********************************************************
# Storage installation return
#**********************************************************

sub storage_installation_return {
	my $self = shift;
	my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

	
	my %UPDATE = (	ID    => $DATA{MAIN_ARTICLE_ID},
					COUNT => $DATA{COUNT_INCOMING} + $DATA{COUNT},
					SUM   => $DATA{SUM_TOTAL} + $DATA{SUM},
				);
	my %FIELDS = (	ID			=> 'id',
					COUNT      	=> 'count',
					SUM        	=> 'sum',
	);

   my %info = $self->storage_incoming_articles_info({ ID => $attr->{MAIN_ARTICLE_ID} });

	$self->changes($admin, {	CHANGE_PARAM => 'ID',
								TABLE        => 'storage_incoming_articles',
								FIELDS       => \%FIELDS,
								OLD_INFO     => \%info,
								DATA         => \%UPDATE,
							});
							

	my @WHERE_RULES  = ();
	$WHERE = '';
	
	if (defined($attr->{ID_INSTALLATION})) {
		push @WHERE_RULES,  " id='$attr->{ID_INSTALLATION}' ";
	}
	if ($#WHERE_RULES > -1) {
		$WHERE = join(' and ', @WHERE_RULES);
		$self->query($db, "DELETE from storage_installation WHERE $WHERE;", 'do');
	}
																																								
	return 0;	
}



#**********************************************************
# Storage reserve add
#**********************************************************

sub storage_reserve_add {
	my $self = shift;
	my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

	$self->query($db, "INSERT INTO storage_reserve(			aid, 
															storage_incoming_articles_id,
															date,
															count, 
															comments
															
	
														)	  
													VALUES 
														(		
															'$DATA{AID}',
															'$DATA{ID}',
															NOW(), 
															'$DATA{COUNT}',
															'$DATA{COMMENTS}'
															 
														);", 'do' 																											
														);

							
							
	if (! $self->{errno}) {
		$self->storage_log_add({ %$attr, STORAGE_MAIN_ID => $DATA{STORAGE_INCOMING_ARTICLES_ID}, ACTION => 5  })
	}
																																								
	return 0;	
}

#**********************************************************
# Storage reserve list 
#**********************************************************
sub storage_reserve_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	my $ext_fields = '';
	my $EXT_TABLES = '';
	
	if(defined($attr->{AID}) and $attr->{AID} != 0) {
  		push @WHERE_RULES, "sr.aid='$attr->{AID}'";
	}  
 
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	sr.id, 
								sr.aid, 
								sr.storage_incoming_articles_id, 
								sr.count,  
								sr.date, 
								sr.comments,
								adm.name,
								sta.name,
								sat.name,
								sr.count * (sia.sum / sia.count),
								sta.measure
								
								FROM storage_reserve AS sr
							LEFT JOIN admins adm ON ( adm.aid = sr.aid )
							LEFT JOIN storage_incoming_articles sia ON ( sia.id = sr.storage_incoming_articles_id )
							LEFT JOIN storage_articles sta ON ( sta.id = sia.article_id )
							LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
								$WHERE
								ORDER BY $SORT DESC;");
	return $self->{list};
}




#**********************************************************
#  Storage reserve del
#**********************************************************
sub storage_reserve_del {
	my $self = shift;
	my ($attr) = @_;
  	my @WHERE_RULES  = ();
	$WHERE = '';

	if ($attr->{ID}) {
		push @WHERE_RULES,  " id='$attr->{ID}' ";
	}
	if ($#WHERE_RULES > -1) {
		$WHERE = join(' and ', @WHERE_RULES);
		$self->query($db, "DELETE from storage_reserve WHERE $WHERE;", 'do');
	}
	return $self->{result};
}


#**********************************************************
# Storage orders list 
#**********************************************************
sub storage_orders_list {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	if(defined($attr->{ID}) and $attr->{ID} != 0) {
  		push @WHERE_RULES, "so.id='$attr->{ID}'";
	}  
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	so.id, 
								so.count,   
								so.comments,
								sta.name,
								sta.measure,
								sat.name
								FROM storage_orders AS so
							LEFT JOIN storage_articles sta ON ( sta.id = so.id_storage_articles )
							LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type )
								$WHERE
								ORDER BY $SORT DESC;");
	return $self->{list};
}

#**********************************************************
# Storage orders info
#**********************************************************
sub storage_orders_info {
	my $self = shift;
	my ($attr) = @_;
 
 	%DATA = $self->get_data($attr); 

	$self->query($db, "SELECT 	so.id, 
								so.id_storage_articles, 
								so.count, 
								so.comments,
								sta.id,
								sat.id
							FROM storage_orders so
						LEFT JOIN storage_articles sta ON ( sta.id = so.id_storage_articles )
						LEFT JOIN storage_article_types sat ON ( sat.id = sta.article_type ) 
							WHERE so.id='$attr->{ID}';");

	(	$self->{ID},
 		$self->{ID_STORAGE_ARTICLES},
 		$self->{COUNT},
 		$self->{COMMENTS},
 		$self->{ARTICLE_ID},
 		$self->{ARTICLE_TYPE_ID}, 
	)= @{ $self->{list}->[0] };

	return $self;	
}


#**********************************************************
# Storage orders add
#**********************************************************

sub storage_orders_add {
	my $self = shift;
	my ($attr) = @_;
 
	%DATA = $self->get_data($attr); 

	$self->query($db, "INSERT INTO storage_orders(
			id_storage_articles,
			count,
			comments
		)
		VALUES 
		(
			'$DATA{ARTICLE_ID}',
			'$DATA{COUNT}', 
			'$DATA{COMMENTS}'
		);", 'do'
	);
	
	return 0;
}
#**********************************************************
# Change storage orders
#**********************************************************
sub storage_orders_change {
	my $self = shift;
	my ($attr) = @_; 
 
	my %FIELDS = ( 	ID				=> 'id',
					NAME			=> 'id_storage_articles',
					COUNT		=> 'count',
					COMMENTS		=> 'comments'   
	);

	$self->changes($admin,	{
								CHANGE_PARAM => 'ID',
								TABLE        => 'storage_orders',
								FIELDS       => \%FIELDS,
								OLD_INFO     => $self->storage_orders_info({ ID => $attr->{ID} }),
								DATA         => $attr,
							}
	);
	return $self;
}
#**********************************************************
# Del storage articles
#**********************************************************
sub storage_orders_del {
	my $self = shift;
	my ($attr) = @_;
  	my @WHERE_RULES  = ();
	$WHERE = '';

	if ($attr->{ID}) {
		push @WHERE_RULES,  " id='$attr->{ID}' ";
	}

	if ($#WHERE_RULES > -1) {
    	$WHERE = join(' and ', @WHERE_RULES);
    	$self->query($db, "DELETE from storage_orders WHERE $WHERE;", 'do');
   	}
  	return $self->{result};
}



#**********************************************************
# Storage installation user add
# Функция добавления товара в продаж или оренду для клиента
#**********************************************************

sub storage_installation_user_add {
	my $self = shift;
	my ($attr) = @_;
	my $storage_installation_id;
	my @serials;
	my $serial;
	%DATA = $self->get_data($attr); 

	$self->query($db, "INSERT INTO storage_installation(	aid, 
															storage_incoming_articles_id,
															count, 
															comments,
															nas_id,
															sum,
															uid,
															type,
															grounds,
															mac,
															date
														)	  
													VALUES 
														(
															'$admin->{AID}',
															'$DATA{MAIN_ARTICLE_ID}', 
															'$DATA{COUNT}',
															'$DATA{COMMENTS}',
															'$DATA{NAS}',
															(($DATA{SUM_TOTAL}/$DATA{COUNT_INCOMING}) * $DATA{COUNT}),
															'$DATA{UID}',
															'$DATA{STATUS}',
															'$DATA{GROUNDS}',
															'$DATA{MAC}',
															 NOW() 
														);", 'do'
														);
														
	
	$storage_installation_id = $self->{INSERT_ID};
													
	my %UPDATE = (	ID    => $DATA{MAIN_ARTICLE_ID},
					COUNT => (($DATA{COUNT_INCOMING} - $DATA{COUNT}) == 0) ? 'NULL' : $DATA{COUNT_INCOMING} - $DATA{COUNT},
					SUM   => (($DATA{COUNT_INCOMING} - $DATA{COUNT}) == 0) ? 'NULL' : $DATA{SUM_TOTAL} - (($DATA{SUM_TOTAL}/$DATA{COUNT_INCOMING}) * $DATA{COUNT} ),

	);

	my %FIELDS = (	ID			=> 'id',
					COUNT      	=> 'count',
					SUM        	=> 'sum',
	);

   my %info = $self->storage_incoming_articles_info({ ID => $attr->{MAIN_ARTICLE_ID} });

	$self->changes($admin, {	CHANGE_PARAM => 'ID',
								TABLE        => 'storage_incoming_articles',
								FIELDS       => \%FIELDS,
								OLD_INFO     => \%info,
								DATA         => \%UPDATE,
							});
							
	
	#if (defined($attr->{SERIAL}) and $attr->{SERIAL} ne '') {
		
		#@serials = split(/\r\n/, $attr->{SERIAL});
				#foreach $serial (@serials) {

					$self->query($db, "INSERT INTO storage_sn(	
							storage_incoming_articles_id,
							storage_installation_id,
							serial
						)
						VALUES
						(
							'$attr->{MAIN_ARTICLE_ID}',
							'$storage_installation_id', 
							'$attr->{SERIAL}' 
						);", 'do'
					);
				#}
				
		
	#}
							
							
	
	if (! $self->{errno}) {
		$self->storage_log_add({ %$attr, STORAGE_MAIN_ID => $attr->{MAIN_ARTICLE_ID}, ACTION => 1  })
	}
																																								
	return 0;	
}


#**********************************************************
# Change storage articles
#**********************************************************
sub storage_installation_change {
	my $self = shift;
	my ($attr) = @_; 
 
	my %FIELDS = ( 	ID				=> 'id',
					COMMENTS		=> 'comments',
					STATUS			=> 'type',
					GROUNDS			=> 'grounds',
					MAC				=> 'mac',  
	);
	
	my %FIELDS_SN = ( 	ID				=> 'storage_installation_id',
						SERIAL			=> 	'serial',

	);
	
	my %FIELDS_HOSTS = ( 	OLD_MAC 		=> 'mac',
							IP				=> 	'ip',
							HOSTNAME		=>	'hostname',
							NETWORK			=>  'network',
							MAC			=>  'mac',
	);
		

	$self->changes($admin,	{
							CHANGE_PARAM => 'OLD_MAC',
							TABLE        => 'dhcphosts_hosts',
							FIELDS       => \%FIELDS_HOSTS,
							OLD_INFO     => $self->storage_installation_info({ ID => $attr->{ID} }),
							DATA         => $attr,
						}
	);	



	$self->changes($admin,	{
								CHANGE_PARAM => 'ID',
								TABLE        => 'storage_installation',
								FIELDS       => \%FIELDS,
								OLD_INFO     => $self->storage_installation_info({ ID => $attr->{ID} }),
								DATA         => $attr,
							}
	);
	
	$self->changes($admin,	{
							CHANGE_PARAM => 'ID',
							TABLE        => 'storage_sn',
							FIELDS       => \%FIELDS_SN,
							OLD_INFO     => $self->storage_installation_info({ ID => $attr->{ID} }),
							DATA         => $attr,
						}
	);
	

	
	
	return $self;
}



#**********************************************************
# Storage rent fees
#**********************************************************
sub storage_rent_fees {
	my $self = shift;
	my ($attr) = @_;
	
	my @WHERE_RULES  = ();
	
	my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
	my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
	
	if(defined($attr->{ID}) and $attr->{ID} != 0) {
  		push @WHERE_RULES, "i.id='$attr->{ID}'";
	}
	
 	$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
	$self->query($db, "SELECT	i.id, 
								i.uid,
								sia.rent_price,
								i.count,
								u.bill_id,
								sa.name,
								i.storage_incoming_articles_id, 
								i.aid,   
								adm.name,
								i.type
								FROM storage_installation AS i
							LEFT JOIN admins adm ON ( adm.aid = i.aid )
							LEFT JOIN storage_incoming_articles sia ON ( sia.id = i.storage_incoming_articles_id )
							LEFT JOIN users u ON ( u.uid = i.uid )
							LEFT JOIN storage_articles sa ON (sa.id = sia.article_id)
								WHERE i.type=2 and i.uid != 0 and sia.rent_price != 0
								ORDER BY $SORT DESC;");
	return $self->{list};
}