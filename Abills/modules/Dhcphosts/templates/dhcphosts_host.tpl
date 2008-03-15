<SCRIPT>

function samechanged(what) {
  if ( ! what.checked ) {
    what.form.PORTS.disabled = true;
    what.form.PORTS.style.backgroundColor = '$_COLORS[3]';

    what.form.VID.disabled = true;
    what.form.VID.style.backgroundColor = '$_COLORS[3]';

    what.form.NAS_ID.disabled = true;
    what.form.NAS_ID.style.backgroundColor = '$_COLORS[3]';

  } else {

    what.form.PORTS.disabled = false;
    what.form.PORTS.style.backgroundColor = '$_COLORS[2]';

    what.form.VID.disabled = false;
    what.form.VID.style.backgroundColor = '$_COLORS[2]';

    what.form.NAS_ID.disabled = false;
    what.form.NAS_ID.style.backgroundColor = '$_COLORS[2]';

  }
}

samechanged('same');

</SCRIPT>

<FORM action='$SELF_URL' MATHOD='POST'>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=$FORM{UID}>
<input type=hidden name=ID value=$FORM{chg}>
<table>

<tr><td>$_HOSTS_HOSTNAME:</td><td><input type=text name=HOSTNAME value='%HOSTNAME%'></td></tr>			
<tr><td>$_HOSTS_NETWORKS:</td><td>%NETWORKS_SEL%</td></tr>
<tr><td>IP:</td><td><input type=text name=IP value='%IP%'></td></tr>			
<tr><td>$_HOSTS_MAC:<BR>(00:00:00:00:00:00)</td><td><input type=text name=MAC value='%MAC%'></td></tr>
<tr><td>$_EXPIRE:</td><td><input type=text name=EXPIRE value='%EXPIRE%'></td></tr>
<tr><td>$_EXPIRE:</td><td><input type=text name=EXPIRE value='%EXPIRE%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><td>$_COMMENTS:</td><td><input type=text name=COMMENTS value='%COMMENTS%'></td></tr>

<tr><th colspan=2><input type=checkbox name=OPTION_82 onClick='samechanged(this)' value='1' %OPTION_82% NAME='same'> Option 82 </th></tr>
<tr><td>$_PORT (1,2,5):</td><td><input %INPUT_STATE% type=text name=PORTS value='%PORTS%'></td></tr>
<tr><td>VLAN ID:</td><td><input %INPUT_STATE% type=text name=VID value='%VID%'></td></tr>
<tr><td>$_SWITCH:</td><td>%SWITCH_SEL%</td></tr>

</table>
<input type=submit name=%ACTION% value='%ACTION_LNG%'>
</FORM>
