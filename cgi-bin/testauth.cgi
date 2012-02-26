#!/usr/bin/perl
print "Content-type: text/plain\n\n";
print <<HTML
 $ENV{REMOTE_USER}
 $ENV{REMOTE_ADDR}
HTML
