<form action='$SELF_URL'>
<input type=hidden name='index' value='$index'/>
<input type=hidden name='UID' value='%UID%'/>
<input type=hidden name='COMPANY_ID' value='$FORM{COMPANY_ID}'/>
<TABLE width=400>
<TR><TH colspan='2' class=form_title>$_BILL: %BILL_TYPE%</TH></TR>
<TR><TD>$_BILL:</TD><TD>%BILL_ID%:%LOGIN%</TD></TR>
<TR><TD>$_CREATE:</TD><TD><input type='checkbox' name='%CREATE_BILL_TYPE%' value='1' %CREATE_BILL% /></TD></TR>
<TR><TD>$_TO:</TD><TD>%SEL_BILLS%</TD></TR>
</TABLE>
%CREATE_BTN%
<input type='submit' name='change' value='$_CHANGE' class='button'/>
</form>
