<form acrion='$SELF_URL'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg}>
<table>
<tr><th colspan=2 class=form_title>$_EXTRA_TARIFICATION</th></tr>
<tr><td>ID</th><td>%ID%</th></tr>
<tr><td>$_NAME</th><td><input type=text name=NAME value='%NAME%'></th></tr>
<tr><td>$_PREPAID $_TIME</th><td><input type=text name=PREPAID_TIME value='%PREPAID_TIME%'></th></tr>
</table>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</form>