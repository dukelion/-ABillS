<form action='$SELF_URL' method='post' name='compensation'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>
<table width=400 class='form'>
<tr><th colspan=2 class='form_title'>$_COMPENSATION</th></tr>
<tr><td>$_FROM:</td><td>%FROM_DATE%</td></tr>
<tr><td>$_TO:</td><td>%TO_DATE%</td></tr>
<tr><td>$_DESCRIBE:</td><td><textarea name='DESCRIBE' cols=35 rows=2>%DESCRIBE%</textarea></td></tr>
<tr><td>$_INNER $_DESCRIBE:</td><td><textarea name='INNER_DESCRIBE' cols=35 rows=2>%INNER_DESCRIBE%</textarea></td></tr>
<tr><th colspan=2 class=even><input type=submit name='add' value='$_COMPENSATION' class='noprint'></th></tr>
</table>

</form>
