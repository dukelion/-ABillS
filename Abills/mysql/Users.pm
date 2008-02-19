package Users;
# Users manage functions
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

# User name expration
my $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$"; # configurable;

use main;
@ISA  = ("main");


my $uid;
#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if($#WHERE_RULES > -1);
  
  $admin->{MODULE}='';
  $CONF->{MAX_USERNAME_LENGTH} = 10 if (! defined($CONF->{MAX_USERNAME_LENGTH}));
  
  if (defined($CONF->{USERNAMEREGEXP})) {
  	$usernameregexp=$CONF->{USERNAMEREGEXP};
   }

  my $self = { };

  bless($self, $class);

  return $self;
}





#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  my $WHERE;
    
   
  if (defined($attr->{LOGIN}) && defined($attr->{PASSWORD})) {
    $WHERE = "WHERE u.id='$attr->{LOGIN}' and DECODE(u.password, '$CONF->{secretkey}')='$attr->{PASSWORD}'";
    if (defined($attr->{ACTIVATE})) {
    	my $value = $self->search_expr("$attr->{ACTIVATE}", 'INT');
    	$WHERE .= " and u.activate$value";
     }

    if (defined($attr->{EXPIRE})) {
    	my $value = $self->search_expr("$attr->{EXPIRE}", 'INT');
    	$WHERE .= " and u.expire$value";
     }

    if (defined($attr->{DISABLE})) {
    	$WHERE .= " and u.disable='$attr->{DISABLE}'";
     }
    
    #$PASSWORD = "if(DECODE(password, '$SECRETKEY')='$attr->{PASSWORD}', 0, 1)";
   }
  elsif(defined($attr->{LOGIN})) {
    $WHERE = "WHERE u.id='$attr->{LOGIN}'";
   }
  else {
    $WHERE = "WHERE u.uid='$uid'";
   }

  my $password="''";
  if ($attr->{SHOW_PASSWORD}) {
  	$password="DECODE(u.password, '$CONF->{secretkey}')";
   }

  $self->query($db, "SELECT u.uid,
   u.gid, 
   g.name,
   u.id, u.activate, u.expire, u.credit, u.reduction, 
   u.registration, 
   u.disable,
   if(u.company_id > 0, cb.id, b.id),
   if(c.name IS NULL, b.deposit, cb.deposit),
   u.company_id,
   if(c.name IS NULL, 'N/A', c.name), 
   if(c.name IS NULL, 0, c.vat),
   if(c.name IS NULL, b.uid, cb.uid),
   $password
     FROM users u
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN groups g ON (u.gid=g.gid)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
     $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  
  ($self->{UID},
   $self->{GID},
   $self->{G_NAME},
   $self->{LOGIN}, 
   $self->{ACTIVATE}, 
   $self->{EXPIRE}, 
   $self->{CREDIT}, 
   $self->{REDUCTION}, 
   $self->{REGISTRATION}, 
   $self->{DISABLE}, 
   $self->{BILL_ID}, 
   $self->{DEPOSIT}, 
   $self->{COMPANY_ID},
   $self->{COMPANY_NAME},
   $self->{COMPANY_VAT},
   $self->{BILL_OWNER},
   $self->{PASSWORD}
 )= @{ $self->{list}->[0] };
  
 
  return $self;
}


#**********************************************************
#
#**********************************************************
sub defaults_pi {
  my $self = shift;

  %DATA = (
   FIO            => '', 
   PHONE          => 0, 
   ADDRESS_STREET => '', 
   ADDRESS_BUILD  => '', 
   ADDRESS_FLAT   => '', 
   EMAIL          => '', 
   COMMENTS       => '',
   CONTRACT_ID    => '',
   PASPORT_NUM    => '',
   PASPORT_DATE   => '0000-00-00',
   PASPORT_GRANT  => '',
   ZIP            => '',
   CITY           => ''
  );
 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# pi_add()
#**********************************************************
sub pi_add {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr, { default => defaults_pi()   }); 
  
  if($DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }
    
  $self->query($db,  "INSERT INTO users_pi (uid, fio, phone, address_street, address_build, address_flat, 
          email, contract_id, comments, pasport_num, pasport_date,  pasport_grant, zip, city)
           VALUES ('$DATA{UID}', '$DATA{FIO}', '$DATA{PHONE}', \"$DATA{ADDRESS_STREET}\", 
            \"$DATA{ADDRESS_BUILD}\", \"$DATA{ADDRESS_FLAT}\",
            '$DATA{EMAIL}', '$DATA{CONTRACT_ID}',
            '$DATA{COMMENTS}',
            '$DATA{PASPORT_NUM}',
            '$DATA{PASPORT_DATE}',
            '$DATA{PASPORT_GRANT}',
            '$DATA{ZIP}',
            '$DATA{CITY}'
             );", 'do');
  
  return $self if ($self->{errno});
  
  $admin->action_add("$DATA{UID}", "ADD PIf");
  return $self;
}



#**********************************************************
# Personal inforamtion
# personal_info()
#**********************************************************
sub pi {
	my $self = shift;
  my ($attr) = @_;
  
  my $UID = ($attr->{UID}) ? $attr->{UID} : $self->{UID};
  
  
  $self->query($db, "SELECT pi.fio, 
  pi.phone, 
  pi.address_street, 
  pi.address_build,
  pi.address_flat,
  pi.email,  
  pi.contract_id,
  pi.comments,
  pi.pasport_num,
  pi.pasport_date,
  pi.pasport_grant,
  pi.zip,
  pi.city
    FROM users_pi pi
    WHERE pi.uid='$UID';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }



  ($self->{FIO}, 
   $self->{PHONE}, 
   $self->{ADDRESS_STREET}, 
   $self->{ADDRESS_BUILD}, 
   $self->{ADDRESS_FLAT}, 
   $self->{EMAIL}, 
   $self->{CONTRACT_ID},
   $self->{COMMENTS},
   $self->{PASPORT_NUM},
   $self->{PASPORT_DATE},
   $self->{PASPORT_GRANT},
   $self->{ZIP},
   $self->{CITY}
  )= @{ $self->{list}->[0] };
	
	
	return $self;
}

#**********************************************************
# Personal Info change
#
#**********************************************************
sub pi_change {
	my $self   = shift;
  my ($attr) = @_;


my %FIELDS = (EMAIL          => 'email',
              FIO            => 'fio',
              PHONE          => 'phone',
              ADDRESS_BUILD  => 'address_build',
              ADDRESS_STREET => 'address_street',
              ADDRESS_FLAT   => 'address_flat',
              COMMENTS       => 'comments',
              UID            => 'uid',
              CONTRACT_ID    => 'contract_id',
              PASPORT_NUM    => 'pasport_num',
              PASPORT_DATE   => 'pasport_date',
              PASPORT_GRANT  => 'pasport_grant',
              ZIP            => 'zip',
              CITY           => 'city'
              
             );

	$self->changes($admin, { CHANGE_PARAM => 'UID',
		                TABLE        => 'users_pi',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->pi({ UID => $attr->{UID} }),
		                DATA         => $attr
		              } );

	
	return $self;
}


#**********************************************************
# defauls user settings
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = ( LOGIN => '', 
   ACTIVATE       => '0000-00-00', 
   EXPIRE         => '0000-00-00', 
   CREDIT         => 0, 
   REDUCTION      => '0.00', 
   SIMULTANEONSLY => 0, 
   DISABLE        => 0, 
   COMPANY_ID     => 0,
   GID            => 0,
   DISABLE        => 0,
   PASSWORD       => '');
 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# groups_list()
#**********************************************************
sub groups_list {
 my $self = shift;
 my ($attr) = @_;

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 undef @WHERE_RULES;

 if ($attr->{GIDS}) {
    push @WHERE_RULES, "g.gid IN ($attr->{GIDS})";
  }
 elsif ($attr->{GID}) {
    push @WHERE_RULES, "g.gid='$attr->{GID}'";
  }

 my $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : ''; 
 
 $self->query($db, "select g.gid, g.name, g.descr, count(u.uid) FROM groups g
        LEFT JOIN users u ON  (u.gid=g.gid) 
        $WHERE
        GROUP BY g.gid
        ORDER BY $SORT $DESC");

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*) FROM groups g $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

 return $list;
}


#**********************************************************
# group_info()
#**********************************************************
sub group_info {
 my $self = shift;
 my ($gid) = @_;
 
 $self->query($db, "select g.name, g.descr FROM groups g WHERE g.gid='$gid';");

 return $self if ($self->{errno});

 ($self->{G_NAME},
 	$self->{G_DESCRIBE}) = @{ $self->{list}->[0] };
 
 $self->{GID}=$gid;

 return $self;
}

#**********************************************************
# group_info()
#**********************************************************
sub group_change {
 my $self = shift;
 my ($gid, $attr) = @_;

 my %FIELDS = (GID        => 'gid',
               G_NAME     => 'name',
               G_DESCRIBE => 'descr',
               CHG        => 'gid');

 $attr->{CHG}=$gid;
 $self->changes($admin, { CHANGE_PARAM => 'CHG',
		               TABLE        => 'groups',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->group_info($gid),
		               DATA         => $attr
		              } );


 return $self;
}



#**********************************************************
# group_add()
#**********************************************************
sub group_add {
 my $self = shift;
 my ($attr) = @_;

 %DATA = $self->get_data($attr); 
 $self->query($db, "INSERT INTO groups (gid, name, descr)
    values ('$DATA{GID}', '$DATA{G_NAME}', '$DATA{G_DESCRIBE}');", 'do');

 return $self;
}



#**********************************************************
# group_add()
#**********************************************************
sub group_del {
 my $self = shift;
 my ($id) = @_;

 $self->query($db, "DELETE FROM groups WHERE gid='$id';", 'do');
 return $self;
}


#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 undef @WHERE_RULES;
 my $search_fields = '';

 # Start letter 
 if ($attr->{FIRST_LETTER}) {
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }
 elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
  }
 # Login expresion
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
  }
 

 if ($attr->{PHONE}) {
    my $value = $self->search_expr($attr->{PHONE}, 'INT');
    push @WHERE_RULES, "pi.phone$value";
    $self->{SEARCH_FIELDS} = 'pi.phone, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{EMAIL}) {
    $attr->{EMAIL} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.email LIKE '$attr->{EMAIL}'";
    $self->{SEARCH_FIELDS} = 'pi.email, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }


 if ($attr->{ADDRESS_STREET}) {
    $attr->{ADDRESS_STREET} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.address_street LIKE '$attr->{ADDRESS_STREET}' ";
    $self->{SEARCH_FIELDS} .= 'pi.address_street, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{PASPORT_DATE}) {
    $attr->{PASPORT_DATE} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.pasport_date LIKE '$attr->{PASPORT_DATE}' ";
    $self->{SEARCH_FIELDS} .= 'pi.pasport_date, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{PASPORT_NUM}) {
    $attr->{PASPORT_NUM} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.pasport_num LIKE '$attr->{PASPORT_NUM}' ";
    $self->{SEARCH_FIELDS} .= 'pi.pasport_num, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{PASPORT_GRANT}) {
    $attr->{PASPORT_GRANT} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.pasport_grant LIKE '$attr->{PASPORT_GRANT}' ";
    $self->{SEARCH_FIELDS} .= 'pi.pasport_grant, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{ADDRESS_BUILD}) {
    $attr->{ADDRESS_BUILD} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.address_build LIKE '$attr->{ADDRESS_BUILD}'";
    $self->{SEARCH_FIELDS} .= 'pi.address_build, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{ADDRESS_FLAT}) {
    $attr->{ADDRESS_FLAT} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.address_flat LIKE '$attr->{ADDRESS_FLAT}'";
    $self->{SEARCH_FIELDS} .= 'pi.address_flat, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{CITY}) {
    $attr->{CITY} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.city LIKE '$attr->{CITY}'";
    $self->{SEARCH_FIELDS} .= 'pi.city, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{ZIP}) {
    $attr->{ZIP} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.zip LIKE '$attr->{ZIP}'";
    $self->{SEARCH_FIELDS} .= 'pi.zip, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }



 if ($attr->{CONTRACT_ID}) {
    $attr->{CONTRACT_ID} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.contract_id LIKE '$attr->{CONTRACT_ID}'";
    $self->{SEARCH_FIELDS} .= 'pi.contract_id, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{REGISTRATION}) {
    my $value = $self->search_expr("$attr->{REGISTRATION}", 'INT');
    push @WHERE_RULES, "u.registration$value";
    $self->{SEARCH_FIELDS} .= 'u.registration, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }


 if ($attr->{DEPOSIT}) {
    my $value = $self->search_expr($attr->{DEPOSIT}, 'INT');
    push @WHERE_RULES, "b.deposit$value";
  }

 if ($attr->{CREDIT}) {
    my $value = $self->search_expr($attr->{CREDIT}, 'INT');
    push @WHERE_RULES, "u.credit$value";
  }


 if ($attr->{COMMENTS}) {
  	$attr->{COMMENTS} =~ s/\*/\%/ig;
 	  push @WHERE_RULES, "pi.comments LIKE '$attr->{COMMENTS}'";
    $self->{SEARCH_FIELDS} .= 'pi.comments, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }    

 if ($attr->{BILL_ID}) {
    my $value = $self->search_expr($attr->{BILL_ID}, 'INT');
    push @WHERE_RULES, "if(company.id IS NULL, b.id, cb.id)$value";

    $self->{SEARCH_FIELDS} .= 'if(company.id IS NULL, b.id, cb.id), ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }    


 if ($attr->{FIO}) {
    $attr->{FIO} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.fio LIKE '$attr->{FIO}'";
  }

 # Show debeters
 if ($attr->{DEBETERS}) {
    push @WHERE_RULES, "b.deposit<0";
  }

 if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "u.company_id='$attr->{COMPANY_ID}'";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }


#Activate
 if ($attr->{ACTIVATE}) {
   my $value = $self->search_expr("$attr->{ACTIVATE}", 'INT');
   push @WHERE_RULES, "(u.activate$value)"; 
   
   #push @WHERE_RULES, "(u.activate='0000-00-00' or u.activate$value)"; 
   $self->{SEARCH_FIELDS} .= 'u.activate, ';
   $self->{SEARCH_FIELDS_COUNT}++;
 }

#Expire
 if ($attr->{EXPIRE}) {
   my $value = $self->search_expr("$attr->{EXPIRE}", 'INT');
   push @WHERE_RULES, "(u.expire$value)"; 
   #push @WHERE_RULES, "(u.expire='0000-00-00' or u.expire$value)"; 
   
   $self->{SEARCH_FIELDS} .= 'u.expire, ';
   $self->{SEARCH_FIELDS_COUNT}++;
 }

#DIsable
 if ($attr->{DISABLE}) {
   push @WHERE_RULES, "u.disable='$attr->{DISABLE}'"; 
 }
 
 
 
#Show last paymenst
 if ($attr->{PAYMENTS}) {

    my $value = $self->search_expr($attr->{PAYMENTS}, 'INT');
    push @WHERE_RULES, "max(p.date)$value";
    $self->{SEARCH_FIELDS} .= 'max(p.date), ';
    $self->{SEARCH_FIELDS_COUNT}++;




    my $HAVING = ($#WHERE_RULES > -1) ?  "HAVING " . join(' and ', @WHERE_RULES) : '';


   
    $self->query($db, "SELECT u.id, 
       pi.fio, if(company.id IS NULL, b.deposit, cb.deposit), u.credit, u.disable, 
       $self->{SEARCH_FIELDS}
       u.uid, 
       u.company_id, 
       pi.email, 
       u.activate, 
       u.expire,
       u.gid,
       b.deposit
     FROM users u
     LEFT JOIN payments p ON (u.uid = p.uid)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     GROUP BY u.uid     
     $HAVING 

     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

   return $self if($self->{errno});



   my $list = $self->{list};

   if ($self->{TOTAL} > 0) {
     
     my $value = $self->search_expr($attr->{PAYMENTS}, 'INT');
     $WHERE_RULES[$#WHERE_RULES]="p.date$value";
    
     $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : '';
    
     $self->query($db, "SELECT count(DISTINCT u.uid) FROM users u 
       LEFT JOIN payments p ON (u.uid = p.uid)
       LEFT JOIN users_pi pi ON (u.uid = pi.uid)
       LEFT JOIN bills b ON (u.bill_id = b.id)
      $WHERE;");

      ($self->{TOTAL}) = @{ $self->{list}->[0] };
    }

 	  return $list
  }
 
 
 $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : '';
 
 $self->query($db, "SELECT u.id, 
      pi.fio, if(company.id IS NULL, b.deposit, cb.deposit), u.credit, u.disable, 
      $self->{SEARCH_FIELDS}
      u.uid, u.company_id, pi.email, u.activate, u.expire
     FROM users u
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON u.bill_id = b.id
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});



 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(u.id) FROM users u 
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON u.bill_id = b.id
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
    $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}


#**********************************************************
# Add to deposit
#**********************************************************
sub add2deposit {
	my $self = shift;
	my ($sum) = @_;
	
 $self->query($db, "UPDATE users SET deposit=deposit+$sum 
     WHERE uid='$self->{UID}';");

  return $self;	
}

#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  
  my %DATA = $self->get_data($attr, { default => defaults() }); 

  if (! defined($DATA{LOGIN})) {
     $self->{errno} = 8;
     $self->{errstr} = 'ERROR_ENTER_NAME';
     return $self;
   }
  elsif (length($DATA{LOGIN}) > $CONF->{MAX_USERNAME_LENGTH}) {
     $self->{errno} = 9;
     $self->{errstr} = 'ERROR_LONG_USERNAME';
     return $self;
   }

  #ERROR_SHORT_PASSWORD
  elsif($DATA{LOGIN} !~ /$usernameregexp/) {
     $self->{errno} = 10;
     $self->{errstr} = 'ERROR_WRONG_NAME';
     return $self; 	
   }
  elsif($DATA{EMAIL} && $DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }
  
  
  $DATA{DISABLE} = int($DATA{DISABLE});
  $self->query($db,  "INSERT INTO users (id, activate, expire, credit, reduction, 
           registration, disable, company_id, gid, password)
           VALUES ('$DATA{LOGIN}', '$DATA{ACTIVATE}', '$DATA{EXPIRE}', '$DATA{CREDIT}', '$DATA{REDUCTION}', 
           now(),  '$DATA{DISABLE}', 
           '$DATA{COMPANY_ID}', '$DATA{GID}', 
           ENCODE('$DATA{PASSWORD}', '$CONF->{secretkey}')
            );", 'do');
  
  return $self if ($self->{errno});
  
  $self->{UID} = $self->{INSERT_ID};
  $self->{LOGIN} = $DATA{LOGIN};

  $admin->action_add("$self->{UID}", "ADD $DATA{LOGIN}");



  if ($attr->{CREATE_BILL}) {
  	#print "create bill";
  	$self->change($self->{UID}, { 
  		 DISABLE => int($DATA{DISABLE}),
  		 UID     => $self->{UID},
  		 create  => 1 });

  }

  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($uid, $attr) = @_;
  
  my %FIELDS = (UID         => 'uid',
              LOGIN       => 'id',
              ACTIVATE    => 'activate',
              EXPIRE      => 'expire',
              CREDIT      => 'credit',
              REDUCTION   => 'reduction',
              SIMULTANEONSLY => 'logins',
              COMMENTS    => 'comments',
              COMPANY_ID  => 'company_id',
              DISABLE     => 'disable',
              GID         => 'gid',
              PASSWORD    => 'password',
              BILL_ID     => 'bill_id'
             );

  my $old_info = $self->info($attr->{UID});
  
  if($attr->{create}){
  	 use Bills;
  	 my $Bill = Bills->new($db, $admin, $CONF);
  	 $Bill->create({ UID => $self->{UID} });
     if($Bill->{errno}) {
       $self->{errno}  = $Bill->{errno};
       $self->{errstr} =  $Bill->{errstr};
       return $self;
      }
     #$DATA{BILL_ID}=$Bill->{BILL_ID};
     $attr->{BILL_ID}=$Bill->{BILL_ID};
     $attr->{DISABLE}=$old_info->{DISABLE};
   }
  
  
	$self->changes($admin, { CHANGE_PARAM => 'UID',
		                TABLE        => 'users',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $old_info,
		                DATA         => $attr
		              } );



  return $self->{result};
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  my @clear_db = ('admin_actions', 
                  'fees', 
                  'payments', 
                  'users_nas', 
                  'users',
                  'users_pi');

  foreach my $table (@clear_db) {
     $self->query($db, "DELETE from $table WHERE uid='$self->{UID}';", 'do');
     $self->{info} .= "$table, ";
    }

  $admin->action_add($self->{UID}, "DELETE $self->{UID}:$self->{LOGIN}");
  return $self->{result};
}

#**********************************************************
# list_allow nass
#**********************************************************
sub nas_list {
  my $self = shift;
  my $list;
  $self->query($db, "SELECT nas_id FROM users_nas WHERE uid='$self->{UID}';");


  if ($self->{TOTAL} > 0) {
    $list = $self->{list};
   }
  else {
    $self->query($db, "SELECT nas_id FROM tp_nas WHERE tp_id='$self->{TARIF_PLAN}';");
    $list = $self->{list};
   }

	return $list;
}


#**********************************************************
# list_allow nass
#**********************************************************
sub nas_add {
 my $self = shift;
 my ($nas) = @_;
 
 $self->nas_del();
 foreach my $line (@$nas) {
   $self->query($db, "INSERT INTO users_nas (nas_id, uid) VALUES ('$line', '$self->{UID}');", 'do');
  }
  
  $admin->action_add($self->{UID}, "NAS ". join(',', @$nas) );
  return $self;
}

#**********************************************************
# nas_del
#**********************************************************
sub nas_del {
  my $self = shift;
  
  $self->query($db, "DELETE FROM users_nas WHERE uid='$self->{UID}';", 'do');	
  return $self if($db->err > 0);

  $admin->action_add($self->{UID}, "DELETE NAS");
  return $self;
}


#**********************************************************
#
#**********************************************************
sub bruteforce_add {
  my $self = shift;	
  my ($attr) = @_;
  
  
	$self->query($db, "INSERT INTO users_bruteforce (login, password, datetime, ip, auth_state) VALUES 
	      ('$attr->{LOGIN}', '$attr->{PASSWORD}', now(), INET_ATON('$attr->{REMOTE_ADDR}'), '$attr->{AUTH_STATE}');", 'do');	
	
	return $self;
}


#**********************************************************
#
#**********************************************************
sub bruteforce_list {
  my $self = shift;	
	my ($attr) = @_;
	
	@WHERE_RULES = ();

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


	my $GROUP = 'GROUP BY login';
  my $count='count(login)';	
	
	if ($attr->{AUTH_STATE}) {
    push @WHERE_RULES, "auth_state='$attr->{AUTH_STATE}'";
   }
	
	if ($attr->{LOGIN}) {
		push @WHERE_RULES, "login='$attr->{LOGIN}'";
  	$count='auth_state';
  	$GROUP = '';
	 }
	
  my $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if($#WHERE_RULES > -1);
	my $list;
	
	
  if (! $attr->{CHECK}) {
	  $self->query($db,  "SELECT login, password, datetime, $count, INET_NTOA(ip) FROM users_bruteforce
	    $WHERE
	    $GROUP
	    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");
    $list = $self->{list};
  }

  $self->query($db, "SELECT count(DISTINCT login) FROM users_bruteforce $WHERE;");
  ($self->{TOTAL}) = @{ $self->{list}->[0] };

	
	return $list;
}

#**********************************************************
#
#**********************************************************
sub bruteforce_del {
  my $self = shift;	
	my ($attr) = @_;
	
  $self->query($db,  "DELETE FROM users_bruteforce
	 WHERE login='$attr->{LOGIN}';", 'do');

	return $self;
}



#**********************************************************
#
#**********************************************************
sub web_session_add {
  my $self = shift;	
  my ($attr) = @_;

  $self->query($db, "DELETE  FROM web_users_sessions WHERE uid='$attr->{UID}';", 'do');	

	$self->query($db, "INSERT INTO web_users_sessions 
	      (uid, datetime, login, remote_addr, sid, ext_info) VALUES 
	      ('$attr->{UID}', UNIX_TIMESTAMP(), '$attr->{LOGIN}', INET_ATON('$attr->{REMOTE_ADDR}'), '$attr->{SID}',
	      '$attr->{EXT_INFO}');", 'do');	
	
	return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub web_session_info {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE;
    
  if($attr->{SID}) {
    $WHERE = "WHERE sid='$attr->{SID}'";
   }
  else {
    $self->{errno} = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
   }


  $self->query($db, "SELECT uid, 
    datetime, 
    login, 
    INET_NTOA(remote_addr), 
    UNIX_TIMESTAMP() - datetime,
    sid
     FROM web_users_sessions
     $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  
  ($self->{UID},
   $self->{DATETIME},
   $self->{LOGIN},
   $self->{REMOTE_ADDR}, 
   $self->{ACTIVATE},
   $self->{SID}
   ) = @{ $self->{list}->[0] };
 
  return $self;
}

#**********************************************************
#
#**********************************************************
sub web_sessions_list {
  my $self = shift;	
	my ($attr) = @_;
	

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


	my $GROUP = 'GROUP BY login';
  my $count='count(login)';	
	
	if ($attr->{AUTH_STATE}) {
    push @WHERE_RULES, "auth_state='$attr->{AUTH_STATE}'";
   }
	
	if ($attr->{LOGIN}) {
		push @WHERE_RULES, "login='$attr->{LOGIN}'";
  	$count='auth_state';
  	$GROUP = '';
	 }
	
  my $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if($#WHERE_RULES > -1);
	my $list;
	
	
  if (! $attr->{CHECK}) {
	  $self->query($db,  "SELECT uid, datetime, login, INET_NTOA(remote_addr), sid 
	   FROM web_users_sessions
	    $WHERE
	    $GROUP
	    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");
    $list = $self->{list};
  }

  $self->query($db, "SELECT count(DISTINCT login) FROM web_users_sessions $WHERE;");
  ($self->{TOTAL}) = @{ $self->{list}->[0] };

	
	return $list;
}

#**********************************************************
#
#**********************************************************
sub web_session_del {
  my $self = shift;	
	my ($attr) = @_;
	
  $self->query($db,  "DELETE FROM web_users_sessions
	 WHERE sid='$attr->{SID}';", 'do');

	return $self;
}

1
