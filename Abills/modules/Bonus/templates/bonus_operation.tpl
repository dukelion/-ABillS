<script language=\"JavaScript\" type=\"text/javascript\">
<!--
function postthread(param) {
       param = document.getElementById(param);
//       var id = setTimeout(param.disabled=true,10);
       param.value='$_IN_PROGRESS...';
       param.style.backgroundColor='#dddddd'; 
}
-->
</script>

<div class='noprint'>
<form action='$SELF_URL' METHOD='POST' name='bonus_payment' onsubmit=\"postthread('submitbutton');\">
<input type=hidden name=index value=$index>
<input type=hidden name=OP_SID value=%OP_SID%>
<input type=hidden name=UID value=$FORM{UID}>
<input type=hidden name=BILL_ID value=%BILL_ID%>

<TABLE>
<TR><TH class='form_title' colspan=3>$_PAYMENTS / $_FEES</TH></TR>

<TR><TD colspan=2>$_SUM:</TD><TD><input type=text name=SUM value='$FORM{SUM}'></TD></TR>
<TR><TD colspan=2>$_ACTION:</TD><TD>%ACTION_TYPES%</TD></TR>
<TR><TD rowspan=2>$_DESCRIBE:</TD><TD>$_USER:</TD><TD><input type=text name=DESCRIBE value='%DESCRIBE%' size=40></TD></TR>
<TR> <TD>$_INNER:</TD><TD><input type=text name=INNER_DESCRIBE size=40></TD></TR>
<TR><TD colspan=3><hr size=1></TD></TR>
<TR><TD colspan=2>$_EXPIRE:</TD><TD><input type=text name='EXPIRE' value='%EXPIRE%' size=12 ID='EXPIRE' > 
<script language=\"JavaScript\">
	var o_cal = new tcal ({	'formname': 'bonus_payment',	'controlname': 'EXPIRE'	});
	
	// individual template parameters can be modified via the calendar variable
	o_cal.a_tpl.yearscroll = false;
	o_cal.a_tpl.weekstart  = 1;
 	o_cal.a_tpl.months     = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
	o_cal.a_tpl.weekdays   = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Суб'];

</script>

</TD></TR>
<TR><TD colspan=2>$_PAYMENT_METHOD:</TD><TD>%SEL_METHOD%</TD></TR>
<TR><TD colspan=2>EXT ID:</TD><TD><input type=text name='EXT_ID' value='%EXT_ID%'></TD></TR>
%DATE%
</TABLE>
<input type=submit name=add value='$_EXECUTE' ID='submitbutton' >
</form>
</div>
