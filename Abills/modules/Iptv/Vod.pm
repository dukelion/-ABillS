
$conf{IPTV_VOD_SERVER_CONF}= '/home/asm/iptv/VOD.conf' if (! $conf{IPTV_VOD_SERVER_CONF});
$conf{IPTV_VOD_SERVER_IP}  = '10.0.0.1'            if (! $conf{IPTV_VOD_SERVER_IP});
$conf{IPTV_VLC_PASSWORD}   = 'videolan'            if (! $conf{IPTV_VLC_PASSWORD});
$conf{IPTV_VLC_HOST_PORT}  = 'localhost:4212'      if (! $conf{IPTV_VLC_HOST_PORT});

$conf{IPTV_VLC_VOD_START}  = '/usr/local/bin/vlc -I telnet --control telnet --telnet-password $conf{IPTV_VLC_PASSWORD} --rtsp-host 0.0.0.0:5554 --vlm-conf "$conf{IPTV_VOD_SERVER_CONF}" --pidfile '      if (! $conf{IPTV_VLC_VOD_START});

$conf{IPTV_VLC_VOD_STOP}   = 'kill -9 '      if (! $conf{IPTV_VLC_VOD_STOP});


#**********************************************************
#
#**********************************************************
sub vod_files_list {
 
   my $result = telnet_cmd("$conf{IPTV_VLC_HOST_PORT}", \@commands, { TimeOut => 10 });

   #print $result;

}

#**********************************************************
#
#**********************************************************
sub vod_status {
  my ($attr) = @_;

  if ($attr->{START}) {
    my $res = system("$conf{IPTV_VLC_VOD_START}");
   }
  elsif($attr->{STOP}) {
  	
   }
  #Get status
  else {
  	
   }
}


#**********************************************************
#
#**********************************************************
sub vod_addfile {
  my ($media_file, $attr) = @_;


  

	$cfgpath=$conf{IPTV_VOD_SERVER_CONF};		
  my $content = '';
  my $VOD_ACTIVE_FILES = ();

  $media_file =~ s/\/\//\//g;
  
  if (! open(VOD_CFG, "$cfgpath")) {
      print "Can't open config '$cfgpath' $!\n";
      return 0;
    }

   while(<VOD_CFG>) {
     $content .= $_;
    }
  close(VOD_CFG);

  while($content =~ /new (.+)\s+vod.+\nsetup\s+.+\s+input\s+\"(.+)\"\n/g) {
  	my $cfg_file  = $1;
  	my $full_name = $2;
  	$VOD_ACTIVE_FILES{"$full_name"}=$cfg_file;
  	#print "! $cfg_file  ->	$full_name <br>\n";
   }

  my $cfg_file_name = $media_file;
  $cfg_file_name =~ s/\.[a-z0-9]+$//g;
  $cfg_file_name =~ s/[\.\ \_]?//g;
  
  
	if (! $VOD_ACTIVE_FILES{$media_file}) {					#if identifying string not found
    require "nas.pl";

    my @commands = ();
    push @commands, "Password:\t$conf{IPTV_VLC_PASSWORD}";
    push @commands, ">\tnew ".$cfg_file_name." vod enabled";
    push @commands, ">\tsetup ".$cfg_file_name." input \"".$media_file."\"";
    push @commands, ">\texit";
    #push @commands, ">\tshow";

    #print join("\n", @commands) if ($attr->{debug});


    my $result = telnet_cmd("$conf{IPTV_VLC_HOST_PORT}", \@commands, { TimeOut => 10 });

    #print $result;

    if (! open(VOD_CFG, ">> $cfgpath")) {
      print "Can't open config '$cfgpath' $!\n";
      return 0;
     }

     print VOD_CFG "\n\n# $DATE $TIME";		#load into the VOD config file
  	 print VOD_CFG "\nnew ".$cfg_file_name." vod enabled";		#load into the VOD config file
	   print VOD_CFG "\nsetup ".$cfg_file_name." input \"".$media_file."\""; #load into the VOD config file
     close(VOD_CFG);

     $VOD_ACTIVE_FILES{$media_file}=$cfg_file_name;
   }


=comments
print << "[END]";
<div id='content'>
<table align='left' style='border:none'>
<tr><td  style = 'width:320px;border:none'>
<div style = 'width:320px;'>
<OBJECT ID="mediaPlayer" width="320" height="309"
                CLASSID="CLSID:6BF52A52-394A-11d3-B153-00C04F79FAA6"
                CODEBASE="http://activex.microsoft.com/activex/controls/mplayer/en/nsmp2inf.cab#Version=6,4,5,715"
                STANDBY="Loading Microsoft Windows Media Player components..."
                TYPE="application/x-oleobject">
<PARAM NAME="url" VALUE="mms://$conf{IPTV_VOD_SERVER_IP}:8080">
<PARAM NAME="autoStart" VALUE="1">
<PARAM NAME="bgColor" VALUE="#000000">
<PARAM NAME="showControls" VALUE="true">
<PARAM NAME="TransparentatStart" VALUE="false">
<PARAM NAME="AnimationatStart" VALUE="true">
<PARAM NAME="StretchToFit" VALUE="true">
<EMBED src="mms://$conf{IPTV_VOD_SERVER_IP}:8080"
                        type="application/x-mplayer2"
                        name="MediaPlayer"
                        autostart="1" showcontrols="1" showstatusbar="1" autorewind="1"
                        width="320" height="309"></EMBED>
</OBJECT>
</div>
</td></tr>
<tr><td>
<a class='text' href='mms://$conf{IPTV_VOD_SERVER_IP}:8080'>ќткрыть в ћедиаѕлеер</a>
</td></tr>

</table>
</div>
</div>
[END]


<embed type="application/x-vlc-plugin"
         name="video1"
         autoplay="no" loop="yes" width="400" height="300"
         target="http://$conf{IPTV_VOD_SERVER_IP}:8080" />
<br />
  <a href="javascript:;" onclick='document.video1.play()'>Play video1</a>
  <a href="javascript:;" onclick='document.video1.pause()'>Pause video1</a>
  <a href="javascript:;" onclick='document.video1.stop()'>Stop video1</a>
  <a href="javascript:;" onclick='document.video1.fullscreen()'>Fullscreen</a>
  
=cut

# vlc.exe -Idummy mms://stream06.rambler.ru/europa_inside?WMContentBitrate=80000
# :sout=#std{access=mmsh,mux=asfh,dst=10.10.10.5:8080}
# :sout-all :sout-keep

print << "[END]";
<p align=center>
<embed type="application/x-vlc-plugin"
         name="video1"
         autoplay="no" loop="yes" width="400" height="300"
         target="rtsp://$conf{IPTV_VOD_SERVER_IP}:5554/$VOD_ACTIVE_FILES{$media_file}" />
<br />
  <a href="javascript:;" onclick='document.video1.play()'>Play video1</a>
  <a href="javascript:;" onclick='document.video1.pause()'>Pause video1</a>
  <a href="javascript:;" onclick='document.video1.stop()'>Stop video1</a>
  <a href="javascript:;" onclick='document.video1.fullscreen()'>Fullscreen</a>
</p>
[END]


  if ($VOD_ACTIVE_FILES{$media_file}) {
    return "rtsp://$conf{IPTV_VOD_SERVER_IP}:5554/$cfg_file_name";
   }
	else {
		print "! Error. Can't stream file '$media_file' $cfg_file_name \n";
	 }
	
}


1
