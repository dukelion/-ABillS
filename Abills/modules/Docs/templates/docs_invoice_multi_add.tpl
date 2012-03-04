<form action=$SELF_URL name=multi_create>
<input type=hidden name=index value=$index>

%USERS_TABLE%

<table>
<tr><td>$_DATE:</td><td>%DATE% </td></tr>
<tr><td>$_ORDER:</td><td><input size=30 type=text name=ORDER value=%ORDER%></td></tr>
<tr><td>$_SUM:</td><td><input  type=text name=SUM value='%SUM%' size=5></td></tr>
<tr><td>$_SEND E-mail:</td><td><input type=checkbox name=SEND_EMAIL value='1' checked></td></tr>
</table>

<input type=submit name=create value='$_CREATE'>
</form>
