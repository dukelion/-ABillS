<FORM action=$SELF_URL MATHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=$FORM{UID}>
<input type=hidden name=ID value=$FORM{chg}>
<table>

<tr><td>$_HOSTS_HOSTNAME:</td><td><input type=text name=HOSTNAME value='%HOSTNAME%'></td></tr>			
<tr><td>$_HOSTS_NETWORKS:</td><td>%NETWORKS_SEL%</td></tr>
<tr><td>IP:</td><td><input type=text name=IP value='%IP%'></td></tr>			
<tr><td>$_HOSTS_MAC:<BR>(00:00:00:00:00:00)</td><td><input type=text name=MAC value='%MAC%'></td></tr>
<tr><td>$_EXPIRE:</td><td><input type=text name=EXPIRE value='%EXPIRE%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><td>$_COMMENTS:</td><td><input type=text name=COMMENTS value='%COMMENTS%'></td></tr>

<tr><th colspan=2>Option 82</th></tr>
<tr><td>$_PORT:</td><td><input type=text name=PORT value='%PORT%'></td></tr>
<tr><td>$_SWITCH:</td><td>%SWITCH_SEL%</td></tr>
</table>
<input type=submit name=%ACTION% value='%ACTION_LNG%'>
</FORM>
