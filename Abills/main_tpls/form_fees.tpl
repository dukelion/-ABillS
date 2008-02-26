<div class='noprint'>
<form action='$SELF_URL'>
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=index value='$index'>
<input type=hidden name=subf value='$FORM{subf}'>
%SHEDULE%
<TABLE>
<TR><TD>$_SUM:</TD><TD><input type='text' name='SUM'></TD></TR>
<TR><TD>$_DESCRIBE:</TD><TD><input type='text' name='DESCRIBE'></TD></TR>
<TR><TD>$_EXCHANGE_RATE:</TD><TD>%SEL_ER%</TD></TR>
%PERIOD_FORM%
%EXT_DATA%
</TABLE>
<input type=submit name='take' value='$_TAKE'>
</form>
</div>
