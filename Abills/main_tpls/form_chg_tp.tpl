<form action='$SELF_URL' METHOD='POST' name='user'>
<input type=hidden name=sid value='$sid'>
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=m value='%m%'>
<input type=hidden name='index' value='$index'>
<TABLE width=500 cellspacing=10 cellpadding=1>
<tr><th colspan=2 bgcolor=$_COLORS[0] align=right>$_TARIF_PLANS</th></tr>
<TR><TD>$_FROM:</TD><TD bgcolor='$_COLORS[2]'>$user->{TP_ID} %TP_NAME% </TD></TR>
<TR><TD>$_TO:</TD><TD>%TARIF_PLAN_SEL%</TD></TR>
<TR><TD>$_GET $_ABON:</TD><TD><input type=checkbox name=GET_ABON value=1 checked></TD></TR>
%PARAMS%

<tr><td colspan=2>%SHEDULE_LIST%</td></tr>
</TABLE>
<input type=submit name=%ACTION% value=\'%LNG_ACTION%\'>
</form>
