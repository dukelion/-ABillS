package Filearch;
#Nas Server configuration and managing
 
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);


my $db;
use main;
use Socket;

@ISA  = ("main");
my $CONF;
my $admin;
my $SECRETKEY = '';

sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
#  $self->{debug}=1;
  return $self;
}


#**********************************************************
# list
#**********************************************************
sub genres_list() {
  my $self = shift;
  my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 

 $self->query($db, "SELECT  g.name, count(f.genre_id), g.sharereactor, g.imdb, g.id
    FROM filearch_video_genres g
    LEFT JOIN filearch_film_genres f ON (g.id=f.genre_id)
    GROUP BY g.id
    ORDER BY $SORT $DESC;");

 return $self->{list};
}


#**********************************************************
# Add
#**********************************************************
sub genres_add {
  my $self = shift;
  my ($attr) = @_;

  
  %DATA = $self->get_data($attr); 

  $self->query($db, "INSERT INTO filearch_video_genres (name,
    imdb,
    sharereactor)
    values ('$DATA{NAME}', '$DATA{IMDB_NAME}', '$DATA{SR_NAME}');", 'do');
  $self->{GID}=$self->{INSERT_ID};
  return $self;
}


#**********************************************************
# change
#**********************************************************
sub genres_change {
  my $self = shift;
  my ($attr) = @_;


  my %FIELDS = ( ID        => 'id', 
                 NAME      => 'name',
                 IMDB_NAME => 'imdb',
                 SR_NAME   => 'sharereactor'
                );   
 
	$self->changes($admin, { CHANGE_PARAM => 'ID',
		                TABLE        => 'filearch_video_genres',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->genres_info($attr->{ID}, $attr),
		                DATA         => $attr
		              } );
 
	return $self;
}

#**********************************************************
# del
#**********************************************************
sub genres_del {
  my $self = shift;
  my ($id) = @_;
  	
  $self->query($db, "DELETE FROM filearch_video_genres WHERE id='$id';", 'do');
  
 return $self;
}

#**********************************************************
# Info
#**********************************************************
sub genres_info {
  my $self = shift;
  my ($id, $attr) = @_;
  
  $self->query($db, "SELECT id, 
       name,
       imdb,
       sharereactor
    FROM filearch_video_genres
    WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];
  
  ($self->{ID}, 
   $self->{NAME},
   $self->{IMDB_NAME},
   $self->{SR_NAME}
  ) = @$ar;


  return $self;
}

#**********************************************************
# list
#**********************************************************
sub actors_list() {
  my $self = shift;
  my ($attr) = @_;
  
  my @WHERE_RULES = ();
  
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if ($attr->{NAME}) {
  	$attr->{NAME} =~ s/\*/\%/g;
    push @WHERE_RULES, "(a.name LIKE '$attr->{NAME}' or a.origin_name LIKE '$attr->{NAME}')";
   }
  
  if ($attr->{IDS}) {
  	push @WHERE_RULES, "(a.origin_name IN ($attr->{IDS}) or a.name IN ($attr->{IDS}))";
   }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : ''; 
 

 $self->query($db, "SELECT a.id, a.name, a.origin_name, count(f.actor_id)
    FROM filearch_video_actors a
    LEFT JOIN filearch_film_actors f ON (a.id=f.actor_id)
    $WHERE
    GROUP BY a.id
    ORDER BY $SORT $DESC
   LIMIT $PG, $PAGE_ROWS;");

 my $list = $self->{list};

 $self->query($db, "SELECT count(*)
    FROM filearch_video_actors a
    LEFT JOIN filearch_film_actors f ON (a.id=f.actor_id)
    $WHERE;");

  my $a_ref = $self->{list}->[0];
  ($self->{TOTAL}) = @$a_ref;


 return $list;
}


#**********************************************************
# Add
#**********************************************************
sub actors_add {
  my $self = shift;
  my ($attr) = @_;

  
  %DATA = $self->get_data($attr, { default => { NAME        => '',
  	                                            ORIGIN_NAME => '',
  	                                            BIO         => '' } }); 

  $self->query($db, "INSERT INTO filearch_video_actors (name, origin_name, bio)
    values ('$DATA{NAME}', '$DATA{ORIGIN_NAME}', '$DATA{BIO}');", 'do');

  $self->{ACTOR_ID}=$self->{INSERT_ID};

  return $self;
}


#**********************************************************
# change
#**********************************************************
sub actors_change {
  my $self = shift;
  my ($attr) = @_;


  my %FIELDS = ( ID          => 'id', 
                 NAME        => 'name',
                 BIO         => 'bio',
                 ORIGIN_NAME => 'origin_name'
                );   
 
	$self->changes($admin, { CHANGE_PARAM => 'ID',
		                TABLE        => 'filearch_video_actors',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->actors_info($attr->{ID}, $attr),
		                DATA         => $attr
		              } );
 
	return $self;
}

#**********************************************************
# del
#**********************************************************
sub actors_del {
  my $self = shift;
  my ($id) = @_;
  	
  $self->query($db, "DELETE FROM filearch_video_actors WHERE id='$id';", 'do');
  
 return $self;
}

#**********************************************************
# Info
#**********************************************************
sub actors_info {
  my $self = shift;
  my ($id, $attr) = @_;
  
  

  $self->query($db, "SELECT id, 
       name,
       origin_name,
       bio
    FROM filearch_video_actors
    WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];
  
  ($self->{ID}, 
   $self->{NAME}, 
   $self->{ORIGIN_NAME},
   $self->{BIO}
  ) = @$ar;


  return $self;
}


#**********************************************************
# Add
#**********************************************************
sub video_add {
  my $self = shift;
  my ($attr) = @_;

 
  %DATA = $self->get_data($attr); 

  if (! $DATA{COUNTRY_ID}) {
    $self->file_country_info({ COUNTRY_NAME => $DATA{COUNTRY}, ADD => 1 }) if ($DATA{COUNTRY});

    $DATA{COUNTRY_ID}=$self->{COUNTRY_ID};
   }

  $self->query($db, "INSERT INTO filearch_video 
     (id,
      original_name,
      year,
      producer,
      descr,
      studio,
      duration,
      language,
      file_format,
      file_quality,
      file_vsize,
      file_sound,
      cover_url,
      parent,
      extra,
      country,
      pin_access
      )
     values
     ('$DATA{ID}',
      '$DATA{ORIGIN_NAME}',
      '$DATA{YEAR}',
      '$DATA{PRODUCER}',
      '$DATA{DESCR}',
      '$DATA{STUDIO}',
      '$DATA{DURATION}',
      '$DATA{LANGUAGE}',
      '$DATA{FILE_FORMAT}',
      '$DATA{FILE_QUALITY}',
      '$DATA{FILE_VSIZE}',
      '$DATA{FILE_SOUND}',
      '$DATA{COVER}',
      '$DATA{PARENT}',
      '$DATA{EXTRA}',
      '$DATA{COUNTRY_ID}',
      '$DATA{PIN_ACCESS}'
     );", 'do');

  

  $self->film_genres_add({ ID => "$DATA{ID}", GENRE => $DATA{GENRES} }) if ($DATA{GENRES});
  
  $self->film_actors_add( $attr );
 

  return $self;
}

#**********************************************************
# list
#**********************************************************
sub video_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();
 
  if (defined($attr->{STATUS})) {
    push @WHERE_RULES, "f.status='$attr->{STATUS}'";
   }

  if ($attr->{NAME}) {
  	$attr->{NAME} =~ s/\*/\%/ig;
    push @WHERE_RULES, "(f.name LIKE '$attr->{NAME}' or f.filename LIKE '$attr->{NAME}')";
   }

  if ($attr->{YEAR}) {
    my $value = $self->search_expr($attr->{YEAR}, 'INT');
    push @WHERE_RULES, "v.year LIKE '$attr->{YEAR}'";
   }


  if ($attr->{COMMENTS}) {
  	$attr->{COMMENTS} =~ s/\*/\%/ig;
    push @WHERE_RULES, "f.filename LIKE '$attr->{COMMENTS}'";
   }

  if ($attr->{SIZE}) {
  	my $value = $self->search_expr($attr->{SIZE}, 'INT');
    push @WHERE_RULES, "f.size$value";
   }

  if (defined($attr->{PARENT})) {
    push @WHERE_RULES, "v.parent='$attr->{PARENT}'";
   }


  if ($attr->{GENRE}) {
    push @WHERE_RULES, "fg.genre_id='$attr->{GENRE}'";
   }


  if ($attr->{ACTOR}) {
    $attr->{ACTOR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "va.name LIKE '$attr->{ACTOR}'";
   }
  elsif ($attr->{ACTOR_ID}) {
    push @WHERE_RULES, "fa.actor_id='$attr->{ACTOR_ID}'";
   }

  if ($attr->{AID}) {
    push @WHERE_RULES, "f.aid='$attr->{AID}'";
   }
  
  if (defined($attr->{STATE})) {
    if ($attr->{STATE} == 0) {
    	push @WHERE_RULES, "fs.state IS NULL";
      }
    else {
      push @WHERE_RULES, "fs.state='$attr->{STATE}'";
     }
  }

  if ($attr->{WIHOUT_INFO}) {
  	push @WHERE_RULES, "v.id IS NULL";
   }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : ''; 
 
 
 $self->query($db, "SELECT    f.id,
  if (f.name='', f.filename, f.name),
  v.year,
  '',
  v.file_format,
  v.file_quality,
  f.size,
  f.added,
  fs.state,
  f.filename,
  f.path,
  f.checksum,
  f.comments,
  f.aid,
  count(v.id),
  v.extra,
  v.parent
   FROM filearch f
   LEFT JOIN filearch_video v ON (f.id = v.id) 
   LEFT JOIN filearch_film_genres fg ON (fg.video_id = v.id) 
   LEFT JOIN filearch_film_actors fa ON (fa.video_id = v.id) 
   LEFT JOIN filearch_state fs ON (f.id = fs.file_id) 
   LEFT JOIN filearch_video_actors va ON (va.id = fa.actor_id) 
    $WHERE
    GROUP BY f.id
    ORDER BY $SORT $DESC

    LIMIT $PG, $PAGE_ROWS;");


 my $list = $self->{list};

 if ($self->{TOTAL} == $PAGE_ROWS || $PG > 0) {
   $self->query($db, "SELECT count(DISTINCT f.id)
     FROM filearch f
     LEFT JOIN filearch_video v ON (f.id = v.id) 
     LEFT JOIN filearch_film_genres fg ON (fg.video_id = v.id) 
     LEFT JOIN filearch_film_actors fa ON (fa.video_id = v.id) 
     LEFT JOIN filearch_video_actors va ON (va.id = fa.actor_id) 
     LEFT JOIN filearch_state fs ON (f.id = fs.file_id) 
     $WHERE
     ;");
 
   my $a_ref = $self->{list}->[0];
   ($self->{TOTAL}) = @$a_ref;
  }

 return $list;
}

#**********************************************************
# change
#**********************************************************
sub video_next {
	my $self = shift;
  my ($attr) = @_;

  $self->query($db, "SELECT f.id, f.filename 
     FROM filearch f
     LEFT JOIN filearch_video v ON (f.id = v.id) 
     WHERE f.name='' and f.id>'$attr->{ID}'
     ORDER BY f.id
     LIMIT 1;");

  my $ar = $self->{list}->[0];
  
  ($self->{ID},
   $self->{FILENAME}
   ) = @$ar;

  return $self;  	
}

#**********************************************************
# change
#**********************************************************
sub video_change {
  my $self = shift;
  my ($attr) = @_;


  my %FIELDS = ( ID            => 'id',
                 ORIGIN_NAME => 'original_name',
                 YEAR          => 'year',
                 PRODUCER      => 'producer',
                 DESCR         => 'descr',
                 STUDIO        => 'studio',
                 DURATION      => 'duration',
                 LANGUAGE      => 'language',
                 FILE_FORMAT   => 'file_format',
                 FILE_QUALITY  => 'file_quality',
                 FILE_VSIZE    => 'file_vsize',
                 FILE_SOUND    => 'file_sound',
                 COVER         => 'cover_url',
                 PARENT        => 'parent',
                 EXTRA         => 'extra',
                 COUNTRY       => 'country',
                 PIN_ACCESS    => 'pin_access',
                 UPDATED       => 'updated'
                );   



  $attr->{PIN_ACCESS} = (! defined($attr->{PIN_ACCESS})) ?  0 : 1;
  
  my $OLD_INFO = $self->video_info($attr->{ID}, $attr);
  
  if ($OLD_INFO->{EXT_INFO} < 1) {
  	 $self->video_add($attr);
  	 return $self;
   }
 
	$self->changes($admin, { CHANGE_PARAM => 'ID',
		                       TABLE        => 'filearch_video',
		                       FIELDS       => \%FIELDS,
		                       OLD_INFO     => $OLD_INFO,
		                       DATA         => $attr
		                      } );
 
  $self->film_genres_add({ ID => "$attr->{ID}", GENRE => $attr->{GENRES} }) if ($attr->{GENRES});
  $self->film_actors_add( $attr ) if ($attr->{ACTORS});

	return $self;
}

#**********************************************************
# del
#**********************************************************
sub video_del {
  my $self = shift;
  my ($id) = @_;
  $self->query($db, "DELETE FROM filearch_video WHERE id='$id';", 'do');
  return $self;
}

#**********************************************************
# Info
#**********************************************************
sub video_info {
  my $self = shift;
  my ($id, $attr) = @_;
  
  $self->query($db, "SELECT f.id,
         v.original_name,
         v.year,
         v.producer,
         v.descr,
         v.studio,
         v.duration,
         v.language,
         v.file_format,
         v.file_quality,
         v.file_vsize,
         v.file_sound,
         f.size,
         f.checksum,
         if (f.name='', f.filename, f.name),
         count(fa.video_id),
         count(fg.video_id),
         count(v.id),
         v.cover_url,
         f.filename,
         f.path,
         v.parent,
         v.extra,
         v.country,
         v.pin_access,
         v.updated
  FROM filearch f
   LEFT JOIN filearch_video v ON (f.id = v.id)  
   LEFT JOIN filearch_film_actors fa ON (f.id = fa.video_id)  
   LEFT JOIN filearch_film_genres fg ON (f.id = fg.video_id)  
   WHERE f.id='$id'
 GROUP BY f.id;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];
  
  ($self->{ID},
   $self->{ORIGIN_NAME},
   $self->{YEAR},
   $self->{PRODUCER},
   $self->{DESCR},
   $self->{STUDIO},
   $self->{DURATION},
   $self->{LANGUAGE},
   $self->{FILE_FORMAT},
   $self->{FILE_QUALITY},
   $self->{FILE_VSIZE},
   $self->{FILE_SOUND},
   $self->{SIZE},
   $self->{CHECKSUM},
   $self->{NAME},
   $self->{ACTORS_COUNT},
   $self->{GENRE_COUNT},
   $self->{EXT_INFO},
   $self->{COVER},
   $self->{FILENAME},
   $self->{PATH},
   $self->{PARENT},
   $self->{EXTRA},
   $self->{COUNTRY},
   $self->{PIN_ACCESS},
   $self->{UPDATED}
  ) = @$ar;



  if ($self->{GENRE_COUNT} > 0) {
    $self->{GENRE_HASH} = $self->film_genres_list($self->{ID});
   }

  if ($self->{ACTORS_COUNT} > 0) {
    $self->{ACTORS_HASH} = $self->film_actors_list($self->{ID});
   }
 
  #Get parents
  $self->video_list({ PARENT => $id });
  if ($self->{TOTAL} > 0) {
  	 $self->{PARTS} = $self->{list};
   }
  

  return $self;
}


#**********************************************************
# list
#**********************************************************
sub file_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 my @WHERE_RULES = (); 

  if ($attr->{STATUS}) {
    push @WHERE_RULES, "f.status='$attr->{STATUS}'";
   }

  if ($attr->{FILENAME}) {
  	$attr->{FILENAME} =~ s/\*/\%/ig;
    push @WHERE_RULES, "f.filename LIKE '$attr->{FILENAME}'";
   }

  if ($attr->{PATH}) {
  	$attr->{PATH} =~ s/\*/\%/ig;
    push @WHERE_RULES, "f.path LIKE '$attr->{PATH}'";
   }

  if ($attr->{NAME}) {
  	$attr->{NAME} =~ s/\*/\%/ig;
    push @WHERE_RULES, "f.name LIKE '$attr->{NAME}'";
   }

  if ($attr->{COMMENTS}) {
  	$attr->{COMMENTS} =~ s/\*/\%/ig;
    push @WHERE_RULES, "f.filename LIKE '$attr->{COMMENTS}'";
   }
  
  if ($attr->{CHECKSUM}) {
  	$attr->{CHECKSUM} =~ s/\*/\%/ig;
    push @WHERE_RULES, "f.checksum LIKE '$attr->{CHECKSUM}'";
   }


  if ($attr->{SIZE}) {
  	my $value = $self->search_expr($attr->{SIZE}, 'INT');
    push @WHERE_RULES, "f.size$value";
   }

  if ($attr->{AID}) {
    push @WHERE_RULES, "f.aid='$attr->{AID}'";
   }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : ''; 

 $self->query($db, "SELECT  id,
  filename,
  path,
  name,
  size,
  added,
  checksum,
  comments,
  aid
  
    FROM filearch f
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 my $list = $self->{list};

 $self->query($db, "SELECT count(*)
    FROM filearch f
    $WHERE;");

  my $a_ref = $self->{list}->[0];
  ($self->{TOTAL}) = @$a_ref;


 return $list;
}


#**********************************************************
# Add
#**********************************************************
sub file_country_add {
	my $self = shift;
  my ($attr) = @_;

  $self->query($db, "INSERT INTO filearch_countries (name) VALUES ('$attr->{COUNTRY_NAME}');", 'do');
  
  $self->{COUNTRY_ID}=$self->{INSERT_ID};

  return $self;	
}      


#**********************************************************
# Add
#**********************************************************
sub file_country_info {
  my $self = shift;
  my ($attr) = @_;



  
  my $WHERE = ($attr->{COUNTRY_NAME}) ? " name='$attr->{COUNTRY_NAME}' " :  "id='$attr->{ID}'" ;

  $self->query($db, "SELECT id, name FROM filearch_countries 
   WHERE $WHERE;", 'do');

  if ($attr->{ADD} && $self->{TOTAL} == 0) {
  	$self->file_country_add({ COUNTRY_NAME => $attr->{COUNTRY_NAME} });
   }

  return $self;	
}

#**********************************************************
# list
#**********************************************************
sub file_country_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "SELECT id, name FROM filearch_countries");
  
  return $self->{list};	
}


#**********************************************************
# Add
#**********************************************************
sub file_add {
  my $self = shift;
  my ($attr) = @_;

  
  #$self->film_genres_add('$DATA{GENRES}');
  
  %DATA = $self->get_data($attr); 
  $self->query($db, "INSERT INTO filearch (
                       filename,
                       path,
                       name,
                       checksum,
                       added,
                       size,
                       aid,
                       comments)
    values ('$DATA{FILENAME}', '$DATA{PATH}', 
      '$DATA{NAME}',
      '$DATA{CHECKSUM}',
      now(),
      '$DATA{SIZE}',
      '$DATA{AID}',
      '$DATA{COMMENTS}'
     );", 'do');

  return $self;
}


#**********************************************************
# change
#**********************************************************
sub file_change {
  my $self = shift;
  my ($attr) = @_;


  my %FIELDS = ( ID        => 'id', 
                 FILENAME  => 'filename',
                 PATH      => 'path',
                 NAME      => 'name',
                 CHECKSUM  => 'checksum',
                 SIZE      => 'size',
                 COMMENTS  => 'comments',
                 STATE     => 'state'
                );   

	$self->changes($admin, { CHANGE_PARAM => 'ID',
		                       TABLE        => 'filearch',
		                       FIELDS       => \%FIELDS,
		                       OLD_INFO     => $self->file_info($attr->{ID}, $attr),
		                       DATA         => $attr
		                      } );
 
    

 
	return $self;
}

#**********************************************************
# del
#**********************************************************
sub file_del {
  my $self = shift;
  my ($id) = @_;
  $self->query($db, "DELETE FROM filearch WHERE id='$id';", 'do');
  
  $self->video_del($id);
  return $self;
}

#**********************************************************
# Info
#**********************************************************
sub file_info {
  my $self = shift;
  my ($id, $attr) = @_;
  
  $self->query($db, "SELECT id,
   filename,
   path,
   name,
   checksum,
   added,
   aid,
   size,
   comments,
   state
    FROM filearch
   WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];
  
  ($self->{ID}, 
   $self->{FILENAME}, 
   $self->{PATH},
   $self->{NAME},
   $self->{CHECKSUM},
   $self->{ADDED},
   $self->{AID},
   $self->{SIZE},
   $self->{COMMENTS},
   $self->{STATE}
  ) = @$ar;

  return $self;
}




#**********************************************************
# list
#**********************************************************
sub film_genres_list() {
  my $self = shift;
  my ($id) = @_;
 
  my %GENRE_HASH = ();
  $self->query($db, "SELECT fg.genre_id, g.name
    FROM filearch_film_genres fg, filearch_video_genres g
    WHERE fg.genre_id=g.id and fg.video_id='$id';");
  
  foreach my $line ( @{$self->{list}} ) {
  	$GENRE_HASH{$line->[0]}=$line->[1];
   }

  return \%GENRE_HASH;
}


#**********************************************************
# Add
#**********************************************************
sub film_genres_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr); 
  
  my @genres_arr = split(/, /, $DATA{GENRE});

  $self->query($db, "DELETE FROM filearch_film_genres  WHERE video_id='$DATA{ID}';", 'do');
  
  foreach my $GENRE_ID (@genres_arr)  {
    $self->query($db, "INSERT INTO filearch_film_genres (video_id, genre_id)
     values ('$DATA{ID}', '$GENRE_ID');", 'do');
   }

  return $self;
}

#**********************************************************
# list
#**********************************************************
sub film_actors_list() {
  my $self = shift;
  my ($id) = @_;


 my %ACTORS_HASH = ();
 $self->query($db, "SELECT a.id, a.name, a.origin_name
    FROM filearch_film_actors fa, filearch_video_actors a
    WHERE fa.actor_id=a.id and fa.video_id='$id'
    ORDER BY a.name;");

  foreach my $line ( @{$self->{list}} ) {
  	$ACTORS_HASH{$line->[0]}="$line->[1] /$line->[2]/";
   }

  return \%ACTORS_HASH;
}


#**********************************************************
# Add
#**********************************************************
sub film_actors_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr);   

  if (! $attr->{ACTORS}) {
  	return $self;
   }
  
  my @actors_arr = split(/, /, $attr->{ACTORS});
  my %actors_info_hash = ();

  foreach my $line (@actors_arr) {
    $line =~ s/^ //g;
    if ($line =~ /(.+)\/(.+)\//) {
       my $name = $1;
       my $origin_name = $2;
       $name =~ s/( +)$//g;
       $actors_info_hash{"$origin_name"}="$name";
    	}
    else {
      $actors_info_hash{"$line"}="$line";
     }
   }

  my %actors_hash = ();
  my $ids = join('", "', keys %actors_info_hash);
  $ids = "\"".$ids."\"";
  
  my $list = $self->actors_list({ IDS => $ids });

  foreach my $line (@$list) {
   	$actors_hash{"$line->[2]"}=$line->[0];
   	$actors_hash{"$line->[1]"}=$line->[0];
   }

  $self->query($db, "DELETE FROM filearch_film_actors  WHERE video_id='$DATA{ID}';", 'do');

  while(my($origin_name, $name)=each(%actors_info_hash)) {
    my $actor_id = 0;
    if (! defined($actors_hash{"$origin_name"})) {
    	$self->actors_add({ NAME        => "$name",
    		                  ORIGIN_NAME => "$origin_name" });
    	$actor_id = $self->{ACTOR_ID};
    	if ($self->{errno}) {
    		print " $name / $origin_name\n";
    	 }
     }
    else {
    	$actor_id=$actors_hash{"$origin_name"};
     }
    
    $self->query($db, "INSERT INTO filearch_film_actors (video_id, actor_id)
      values ('$DATA{ID}', '$actor_id');", 'do');

   }

  $self->{ACTOR_ID}=$self->{INSERT_ID};

  return $self;
}

#**********************************************************
# Add
#**********************************************************
sub video_check {
  my $self = shift;
  my ($attr) = @_;
   
  
  my @IDS = split(/, /, $attr->{IDS});
  
  my $id_sqlstr = join('\', \'', @IDS);
  $id_sqlstr = "'$id_sqlstr'";
  
  $self->query($db, "DELETE from filearch_state WHERE uid='$attr->{UID}' and 
       file_id in ($attr->{IDS});", 'do');

  if ($attr->{STATE}) {
    foreach my $line (@IDS) {
      $self->query($db, "INSERT INTO filearch_state (file_id, uid, state)
        values ('$line', '$attr->{UID}', '$attr->{STATE}');", 'do');
       #print "$attr->{STATE} // STATE $attr->{IDS}";
     }
  }
}





































#**********************************************************
# Add
#**********************************************************
sub chapter_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr); 
  $self->query($db, "INSERT INTO filearch_chapters 
     (
      name,
      type,
      dir,
      skip
      )
     values
     (
      '$DATA{NAME}',
      '$DATA{TYPE}',
      '$DATA{dir}',
      '$DATA{skip}'
     );", 'do');

  return $self;
}

#**********************************************************
# list
#**********************************************************
sub chapters_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  undef @WHERE_RULES;
  
  if ($attr->{NAME}) {
  	$attr->{NAME} =~ s/\*/\%/ig;
    push @WHERE_RULES, "(f.name LIKE '$attr->{NAME}' or f.filename LIKE '$attr->{NAME}')";
   }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : ''; 
 
 
 $self->query($db, "SELECT  c.id,
  c.name,
  c.type,
  c.dir
   FROM filearch_chapters  c
    $WHERE
    GROUP BY c.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 my $list = $self->{list};

 if ($self->{TOTAL} == $PAGE_ROWS || $PG > 0) {
   $self->query($db, "SELECT count(DISTINCT f.id)
     FROM filearch_chapters 
     $WHERE
   ;");
 
   my $a_ref = $self->{list}->[0];
   ($self->{TOTAL}) = @$a_ref;
  }

 return $list;
}

#**********************************************************
# change
#**********************************************************
sub chapter_change {
  my $self = shift;
  my ($attr) = @_;


  my %FIELDS = ( ID            => 'id',
                 NAME          => 'name',
                 TYPE          => 'type',
                 DIR           => 'dir',
                 SKIP          => 'skip',
                 COMMENTS      => 'comments'
                );   
  
  my $OLD_INFO = $self->chapter_info($attr->{ID}, $attr);
 
	$self->changes($admin, { CHANGE_PARAM => 'ID',
		                       TABLE        => 'filearch_chapters',
		                       FIELDS       => \%FIELDS,
		                       OLD_INFO     => $OLD_INFO,
		                       DATA         => $attr
		                      } );
 
	return $self;
}

#**********************************************************
# del
#**********************************************************
sub chapter_del {
  my $self = shift;
  my ($id) = @_;
  $self->query($db, "DELETE FROM filearch_chapters WHERE id='$id';", 'do');
  return $self;
}


#**********************************************************
# Info
#**********************************************************
sub chapter_info {
  my $self = shift;
  my ($id, $attr) = @_;
  
  $self->query($db, "SELECT c.id,
         c.name,
         c.type,
         c.dir,
         c.skip
  FROM filearch_chapters c
   WHERE c.id='$id'
 GROUP BY c.id;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];
  
  ($self->{ID},
   $self->{NAME},
   $self->{TYPE},
   $self->{DIR},
   $self->{SKIP}
  ) = @$ar;


  return $self;
}




1
