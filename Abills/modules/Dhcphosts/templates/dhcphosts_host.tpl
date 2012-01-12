<dir class=noprint id=dhcphosts_host>
<FORM action='$SELF_URL' MATHOD='POST' id=form_host>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=$FORM{UID}>
<input type=hidden name=ID value=$FORM{chg}>
<input type=hidden name='step' value='$FORM{step}'>
<table class=form width=450>

<tr><th class=form_title colspan=2>DHCP</th></tr>			
<tr><td>$_HOSTS_HOSTNAME:</td><td><input type=text name=HOSTNAME value='%HOSTNAME%'></td></tr>			
<tr><td>$_HOSTS_NETWORKS:</td><td>%NETWORKS_SEL% %NETWORK_BUTTON%</td></tr>
<tr><td>IP:</td><td><input type=text name=IP value='%IP%' size=15> $_AUTO: <input type=checkbox name=AUTO_IP value=1></td></tr>			
<tr><td>$_HOSTS_MAC:<BR>(00:00:00:00:00:00)</td><td><input type=text name=MAC value='%MAC%'></td></tr>
<tr><td>$_FILE:</td><td><input type=text name=BOOT_FILE value='%BOOT_FILE%'></td></tr>
<tr><td>NEXT HOST:</td><td><input type=text name=NEXT_SERVER value='%NEXT_SERVER%'></td></tr>
<tr><td>$_EXPIRE:</td><td><input type=text name=EXPIRE value='%EXPIRE%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><td>$_COMMENTS:</td><td><input type=text name=COMMENTS value='%COMMENTS%'></td></tr>

<tr><th colspan=2><input type=checkbox name=OPTION_82 onClick='samechanged(this)' value='1' %OPTION_82% NAME='same'> Option 82 </th></tr>
<tr><td>$_PORT (1,2,5):</td><td><input type=text name=PORTS value='%PORTS%'></td></tr>
<tr><td>VLAN ID:</td><td><input type=text name=VID value='%VID%'></td></tr>
<tr><td>$_SWITCH:</td><td>%SWITCH_SEL% %NAS_BUTTON%</td></tr>

<tr class=even><td>$_ACTIVATE IPN:</td><td><input type=checkbox name=IPN_ACTIVATE value=1 %IPN_ACTIVATE%>%IPN_ACTIVATE_BUTTON%</td></tr>
<tr><th class=even colspan=2>
%BACK_BUTTON%
<input type=submit name=%ACTION% value='%ACTION_LNG%'></th></tr>			
</table>

</FORM>
</div>

