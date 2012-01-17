<form action='$SELF_URL' method='post' name='account_add'>
<input type=hidden name=index value=$index>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='DOC_ID' value='%DOC_ID%'>
<input type=hidden name='sid' value='$FORM{sid}'>
<input type=hidden name='OP_SID' value='%OP_SID%'>
<input type=hidden name='VAT' value='%VAT%'>
<input type=hidden name='SEND_EMAIL' value='1'>
<Table class=form>
<tr><th class='form_title' colspan=2>%CAPTION%</th></tr>
%FORM_ACCT_ID%
<tr><td>$_DATE:</td><td>%DATE_FIELD%</td></tr>
<tr><td>$_CUSTOMER:</td><td><input type=text name=CUSTOMER value='%CUSTOMER%' size=60></td></tr>
<tr><td>$_PHONE:</td><td><input type=text name=PHONE value=%PHONE%></td></tr>
%ORDERS%
<!-- <tr><td>$_VAT:</td><td>%COMPANY_VAT%</td></tr> -->
<tr><td colspan=2>&nbsp;</td></tr>
<!-- <tr><td>$_PRE</td><td><input type=checkbox name=PREVIEW value='1'></td></tr> -->
<tr><th class='even' colspan=2><input type=submit name=create value='$_CREATE'></th></tr>
</table>
<!-- <input type=submit name=pre value='$_PRE'>  -->

</form>
