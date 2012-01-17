<form action=$SELF_URL method=post>
<input type=hidden name=index value=$index>
<table width=400>
<tr><th colspan=2 class=form_title>$_MONEY_TRANSFER</th></tr>
<tr><td>$_TO_USER (UID):</td><td><input type=text name=RECIPIENT value='%RECIPIENT%'></td></tr>
<tr><td>$_SUM:</td><td><input type=text name=SUM value=%SUM%></td></tr>
<tr><th colspan=2><input type=submit name=s2 value='$_SEND'></th></tr>
</table>
</form>
 