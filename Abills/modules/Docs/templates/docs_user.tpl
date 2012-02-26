<form action='$SELF_URL' method='post' name='docs_user'>
<input type=hidden name=index value=$index>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='sid' value='$FORM{sid}'>
<input type=hidden name='step' value='$FORM{step}'>
<table class=form>
<tr><th class='form_title' colspan=2>$_DOCS</th></tr>
<tr><td>$_INVOICE_AUTO_GEN:</td><td><input type=checkbox name=PERIODIC_CREATE_DOCS value=1 %PERIODIC_CREATE_DOCS%></td></tr>
<tr><td>$_SEND E-mail:</td><td><input type=checkbox name=SEND_DOCS value=1 %SEND_DOCS%></td></tr>
<tr><td>$_PERSONAL_DELIVERY</td><td><input type=checkbox name=PERSONAL_DELIVERY value=1 %PERSONAL_DELIVERY%></td></tr>
<tr><td>E-mail:</td><td><input type=text name=EMAIL value='%EMAIL%'></td></tr>
<tr><td>$_INVOICING_PERIOD</td><td>%INVOICE_PERIOD_SEL%</td></tr>
<tr><td>$_INVOICE $_DATE</td><td>%INVOICE_DATE%</td></tr>

<tr><td>$_NEXT_INVOICE_DATE</td><td>%NEXT_INVOICE_DATE%</td></tr>
<tr><th colspan=2>$_COMMENTS</th></tr>
<tr><td colspan=2><textarea name=COMMENTS rows=6 cols=60>%COMMENTS%</textarea></td></tr>
<tr><th class='even' colspan=2>
%BACK_BUTTON%
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</th></tr>
</table>

</form>
