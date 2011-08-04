<form action='$SELF_URL' METHOD='POST' ENCTYPE='multipart/form-data'>
<input type='hidden' name='index' value='$index'>

<table>
<tr><th align=right colspan=2 bgcolor='$_COLORS[0]'>IMPORT</th></tr>
<tr><td>$_FILE:</td><td><input type=file name='FILE_DATA' value='%FILE_DATA%'> <input type=submit name=IMPORT value='IMPORT'></td></tr>
<tr><td>$_FROM:</td><td>%IMPORT_TYPE_SEL%</td></tr>
<!-- <tr><td>$_CANCEL_PAYMENT:</td><td><input type=checkbox name=CANCEL_PAYMENT value='1'></td></tr> -->
<tr><td>$_DATE:</td><td><input type=text name=DATE value='$DATE'></td></tr>
<tr><td>ENCODE:</td><td>%ENCODE_SEL%</td></tr>
<tr><td>DEBUG:</td><td><input type=checkbox name=DEBUG value='1'></td></tr>
</table>
</form>