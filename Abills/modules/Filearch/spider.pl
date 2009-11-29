#!/usr/bin/perl -w
# File spider



use vars  qw(%RAD %conf $db $admin %AUTH $DATE $TIME $var_dir $debug);
use strict;



use FindBin '$Bin';
require $Bin . '/config.pl';
unshift(@INC, $Bin . '/../', $Bin . "/../Abills/$conf{dbtype}");
require Abills::Base;
Abills::Base->import();

require Abills::SQL;
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
$db  = $sql->{db};

require "Filearch.pm";
Filearch->import();

my $Filearch = Filearch->new($db, $admin, \%conf);
#require "Abills/nas.pl";


use Socket;
use IO::Socket;
use IO::Select;


$debug=0;
require "Abills/modules/Filearch/Filesearcher.pm";
Filesearcher->import();


use Digest::MD4;
use constant BLOCKSIZE => 9728000;

$conf{FILEARCH_PATH}   = '/bfs/Share/Video/Movies' if (! $conf{FILEARCH_PATH});
$conf{FILEARCH_FORMATS}= '.avi,*.mpg,*.vob' if (! $conf{FILEARCH_FORMATS});
$conf{FILEARCH_SKIPDIR}= '/bfs/Share/Video/Movies/_unsorted' if (! $conf{FILEARCH_SKIPDIR});
my $recursive=0;
my $rec_level=0;

my %stats = (TOTAL => 0,
             ADDED => 0);

my @not_exist_files=();
my $FILEHASH;
my %file_list = ();

my $params = parse_arguments(\@ARGV);


if ($params->{debug}) {
  print "Debug mode: $params->{debug}\n";
  $debug = $params->{debug} ;
}

if ($#ARGV < 0) {
	print "spider.pl [options]
	checkfiles         - CHECK disk files
	getinfo            - get info from sharereaktor.ru (Only new)
	CHECK_ALL=1        - CHECK all files
  GET_DUBS           - Get dublicats
  debug              - Debug mode
  ed2k_hash=FILENAME - Make ed2k hash
  CHECK_SR=[DIR]     - CHECK file names from Share reactors
    NEW_FOLDER=[DIR] - Move to dir
  SKIP_DIRS          - Skip some dirs
  
	\n";
 }
elsif ($ARGV[0] eq 'checkfiles') {
  #Get records from DB
  $FILEHASH = file_hash();
  #Check files
  getfiles($conf{FILEARCH_PATH});
  print "TOTAL: $stats{TOTAL} ADDED: $stats{ADDED}\n";
}
elsif($ARGV[0] eq 'getinfo') {
	post_info();
	if ($#not_exist_files > -1) {
	 print "Not exist files:\n";
	 foreach my $line (@not_exist_files) {
		 print " $line\n";
	  }
  }
 
  print "TOTAL: $stats{TOTAL} ADDED: $stats{ADDED}\n";
}
elsif (defined($params->{'GET_DUBS'})) {
  my $path = ($params->{GET_DUBS} eq '') ? '.' : $params->{GET_DUBS};
  get_dublicats($path);
  
  print "Finish:\n";
  while(my($hash, $params_arr)= each %file_list ) {
    if ($#{ $params_arr } > 0) {
      print "$hash\n";	
      foreach my $line (@$params_arr) {
    	  print "  $line\n";
       }
     }
  }
 }
elsif (defined($params->{'CHECK_SR'})) {
  my $path = ($params->{CHECK_SR} eq '') ? '.' : $params->{CHECK_SR};
  $params->{NEW_FOLDER} = '.' if (! $params->{NEW_FOLDER});
  check_sr($path);
 }
elsif ($params->{ed2k_hash}) {
  my($path, $filename, $size, $hash) = make_ed2k_hash($params->{ed2k_hash});
  print "$path, $filename, $size, $hash\n";
}




#**********************************************************
#
#**********************************************************
sub check_sr {
  my ($dir) = @_;

  print "Check files PATH: '$dir'\n" if ($debug == 1);
  
  # HASH -> (PATH_ARRAY)
  my %file_list = ();
  
  opendir DIR, $dir or return;
    my @contents = map "$dir/$_",
    sort grep !/^\.\.?$/,
    readdir DIR;
  closedir DIR;

foreach my $file (@contents) {
  exit if ($recursive == $rec_level && $recursive != 0 );

  if (! -l $file && -d $file ) {
    $rec_level++;
    &check_sr($file);
   }
  elsif ($file) {

    my ($filename, $dir, $size, $ed2k_hash) = make_ed2k_hash($file);

    print "$file / $ed2k_hash\n" if ($debug == 1);
    
    my $search_ret = sr_search($ed2k_hash);
    
    if (ref $search_ret eq 'HASH') {
       $search_ret->{ORIGIN_NAME} =~ s/ /\./g;
#       /\:*?<>"

       if($search_ret->{LINKS} =~ /ed2k:\/\/\|file\|[\(\)a-zA-Z0-9 @&"',\.]+(\d)[ |\.]of[ |\.]\d[\(\)a-zA-Z0-9 @&"',\.]+\|$size\|$ed2k_hash\|/) {
       	  $search_ret->{ORIGIN_NAME} .= ".cd$1";
        }

       print "$file -> $search_ret->{ORIGIN_NAME}.avi | $search_ret->{NAME}\n";
       if (! -f "$params->{NEW_FOLDER}/$search_ret->{ORIGIN_NAME}.avi") {
         $file =~ s/"/\\"/;
         #$search_ret->{ORIGIN_NAME} =~ s/\"/\\"/;
         $search_ret->{ORIGIN_NAME} =~ s/\/\:*?<>"/_/;
         
         print "mv \"$file\" \"$params->{NEW_FOLDER}/$search_ret->{ORIGIN_NAME}.avi\"\n";
         
         system("mv \"$file\" \"$params->{NEW_FOLDER}/$search_ret->{ORIGIN_NAME}.avi\"");
        }
       else {
       	 print "Exist...\n";
        }
     }
  
    
    #push @{ $file_list{$ed2k_hash} }, "$filename, $dir, $size, $ed2k_hash";
   }
}

}



#**********************************************************
#
#**********************************************************
sub get_dublicats {
  my ($dir) = @_;

  print "Check files PATH: '$dir'\n" if ($debug == 1);
  # HASH -> (PATH_ARRAY)
  opendir DIR, $dir or return;
    my @contents = map "$dir/$_",
    sort grep !/^\.\.?$/,
    readdir DIR;
  closedir DIR;

foreach my $file (@contents) {
  exit if ($recursive == $rec_level && $recursive != 0 );

  if (! -l $file && -d $file ) {
    $rec_level++;
    &get_dublicats($file);
   }
  elsif ($file) {
    print "$file\n" if ($debug == 1);
    my ($filename, $dir, $size, $ed2k_hash) = make_ed2k_hash($file);
    push @{ $file_list{$ed2k_hash} }, "$filename/$dir, $size, $ed2k_hash";
   }
}

 
}

#*********************************************************
#
#*********************************************************
sub make_ed2k_hash {
 my ($file) = @_;
 my $ed2k_hash = '';

    #Make ed2k hash
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$file");

   	my $filename = $file;
   	$filename =~ s/$conf{FILEARCH_PATH}//;
  	my $dir  = dirname($filename);
  	$filename =~ s/$dir\///;
  	$dir =~ s/^\///;
    
    #my $date = strftime "%Y-%m-%d %H:%M:%S", localtime($mtime);
    $blocks = int($size / BLOCKSIZE);
    $blocks++ if ($size % BLOCKSIZE > 0);
    my @blocks_hashes = ();

    my $ctx = Digest::MD4->new;   
    open(FILE, "$file") || die "Can't open '$file' $!\n";
    binmode(FILE);
    my $data;    
    for (my $b=0; $b < $blocks; $b++) {

       my $len =  BLOCKSIZE;
       $len = $size % BLOCKSIZE if ($b == $blocks - 1); 
       
       my $ADDRESS = ($b * BLOCKSIZE);
       seek(FILE, $ADDRESS, 0) or die "seek:$!\n";
       read(FILE, $data, $len);
       $ctx->add($data);
       $blocks_hashes[$b]=$ctx->digest;
       print " hash block $b: ". bin2hex($blocks_hashes[$b]) ."\n" if ($debug > 1);
     }
    close(FILE);

    $ctx->add(@blocks_hashes);
    my $filehash = $ctx->hexdigest;
    #$filehash =~ tr/[a-z]/[A-Z]/;



 
 return ($dir, $filename, $size, $filehash);
}

#**********************************************************
# Ge physical file location
#**********************************************************
sub getfiles {
  my $dir = shift;

  if ($dir =~ /$conf{FILEARCH_SKIPDIR}/) {
  	print "Skip dir '$conf{FILEARCH_SKIPDIR}'\n";
  	return 0;
   }

  opendir DIR, $dir or return;
    my @contents = map "$dir/$_",
    sort grep !/^\.\.?$/,
    readdir DIR;
  closedir DIR;



foreach my $file (@contents) {
  exit if ($recursive == $rec_level && $recursive != 0 );

  if (! -l $file && -d $file ) {
    $rec_level++;
    #print "Recurs Level: $rec_level\n";
    &getfiles($file);
   }
  elsif ($file) {
    $stats{TOTAL}++;

    #Make ed2k hash
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$file");

   	my $filename = $file;
   	$filename =~ s/$conf{FILEARCH_PATH}//;
  	$dir  = dirname($filename);
  	$filename =~ s/$dir\///;
  	$dir  =~ s/^\///;
  	$size = 0;
    
    if (defined($FILEHASH->{"$filename"}{"$dir"})) {
    	 print "Skip $dir / $filename\n" if ($debug > 1);
    	 next;
     }
    
    my $filehash = '';
    if ($conf{ED2K}) {
      ($dir, $filename, $size, $filehash) = make_ed2k_hash($file);
  	 }

  	print "D: $dir F: $filename H: $filehash S: $size \n" if ($debug > 0);
  	


    $filename =~ s/'/\\'/g;
    $dir =~ s/'/\\'/g;
  	$Filearch->file_add({ FILENAME => "$filename",
  		                    PATH     => "$dir", 
                          NAME     => "",
                          CHECKSUM => "ed2k|$filehash",
                          SIZE     => $size,
                          AID      => 0,
                          COMMENTS => ''
                        });
  	
    if ($Filearch->{errno}) {
      print "[$Filearch->{errno}] \"$Filearch->{errstr}\"";
      exit 0;
     }

    $stats{ADDED}++;
   }

 }

  $rec_level--;
}



#**********************************************************
#
#**********************************************************
sub dirname {
    my($x) = @_;
    if ( $x !~ s@[/\\][^/\\]+$@@ ) {
     	$x = '.';
    }
    $x;
}

#**********************************************************
#
#**********************************************************
sub file_hash {
  my $list = $Filearch->file_list({ PAGE_ROWS => 1000000 });
	my %FILEHASH = ();
	foreach my $line (@$list) {
	   $FILEHASH{"$line->[1]"}{"$line->[2]"}=$line->[4];
	 }
	
	
	return \%FILEHASH;
}

#**********************************************************
#
#**********************************************************
sub files_list {
	
	
	return 0;
}

#**********************************************************
# POST INFO FROM SHARE REAKTOR
#**********************************************************
sub post_info {
  
  my %langs = ('Русский дублированный'            => 0,
               'Русский профессиональный перевод' => 1,
               'Русский любительский перевод'     => 2,
               'Русский'                          => 3);

  
  my $genres_list = $Filearch->genres_list();
	my %SR_GENRES_HASH = ();
	foreach my $line (@$genres_list) {
    $SR_GENRES_HASH{$line->[2]}=$line->[4];
   }

  my $list = $Filearch->video_list({ PAGE_ROWS => 1000000 });
	foreach my $line (@$list) {
     next if ($line->[14] > 0 && ! defined($params->{CHECK_ALL} ));
     
     my($type, $search_string);
     if ($line->[11] =~ /ed2k/) {
    	 ($type, $search_string)=split(/\|/, $line->[11], 2);
      } 

     #Check exist files
     if (! -f "$conf{FILEARCH_PATH}/$line->[10]/$line->[9]") {
       push @not_exist_files, "$line->[10]/$line->[9]|$line->[11]";
      } 

     print "$line->[9]\n" if ($debug > 0);

     my $search_ret = sr_search($search_string);
     if (ref $search_ret eq 'HASH') {
     	  $Filearch->file_change({ ID   => $line->[0], 
     	                           NAME => $search_ret->{NAME} 
     	                          });
     	  
     	   if (defined($search_ret->{GENRE})) {
           my @genre_arr = split(/, /, $search_ret->{GENRE});
           my @genre_ids = ();
           foreach my $line (@genre_arr) {
           	 if ($SR_GENRES_HASH{$line}) {
               push @genre_ids, $SR_GENRES_HASH{$line};
              }
   	         else {
               print  "Unknovn genre '$line'\n";
               exit;
   	          }
   	        }
           $search_ret->{GENRES} = join(', ', @genre_ids);
          }
        
        #get language
        if (defined($langs{$search_ret->{LANGUAGE}})) {
          $search_ret->{LANGUAGE}=$langs{$search_ret->{LANGUAGE}};
   	     }
        
        if (defined($search_ret->{ORIGIN_NAME})) {
        	 $search_ret->{ORIGIN_NAME}=~s/'/\\'/g;
          }
  	    
   	    if (defined($search_ret->{PRODUCER})) {
   	    	$search_ret->{PRODUCER}=~s/'/\\'/g;
   	     }

   	    if (defined($search_ret->{ACTORS})) {
   	    	$search_ret->{ACTORS}=~s/'/\\'/g;
   	     }

   	    $Filearch->video_change({ ID => $line->[0], %$search_ret});
   	    $stats{ADDED}++;
      }

    $stats{TOTAL}++;
	 }

}


1

