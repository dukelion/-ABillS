#!/usr/bin/perl
# Docs
#
#

$img = $ARGV[0];


print("Content-type: image/jpg\n\n");
$img_file = "img/$img.jpg";

if ((! -e $img_file) || ($img_file =~ /;/)) {
   $img_file = "img/none.jpg";
}


open(FILE, "<$img_file") || die "Can't open file $! \n";
  @file = <FILE>;
close(FILE);

print @file;
