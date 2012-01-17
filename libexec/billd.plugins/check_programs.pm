# billd plugin
#
# DESCRIBE: Check run programs and run if they shutdown
#
#**********************************************************

check_programs();


#**********************************************************
#
#
#**********************************************************
sub check_programs {

print "Check run programs\n" if ($debug > 1);
if (! $ARGV->{PROGRAMS}) {
	print "Select programs: PROGRAMS=...\n";
  return 0;
 }
	my @programs = split(/;/, $ARGV->{PROGRAMS});
	
	foreach my $line (@programs) {
		my ($name, $start_cmd) = split(/:/, $line, 2);
    if ($debug > 1) {
    	print "Program: $name, $start_cmd\n";    	
     } 
    
    my @ps = split m|$/|, qx/ps axc | grep $name/;
    if ($debug > 1) {
      print join("\n", @ps)."\n";    	
     }
     
     if ($#ps < 0) {
       if ($name eq 'radiusd' && ! $start_cmd) {
     		 if ($OS eq 'FreeBSD') {
      		  $start_cmd="/usr/local/etc/rc.d/radiusd start";
      		}
        }
       my $cmd_result = `$start_cmd`;
       print "$name Program not runnting: $cmd_result\n";
      }
   }

exit;
}


1
