<FORM ACTION='https://ukrpays.com/указанный адрес' method='POST'>
<INPUT TYPE='HIDDEN' NAME='OPERATION_ID' VALUE='$FORM{OPERATION_ID}'>

<input type='hidden' name='login' value='%UID%'>
<input type='hidden' name='sus_url' value='http://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1&amp;index=$index'>
<input type='hidden' name='lang' value='%LANG%'>


<TABLE width='400'cellspacing='0' cellpadding='0' border='0'><TR><TD bgcolor='#E1E1E1'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0'>
<tr><td bgcolor=$_COLORS[1]>

<table width=100%>


<tr><th align=right bgcolor=$_COLORS[0] colspan=2>Visa / Mastercard (Ukrpays)</th></tr>
<tr><th colspan=2><img src='https://ukrpays.com/img/logo.gif'></th></tr>
<tr><td>$_SUM:</td><td><input type='text' name='amount' value='$FORM{SUM}'></td></tr>
<tr><th colspan=2><input type='submit' name='pay' value='$_ADD'></th></tr>
</table>


<td></tr></table>
<td></tr></table>

</FORM>