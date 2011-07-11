<SCRIPT TYPE=\"text/javascript\">
<!-- 
function add_comments () {

if (document.user_form.DISABLE.checked) {
  document.user_form.DISABLE.checked=false;

  Q=prompt('$_COMMENTS','');

  if (Q == '' || Q == null) {
  	alert('Enter comments');
  	document.user_form.DISABLE.checked=false;
  	document.user_form.ACTION_COMMENTS.style.visibility='hidden';
   }
  else {
  	document.user_form.DISABLE.checked=true;
    document.user_form.ACTION_COMMENTS.value=Q;
    document.user_form.ACTION_COMMENTS.style.visibility='visible';
   }
 }
else {
	document.user_form.DISABLE.checked=false;
	document.user_form.ACTION_COMMENTS.style.visibility='hidden';
	document.user_form.ACTION_COMMENTS.value='';
 } 

}

// individual template parameters can be modified via the calendar variable
o_cal.a_tpl.yearscroll = false;
o_cal.a_tpl.weekstart  = 1;
o_cal.a_tpl.months     = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
o_cal.a_tpl.weekdays   = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Суб'];


-->
</SCRIPT>


<form action='$SELF_URL' METHOD='POST' NAME=user_form>
<input type=hidden name='index' value='$index'>
<input type=hidden name=COMPANY_ID value='%COMPANY_ID%'>
<TABLE width='450' cellspacing='0' cellpadding='3'>
%EXDATA%
<TR><TD colspan=2>&nbsp;</TD></TR>

<TR><TD>$_CREDIT:</TD><TD><input type=text name='CREDIT' value='%CREDIT%' size=8> 
$_DATE: <input type=text name='CREDIT_DATE' value='%CREDIT_DATE%' ID='CREDIT_DATE' size=12> 
<script language='JavaScript'>var o_cal = new tcal ({	'formname': 'user_form',	'controlname': 'CREDIT_DATE'	});</script>
</TD></TR>
<TR><TD>$_GROUPS:</TD><TD>%GID%:%G_NAME% <a href='$SELF_URL?index=12&UID=$FORM{UID}' class='change rightAlignText'>$_CHANGE</a></TD></TR>
<TR><TD>$_ACTIVATE:</TD><TD><input type=text name=ACTIVATE value='%ACTIVATE%' ID='ACTIVATE' size=12>
	<script language='JavaScript'>var o_cal = new tcal ({	'formname': 'user_form',	'controlname': 'ACTIVATE'	});</script>
</TD></TR>
<TR><TD>$_EXPIRE:</TD><TD><input type=text name=EXPIRE value='%EXPIRE%' ID='EXPIRE' size=12>	
	<script language='JavaScript'>var o_cal = new tcal ({	'formname': 'user_form',	'controlname': 'EXPIRE'	});</script></TD></TR>
<TR><TD>$_REDUCTION (%):</TD><TD><input type=text name=REDUCTION value='%REDUCTION%' size=8>

$_DATE: <input type=text name='REDUCTION_DATE' value='%REDUCTION_DATE%' ID='REDUCTION_DATE' size=12> 
<script language='JavaScript'>var o_cal = new tcal ({	'formname': 'user_form',	'controlname': 'REDUCTION_DATE'	});</script>

</TD></TR>
<TR><TD rowspan=2>$_DISABLE:</TD><TD><input type=checkbox name=DISABLE value='1' onClick=\"add_comments();\" %DISABLE%> %DISABLE_MARK%</TD></TR>
 <TR><TD>%DISABLE_COMMENTS%<input type=text name=ACTION_COMMENTS value='%DISABLE_COMMENTS%'  size=30 style='visibility: hidden;'>%ACTION_COMMENTS%</TD></TR>
<TR><TD>$_REGISTRATION</TD><TD>%REGISTRATION%</TD></TR>
<TR><td colspan='2'>%PASSWORD%</TD></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
