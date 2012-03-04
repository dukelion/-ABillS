<form action='$SELF_URL'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg}>
<input type=hidden name=TP_ID value=$FORM{TP_ID}>
<table class=form>


<tr><td>$_SERVICE $_PERIOD ($_MONTH):</td><td><input type=text name='SERVICE_PERIOD' value='%SERVICE_PERIOD%'></td></tr>
<tr><td>$_REGISTRATION ($_DAYS):</td><td><input type=text name='REGISTRATION_DAYS' value='%REGISTRATION_DAYS%'></td></tr>
<tr><td>$_REDUCTION %:</td><td><input type=text name='DISCOUNT' value='%DISCOUNT%'></td></tr>
<tr><td>$_REDUCTION ($_DAYS):</td><td><input type=text name='DISCOUNT_DAYS' value='%DISCOUNT_DAYS%'></td></tr>
<tr><th colspan='2' class=even><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table>

</form>
