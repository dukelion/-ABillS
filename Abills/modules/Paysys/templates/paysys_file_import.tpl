<form action='$SELF_URL' METHOD='POST' ENCTYPE='multipart/form-data'>
<input type='hidden' name='index' value='$index'>

<table>
<tr><th align=right colspan=2 bgcolor='$_COLORS[0]'>IMPORT</th></tr>
<tr><td>$_FILE:</td><td><input type=file name='FILE_DATA' value='%FILE_DATA%'> <input type=submit name=IMPORT value='IMPORT'></td></tr>
<tr><td>$_FROM:</td><td>%IMPORT_TYPE_SEL%</td></tr>
</table>
</form>