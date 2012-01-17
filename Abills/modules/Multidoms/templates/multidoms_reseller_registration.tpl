

<script type=\"text/javascript\">
	function selectLanguage() {
		sLanguage	= '';
		
		try {
			frm = document.forms[0];
			if(frm.language)
				sLanguage = frm.language.options[frm.language.selectedIndex].value;
			sLocation = '$SELF_URL?registration=1&language='+sLanguage;
			location.replace(sLocation);
		} catch(err) {
			alert('Your brownser do not support JS');
		}
	}
</script>


<div align=center>
<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='reg_process' value='1'>
<table>
<tr><th colspan=2 bgcolor=$_COLORS[0] akugn=right>$_REGISTRATION</th></tr>

<TR bgcolor='$_COLORS[2]'><TD>$_LANGUAGE:</TD><TD>%SEL_LANGUAGE%</td></tr>
<tr><td>$_LOGIN:</td><td><input type='text' name='LOGIN' value='%LOGIN%'></td></tr>

<tr><td class=small colspan=2 bgcolor=$_COLORS[9] akugn=right></td></tr>
<tr><td>$_FIO:</td><td><input type='text' name='FIO' value='%FIO%'></td></tr>
<tr><td>$_COMPANY:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>$_PHONE (380505738199):</td><td><input type='text' name='PHONE' value='%PHONE%'></td></tr>
<tr><td>E-Mail:</td><td><input type='text' name='EMAIL' value='%EMAIL%'></td></tr>

<tr><td class=small colspan=2 bgcolor=$_COLORS[9] akugn=right></td></tr>
<tr><td>$_PASSWD:</td><td><input type='password' id='text_pma_pw' name='newpassword' title='$_PASSWD' onchange=\"pred_password.value = 'userdefined';\" /></td></tr>
<tr><td>$_CONFIRM_PASSWD:</td><td><input type='password' name='confirm' id='text_pma_pw2' title='$_CONFIRM' onchange=\"pred_password.value = 'userdefined';\" /></td></tr>
<tr><td class=small  colspan=2 bgcolor=$_COLORS[9] akugn=right></td></tr>

<!---
<tr><td>$_ADDRESS:</td><td><input type='text' name='ADDRESS' value='%ADDRESS%'></td></tr>
-->

<tr><th colspan=2 bgcolor=$_COLORS[0]>$_RULES</th></tr>
<tr><th colspan=2><textarea cols=60 rows=8>%RULES%</textarea></th></tr>
<tr><td>$_ACCEPT:</td><td><input type='checkbox' name='ACCEPT_RULES' value='1'></td></tr>

%CAPTCHA%

</table>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>



