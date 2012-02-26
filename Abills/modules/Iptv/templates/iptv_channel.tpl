<div class='noprint'>
<form action='$SELF_URL' method='post'>
<input type=hidden name='index' value='$index'>
<input type=hidden name=ID value='$FORM{chg}'>
<table class=form>
<TR><TH colspan='2' class=form_title>$_CHANNELS</TH></TR>
<tr><td>$_NUM:</td><td><input type=text name=NUMBER value='%NUMBER%'></td></tr>
<tr><td>$_NAME:</td><td><input type=text name=NAME value='%NAME%'></td></tr>
<tr><td>$_PORT:</td><td><input type=text name=PORT value='%PORT%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>

<tr><th BGCOLOR=$_COLORS[0] colspan=2>$_DESCRIBE:</th></tr>
<tr><th colspan=2><textarea name=DESCRIBE rows=5 cols=50>%DESCRIBE%</textarea></th></tr>
<tr><th colspan=2 class=even><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>

</form>
</div>
