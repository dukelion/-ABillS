package Users;
# Users manage functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.05;
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
   }
  elsif($attr->{LOGIN}) {
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
   if(c.name IS NULL, '', c.name), 
   if(c.name IS NULL, 0, c.vat),
   if(c.name IS NULL, b.uid, cb.uid),
   if(u.company_id > 0, c.ext_bill_id, u.ext_bill_id),
   u.credit_date,
   u.reduction_date,
   if(c.name IS NULL, 0, c.credit),
   u.domain_id,
   u.deleted,
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
   $self->{EXT_BILL_ID},
   $self->{CREDIT_DATE},
   $self->{REDUCTION_DATE},
   $self->{COMPANY_CREDIT},
   $self->{DOMAIN_ID},
   $self->{DELETED},
   $self->{PASSWORD}
 )= @{ $self->{list}->[0] };
 
  if ((! $admin->{permissions}->{0} || ! $admin->{permissions}->{0}->{8}) && ($self->{DELETED})) {
    $self->{errno} = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
   }

 
 if ($CONF->{EXT_BILL_ACCOUNT} && $self->{EXT_BILL_ID} && $self->{EXT_BILL_ID} > 0) {
 	 $self->query($db, "SELECT b.deposit, b.uid
     FROM bills b WHERE id='$self->{EXT_BILL_ID}';");

   if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
    }

   ($self->{EXT_BILL_DEPOSIT},
    $self->{EXT_BILL_OWNER}
    )= @{ $self->{list}->[0] };
  } 
 
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
   COUNTRY_ID     => 0, 
   EMAIL          => '', 
   COMMENTS       => '',
   CONTRACT_ID    => '',
   PASPORT_NUM    => '',
   PASPORT_DATE   => '0000-00-00',
   PASPORT_GRANT  => '',
   ZIP            => '',
   CITY           => '',
   CREDIT_DATE    => '0000-00-00',
   REDUCTION_DATE => '0000-00-00',
   ACCEPT_RULES   => 0,
   LOCATION_ID    => 0
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
    if ($DATA{EMAIL} !~ /(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }

#Info fields
  my $info_fields = '';
  my $info_fields_val = '';

	my $list = $self->config_list({ PARAM => 'ifu*', SORT => 2 });
  if ($self->{TOTAL} > 0) {
    my @info_fields_arr = ();
    my @info_fields_val = ();

    foreach my $line (@$list) {
      if ($line->[0] =~ /ifu(\S+)/) {
    	  my $value = $1;
    	  push @info_fields_arr, $value;
        if (defined($attr->{$value})) {
    	    #attach
    	    if ( ref $attr->{$value} eq 'HASH' && $attr->{$value}{filename}) {
            $self->attachment_add({ 
            	TABLE        => $value.'_file',
              CONTENT      => $attr->{$value}{Contents},
              FILESIZE     => $attr->{$value}{Size},
              FILENAME     => $attr->{$value}{filename},
              CONTENT_TYPE => $attr->{$value}{'Content-Type'}
             });
            $attr->{$value}=$self->{INSERT_ID};
           }
          else {
          	$attr->{$value} =~ s/^ +|[ \n]+$//g;
           }
         }
   	    else {
   	    	$attr->{$value} = '';
   	     }
   	    push @info_fields_val, "'$attr->{$value}'";
       }
     }

    $info_fields = ', '. join(', ', @info_fields_arr) if ($#info_fields_arr > -1);
    $info_fields_val = ', '. join(', ', @info_fields_val) if ($#info_fields_arr > -1);
   }

  my $prefix='';
  my $sufix =''; 
  if ($attr->{CONTRACT_TYPE}) {
  	($prefix, $sufix)=split(/\|/, $attr->{CONTRACT_TYPE});
   }


  $self->query($db,  "INSERT INTO users_pi (uid, fio, phone, address_street, address_build, address_flat, country_id,
          email, contract_id, contract_date, comments, pasport_num, pasport_date,  pasport_grant, zip, 
          city, accept_rules, location_id, contract_sufix
           $info_fields)
           VALUES ('$DATA{UID}', '$DATA{FIO}', '$DATA{PHONE}', \"$DATA{ADDRESS_STREET}\", 
            \"$DATA{ADDRESS_BUILD}\", \"$DATA{ADDRESS_FLAT}\", '$DATA{COUNTRY_ID}',
            '$DATA{EMAIL}', '$DATA{CONTRACT_ID}', '$DATA{CONTRACT_DATE}',
            '$DATA{COMMENTS}',
            '$DATA{PASPORT_NUM}',
            '$DATA{PASPORT_DATE}',
            '$DATA{PASPORT_GRANT}',
            '$DATA{ZIP}',
            '$DATA{CITY}',
            '$DATA{ACCEPT_RULES}', '$DATA{LOCATION_ID}',
            '$sufix'
            $info_fields_val );", 'do');
  
  return $self if ($self->{errno});
  
  $admin->action_add("$DATA{UID}", "ADD PI", { TYPE => 1 });
  return $self;
}



#**********************************************************
#
#**********************************************************
sub attachment_info () {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE  ='';
  
  if ($attr->{ID}) {
  	$WHERE .= " id='$attr->{ID}'";
   }
 
  my $content = (! $attr->{INFO_ONLY}) ? ',content' : '';
 
  my $table = $attr->{TABLE};
 
  $self->query($db,  "SELECT id, filename, 
    content_type, 
    content_size
    $content
   FROM `$table`
   WHERE $WHERE" );

 return $self if ($self->{TOTAL} < 1);

  ($self->{ATTACHMENT_ID},
   $self->{FILENAME}, 
   $self->{CONTENT_TYPE},
   $self->{FILESIZE},
   $self->{CONTENT}
  )= @{ $self->{list}->[0] };


  return $self;
}


#**********************************************************
# Personal inforamtion
# pi()
#**********************************************************
sub pi {
	my $self = shift;
  my ($attr) = @_;
  
  my $UID = ($attr->{UID}) ? $attr->{UID} : $self->{UID};

#Make info fields use
  my $info_fields = '';
  my @info_fields_arr = ();

	my $list = $self->config_list({ PARAM => 'ifu*', SORT => 2 });
  if ($self->{TOTAL} > 0) {
    my %info_fields_hash = ();

    foreach my $line (@$list) {
      if ($line->[0] =~ /ifu(\S+)/) {
    	  push @info_fields_arr, $1;
        $info_fields_hash{$1}="$line->[1]";
      }
     }
    $info_fields = ', '. join(', ', @info_fields_arr) if ($#info_fields_arr > -1);

    $self->{INFO_FIELDS_ARR}  = \@info_fields_arr;
    $self->{INFO_FIELDS_HASH} = \%info_fields_hash;
   }
  
  $self->query($db, "SELECT pi.fio, 
  pi.phone, 
  pi.country_id,
  pi.address_street, 
  pi.address_build,
  pi.address_flat,  
  pi.email,  
  pi.contract_id,
  pi.contract_date,
  pi.contract_sufix,
  pi.comments,
  pi.pasport_num,
  pi.pasport_date,
  pi.pasport_grant,
  pi.zip,
  pi.city,
  pi.accept_rules,
  pi.location_id
  $info_fields
    FROM users_pi pi
    WHERE pi.uid='$UID';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my @INFO_ARR = ();
	  
  ($self->{FIO}, 
   $self->{PHONE}, 
   $self->{COUNTRY_ID}, 
   $self->{ADDRESS_STREET}, 
   $self->{ADDRESS_BUILD}, 
   $self->{ADDRESS_FLAT}, 
   $self->{EMAIL}, 
   $self->{CONTRACT_ID},
   $self->{CONTRACT_DATE},
   $self->{CONTRACT_SUFIX},
   $self->{COMMENTS},
   $self->{PASPORT_NUM},
   $self->{PASPORT_DATE},
   $self->{PASPORT_GRANT},
   $self->{ZIP},
   $self->{CITY},
   $self->{ACCEPT_RULES},
   $self->{LOCATION_ID},
   @INFO_ARR
  )= @{ $self->{list}->[0] };
	
	$self->{INFO_FIELDS_VAL} = \@INFO_ARR;

  my $i = 0;
  foreach my $val (@INFO_ARR) {
  	$self->{$info_fields_arr[$i]}=$val;
  	$self->{'INFO_FIELDS_VAL_'.$i}=$val;
  	$i++;
   }

# if ($self->{LOCATION_ID} > 0 ) {
#   $self->query($db, "select d.id, d.city, d.name, s.name, b.number  
#     FROM users_pi pi 
#     LEFT JOIN builds b ON (b.id=pi.location_id)
#     LEFT JOIN streets s  ON (s.id=b.street_id)
#     LEFT JOIN districts d  ON (d.id=s.district_id)
#     WHERE pi.uid='$UID'");
#   
#    if ($self->{TOTAL} > 0) {
#      ($self->{DISTRICT_ID}, 
#       $self->{CITY}, 
#       $self->{ADDRESS_DISTRICT}, 
#       $self->{ADDRESS_STREET}, 
#       $self->{ADDRESS_BUILD}, 
#      )= @{ $self->{list}->[0] };
#     }
#  }
 if ($self->{LOCATION_ID} > 0 ) {
   $self->query($db, "select d.id, d.city, d.name, s.name, b.number  
     FROM builds b
     LEFT JOIN streets s  ON (s.id=b.street_id)
     LEFT JOIN districts d  ON (d.id=s.district_id)
     WHERE b.id='$self->{LOCATION_ID}'");
   
    if ($self->{TOTAL} > 0) {
      ($self->{DISTRICT_ID}, 
       $self->{CITY}, 
       $self->{ADDRESS_DISTRICT}, 
       $self->{ADDRESS_STREET}, 
       $self->{ADDRESS_BUILD}, 
      )= @{ $self->{list}->[0] };
     }
  }



	return $self;
}

#**********************************************************
# Personal Info change
# pi_change();
#**********************************************************
sub pi_change {
	my $self   = shift;
  my ($attr) = @_;


my %PI_FIELDS = (EMAIL       => 'email',
              FIO            => 'fio',
              PHONE          => 'phone',
              COUNTRY_ID     => 'country_id',
              ADDRESS_BUILD  => 'address_build',
              ADDRESS_STREET => 'address_street',
              ADDRESS_FLAT   => 'address_flat',
              ZIP            => 'zip',
              CITY           => 'city',
              COMMENTS       => 'comments',
              UID            => 'uid',
              CONTRACT_ID    => 'contract_id',
              CONTRACT_DATE  => 'contract_date',
              CONTRACT_SUFIX => 'contract_sufix',
              PASPORT_NUM    => 'pasport_num',
              PASPORT_DATE   => 'pasport_date',
              PASPORT_GRANT  => 'pasport_grant',
              ACCEPT_RULES   => 'accept_rules',
              LOCATION_ID    => 'location_id'
             );


if (! $attr->{SKIP_INFO_FIELDS} ) {
  my $list = $self->config_list({ PARAM => 'ifu*'});
  if ($self->{TOTAL} > 0) {
    foreach my $line (@$list) {
      if ($line->[0] =~ /ifu(\S+)/) {
        my $field_name = $1;
        $PI_FIELDS{$field_name}="$field_name";
        my ($position, $type, $name)=split(/:/, $line->[1]);
        if ($type == 13) {
    	    #attach
    	    if ( ref $attr->{$field_name} eq 'HASH' && $attr->{$field_name}{filename}) {
            $self->attachment_add({
            	TABLE        => $field_name.'_file',
              CONTENT      => $attr->{$field_name}{Contents},
              FILESIZE     => $attr->{$field_name}{Size},
              FILENAME     => $attr->{$field_name}{filename},
              CONTENT_TYPE => $attr->{$field_name}{'Content-Type'}
             });
            $attr->{$field_name}=$self->{INSERT_ID};
           }
          else {
          	delete $attr->{$field_name};
           }
         }
        elsif ($type == 4) {
        	$attr->{$field_name} = 0 if (! $attr->{$field_name});
         }
      }
     }
   }
}

  my ($prefix, $sufix); 
  if ($attr->{CONTRACT_TYPE}) {
  	($prefix, $sufix)=split(/\|/, $attr->{CONTRACT_TYPE});
  	$attr->{CONTRACT_SUFIX}=$sufix;
   }

 $admin->{MODULE}='';

 $self->changes($admin, { CHANGE_PARAM => 'UID',
		                TABLE        => 'users_pi',
		                FIELDS       => \%PI_FIELDS,
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
   CREDIT_DATE    => '0000-00-00',
   REDUCTION      => '0.00', 
   REDUCTION_DATE => '0000-00-00',
   SIMULTANEONSLY => 0, 
   DISABLE        => 0, 
   COMPANY_ID     => 0,
   GID            => 0,
   DISABLE        => 0,
   PASSWORD       => '',
   BILL_ID        => 0,
   EXT_BILL_ID    => 0,
   DOMAIN_ID      => 0
   
   );
 
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

 my $USERS_WHERE = '';
 if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, "g.domain_id='$admin->{DOMAIN_ID}'";
    $USERS_WHERE = "AND u.domain_id='$admin->{DOMAIN_ID}'";
  }


 my $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : ''; 
 
 $self->query($db, "select g.gid, g.name, g.descr, count(u.uid), g.domain_id FROM groups g
        LEFT JOIN users u ON  (u.gid=g.gid $USERS_WHERE) 
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
 
 $self->query($db, "select g.name, g.descr, g.separate_docs, g.domain_id FROM groups g WHERE g.gid='$gid';");

 return $self if ($self->{errno} || $self->{TOTAL} < 1);

 ($self->{G_NAME},
 	$self->{G_DESCRIBE},
 	$self->{SEPARATE_DOCS},
 	$self->{DOMAIN_ID}
 	) = @{ $self->{list}->[0] };
 
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
               CHG        => 'gid',
               SEPARATE_DOCS => 'separate_docs'
               );

 $attr->{CHG}=$gid;
 
 $attr->{SEPARATE_DOCS}=($attr->{SEPARATE_DOCS}) ? 1 : 0;
 
 $self->changes($admin, { CHANGE_PARAM => 'CHG',
		               TABLE        => 'groups',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->group_info($gid),
		               DATA         => $attr,
		               EXT_CHANGE_INFO  => "GID:$gid"
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
 
 $self->query($db, "INSERT INTO groups (gid, name, descr, separate_docs, domain_id)
    values ('$DATA{GID}', '$DATA{G_NAME}', '$DATA{G_DESCRIBE}', '$DATA{SEPARATE_DOCS}', '$admin->{DOMAIN_ID}');", 'do');


 $admin->system_action_add("GID:$DATA{GID}", { TYPE => 1 });
 
 return $self;
}



#**********************************************************
# group_add()
#**********************************************************
sub group_del {
 my $self = shift;
 my ($id) = @_;

 $self->query($db, "DELETE FROM groups WHERE gid='$id';", 'do');
 
 $admin->system_action_add("GID:$id", { TYPE => 10 });    
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

 my $EXT_TABLES = '';

 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 undef @WHERE_RULES;
 my $search_fields = '';

 # Start letter 
 if ($attr->{LOGIN}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }
 elsif ($attr->{UID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'u.uid', { EXT_FIELD => 1 }) };
  }

 if ($CONF->{EXT_BILL_ACCOUNT}) {
   $self->{SEARCH_FIELDS} .= 'if(company.id IS NULL,ext_b.deposit,ext_cb.deposit), ';
   $self->{SEARCH_FIELDS_COUNT}++;
   if ($attr->{EXT_BILL_ID}) {
      my $value = $self->search_expr($attr->{EXT_BILL_ID}, 'INT');
      push @WHERE_RULES, "if(company.id IS NULL,ext_b.id,ext_cb.id)$value";
     }
   $EXT_TABLES = "
            LEFT JOIN bills ext_b ON (u.ext_bill_id = ext_b.id)
            LEFT JOIN bills ext_cb ON  (company.ext_bill_id=ext_cb.id) ";
  }

 if ($attr->{PHONE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PHONE}, 'STR', 'pi.phone', { EXT_FIELD => 1 }) };
  }

 if ($attr->{EMAIL}) { 
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{EMAIL}, 'STR', 'pi.email', { EXT_FIELD => 1 }) }; 
 	}

 if($attr->{NOT_FILLED}) {
 	 push @WHERE_RULES, "builds.id IS NULL";
 	 $EXT_TABLES .= "LEFT JOIN builds ON (builds.id=pi.location_id)";
  }
 elsif ($attr->{LOCATION_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{LOCATION_ID}, 'INT', 'pi.location_id', { EXT_FIELD => 'streets.name, builds.number, pi.address_flat, builds.id' }) };
   $EXT_TABLES .= "LEFT JOIN builds ON (builds.id=pi.location_id)
   LEFT JOIN streets ON (streets.id=builds.street_id)";
   $self->{SEARCH_FIELDS_COUNT}+=3;
  }
 else {
   if ($attr->{STREET_ID}) {
     push @WHERE_RULES, @{ $self->search_expr($attr->{STREET_ID}, 'INT', 'builds.street_id', { EXT_FIELD => 'streets.name, builds.number' }) };
     $EXT_TABLES .= "LEFT JOIN builds ON (builds.id=pi.location_id)
     LEFT JOIN streets ON (streets.id=builds.street_id)";
     $self->{SEARCH_FIELDS_COUNT}+=1;
    }
   elsif ($attr->{DISTRICT_ID}) {
     push @WHERE_RULES, @{ $self->search_expr($attr->{DISTRICT_ID}, 'INT', 'streets.district_id', { EXT_FIELD => 'districts.name' }) };
     $EXT_TABLES .= "LEFT JOIN builds ON (builds.id=pi.location_id)
      LEFT JOIN streets ON (streets.id=builds.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
    }
   elsif ($CONF->{ADDRESS_REGISTER}) {
     if ($attr->{ADDRESS_STREET}) {
       push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_STREET}, 'STR', 'streets.name', { EXT_FIELD => 'streets.name' }) };
       $EXT_TABLES .= "INNER JOIN builds ON (builds.id=pi.location_id)
        INNER JOIN streets ON (streets.id=builds.street_id)";
      }
    }
   elsif ($attr->{ADDRESS_STREET}) {
     push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_STREET}, 'STR', 'pi.address_street', { EXT_FIELD => 1 }) };
    }


   if ($CONF->{ADDRESS_REGISTER}) {
     if ($attr->{ADDRESS_BUILD}) {
       push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_BUILD}, 'STR', 'builds.number', { EXT_FIELD => 'builds.number' }) };
       $EXT_TABLES .= "INNER JOIN builds ON (builds.id=pi.location_id)" if ($EXT_TABLES !~ /builds/);
      }
    }
   elsif ($attr->{ADDRESS_BUILD}) {
     push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_BUILD}, 'STR', 'pi.address_build', { EXT_FIELD => 1 }) };
    } 

   if ($attr->{COUNTRY_ID}) {
     push @WHERE_RULES, @{ $self->search_expr($attr->{COUNTRY_ID}, 'STR', 'pi.country_id', { EXT_FIELD => 1 }) };
   }
  }

 if ($attr->{ADDRESS_FLAT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_FLAT}, 'STR', 'pi.address_flat', { EXT_FIELD => 1 }) };
  }


 if ($attr->{PASPORT_DATE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PASPORT_DATE}, 'DATE', 'pi.pasport_date', { EXT_FIELD => 1 }) };
  }

 if ($attr->{PASPORT_NUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PASPORT_NUM}, 'STR', 'pi.pasport_num', { EXT_FIELD => 1 }) };
  }

 if ($attr->{PASPORT_GRANT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PASPORT_GRANT}, 'STR', 'pi.pasport_grant', { EXT_FIELD => 1 }) };
  }

 if ($attr->{CITY}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{CITY}, 'STR', 'pi.city', { EXT_FIELD => 1 }) };
  }

 if ($attr->{ZIP}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{ZIP}, 'STR', 'pi.zip', { EXT_FIELD => 1}) }; 
  }

 if ($attr->{CONTRACT_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{CONTRACT_ID}, 'STR', 'pi.contract_id', { EXT_FIELD => 1}) };  
  }

 if ($attr->{CONTRACT_SUFIX}) {
 	 $attr->{CONTRACT_SUFIX}=~s/\|//g;
   push @WHERE_RULES, @{ $self->search_expr($attr->{CONTRACT_SUFIX}, 'STR', 'pi.contract_sufix', { EXT_FIELD => 1 }) }; 
  }

 if ($attr->{CONTRACT_DATE}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{CONTRACT_DATE}", 'DATE', 'pi.contract_date', { EXT_FIELD => 1 }) };
  }

 if ($attr->{DOMAIN_ID}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{DOMAIN_ID}", 'INT', 'u.domain_id', { EXT_FIELD => 1 }) };
  }
 elsif (defined($admin->{DOMAIN_ID})) {
 	 push @WHERE_RULES, @{ $self->search_expr("$admin->{DOMAIN_ID}", 'INT', 'u.domain_id', { EXT_FIELD => 0 }) };
  }

 if ($attr->{REGISTRATION}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{REGISTRATION}", 'INT', 'u.registration', { EXT_FIELD => 1 }) };
  }

 if ($attr->{DEPOSIT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DEPOSIT}, 'INT', 'b.deposit') }; 
  }

 if ($attr->{CREDIT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{CREDIT}, 'INT', 'u.credit') };
  }

 if ($attr->{CREDIT_DATE}) {
    push @WHERE_RULES,  @{ $self->search_expr($attr->{CREDIT_DATE}, 'DATE', 'u.credit_date', { EXT_FIELD => 1 }) };
  }

 if ($attr->{REDUCTION}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{REDUCTION}, 'INT', 'u.reduction', { EXT_FIELD => 1 }) };
  }

 if ($attr->{REDUCTION_DATE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{REDUCTION_DATE}, 'INT', 'u.reduction_date', { EXT_FIELD => 1 }) };
  }

 if ($attr->{COMMENTS}) {
   push @WHERE_RULES,  @{ $self->search_expr($attr->{COMMENTS}, 'STR', 'pi.comments', { EXT_FIELD => 1 }) };
  }

 if ($attr->{BILL_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{BILL_ID}, 'INT', 'if(company.id IS NULL,b.id,cb.id)', { EXT_FIELD => 1 }) };
  }    

 if ($attr->{FIO}) {
   push @WHERE_RULES,  @{ $self->search_expr($attr->{FIO}, 'STR', 'pi.fio') };
  }
 # Show debeters
 if ($attr->{DEBETERS}) {
   push @WHERE_RULES, "b.deposit<0";
  }

 if ($attr->{COMPANY_ID}) {
   push @WHERE_RULES,  @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'u.company_id') };
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
 if (defined($attr->{GID}) && $attr->{GID} ne '') {
   push @WHERE_RULES,  @{ $self->search_expr($attr->{GID}, 'INT', 'u.gid', { EXT_FIELD => 1 }) };
  }

#Activate
 if ($attr->{ACTIVATE}) {
  push @WHERE_RULES,  @{ $self->search_expr($attr->{ACTIVATE}, 'INT', 'u.activate', { EXT_FIELD => 1 })  };
 }

#DIsable
 if (defined($attr->{DISABLE}) && $attr->{DISABLE} ne '') {
   push @WHERE_RULES, "u.disable='$attr->{DISABLE}'"; 
  }

#Expire
 if ($attr->{EXPIRE}) {
   push @WHERE_RULES,  @{ $self->search_expr($attr->{EXPIRE}, 'INT', 'u.expire', { EXT_FIELD => 1 })  };
  }

 if ($attr->{ACTIVE}) {
 	 push @WHERE_RULES,  "(u.expire<curdate() or u.expire='0000-00-00') and u.credit + if(company.id IS NULL, b.deposit, cb.deposit) > 0 and u.disable=0 ";
  }
 
 if ((! $admin->{permissions}->{0}->{8})
  || ($attr->{USER_STATUS} && ! $attr->{DELETED})
  ){
	 push @WHERE_RULES,  @{ $self->search_expr(0, 'INT', 'u.deleted', { EXT_FIELD => 1 })  };
  }
 elsif ($attr->{DELETED}) {
 	 push @WHERE_RULES,  @{ $self->search_expr("$attr->{DELETED}", 'INT', 'u.deleted', { EXT_FIELD => 1 })  };
  }

#Info fields
my $list = $self->config_list({ PARAM => 'ifu*', SORT => 2 });

if ($self->{TOTAL} > 0) {
    foreach my $line (@$list) {
      if ($line->[0] =~ /ifu(\S+)/) {
        my $field_name = $1;
        my ($position, $type, $name)=split(/:/, $line->[1]);

        if (defined($attr->{$field_name}) && $type == 4) {
     	    push @WHERE_RULES, 'pi.'. $field_name ."='$attr->{$field_name}'"; 
         }
        #Skip for bloab
        elsif ($type == 5) {
        	next;
         }
        elsif ($attr->{$field_name}) {
          if ($type == 1) {
        	  my $value = $self->search_expr("$attr->{$field_name}", 'INT');
            push @WHERE_RULES, "(pi.". $field_name. "$value)"; 
           }
          elsif ($type == 2)  {
          	push @WHERE_RULES, "(pi.$field_name='$attr->{$field_name}')"; 
            $self->{SEARCH_FIELDS} .= "$field_name" . '_list.name, ';
            $self->{SEARCH_FIELDS_COUNT}++;
            
            $EXT_TABLES .= "
            LEFT JOIN $field_name" ."_list ON (pi.$field_name = $field_name" ."_list.id)";            
          	next;
           }
          else {
    	      $attr->{$field_name} =~ s/\*/\%/ig;
            push @WHERE_RULES, "pi.$field_name LIKE '$attr->{$field_name}'"; 
           }
          $self->{SEARCH_FIELDS} .= "pi.$field_name, ";
          $self->{SEARCH_FIELDS_COUNT}++;
         }

       }
     }
  $self->{EXTRA_FIELDS}=$list;
 }


#Show last paymenst
 if ($attr->{PAYMENTS} || $attr->{PAYMENT_DAYS}) {    
    my @HAVING_RULES = @WHERE_RULES;
    if($attr->{PAYMENTS}) {
      my $value = $self->search_expr($attr->{PAYMENTS}, 'INT');
      push @WHERE_RULES, "p.date$value";
      push @HAVING_RULES, "max(p.date)$value";
      $self->{SEARCH_FIELDS} .= 'max(p.date), ';
      $self->{SEARCH_FIELDS_COUNT}++;
     }
    elsif($attr->{PAYMENT_DAYS}) {
      my $value = "curdate() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
      $value =~ s/([<>=]{1,2})//g;
      $value = $1 . $value;

      push @WHERE_RULES, "p.date$value";
      push @HAVING_RULES, "max(p.date)$value";
      $self->{SEARCH_FIELDS} .= 'max(p.date), ';
      $self->{SEARCH_FIELDS_COUNT}++;
     }

    my $HAVING = ($#WHERE_RULES > -1) ?  "HAVING " . join(' and ', @HAVING_RULES) : '';


   
    $self->query($db, "SELECT u.id, 
       pi.fio, 
       if(company.id IS NULL, b.deposit, cb.deposit), 
       if(u.company_id=0, u.credit, 
          if (u.credit=0, company.credit, u.credit)), u.disable, 
       $self->{SEARCH_FIELDS}
       u.uid, 
       u.company_id, 
       pi.email, 
       u.activate, 
       u.expire,
       u.gid,
       b.deposit,
       u.domain_id
     FROM users u
     LEFT JOIN payments p ON (u.uid = p.uid)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     $EXT_TABLES
     GROUP BY u.uid     
     $HAVING 

     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");
   return $self if($self->{errno});

   my $list = $self->{list};

   if ($self->{TOTAL} > 0) {
     if ($attr->{PAYMENT}) {
       $WHERE_RULES[$#WHERE_RULES]=@{ $self->search_expr($attr->{PAYMENTS}, 'INT', 'p.date') };
      }
     elsif($attr->{PAYMENT_DAYS}) {
      my $value = "curdate() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
      $value =~ s/([<>=]{1,2})//g;
      $value = $1 . $value;
      $WHERE_RULES[$#WHERE_RULES]="p.date$value";
      }
    
     $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : '';
    
     $self->query($db, "SELECT count(DISTINCT u.uid) FROM users u 
       LEFT JOIN payments p ON (u.uid = p.uid)
       LEFT JOIN users_pi pi ON (u.uid = pi.uid)
       LEFT JOIN bills b ON (u.bill_id = b.id)
      $WHERE;");
      if ($self->{TOTAL} > 0) {
        ($self->{TOTAL}) = @{ $self->{list}->[0] };
       }
    }

 	  return $list
  }
 #Show last fees
 if ($attr->{FEES} || $attr->{FEES_DAYS}) {
    my @HAVING_RULES = @WHERE_RULES;
    if($attr->{PAYMENTS}) {
      my $value = $self->search_expr($attr->{FEES}, 'INT');
      push @WHERE_RULES, "f.date$value";
      push @HAVING_RULES, "max(f.date)$value";
      $self->{SEARCH_FIELDS} .= 'max(f.date), ';
      $self->{SEARCH_FIELDS_COUNT}++;
     }
    elsif($attr->{FEES_DAYS}) {
      my $value = "curdate() - INTERVAL $attr->{FEES_DAYS} DAY";
      $value =~ s/([<>=]{1,2})//g;
      $value = $1 . $value;

      push @WHERE_RULES, "p.date$value";
      push @HAVING_RULES, "max(f.date)$value";
      $self->{SEARCH_FIELDS} .= 'max(f.date), ';
      $self->{SEARCH_FIELDS_COUNT}++;
     }

    my $HAVING = ($#WHERE_RULES > -1) ?  "HAVING " . join(' and ', @HAVING_RULES) : '';
   
    $self->query($db, "SELECT u.id, 
       pi.fio, 
       if(company.id IS NULL, b.deposit, cb.deposit), 
       if(u.company_id=0, u.credit, 
          if (u.credit=0, company.credit, u.credit)), u.disable, 
       $self->{SEARCH_FIELDS}
       u.uid, 
       u.company_id, 
       pi.email, 
       u.activate, 
       u.expire,
       u.gid,
       b.deposit,
       u.domain_id
     FROM users u
     LEFT JOIN fees f ON (u.uid = f.uid)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     $EXT_TABLES
     GROUP BY u.uid     
     $HAVING 

     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");
   return $self if($self->{errno});

   my $list = $self->{list};

   if ($self->{TOTAL} > 0) {
     if ($attr->{FEES}) {
       $WHERE_RULES[$#WHERE_RULES]=@{ $self->search_expr($attr->{PAYMENTS}, 'INT', 'f.date') };
      }
     elsif($attr->{FEES_DAYS}) {
      my $value = "curdate() - INTERVAL $attr->{FEES_DAYS} DAY";
      $value =~ s/([<>=]{1,2})//g;
      $value = $1 . $value;
      $WHERE_RULES[$#WHERE_RULES]="f.date$value";
      }
    
     $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : '';
    
     $self->query($db, "SELECT count(DISTINCT u.uid) FROM users u 
       LEFT JOIN fees f ON (u.uid = f.uid)
       LEFT JOIN users_pi pi ON (u.uid = pi.uid)
       LEFT JOIN bills b ON (u.bill_id = b.id)
      $WHERE;");
      if ($self->{TOTAL} > 0) {
        ($self->{TOTAL}) = @{ $self->{list}->[0] };
       }
    }

 	  return $list
  }
 
 $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : '';
 $self->query($db, "SELECT u.id, 
      pi.fio, if(company.id IS NULL,b.deposit,cb.deposit), 
             if(u.company_id=0, u.credit,
      if (u.credit=0, company.credit, u.credit)),
      u.disable, 
      $self->{SEARCH_FIELDS}
      u.uid, u.company_id, pi.email, u.activate, u.expire
     FROM users u
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     $EXT_TABLES
     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno}); 

 $list = $self->{list};

 if ($self->{TOTAL} == $PAGE_ROWS || $PG > 0 || $attr->{FULL_LIST}) {
    $self->query($db, "SELECT count(u.id), 
     sum(if(u.expire<curdate() AND u.expire<>'0000-00-00', 1, 0)), 
     sum(u.disable),
     sum(u.deleted)
     FROM users u 
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON u.bill_id = b.id
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     $EXT_TABLES
    $WHERE");
    ($self->{TOTAL}, 
     $self->{TOTAL_EXPIRED}, 
     $self->{TOTAL_DISABLED}, 
     $self->{TOTAL_DELETED}) = @{ $self->{list}->[0] };
   }

  return $list;
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
    if ($DATA{EMAIL} !~ /(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }
  
  $DATA{DISABLE} = int($DATA{DISABLE});
  my $registration = ($DATA{REGISTRATION}) ? "'$DATA{REGISTRATION}'" : 'now()';

  $self->query($db,  "INSERT INTO users (uid, id, activate, expire, credit, reduction, 
           registration, disable, company_id, gid, password, credit_date, reduction_date, domain_id)
           VALUES ('$DATA{UID}', '$DATA{LOGIN}', '$DATA{ACTIVATE}', '$DATA{EXPIRE}', '$DATA{CREDIT}', '$DATA{REDUCTION}', 
           $registration,  '$DATA{DISABLE}', 
           '$DATA{COMPANY_ID}', '$DATA{GID}', 
           ENCODE('$DATA{PASSWORD}', '$CONF->{secretkey}'), '$DATA{CREDIT_DATE}', '$DATA{REDUCTION_DATE}', '$admin->{DOMAIN_ID}'
           );", 'do');
  
  return $self if ($self->{errno});
  
  $self->{UID}   = $self->{INSERT_ID};
  $self->{LOGIN} = $DATA{LOGIN};
  
  $admin->{MODULE}='';
  $admin->action_add("$self->{UID}", "LOGIN:$DATA{LOGIN}", { TYPE => 7 });

  if ($attr->{CREATE_BILL}) {
  	$self->change($self->{UID}, { 
  		 DISABLE     => int($DATA{DISABLE}),
  		 UID         => $self->{UID},
  		 CREATE_BILL => 1,
  		 CREATE_EXT_BILL  => $attr->{CREATE_EXT_BILL} });
    
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
              CREDIT_DATE => 'credit_date',
              REDUCTION   => 'reduction',
              REDUCTION_DATE => 'reduction_date',  
              SIMULTANEONSLY => 'logins',
              COMMENTS    => 'comments',
              COMPANY_ID  => 'company_id',
              DISABLE     => 'disable',
              GID         => 'gid',
              PASSWORD    => 'password',
              BILL_ID     => 'bill_id',
              EXT_BILL_ID => 'ext_bill_id',              
              DOMAIN_ID   => 'domain_id',
              DELETED     => 'deleted'
             );

  my $old_info = $self->info($attr->{UID});

  if($attr->{CREATE_BILL}) {
  	 use Bills;
  	 my $Bill = Bills->new($db, $admin, $CONF);
  	 $Bill->create({ UID => $self->{UID} });
     if($Bill->{errno}) {
       $self->{errno}  = $Bill->{errno};
       $self->{errstr} =  $Bill->{errstr};
       return $self;
      }
     $attr->{BILL_ID}=$Bill->{BILL_ID};
     $attr->{DISABLE}=$old_info->{DISABLE};
     
     if ($attr->{CREATE_EXT_BILL}) {
    	 $Bill->create({ UID => $self->{UID} });
       if($Bill->{errno}) {
         $self->{errno}  = $Bill->{errno};
         $self->{errstr} =  $Bill->{errstr};
         return $self;
        }
       $attr->{EXT_BILL_ID}=$Bill->{BILL_ID};
      }
   }
  elsif ($attr->{CREATE_EXT_BILL}) {

  	   use Bills;
  	   my $Bill = Bills->new($db, $admin, $CONF);
    	 $Bill->create({ UID => $self->{UID} });
       $attr->{DISABLE}=$old_info->{DISABLE};

       if($Bill->{errno}) {
         $self->{errno}  = $Bill->{errno};
         $self->{errstr} =  $Bill->{errstr};
         return $self;
        }
       $attr->{EXT_BILL_ID}=$Bill->{BILL_ID};
   }
 
  if (defined($attr->{CREDIT}) && $attr->{CREDIT} == 0) {
     $attr->{CREDIT_DATE}='0000-00-00';
   }
  if (defined($attr->{REDUCTION}) && $attr->{REDUCTION} == 0) {
     $attr->{REDUCTION_DATE} = '0000-00-00';
   }
 
  if (! defined($attr->{DISABLE})) {
  	$attr->{DISABLE}=0;
   }
 
  #Make extrafields use
  $admin->{MODULE}='';
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

  if ($attr->{FULL_DELETE}) {
    my @clear_db = ('admin_actions', 
                  'fees', 
                  'payments', 
                  'users_nas', 
                  'users',
                  'users_pi');


    $self->{info}='';
    foreach my $table (@clear_db) {
      $self->query($db, "DELETE from $table WHERE uid='$self->{UID}';", 'do');
      $self->{info} .= "$table, ";
     }

    $admin->{MODULE}='';
    $admin->action_add($self->{UID}, "DELETE $self->{UID}:$self->{LOGIN}", {  TYPE => 12 });
   }
  else {
  	$self->change($self->{UID}, { DELETED => 1, UID => $self->{UID}  });
   }

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

  my $WHERE = "";

  if ($attr->{DATE}) {
  	$WHERE = "datetime < $attr->{DATE}";
   }
	else {
		$WHERE = "login='$attr->{LOGIN}'";
	 }
	
  $self->query($db,  "DELETE FROM users_bruteforce
	 WHERE $WHERE;", 'do');

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

#**********************************************************
#
#**********************************************************
sub info_field_add {
  my $self = shift;	
	my ($attr) = @_;

	my @column_types = (" varchar(120) not null default ''",
	                    " int(11) NOT NULL default '0'",
	                    " smallint unsigned NOT NULL default '0' ",
	                    " text not null ",
	                    " tinyint(11) NOT NULL default '0' ",
	                    " content longblob NOT NULL",
	                    " varchar(100) not null default ''",
	                    " int(11) unsigned NOT NULL default '0'",
	                    " varchar(12) not null default ''",
	                    " varchar(120) not null default ''",
	                    " varchar(20) not null default ''",
	                    " varchar(50) not null default ''",
	                    " varchar(50) not null default ''",
	                    " int unsigned NOT NULL default '0' ",
	                    );
	
	$attr->{FIELD_TYPE} = 0 if (! $attr->{FIELD_TYPE});

	my $column_type = $column_types[$attr->{FIELD_TYPE}];
	my $field_prefix = 'ifu';

  #Add field to table
  if ($attr->{COMPANY_ADD}) {
  	$field_prefix='ifc';
  	$self->query($db, "ALTER TABLE companies ADD COLUMN _". $attr->{FIELD_ID} ." $column_type;", 'do');
   }	
	else {
	  $self->query($db, "ALTER TABLE users_pi ADD COLUMN _". $attr->{FIELD_ID}." $column_type;", 'do');
   }

  if (! $self->{errno}) {
    if ($attr->{FIELD_TYPE}==2) {
       $self->query($db, "CREATE TABLE _$attr->{FIELD_ID}_list (
       id smallint unsigned NOT NULL primary key auto_increment,
       name varchar(120) not null default 0
       )DEFAULT CHARSET=$CONF->{dbcharset};", 'do');    	
     }
    elsif ($attr->{FIELD_TYPE}==13) {
       $self->query($db, "CREATE TABLE `_$attr->{FIELD_ID}_file` (`id` int(11) unsigned NOT NULL PRIMARY KEY auto_increment,
         `filename` varchar(250) not null default '',
         `content_size` varchar(30) not null  default '',
         `content_type` varchar(250) not null default '',
         `content` longblob NOT NULL,
         `create_time` datetime NOT NULL default '0000-00-00 00:00:00') DEFAULT CHARSET=$CONF->{dbcharset};", 'do');    	
     }

    $self->config_add({ PARAM => $field_prefix. "_$attr->{FIELD_ID}", 
  	                    VALUE => "$attr->{POSITION}:$attr->{FIELD_TYPE}:$attr->{NAME}"
  	                    });

   }

	return $self;
}


#**********************************************************
#
#**********************************************************
sub info_field_del {
  my $self = shift;	
	my ($attr) = @_;
	

  my $sql = '';	
	if ($attr->{SECTION} eq 'ifc') {
    $sql="ALTER TABLE companies DROP COLUMN $attr->{FIELD_ID};";
   }
  else {
  	$sql="ALTER TABLE users_pi DROP COLUMN $attr->{FIELD_ID};";
   }

  $self->query($db,  $sql, 'do');

  if (! $self->{errno} ||  $self->{errno} == 3) {
  	$self->config_del("$attr->{SECTION}$attr->{FIELD_ID}");
   }

	return $self;
}


#**********************************************************
#
#**********************************************************
sub info_list_add {
  my $self = shift;	
	my ($attr) = @_;
	
  $self->query($db,  "INSERT INTO $attr->{LIST_TABLE} (name) VALUES ('$attr->{NAME}');", 'do');

	return $self;
}


#**********************************************************
#
#**********************************************************
sub info_list_del {
  my $self = shift;	
	my ($attr) = @_;
	
  $self->query($db,  "DELETE FROM $attr->{LIST_TABLE} WHERE id='$attr->{ID}';", 'do');

	return $self;
}


#**********************************************************
#
#**********************************************************
sub info_lists_list {
  my $self = shift;	
	my ($attr) = @_;

  $self->query($db,  "SELECT id, name FROM $attr->{LIST_TABLE} ORDER BY name;");

	return $self->{list};
}


#**********************************************************
# info_list__info()
#**********************************************************
sub info_list_info {
 my $self = shift;
 my ($id, $attr) = @_;
 
 $self->query($db, "select id, name FROM $attr->{LIST_TABLE} WHERE id='$id';");

 return $self if ($self->{errno} || $self->{TOTAL} < 1);

 ($self->{ID},
 	$self->{NAME}) = @{ $self->{list}->[0] };

 return $self;
}


#**********************************************************
# info_list_change()
#**********************************************************
sub info_list_change {
  my $self = shift;
  my ($id, $attr) = @_;
  
  my %FIELDS = (ID         => 'id',
                NAME       => 'name'
             );

  my $old_info = $self->info_list_info($id, { LIST_TABLE => $attr->{LIST_TABLE} });

	$self->changes($admin, { CHANGE_PARAM => 'ID',
		                TABLE        => $attr->{LIST_TABLE},
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $old_info,
		                DATA         => $attr
		              } );

  return $self->{result};
}


#**********************************************************
# groups_list()
#**********************************************************
sub config_list {
 my $self = shift;
 my ($attr) = @_;

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my @WHERE_RULES = ();

 if ($attr->{PARAM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PARAM}, 'STR', 'param') };
  }
 
 if ($attr->{VALUE}) {
    $attr->{VALUE} =~ s/\*/\%/ig;
    push @WHERE_RULES, "value LIKE '$attr->{VALUE}'";
  }

 push @WHERE_RULES, 'domain_id=\''.($admin->{DOMAIN_ID} || $attr->{DOMAIN_ID} || 0).'\'';

 my $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : ''; 
 
 $self->query($db, "SELECT param, value FROM config $WHERE ORDER BY $SORT $DESC");
 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*) FROM config $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

 return $list;
}


#**********************************************************
# config_info()
#**********************************************************
sub config_info {
 my $self = shift;
 my ($attr) = @_;

 $attr->{DOMAIN_ID}=0 if (! $attr->{DOMAIN_ID});
 
 $self->query($db, "select param, value, domain_id FROM config WHERE param='$attr->{PARAM}' AND domain_id='$attr->{DOMAIN_ID}';");

 return $self if ($self->{errno} || $self->{TOTAL} < 1);

 ($self->{PARAM},
 	$self->{VALUE},
 	$self->{DOMAIN_ID},
 	) = @{ $self->{list}->[0] };

 return $self;
}

#**********************************************************
# group_info()
#**********************************************************
sub config_change {
 my $self = shift;
 my ($param, $attr) = @_;

 my %FIELDS = (PARAM     => 'param',
               NAME      => 'value',
               DOMAIN_ID => 'DOMAIN_ID');

 $self->changes($admin, { CHANGE_PARAM => 'PARAM',
		               TABLE        => 'config',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->config_info({ PARAMS => $param, DOMAIN_ID => $attr->{DOMAIN_ID} }),
		               DATA         => $attr,
		               %$attr
		              } );


 return $self;
}

#**********************************************************
# group_add()
#**********************************************************
sub config_add {
 my $self = shift;
 my ($attr) = @_;

 $self->query($db, "INSERT INTO config (param, value, domain_id) values ('$attr->{PARAM}', '$attr->{VALUE}', '$attr->{DOMAIN_ID}');", 'do');

 return $self;
}

#**********************************************************
# group_add()
#**********************************************************
sub config_del {
 my $self = shift;
 my ($id) = @_;

 $self->query($db, "DELETE FROM config WHERE param='$id';", 'do');
 return $self;
}

#**********************************************************
# district_list()
#**********************************************************
sub district_list {
 my $self = shift;
 my ($attr) = @_;

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my @WHERE_RULES = ();

 if ($attr->{ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{ID}, 'INT', 'd.id') };
  }

 if ($attr->{NAME}) {
 	  push @WHERE_RULES, @{ $self->search_expr($attr->{NAME}, 'STR', 'd.name') };
  }
 
 if ($attr->{COMMENTS}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{COMMENTS}, 'STR', 'd.comments') };
  }

 my $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : ''; 
 
 $self->query($db, "SELECT d.id, d.name, d.country, d.city, zip, count(s.id), d.coordx, d.coordy, d.zoom FROM districts d
     LEFT JOIN streets s ON (d.id=s.district_id)
   $WHERE 
   GROUP BY d.id
   ORDER BY $SORT $DESC");

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*) FROM districts d $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

 return $list;
}


#**********************************************************
# district_info()
#**********************************************************
sub district_info {
 my $self = shift;
 my ($attr) = @_;
 
 $self->query($db, "select id, name, country, 
 city, zip, comments, coordx, coordy, zoom
  FROM districts WHERE id='$attr->{ID}';");

 return $self if ($self->{errno} || $self->{TOTAL} < 1);

 ($self->{ID},
  $self->{NAME},
  $self->{COUNTRY},
  $self->{CITY},
  $self->{ZIP},
 	$self->{COMMENTS},
 	$self->{COORDX},
 	$self->{COORDY},
 	$self->{ZOOM},
 	) = @{ $self->{list}->[0] };

 return $self;
}

#**********************************************************
# district_info()
#**********************************************************
sub district_change {
 my $self = shift;
 my ($id, $attr) = @_;

 my %FIELDS = (ID       => 'id',
               NAME     => 'name',
               COUNTRY  => 'country',
               CITY     => 'city',
               ZIP      => 'zip',
               COMMENTS => 'comments',
               COORDX   => 'coordx',
               COORDY   => 'coordy',
               ZOOM     => 'zoom',               
               );

 $self->changes($admin, { CHANGE_PARAM => 'ID',
		               TABLE        => 'districts',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->district_info({ ID => $id }),
		               DATA         => $attr
		              } );

 return $self;
}

#**********************************************************
# district_add()
#**********************************************************
sub district_add {
 my $self = shift;
 my ($attr) = @_;

 $self->query($db, "INSERT INTO districts (name, country, city, zip, comments, coordx, coordy, zoom) 
   values ('$attr->{NAME}', '$attr->{COUNTRY}', '$attr->{CITY}', '$attr->{ZIP}',  '$attr->{COMMENTS}',
   '$attr->{COORDX}', '$attr->{COORDY}','$attr->{ZOOM}');", 'do');

 $admin->system_action_add("DISTRICT:$self->{INSERT_ID}:$attr->{NAME}", { TYPE => 1 }) if (! $self->{errno});
 return $self;
}

#**********************************************************
# district_del()
#**********************************************************
sub district_del {
 my $self = shift;
 my ($id) = @_;

 $self->query($db, "DELETE FROM districts WHERE id='$id';", 'do');

 $admin->system_action_add("DISTRICT:$id", { TYPE => 10 }) if (! $self->{errno});
 return $self;
}



#**********************************************************
# street_list()
#**********************************************************
sub street_list {
 my $self = shift;
 my ($attr) = @_;


 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 @WHERE_RULES = ();
 
 if ($attr->{NAME}) {
	 push @WHERE_RULES, @{ $self->search_expr($attr->{NAME}, 'STR', 's.name') };
  }

 if ($attr->{DISTRICT_ID}) {
	 push @WHERE_RULES, @{ $self->search_expr($attr->{DISTRICT_ID}, 'INT', 's.district_id') };
  }

 my $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : ''; 

 my $EXT_TABLE        = '';
 my $EXT_FIELDS       = '';
 my $EXT_TABLE_TOTAL  = '';
 my $EXT_FIELDS_TOTAL = '';
 if ($attr->{USERS_INFO} && ! $admin->{MAX_ROWS}) {
 	 $EXT_TABLE = 'LEFT JOIN users_pi pi ON (b.id=pi.location_id)';
   $EXT_FIELDS = ', count(pi.uid)';
   $EXT_TABLE_TOTAL  = 'LEFT JOIN builds b ON (b.street_id=s.id) LEFT JOIN users_pi pi ON (b.id=pi.location_id)';
   $EXT_FIELDS_TOTAL = ', count(DISTINCT b.id), count(pi.uid), sum(b.flats) / count(pi.uid)';
  }


 my $sql = "SELECT s.id, s.name, d.name, count(DISTINCT b.id) $EXT_FIELDS FROM streets s
  LEFT JOIN districts d ON (s.district_id=d.id)
  LEFT JOIN builds b ON (b.street_id=s.id)
  $EXT_TABLE 
  $WHERE 
  GROUP BY s.id
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;";

 $self->query($db, $sql);

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
 	 my $sql = "SELECT count(DISTINCT s.id) $EXT_FIELDS_TOTAL FROM streets s 
     $EXT_TABLE_TOTAL  $WHERE";
 	 #my $sql = "SELECT count(DISTINCT s.id) , count(DISTINCT builds.id), count(users_pi.uid), sum(builds.flats) / count(users_pi.uid) FROM users_pi
#LEFT JOIN builds ON (builds.id=users_pi.location_id) LEFT JOIN streets  s ON (builds.street_id=s.id) $WHERE";
    $self->query($db, $sql);
    ($self->{TOTAL},
     $self->{TOTAL_BUILDS},
     $self->{TOTAL_USERS},
     $self->{DENSITY_OF_CONNECTIONS}
    ) = @{ $self->{list}->[0] };
   }

 return $list;
}


#**********************************************************
# street_info()
#**********************************************************
sub street_info {
 my $self = shift;
 my ($attr) = @_;
 
 $self->query($db, "select id, name, district_id FROM streets WHERE id='$attr->{ID}';");

 return $self if ($self->{errno} || $self->{TOTAL} < 1);

 ($self->{ID},
 	$self->{NAME},
 	$self->{DISTRICT_ID}
 	) = @{ $self->{list}->[0] };

 return $self;
}

#**********************************************************
# street_change()
#**********************************************************
sub street_change {
 my $self = shift;
 my ($id, $attr) = @_;

 my %FIELDS = (ID          => 'id',
               NAME        => 'name',
               DISTRICT_ID => 'district_id');

 $self->changes($admin, { CHANGE_PARAM => 'ID',
		               TABLE        => 'streets',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->street_info({ ID => $id }),
		               DATA         => $attr
		              } );

 return $self;
}



#**********************************************************
# street_add()
#**********************************************************
sub street_add {
 my $self = shift;
 my ($attr) = @_;

 $self->query($db, "INSERT INTO streets (name, district_id) values ('$attr->{NAME}', '$attr->{DISTRICT_ID}');", 'do');

 $admin->system_action_add("STREET:$self->{INSERT_ID}:$attr->{NAME}", { TYPE => 1 }) if (! $self->{errno});
 return $self;
}


#**********************************************************
# street_del()
#**********************************************************
sub street_del {
 my $self = shift;
 my ($id) = @_;

 $self->query($db, "DELETE FROM streets WHERE id='$id';", 'do');

 $admin->system_action_add("STREET:$id", { TYPE => 10 }) if (! $self->{errno});
 return $self;
}



#**********************************************************
# build_list()
#**********************************************************
sub build_list {
 my $self = shift;
 my ($attr) = @_;


 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 if ($SORT == 1 && $DESC eq '') {
 	 $SORT = "length(b.number), b.number";
  }

 @WHERE_RULES = ();
 
 if ($attr->{NUMBER}) {
	 push @WHERE_RULES, @{ $self->search_expr($attr->{NUMBER}, 'STR', 'b.number') };
  }

 if ($attr->{DISTRICT_ID}) {
	 push @WHERE_RULES, @{ $self->search_expr($attr->{DISTRICT_ID}, 'INT', 's.district_id') };
  }

 if ($attr->{STREET_ID}) {
	 push @WHERE_RULES, @{ $self->search_expr($attr->{STREET_ID}, 'INT', 'b.street_id') };
  }

 if ($attr->{FLORS}) {
	 push @WHERE_RULES, @{ $self->search_expr($attr->{FLORS}, 'INT', 'b.flors') };
  }

 if ($attr->{ENTRANCES}) {
	 push @WHERE_RULES, @{ $self->search_expr($attr->{ENTRANCES}, 'INT', 'b.entrances') };
  }

 my $ext_fields = '';
 if ($attr->{SHOW_MAPS}) {
   $ext_fields = ",b.map_x, b.map_y, b.map_x2, b.map_y2, b.map_x3, b.map_y3, b.map_x4, b.map_y4";
  }
 elsif($attr->{SHOW_MAPS_GOOGLE}) {
   $ext_fields = ",b.coordx, b.coordy";
   push @WHERE_RULES, "(b.coordx<>0 and b.coordy)";
  }

 my $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : ''; 
 my $sql = '';
 if ($attr->{CONNECTIONS}) {
	 $sql = "SELECT b.number, b.flors, b.entrances, b.flats, s.name, 
     count(pi.uid), ROUND((count(pi.uid) / b.flats * 100), 0),
	   b.added, b.id $ext_fields	   
	   
	    FROM builds b
     LEFT JOIN streets s ON (s.id=b.street_id)
     LEFT JOIN users_pi pi ON (b.id=pi.location_id)
     $WHERE 
     GROUP BY b.id
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS    
     ;";
  }
 else {
 	 $sql = "SELECT b.number, b.flors, b.entrances, b.flats, s.name, b.added, b.id $ext_fields FROM builds b
     LEFT JOIN streets s ON (s.id=b.street_id)
     $WHERE ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;";
  }

 $self->query($db, "$sql");
 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*) FROM builds b 
    LEFT JOIN streets s ON (s.id=b.street_id)
    $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }
 return $list;
}


#**********************************************************
# build_info()
#**********************************************************
sub build_info {
 my $self = shift;
 my ($attr) = @_;
 
 $self->query($db, "select id, 
   number, 
   street_id,
   flors,
   entrances,
   flats,
   added,
   map_x,
   map_y,
   map_x2,
   map_y2,   
   map_x3,
   map_y3,   
   map_x4,
   map_y4,
   coordx,
   coordy   
 FROM builds WHERE id='$attr->{ID}';");

 return $self if ($self->{errno} || $self->{TOTAL} < 1);

 ($self->{ID},
 	$self->{NUMBER},
 	$self->{STREET_ID},
 	$self->{FLORS},
 	$self->{ENTRANCES},
 	$self->{FLATS},
 	$self->{ADDED},
 	$self->{MAP_X},
 	$self->{MAP_Y},
 	$self->{MAP_X2},
 	$self->{MAP_Y2},
 	$self->{MAP_X3},
 	$self->{MAP_Y3},
 	$self->{MAP_X4},
 	$self->{MAP_Y4},
        $self->{COORDX}, 
        $self->{COORDY},
 	) = @{ $self->{list}->[0] };

 return $self;
}

#**********************************************************
# build_change()
#**********************************************************
sub build_change {
 my $self = shift;
 my ($id, $attr) = @_;

 my %FIELDS = (ID          => 'id',
               NUMBER      => 'number',
               STREET_ID   => 'street_id',
               FLORS       => 'flors',
               FLATS       => 'flats',
               ENTRANCES   => 'entrances',
               MAP_X       => 'map_x',
               MAP_Y       => 'map_y',
               MAP_X2      => 'map_x2',
               MAP_Y2      => 'map_y2',
               MAP_X3      => 'map_x3',
               MAP_Y3      => 'map_y3',
               MAP_X4      => 'map_x4',
               MAP_Y4      => 'map_y4',
      	       COORDX 	   => 'coordx',
	       COORDY 	   => 'coordy',
               );

 $self->changes($admin, { CHANGE_PARAM => 'ID',
		               TABLE        => 'builds',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->build_info({ ID => $id }),
		               DATA         => $attr
		              } );

 return $self;
}



#**********************************************************
# build_add()
#**********************************************************
sub build_add {
 my $self = shift;
 my ($attr) = @_;

 $self->query($db, "INSERT INTO builds (number, street_id, flors, flats, entrances, 
 map_x, map_y, map_x2, map_y2, map_x3, map_y3, map_x4, map_y4, added) 
 values ('$attr->{NUMBER}', '$attr->{STREET_ID}', '$attr->{FLORS}', '$attr->{FLATS}', '$attr->{ENTRANCES}', 
 '$attr->{MAP_X}', '$attr->{MAP_Y}', '$attr->{MAP_X2}', '$attr->{MAP_Y2}', '$attr->{MAP_X3}', '$attr->{MAP_Y3}', '$attr->{MAP_X4}', '$attr->{MAP_Y4}', 
 now());", 'do');

 $admin->system_action_add("BUILD:$self->{INSERT_ID}:$attr->{NAME}", { TYPE => 1 }) if (! $self->{errno});
 return $self;
}


#**********************************************************
# build_del()
#**********************************************************
sub build_del {
 my $self = shift;
 my ($id) = @_;

 $self->query($db, "DELETE FROM builds WHERE id='$id';", 'do');

 $admin->system_action_add("BUILD:$id", { TYPE => 10 }) if (! $self->{errno});
 return $self;
}







#**********************************************************
# wizard_list()
#**********************************************************
sub wizard_list {
 my $self = shift;
 my ($attr) = @_;


 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 @WHERE_RULES = ();
 if ($attr->{SESSION_ID}) {
	 push @WHERE_RULES, @{ $self->search_expr($attr->{SESSION_ID}, 'INT', 'session_id') };
  }

 if ($attr->{STEP}) {
	 push @WHERE_RULES, @{ $self->search_expr($attr->{STEP}, 'INT', 'step') };
  }


 my $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : ''; 
 my $sql = "SELECT session_id, step, param, value
   FROM reg_wizard
     $WHERE ORDER BY $SORT $DESC;";

 $self->query($db, "$sql");
 my $list = $self->{list};

 return $list;
}


#**********************************************************
# wizard_add()
#**********************************************************
sub wizard_add {
 my $self = shift;
 my ($attr) = @_;

 $self->query($db, "REPLACE INTO reg_wizard (param, value, aid, module,
  step, session_id) 
 values ('$attr->{PARAM}', '$attr->{VALUE}', '$admin->{AID}', '$attr->{MODULE}', '$attr->{STEP}', 
 '$attr->{SESSION_ID}');", 'do');

 return $self;
}


#**********************************************************
# wizard_del()
#**********************************************************
sub wizard_del {
 my $self = shift;
 my ($id) = @_;

 $self->query($db, "DELETE FROM reg_wizard WHERE session_id='$id';", 'do');

 return $self;
}

1
