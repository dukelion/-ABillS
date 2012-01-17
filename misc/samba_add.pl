#!/usr/bin/perl -w
# Add system and samba users

if ($#ARGV < 1){
   print "Please specify user and password\n";
   print " Example:\n";
   print " samba_add.pl USERNAME PASSWORD\n";
   exit;
}


my $username = $ARGV[0];
my $passwd = $ARGV[1];

my $a = `/usr/sbin/pw useradd $username -g 1139 -h - -d /home/$username -s /sbin/nologin -c "Samba User"`;
my $ADDSMBD = "/usr/local/samba3/bin/pdbedit -t -a $username";

open(ADDUSER, "| $ADDSMBD") || die "Can't open file '$ADDSMBD' $!\n";
  print ADDUSER "$passwd\n";
  print ADDUSER "$passwd\n";
close(ADDUSER);

$a = `killall -1 smbd`;

