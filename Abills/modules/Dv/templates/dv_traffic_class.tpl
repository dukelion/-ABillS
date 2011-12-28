<div class='noprint'>
<form action='$SELF_URL' method='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='ID' value='$FORM{chg}'>
<table class=form>
<tr><th colspan=3 class='form_title'>$_TRAFFIC_CLASS</th></tr>

<tr><td colspan=2>$_NAME:</td><td><input type=text name='NAME' value='%NAME%'></td></tr>

<tr><th colspan=3>$_COMMENTS</th></tr>
<tr><th colspan=3><textarea cols=40 rows=3 name='COMMENTS'>%COMMENTS%</textarea></th></tr>


<tr><th colspan=3>NETS (192.168.101.0/24;10.0.0.0/28) </th></tr>
<tr><th colspan=3><textarea cols=40 rows=10 name='NETS'>%NETS%</textarea></th></tr>
<tr><th colspan=3 class='even'><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>
</form>
</div>
