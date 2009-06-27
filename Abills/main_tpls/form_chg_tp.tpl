<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name=sid value='$sid'>
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=m value='%m%'>
<input type=hidden name='index' value='$index'>
<TABLE width=500 cellspacing=10 cellpadding=1>
<tr><th colspan=2 bgcolor=$_COLORS[0] align=right>$_TARIF_PLANS</th></tr>
<TR><TD>$_FROM:</TD><TD bgcolor='$_COLORS[2]'>$user->{TP_ID} %TP_NAME% <!-- [<a href='$SELF?index=$index&TP_ID=%TP_ID%' title='$_TARIF_PLANS'>$_TARIF_PLANS</a>] --></TD></TR>
<TR><TD>$_TO:</TD><TD>%TARIF_PLAN_SEL%</TD></TR>
%PARAMS%

<tr><td colspan=2>%SHEDULE_LIST%</td></tr>
</TABLE>
<input type=submit name=%ACTION% value=\'%LNG_ACTION%\'>
</form>
