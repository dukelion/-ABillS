#!/usr/bin/perl

@data = ("41:56:192.168.101.1:574", "43:56:192.168.101.1:574",  "46:56:192.168.101.1:574");
@caption = ('login', 'duration', 'variant', 'sent', 'reciv', 'phone', 'ip', 'sum');

  use Spreadsheet::WriteExcel;
  my $filename = 'abils.xls';
  print "Content-type: application/vnd.ms-excel\n";
  # The Content-Disposition will generate a prompt to save the file. If you want
  # to stream the file to the browser, comment out the following line.
  print "Content-Disposition: attachment; filename=$filename\n\n";

  binmode(STDOUT);
  my $workbook  = Spreadsheet::WriteExcel->new('-');
     $worksheet = $workbook->add_worksheet();

  make_xls_table(\@caption, \@data);

# Make Excel Report
# $cols = column count, 
# $date = data array
sub make_xls_table {
    my ($caption, $date) = @_;

    my $cols=@$caption;
    $format = $workbook->add_format(); # Add a format
    $format->set_bold();
    $format->set_color('black');
    $format->set_align('center');

   my $x=0;
   my $y=1;
   foreach my $line (@$caption) {
     	 $worksheet->write($y, $x, "$line", $format);
     	 $x++;
     }

#  Add and define a format
#    $format = $workbook->add_format(); # Add a format
#    $format->set_bold();
#    $format->set_color('black');
    $format->set_align('left');

   $y=2;
   foreach $line (@$date) {
      @col_values=split(/:/, $line);
     
      for($x=0;$x<$cols; $x++) {
      	 $worksheet->write($y, $x, "$col_values[$x]", $format);
       } 
      $y++;
    }

   $workbook->close();
}
 
# Parse Excel file for report
#
sub parse_xls_tenplate  {
  my ($template, $values)=@_;

}

