<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name=sid value='$sid'>
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=m value='%m%'>
<input type=hidden name='index' value='$index'>
<TABLE width=500 border=0>
<TR><TD>$_FROM:</TD><TD bgcolor='$_COLORS[2]'>$user->{TP_ID} %TP_NAME% <!-- [<a href='$SELF?index=$index&TP_ID=%TP_ID%' title='$_TARIF_PLANS'>$_TARIF_PLANS</a>] --></TD></TR>
<TR><TD>$_TO:</TD><TD>%TARIF_PLAN_SEL%</TD></TR>
%PARAMS%
</TABLE>
<input type=submit name=%ACTION% value=\'%LNG_ACTION%\'>
</form>
