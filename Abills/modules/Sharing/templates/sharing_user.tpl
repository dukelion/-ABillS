<form action='$SELF_URL' method='post'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>

<table width=420 cellspacing='0' cellpadding='3'>
<tr><td>$_TARIF_PLAN:</td><th  align='left' valign='middle'>[%TP_ID%] %TP_NAME% %CHANGE_TP_BUTTON%</th></tr>
<tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=SIMULTANEONSLY value='%SIMULTANEONSLY%'></td></tr>
<tr><td>$_SPEED (kb):</td><td><input type=text name=SPEED value='%SPEED%'></td></tr>
<tr><td>$_FILTERS:</td><td><input type=text name=FILTER_ID value='%FILTER_ID%'></td></tr>
<tr><td>CID:</td><td><input type=text name='CID' value='%CID%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type='checkbox' name='DISABLE' value='1' %DISABLE%></td></tr>
<tr><td>$_TYPE:</td><td>%TYPE_SEL%</td></tr>
<tr><td>$_EXTRA_TRAFIC:</td><td>%EXTRA_TRAFIC%</td></tr>
%SAMBA_ADD%
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%' class='noprint'>
</form>
