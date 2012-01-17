<div class='noprint'>
<form action=$SELF_URL method=post>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='$FORM{UID}'>
<table width=420 cellspacing=0 cellpadding=3>
<tr><td>$_TARIF_PLAN:</td><td valign=middle>[%TP_NUM%]<b> %TP_NAME% </b> %CHANGE_TP_BUTTON%</td></tr>
<tr><td>Filter-ID:</td><td><input type=text name=FILTER_ID value='%FILTER_ID%'></td></tr>
<tr><td>PIN:</td><td><input type=text name=PIN value='%PIN%'></td></tr>
<tr><td>VoD:</td><td><input type=checkbox name=VOD value=1 %VOD%></td></tr>
<tr><td>DvCrypt ID:</td><td><input type=input name=DVCRYPT_ID value='%DVCRYPT_ID%'></td></tr>
<tr><td>$_STATUS:</td><td>%STATUS_SEL%</td></tr>

</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>
