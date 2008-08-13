<form action='$SELF_URL' method='post'>
<input type=hidden name=index value=$index>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='DOC_ID' value='%DOC_ID%'>
<input type=hidden name='sid' value='$FORM{sid}'>
<input type=hidden name='OP_SID' value='%OP_SID%'>
<input type=hidden name='VAT' value='%VAT%'>
<Table>
<tr><th align=right bgcolor=$_COLORS[0] colspan=2>$_ACCOUNT</th></tr>
%FORM_ACCT_ID%
<tr><td>$_DATE:</td><td><input type=text name=DATE value='%DATE%'></td></tr>
<tr><td>$_CUSTOMER:</td><td><input type=text name=CUSTOMER value='%CUSTOMER%' size=60></td></tr>
<tr><td>$_PHONE:</td><td><input type=text name=PHONE value=%PHONE%></td></tr>
<tr><td>$_ORDER:</td><td>%SEL_ORDER%</td></tr>
<tr><td>$_SUM:</td><td><input type=text name=SUM value='%SUM%'></td></tr>
<!-- <tr><td>$_VAT:</td><td>%COMPANY_VAT%</td></tr> -->
<tr><td colspan=2>&nbsp;</td></tr>
<!-- <tr><td>$_PRE</td><td><input type=checkbox name=PREVIEW value='1'></td></tr> -->
</table>
<!-- <input type=submit name=pre value='$_PRE'>  -->
<input type=submit name=create value='$_CREATE'>
</form>
