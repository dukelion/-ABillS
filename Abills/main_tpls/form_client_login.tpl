<script type=\"text/javascript\">
	function selectLanguage() {
		sLanguage	= '';
		
		try {
			frm = document.forms[0];
			if(frm.language)
				sLanguage = frm.language.options[frm.language.selectedIndex].value;
			sLocation = '$SELF_URL?DOMAIN_ID=$FORM{DOMAIN_ID}&language='+sLanguage;
			location.replace(sLocation);
		} catch(err) {
			alert('Your brownser do not support JS');
		}
	}
</script>

<br>
<br>


<form action='$SELF_URL' METHOD='post'>
<input type=hidden name=DOMAIN_ID value='$FORM{DOMAIN_ID}'>
<TABLE width='400'  cellspacing='0' cellpadding='0' border='0'><TR><TD bgcolor='$_COLORS[4]'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0'><TR><TD bgcolor='$_COLORS[1]'>
<TABLE width='100%' cellspacing='0' cellpadding='0' border='0'>
<TR><TD colspan=2>&nbsp;</TD></TR>
<TR><TD align=right width=50%>&nbsp;$_LANGUAGE: &nbsp;</TD><TD  width=50%>%SEL_LANGUAGE%</TD></TR>
<TR><TD align=right>&nbsp;$_LOGIN: &nbsp;</TD><TD><input type='text' name='user'></TD></TR>
<TR><TD align=right>&nbsp;$_PASSWD: &nbsp;</TD><TD><input type='password' name='passwd'></TD></TR>
<tr><th colspan='2'><input type='submit' name='logined' value=' $_ENTER '></th></TR>
<TR><TD colspan=2>&nbsp;</TD></TR>
</TABLE>
</TD></TR></TABLE>
</TD></TR></TABLE>
</form>

<br>
<br>
