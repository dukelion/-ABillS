#Mail module
$cool = 1;

# Get mailbox size
sub mbox_size () {
 my $mbox_name = shift;
 
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$MAILBOX_PATH/$mbox_name");
 use POSIX qw(strftime);
 $date = strftime "%Y-%m-%d %H:%M:%S", localtime($mtime);

return $size;
}

sub mbox_msg_count () 
{
   my $mbox_name = shift;
   
   open(MBOX, "$MAILBOX_PATH/$mbox_name") or die "Can't open file $!\n";
    while(<MBOX>) {
    	
     }
   close(MBOX);
}