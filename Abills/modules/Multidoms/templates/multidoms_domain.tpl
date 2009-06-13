<div align=center>
<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='chg' value='$FORM{chg}'>
<table>
<tr><th colspan=2 bgcolor=$_COLORS[0] align=right>$_DOMAINS</th></tr>


<tr><td>$_NAME:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td class=small colspan=2 bgcolor=$_COLORS[9] akugn=right></td></tr>

<tr><td>$_DISABLE:</td><td><input type='checkbox' name='STATE' value=1 %STATE%></td></tr>
<tr><td>$_CREATED:</td><td>%CREATED%</td></tr>
<tr><th colspan=2 bgcolor='$_COLORS[0]'>$_COMMENTS</th></tr>
<tr><th colspan=2><textarea cols=60 rows=8 name=comments>%RULES%</textarea></th></tr>
</table>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>



