#!/usr/bin/perl -w
#
#Linux pppd module
#(Wenger)
#
#/etc/sudoers
#
#apache   ALL = NOPASSWD: /usr/abills/misc/pppd_hangup.pl
#

use strict;
if ($#ARGV < 0) {
  print "No arguments\n pppd.pl hangup [id]\n";
  exit;
}

my $rad_detail = '/var/log/radius/radacct/127.0.0.1/';

#if ($ARGV[0] eq 'hangup') { hangup($ARGV[1]); }

#*************************************
# Hangup pppd
#*************************************
sub hangup {
my $id = shift;
my ($pid, $flag, $ip) = (0, -1, 0);

open(DET, "/bin/ls -1t $rad_detail/detail-* |") || die "No sach file '$rad_detail/detail-*' $!\n";

while(<DET>) {
    open(FIL, "$_");
    while(<FIL>) {
        if (/Acct-Session-Id/) {
            $flag = -1;
            if (/$id/) { $flag = 0 };
        }
        if (/Calling-Station-Id = "(\d+\.\d+\.\d+\.\d+)"/ && $flag == 0) {
            $ip = $1;
        }
    }
    close FIL;
    if ($ip) { 
        close DET;
        open(SYS, "/bin/ps ax | /bin/grep \"ipparam $ip\" | /bin/grep -v grep |");

        $pid = <SYS>;
        $pid =~ s/^\s+(\d+).*/$1/;
        kill 1, $pid;
        close SYS;
        exit 0;
    } else {
        exit 1;
    }
}

}
