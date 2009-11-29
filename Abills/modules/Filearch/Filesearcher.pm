package Filesearcher;
# FileSeacher
#






#use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
%SEARCH_EXPRESSiONS
$debug
);

#use vars  qw(%RAD %conf $db $admin %AUTH $DATE $TIME $var_dir $debug);

use Exporter;

$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw(
  &parse_info
  &web_request 
  &kinopoisk_actors
  &sr_search
  %SEARCH_EXPRESSiONS
 );

@EXPORT_OK = ();
%EXPORT_TAGS = ();




%SEARCH_EXPRESSiONS = ( sr   => { SEARCH       => 'movies/(\d+)">(.+)</A></TD>[ ]+<TD>(\d+)</TD>[ ]+<TD>(\W+)</TD>.+</TR>',  # '(mzinfo.cgi\?id=.+\n)',
	                                  SEARCH_LINK  => 'http://www.sharereactor.ru/cgi-bin/mzsearch.cgi?search=',
                                    SEARCH_PARSE => '',
                                    INFO_PAGE    => 'http://www.sharereactor.ru/movies/%ID%',
                                    GET_INFO     => {
                                  	   NAME        => '<H1>(.+)</H1>',
                                       ORIGIN_NAME => '<B>Оригинальное&nbsp;название:</B> (.+)\n',
                                       YEAR        => '<B>Год&nbsp;выхода:</B> (\d+)',                
                                       GENRE       => '<B>Жанр:</B> (\W+)\n',
                                       PRODUCER    => '<B>Режиссер:<\/B> (.+)\n',
                                       ACTORS      => '<B>В&nbsp;ролях:</B> (.+)\n',
                                       DESCR       => '<B>О&nbsp;фильме:</B> (.+)\n',
                                       STUDIO      => '<B>Выпущено:</B> (.+)\n',
                                       DURATION    => '<B>Продолжительность:</B> (\S+)',
                                       LANGUAGE    => '<B>Язык:</B> (\W+)\n',
                                       
                
                                       COMMENTS    => '<B>Примечания:</B> (\W+)\n',
                                       EXTRA       => '<B>Дополнительно:</B> (\W+)\n',
                                       FILE_FORMAT => '<B>Формат:</B> (\S+)\n',
                                       FILE_QUALITY => '<B>Качество:</B> (\S+)\n',
                                       FILE_VSIZE   => '<B>Видео:</B> (.+)\n',
                                       FILE_SOUND   => '<B>Звук:</B> (.+)\n',
                                       COVER        => '<IMG SRC=\'(.+)\' alt=\'(.+)\'>',
                                       POSTER       => '<IMG SRC=\'(.+)\' alt=\'(.+)\'>',
                                       SITES        => '',
                                       LINKS        => '<B>Ссылка:</B> (.+)\n'
                                   }
	                                },
                          imdb => { SEARCH       => '/title/tt(\d+)/.+>(.+)</a> \((\d+)\)',
                          	        SEARCH_LINK  => 'http://akas.imdb.com/find?tt=on;mx=20;q=',
                        	          SEARCH_PARSE => '',
                        	          INFO_PAGE    => 'http://akas.imdb.com/title/tt%ID%/',
                        	          GET_INFO     => {
                        	        	   NAME        => '<strong class="title">\n(.+) <small>',
                                       ORIGIN_NAME => '<strong class="title">\n(.+) <small>',
                                       YEAR        => '<a href="/Sections/Years/\d+">(\d+)</a>',
                                       GENRE       => 'FUNCTION:imdb_genres',
                                       PRODUCER    => 'Directed by</b><br>\n<a href="/name/nm\d+/">(.+)</a>',
                                       ACTORS      => 'FUNCTION:imdb_actors',
                                       DESCR       => 'Plot Outline:</b> (.+) <a',
                                       STUDIO      => '<B>Выпущено:</B> (.+)\n',
                                       DURATION    => '<b class="ch">Runtime:</b>\n(\d+)',
                                       LANGUAGE    => '',
                                       COUNTRY     => 'Country:</b>\n<a href="/Sections/Countries/\S+/">(\S+)</a>',
                                       COMMENTS    => '<B>Примечания:</B> (\W+)\n',
                                       EXTRA       => '<B>Дополнительно:</B> (\W+)\n',
                                       FILE_FORMAT => '<B>Формат:</B> (\S+)\n',
                                       FILE_QUALITY => '<B>Качество:</B> (\S+)\n',
                                       FILE_VSIZE   => '<B>Видео:</B> (.+)\n',
                                       FILE_SOUND   => '<B>Звук:</B> (.+)\n',
                                       #<img border="0" alt="Aquamarine" title="Aquamarine" src="http://ia.imdb.com/media/imdb/01/I/77/49/00/10m.jpg" height="140" width="95"></a>
                                       COVER        => '="poster" href="photogallery" title=".+"><img border="0" alt=".+" title=".+" src="(.+)" height="140"',
                                       POSTER       => '',
                        	        	   SITES        => ''     
                        	        	           }
                        	        },
                        	        #<td width=100% class="news"><a class="all" href="/level/1/film/409233/sr/1/">Бугимен 3 (видео)</a>
                        	kinopoisk => { SEARCH  => 'level/1/film/(\d+)/sr/1/">(.+)</a>,&nbsp;.+>(.+)</a>',
                          	        SEARCH_LINK  => 'http://www.kinopoisk.ru/index.php?level=7&m_act%5Bwhat%5D=item&from=forma&m_act%5Bid%5D=0&m_act%5Bfind%5D=',
                        	          SEARCH_PARSE => '',
                        	          INFO_PAGE    => 'http://www.kinopoisk.ru/level/1/film/%ID%',
                        	          GET_INFO     => {
                        	        	   ID          => 'id_film = (\d+);',
                                  	   NAME        => '<h1 style="margin: 0; padding: 0" class="moviename-big">(.+)&nbsp;<\/h1>',
                                       ORIGIN_NAME => '#666; font-size: 13px">(.+)<\/span>',
                                       COUNTRY     => 'm_act%5Bcountry%5D\/\d+\/">(\S+)<\/a>',
                                       YEAR        => 'm_act%5Byear%5D/(\d+)/',                
                                       GENRE       => 'FUNCTION:kinopoisk_genres',
                                       PRODUCER    => 'режиссер<\/td><td><a href=".+">(.+)<\/a>',
                                       ACTORS      => 'FUNCTION:kinopoisk_actors',
                                       DESCR       => 'FUNCTION:kinopoisk_descr',
                                       STUDIO      => 'FUNCTION:kinopoisk_studio',
                                       DURATION    => 'время<\/td><td class="time" id="runtime">(\d+)',
                                       LANGUAGE    => '<B>Язык:</B> (\W+)\n',
                
                                      # COMMENTS    => '<B>Примечания:</B> (\W+)\n',
                                      # EXTRA       => '<B>Дополнительно:</B> (\W+)\n',
                                      # FILE_FORMAT => '<B>Формат:</B> (\S+)\n',
                                      # FILE_QUALITY => '<B>Качество:</B> (\S+)\n',
                                      # FILE_VSIZE   => '<B>Видео:</B> (.+)\n',
                                      # FILE_SOUND   => '<B>Звук:</B> (.+)\n',
                                       COVER        => 'src="(/images/film/.+)" width',
                                       COVER_SMALL  => 'src="(/images/film/.+)" width',
                                       POSTER       => 'FUNCTION:kinopoisk_posters',  #'src="(/images/film/.+)" width',
                                       SITES        => ''
                        	        	            
                        	        	            
                        	        	           }
                        	        },
                        	amazon => { SEARCH  => '<td class="dataColumn"><table cellpadding="0" cellspacing="0" border="0"><tr><td>\n<a href="(.+)"><span class="srTitle">(.+)</span></a>',
                          	        SEARCH_LINK  => 'http://amazon.com/s/ref=br_ss_hs/103-8869836-8753426?platform=gurupa&url=index%3Ddvd&keywords=',
                        	          SEARCH_PARSE => '',
                        	          INFO_PAGE    => '%ID%',
                        	          GET_INFO     => {
                        	        	   NAME        => '<div class="content">\n<div style="font-size: 75%"><b class="sans">(.+)</b><br />',
                                       ORIGIN_NAME => '<div class="content">\n<div style="font-size: 75%"><b class="sans">(.+)</b><br />',
                                       YEAR        => '<li><b>DVD Release Date:</b> .+(\d{4})</li>',                
                                       GENRE       => '<li><b>Genres:</b> <a href=".+">(.+)</a>',
                                       PRODUCER    => '<li><b>Directors:</b> <a href=".+">(.+)</a></li>',
                                       ACTORS      => '<li><b>Actors:</b> (.+)',
                                       DESCR       => '<li><b>Plot Outline</b> (.+)</li>',
                                       STUDIO      => '<li><b>Studio:</b>  (.+)</li>',
                                       DURATION    => '<li><b>Run Time:</b>  (\d+)',
                                       LANGUAGE    => '<li><b>Language: (\W+)</li>',
                
                                      # COMMENTS    => '<B>Примечания:</B> (\W+)\n',
                                      # EXTRA       => '<B>Дополнительно:</B> (\W+)\n',
                                      # FILE_FORMAT => '<B>Формат:</B> (\S+)\n',
                                      # FILE_QUALITY => '<B>Качество:</B> (\S+)\n',
                                      # FILE_VSIZE   => '<B>Видео:</B> (.+)\n',
                                      # FILE_SOUND   => '<B>Звук:</B> (.+)\n',
                                       COVER        => ';"  ><img src="(.+)" id="prodImage" width="240" height="240" border="0" alt=".+" /></a></td>',
                                       COVER_SMALL  => ';"  ><img src="(.+)" id="prodImage" width="240" height="240" border="0" alt=".+" /></a></td>',
                                       POSTER       => 'src="(/images/film/.+)"  width',
                                       SITES        => ''
                        	        	            
                        	        	            
                        	        	           }
                        	        } 

                       );

#**********************************************************
# Imdb functions
#**********************************************************
sub imdb {
 my ($text, $attr)=@_;

 
 
}


#**********************************************************
# Search film in share reaktor
#**********************************************************
sub sr_search {
 my ($hash, $attr)=@_;

 my $request = "$SEARCH_EXPRESSiONS{sr}{SEARCH_LINK}$hash";

 if ($attr->{LINK}) {
   $request = "$attr->{LINK}";
  }

 my $res = web_request($request, {'TimeOut' => 60 });

 if($res =~ /\/movies\/(\d*)/) {
   print "FIND: $1 (http://www.sharereactor.ru/movies/$1)" if (defined($attr->{debug}) > 0);
   my $res = web_request("http://www.sharereactor.ru/movies/$1", {'TimeOut' => 60 });      
   return parse_info($res, { EXPRESSIONS => $SEARCH_EXPRESSiONS{sr}{GET_INFO} });
  }

  return 0;
}

#**********************************************************
#
#**********************************************************
sub parse_info (){
  my ($page, $attr) = @_;
  my %INFO=();
  
  %INFO = %{ $attr->{INFO} } if (defined($attr->{INFO}));
    
  my %PARAMS = %{ $attr->{EXPRESSIONS} };
 
 
  #print "<textarea colr=60 rows=8>$page</textarea>\n";
 
 
  while(my($key, $val)=each %PARAMS) {
     my $page1=$page;

     if ($val =~ /^FUNCTION:(.+)/) {
     	 my $function=$1;
     	 $INFO{$key}=$function->($page);
      }
     elsif($page1 =~ /$val/g) {
       #print "$key, $val, $1\n";
       $INFO{$key}=$1;
      }
     else {
     	 #print "$key\n";
      }
   }
   
   #Get Actors
   if (defined($INFO{ACTORS}) && $INFO{ACTORS} =~ /<a/i ) {
     my @actors_arr = split(/, /, $INFO{ACTORS});
     $INFO{ACTORS}='';

     foreach my $line (@actors_arr) {
       if ($line =~ /^<a.+>(.+)<\/a>/ig ) {
         $INFO{ACTORS}.="$1, ";
        }  
       else {
         $line=~/(.+)<(.+)>(.+)<\/a>/ig;
         $INFO{ACTORS}.="$1$3/, ";
        }
   	  }
    }

   #Make genres hash
   if (defined($INFO{GENRE})) {
     my @genre_arr = split(/, /, $INFO{GENRE});
     foreach my $line (@genre_arr) {
       if ($line =~ />(.+)<\/a>/) {
          $line=$1;
        }
       $INFO{GENRE_HASH}{"$line"} = "1";
   	  }
    }
   
  if (defined($INFO{DURATION}) && $INFO{DURATION} =~ /^(\d+)$/) {
  	my $hours = int($INFO{DURATION} / 60);
  	my $min = $INFO{DURATION} - ($hours * 60);
  	$INFO{DURATION} = "$hours:$min:00";
   }

#  if ( $page =~ /<IMG SRC='(.+)' alt='$INFO{NAME}'>/) {
#    $INFO{COVER}=$1;
#   }
  
  $debug=0;
  
  if ($debug > 1) {
    while(my($key, $val)=each %INFO) {
      print "$key: $val<br>\n";
    }
  }

  return \%INFO;
}

#**********************************************************
#
#**********************************************************
sub web_request {
 my ($request, $attr)=@_;
 
 my $res;
 my $host='';
 my $port=80;

 $request =~ /http:\/\/([a-zA-Z.-]+)\/(.+)/;
 $host    = $1; 
 $request = '/'.$2;

 if ($host =~ /:/) {
 	 ($host, $port)=split(/:/, $host, 2);
  }	



 $request =~ s/ /%20/g;
 
 $request = "GET $request HTTP/1.0\r\n";
 $request .= ($attr->{'User-Agent'}) ? $attr->{'User-Agent'} : "User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows 98;Win 9x 4.90)\r\n"; 
 $request .= "Accept: text/html, image/png, image/x-xbitmap, image/gif, image/jpeg, */*\r\n";
 $request .= "Accept-Language: ru\r\n";
 $request .= "Host: $host\r\n";
 $request .= "Content-type: application/x-www-form-urlencoded\r\n";
 $request .= "Referer: $attr->{'Referer'}\r\n" if ($attr->{'Referer'});
# $request .= "Connection: Keep-Alive\r\n";
 $request .= "Cache-Control: no-cache\r\n";
 $request .= "Accept-Encoding: *;q=0\r\n";
 $request .= "\r\n";
 
 print $request if ($attr->{debug});
 
 my $timeout = defined($attr->{'TimeOut'}) ? $attr->{'TimeOut'} : 5;
 my	$socket = new IO::Socket::INET(
				PeerAddr => $host,
				PeerPort => $port,
				Proto    => 'tcp',
				TimeOut  => $timeout
	) or log_print('LOG_DEBUG', "ERR: Can't connect to '$host:$port' $!");


  $socket->send("$request");
  while(<$socket>) {
     $res .= $_;
   }
 my ($header, $content) = split(/\n\n/, $res); 
 close($socket);




#print $header;
 if ($header =~ /HTTP\/1.\d 302/ ) {
   $header =~ /Location: (.+)\r\n/;
   
   my $new_location = $1;
   if ($new_location !~ /^http:\/\//) {
      $new_location="http://$host".$new_location;
    }

   $res = web_request($new_location, { Referer => "$request" });
  }


 if ($res =~ /\<meta\s+http-equiv='Refresh'\s+content='\d;\sURL=(.+)'\>/ig) {
    my $new_location = $1;
    if ($new_location !~ /^http:\/\//) {
      $new_location="http://$host".$new_location;
    }

    $res = web_request($new_location, { Referer => "$new_location" });
  }
 

 #print "<br><textarea cols=80 rows=8>$request\n\n$res</textarea><br>\n";  
  
 
 
 return $res;
}

#**********************************************************
# filearch functions
#**********************************************************
sub imdb_genres {
	my ($page) = @_;
  my @genre_array=();
  $page =~ /<b class="ch">Genre:<\/b>\n(.+)/;
  
  my (@genres_arr) = split(/<a/, $1);
	foreach my $line (@genres_arr) {
		if ($line =~ /href=.+>(.+)<\/a>/i) {
			push @genre_array, $1;
		 }
	}

	return join(', ', @genre_array);
}

#**********************************************************
# filearch functions
#**********************************************************
sub imdb_actors {
	my ($page) = @_;
  my @actors_array = ();

  $page =~ s/<\/tr>/<\/tr>\n/g;

  while ($page =~ /<a href="\/name\/nm\d+\/">(.+)<\/a><\/td><td valign="middle" nowrap="1">/ig) {
  	 push(@actors_array, $1);
   }

	return join(', ', @actors_array);
}


#**********************************************************
# filearch functions
#**********************************************************
sub kinopoisk_genres {
	my ($page) = @_;

  $page =~ /жанр<\/td><td>(.+)\n/;
 

  my %imdb_genres = (
  'боевик'      => 'Action',	  
  'приключения' => 'Adventure',	
  'мультфильм'  => 'Animation',
  'фантастика'  => 'Sci-Fi',
  'комедия'     => 'Comedy',	
  'криминал'    => 'Crime',	
  'мистика'     => 'Mystery',	
  'ужасы'       => 'Horror',
  'драма'       => 'Drama',
  'семейный'    => 'Family',
  'фэнтези'     => 'Fantasy',
  'история'     => 'History',
  'биография'   => 'Biography',
  'короткометражка' => 'Short',	
  'триллер'     => 'Thriller',	
  'военный'     => 'War',	
  'спорт'       => 'Sport',	  
  'мьюзикл'     => 'Musical',
  'документальный' => 'Documentary',	
  'мелодрама'   => 'Romance',
  'музыка'      => 'Music',
  'вестерн'     => 'Western',
  'для взрослых'=> 'Erotica',

  '' => 'Film-Noir',
  '' => 'Game-Show',
  '' => 'News',	
  '' => 'Reality-TV',
  '' => 'Talk-Show'
  
  );
  
  my @genre_array = ();

  my @genre_arr = split(/, /, $1);

  foreach my $line (@genre_arr) {
    if ($line =~ />(.+)<\/a>/) {
       $line=$1;
       #print "$line <br>";
      }

    push @genre_array, $imdb_genres{"$line"};
   }
 

	return join(', ', @genre_array);
}

#**********************************************************
# filearch functions
#**********************************************************
sub kinopoisk_actors {
	my ($page) = @_;
  my @actors_array = ();

  while ($page =~ /<tr><td height=15 align=right><a href="\/level\/4\/id_actor\/\d+\/" class="all">(.+)<\/a>/ig) {
  	 push(@actors_array, $1);
   }

	return join(', ', @actors_array);
}

#**********************************************************
# filearch functions
#**********************************************************
sub kinopoisk_descr {
	my ($page) = @_;
  my $descr = '';

  $page =~ /class="news">\n\t\t\t(.+)/;
  $descr = $1;
  
  $descr =~ s/<span class="_reachbanner_">//;
  $descr =~ s/<br[ \/]{0,3}>/\n/g;
  
  if ($descr =~ /<a href="(.+)" class/) {
    my $request = "http://www.kinopoisk.ru".$1;
    
    $page = web_request($request);
    $page =~ /class="news">\n\t\t\t(.+)/;
    $descr = $1;

    print "$request";

   }
	return $descr;
}


#**********************************************************
# filearch functions
#**********************************************************
sub kinopoisk_posters {
	my ($page) = @_;
  my $posters = '';
  my @posters_arr = (); 
  
                

  if ($page =~ /<a style="text-decoration:none" href="(.+)"><b style="font-weight: bold"><font color="#ff6600">п<\/font><font color="#555555">остеры/) {
     $page = web_request("http://www.kinopoisk.ru".$1);
     while($page =~ /\/images\/poster\/([a-z\_\.0-9]+)\'/ig) {
       push @posters_arr, $1;
      }
   }

  $posters = join(", http://www.kinopoisk.ru/images/poster/", @posters_arr);
  

	return $studios;
}



#**********************************************************
# filearch functions
#**********************************************************
sub kinopoisk_studio {
	my ($page) = @_;
  my $studios = '';
  my @studios_arr = (); 
  
  if ($page =~ /<a style="text-decoration:none" href="(.+)"><b><font color="#ff6600">с<\/font><font color="#555555">тудии/) {
     $page = web_request("http://www.kinopoisk.ru".$1);
     while($page =~ /<a href="\/level\/10\/m_act%5Bstudio%5D\/\d+\/" class="all">(.+)<\/a>/g) {
       push @studios_arr, $1;
      }
   }

  $studios = join(", ", @studios_arr);

	return $studios;
}



1
