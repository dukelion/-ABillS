<form action=$SELF_URL method=post>
<input type=hidden name=index value=$index>
<input type=hidden name=RECIPIENT value=%RECIPIENT%>
<input type=hidden name=SUM value=%SUM%>
<table width=400>
<tr><th colspan=2 class=form_title>$_MONEY_TRANSFER</th></tr>
<tr><td>UID:</td><td>%RECIPIENT%</td></tr>
<tr><td>$_FIO:</td><td>%FIO%</td></tr>
<tr><td>$_SUM:</td><td>%SUM%</td></tr>
<tr><td>$_ACCEPT:</td><td><input type=checkbox name=ACCEPT value=1></td></tr>
<tr><th colspan=2><input type=submit name=transfer value='$_SEND'></th></tr>
</table>
</form>
 