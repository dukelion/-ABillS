<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data' name=reg_request_form>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type=hidden name=module value=Msgs>
<input type=hidden name=REGISTRATION_REQUEST value=1>


<TABLE width=500 cellspacing=0 cellpadding=0 border=0>
<TR><td bgcolor=#E1E1E1>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<TR><td bgcolor=#FFFFFF>


<table>
<tr><th class=form_title colspan=2>$_REGISTRATION</th></tr>
<!-- <tr><td>$_DATE:</td><td>%DATE%</td></tr> -->
%ADDRESS_TPL%
<tr><td>$_COMPANY:</td><td><input type='text' name='COMPANY_NAME' value='%COMPANY_NAME%' size='45'/></td></tr>
<tr><td>$_FIO:</td><td><input type='text' name='FIO' value='%FIO%' size='45'/></td></tr>
<tr><td>$_PHONE:</td><td><input type='text' name='PHONE' value='%PHONE%' size='45'/></td></tr>
<tr><td>E-mail:</td><td><input type='text' name='EMAIL' value='%EMAIL%' size='45'/></td></tr>
<tr><td>$_CONNECTION_TIME:</td><td><input type='text' name='CONNECTION_TIME' value='%CONNECTION_TIME%' ID='CONNECTION_TIME'/> 

<script language=\"JavaScript\">
	var o_cal = new tcal ({	'formname': 'reg_request_form',	'controlname': 'CONNECTION_TIME'	});
	
	// individual template parameters can be modified via the calendar variable
	o_cal.a_tpl.yearscroll = false;
	o_cal.a_tpl.weekstart  = 1;
 	o_cal.a_tpl.months     = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
	o_cal.a_tpl.weekdays   = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Суб'];
</script>
</td></tr>
<tr><td>$_CHAPTERS:</td><td>%CHAPTER_SEL%</td></tr>
<tr><td>$_SUBJECT:</td><td><input type='text' name='SUBJECT' value='%SUBJECT%' size='50'/></td></tr>

<tr><th class='title_color' colspan='2'>$_COMMENTS</th></tr>
<tr><th colspan='2'><textarea name='COMMENTS' cols='70' rows='9'>%COMMENTS%</textarea></th></tr>


%CAPTCHA%


</table>
</td></tr></table>
</td></tr></table>
<input type='submit' name='%ACTION%' value='%ACTION_LNG%'/>
</FORM>


%MAPS%