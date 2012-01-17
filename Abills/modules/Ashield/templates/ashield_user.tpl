<form action=$SELF_URL method=post NAME=user_form>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=info value='$FORM{info}'>

<table cellspacing='0' cellpadding='3' width=500>
<tr><th colspan=4 class=form_title>$_ANTIVIRUS Dr.Web</th></tr>	
<tr><td rowspan=2><input type=radio name=STATUS value='2'> $_HOLD_UP </td><td>$_FROM:</td><td>%DATE_FROM%</td></tr>
<tr><td>$_TO:</td><td>%DATE_TO%</td><th>%RESET_BLOCK%</th></tr>

<tr><td colspan=4 class=small></td></tr>
<tr><td colspan=2><input type=radio name=STATUS value='1'> $_DISABLE</td><td>%EXPIRES_DATE%</td><th>%RESET_EXPIRE%</th></tr>

</table>
%ACTION%
</form>

