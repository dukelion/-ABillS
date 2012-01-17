<div class='noprint'>
<form action='$SELF_URL' name=user>
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=index value='$index'>
<input type=hidden name=subf value='$FORM{subf}'>
<TABLE class=form>
<TR><TH colspan=3 class='form_title'>$_FEES</TH></TR>
<TR><TD colspan=2>$_SUM:</TD><TD><input type='text' name='SUM'></TD></TR>
<TR><TD rowspan=2>$_DESCRIBE:</TD><TD>$_USER:</TD><TD><input type=text name=DESCRIBE value='%DESCRIBE%' size=40></TD></TR>
<TR><TD>$_INNER:</TD><TD><input type=text name=INNER_DESCRIBE size=40></TD></TR>
<TR><TD colspan=2>$_TYPE:</TD><TD>%SEL_METHOD%</TD></TR>
<TR><TD colspan=2>$_EXCHANGE_RATE:</TD><TD>%SEL_ER%</TD></TR>
%PERIOD_FORM%
%EXT_DATA%

<TR><TD colspan=3>%SHEDULE%</TD></TR>
<TR><TH colspan=3 class='even'><input type=submit name='take' value='$_TAKE'></TH></TR>
</TABLE>

</form>
</div>
