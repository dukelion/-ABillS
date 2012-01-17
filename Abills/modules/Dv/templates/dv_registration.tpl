<FORM action='$SELF_URL' METHOD=POST>
<input type=hidden name=index value=$index>
<table>
<tr><th colspan=2 align=right>$_REGISTRATION</th></tr>
<tr><td>$_LOGIN:</td><td><input type=text name='LOGIN' value='%LOGIN%'></td></tr>
<tr><td>$_FIO:</td><td><input type=text name='FIO' value='%FIO%'></td></tr>
<tr><td>E-MAIL:</td><td><input type=text name='EMAIL' value='%EMAIL%'></td></tr>
<tr><td>$_TARIF_PLAN:</td><td>%TP_SEL%</td></tr>
%PAYMENTS%
</table>
<input type=submit name=reg value='$_REGISTRATION'>
</FORM>
