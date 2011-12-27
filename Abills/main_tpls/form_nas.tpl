<div class='noprint'>
<form action=$SELF_URL METHOD=post name=FORM_NAS>
<input type=hidden name='index' value='61'>
<input type=hidden name='NAS_ID' value='%NAS_ID%'>
<TABLE class=form>
<TR><th class=form_title colspan=2>$_NAS</th></TR>
<TR><TD>ID</TD><TD><b>%NAS_ID%</b> <i>%CHANGED%</i></TD></TR>
<TR><TD>IP</TD><TD><input type=text name=NAS_IP value='%NAS_IP%'></TD></TR>
<TR><TD>$_NAME (a-ZA-Z0-9_):</TD><TD><input type=text name=NAS_NAME value='%NAS_NAME%'></TD></TR>
<TR><TD>Radius NAS-Identifier:</TD><TD><input type=text name=NAS_INDENTIFIER value='%NAS_INDENTIFIER%'></TD></TR>
<TR><TD>$_DESCRIBE:</TD><TD><input type=text name=NAS_DESCRIBE value='%NAS_DESCRIBE%'></TD></TR>
<TR><TD>$_TYPE:</TD><TD>%SEL_TYPE%</TD></TR>
<TR><TD>MAC:</TD><TD><input type=text name=MAC value='%MAC%'></TD></TR>
<TR><TD>$_AUTH:</TD><TD>%SEL_AUTH_TYPE%</TD></TR>
<TR><TD>External Accounting:</TD><TD>%NAS_EXT_ACCT%</TD></TR>
<TR><TD>Alive (sec.):</TD><TD><input type=text name=NAS_ALIVE value='%NAS_ALIVE%'></TD></TR>
<TR><TD>$_DISABLE:</TD><TD><input type=checkbox name=NAS_DISABLE value=1 %NAS_DISABLE%></TD></TR>
<TR><th colspan=2>:$_MANAGE:</th></TR>
<TR><TD>IP:PORT:</TD><TD><input type=text name=NAS_MNG_IP_PORT value='%NAS_MNG_IP_PORT%'></TD></TR>
<TR><TD>$_USER:</TD><TD><input type=text name=NAS_MNG_USER value='%NAS_MNG_USER%'></TD></TR>
<TR><TD>$_PASSWD:</TD><TD><input type=password name=NAS_MNG_PASSWORD value='%NAS_MNG_PASSWORD%'></TD></TR>
<TR><th colspan=2>RADIUS $_PARAMS (,)</th></TR>
<TR><th colspan=2><textarea cols=50 rows=4 name=NAS_RAD_PAIRS>%NAS_RAD_PAIRS%</textarea></th></TR>
<TR><td class=line colspan=2></td></TR>
<TR><TD>$_GROUP:</TD><TD>%NAS_GROUPS_SEL%</TD></TR>
%ADDRESS_TPL%

<TR><TD colspan=2>%EXTRA_PARAMS%</TD></TR>
<TR><TD colspan=2 class=even><input type=submit name=%ACTION% value='%LNG_ACTION%'></TD></TR>
</TABLE>

</form>
</div>
