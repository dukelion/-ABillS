<script type=\"text/javascript\">
	function selectLanguage() {
		sLanguage	= '';
		
		try {
			frm = document.forms[0];
			if(frm.language)
				sLanguage = frm.language.options[frm.language.selectedIndex].value;
			sLocation = '$SELF_URL?language='+sLanguage;
			location.replace(sLocation);
		} catch(err) {
			alert('Your brownser do not support JS');
		}
	}
</script>

<form action='$SELF_URL' METHOD='post'>
<br>
<br>
<TABLE width='400'  cellspacing='0' cellpadding='0' border='0'><TR><TD bgcolor='$_COLORS[4]'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0'><TR><TD bgcolor='$_COLORS[1]'>
<TABLE width='100%' cellspacing='0' cellpadding='0' border='0'>
<TR><TD>$_LANGUAGE:</TD><TD>%SEL_LANGUAGE%</TD></TR>
<TR><TD>$_LOGIN:</TD><TD><input type='text' name='user'></TD></TR>
<TR><TD>$_PASSWD:</TD><TD><input type='password' name='passwd'></TD></TR>
<tr><th colspan='2'><input type='submit' name='logined' value='$_ENTER'></th></TR>
</TABLE>
</TD></TR></TABLE>
</TD></TR></TABLE>
</form>
