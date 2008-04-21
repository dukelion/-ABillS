<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='13'>
<input type=hidden name='COMPANY_ID' value='%COMPANY_ID%'>
<TABLE>
<TR><TD>$_NAME:</TD><TD><textarea name='COMPANY_NAME' rows='2' cols='45'>%COMPANY_NAME%</textarea></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_ADDRESS:</TD><TD><input type='text' name='ADDRESS' value='%ADDRESS%' size='60'></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_PHONE:</TD><TD><input type='text' name='PHONE' value='%PHONE%' size='60'></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_BILL:</TD><TD>%BILL_ID%</TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_DEPOSIT:</TD><TD>%DEPOSIT%</TD></TR>
%EXDATA%
<TR bgcolor=$_COLORS[1]><TD>$_CREDIT:</TD><TD><input type=text name=CREDIT value='%CREDIT%'></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_VAT (%):</TD><TD><input type=text name=VAT value='%VAT%'></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_TAX_NUMBER:</TD><TD><input type=text name=TAX_NUMBER value='%TAX_NUMBER%' size=60></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_ACCOUNT:</TD><TD><input type=text name=BANK_ACCOUNT value='%BANK_ACCOUNT%' size=60></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_BANK_NAME:</TD><TD><input type=text name=BANK_NAME value='%BANK_NAME%' size=60></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_COR_BANK_ACCOUNT:</TD><TD><input type=text name=COR_BANK_ACCOUNT value='%COR_BANK_ACCOUNT%' size=60></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_BANK_BIC:</TD><TD><input type=text name=BANK_BIC value='%BANK_BIC%' size=60></TD></TR>
<TR><TD>$_CONTRACT_ID:</TD><TD><input type=text name=CONTRACT_ID value='%CONTRACT_ID%'></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_DISABLE:</TD><TD><input type=checkbox name=DISABLE value='1' %DISABLE%></TD></TR>

%INFO_FIELDS%

</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
