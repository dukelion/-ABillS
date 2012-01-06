<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{chg}'>
<TABLE class=form>
<tr><td>$_NAME:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>$_COMMENTS:</td><td><input type='text' name='COMMENTS' value='%COMMENTS%'></td></tr>
<tr><td>IP:</td><td><input type='text' name='IP' value='%IP%'></td></tr>
<tr><td>NETMASK:</td><td><input type='text' name='NETMASK' value='%NETMASK%'></td></tr>

<tr><th colspan='2' class=even><input type='submit' name='%ACTION%' value='%ACTION_LNG%'></th></tr>
</TABLE>

</form>
