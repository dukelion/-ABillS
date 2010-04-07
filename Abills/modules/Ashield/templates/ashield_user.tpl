<form action=$SELF_URL method=post NAME=user_form>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='$FORM{UID}'>
<table cellspacing='0' cellpadding='3' width=450>
<tr><th colspan=2 class=form_title>$_ANTIVIRUS Dr.Web</th></tr>	
<!-- 
<tr bgcolor=$_COLORS[2]><td>$_TARIF_PLAN:</td><th  align='left' valign='middle'>[%TP_ID%] %TP_NAME% %CHANGE_TP_BUTTON%</th></tr>
<tr><td>$_EXPIRE:</td><td><input type=text name=EXPIRE value='%EXPIRE%' size=12>	
<script language='JavaScript'>var o_cal = new tcal ({	'formname': 'user_form',	'controlname': 'EXPIRE'	});</script>
</td></tr>
-->
<tr><td>E-mail:</td><td><input type=text name=EMAIL value='%EMAIL%'></td></tr>	
<tr><td>$_STATUS:</td><td>%STATUS_SEL%</td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>

