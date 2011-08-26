<form action=$SELF_URL method=post NAME=user_form>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='$FORM{UID}'>
<input type=hidden name=OP_SID value='%OP_SID%'>
<table cellspacing='0' cellpadding='3' width='500'>
<tr><th class=form_title colspan=2>Dr.Web </th></tr>
<tr><td colspan=2>
%TARIF_PLAN_TABLE%
</td></tr>

<!--
<tr><th colspan=2 class=form_title>$_REGISTRATION - $_ANTIVIRUS Dr.Web</th></tr>	
<tr><th colspan=2><a href='' target_new>$_INFO</a></th></tr>	
<tr><td>E-mail:</td><td>%EMAIL%</td></tr>	
-->
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>

