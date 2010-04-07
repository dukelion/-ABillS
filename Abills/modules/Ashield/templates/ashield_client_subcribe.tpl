<form action=$SELF_URL method=post NAME=user_form>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='$FORM{UID}'>
<table cellspacing='0' cellpadding='3'>
<tr><th colspan=2 class=form_title>$_ANTIVIRUS Dr.Web</th></tr>	
<tr><th colspan=2><a href='' target_new>$_INFO</a></th></tr>	
<tr><td>E-mail:</td><td><input type=text name=EMAIL value='%EMAIL%'></td></tr>	
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>

