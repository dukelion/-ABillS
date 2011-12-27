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

  function set_referrer () {
    document.getElementById('REFERRER').value=location.href;
	 }
</script>

<br>
<br>


<form action='$SELF_URL' METHOD='post' name=form_login>
<input type=hidden name=DOMAIN_ID value='$FORM{DOMAIN_ID}'>
<input type=hidden ID=REFERRER name=REFERRER value='$FORM{REFERRER}'>
<TABLE width='400'  class=form>
<TR><TH colspan=2 class=form_title>$_USER_PORTAL&nbsp;</TH></TR>
<TR><TD colspan=2>&nbsp;</TD></TR>
<TR><TD align=right width=50%>&nbsp;$_LANGUAGE: &nbsp;</TD><TD  width=50%>%SEL_LANGUAGE%</TD></TR>
<TR><TD align=right>&nbsp;$_USER: &nbsp;</TD><TD><input type='text' name='user'></TD></TR>
<TR><TD align=right>&nbsp;$_PASSWD: &nbsp;</TD><TD><input type='password' name='passwd'></TD></TR>
<tr><th colspan='2' class=even><input type='submit' name='logined' value=' $_ENTER ' onclick='set_referrer()'></th></TR>
</TABLE>
</form>

<br>
<br>
