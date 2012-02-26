<form action='$SELF_URL' METHOD='POST'>

<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='MBOX_ID' value='%MBOX_ID%'>
<table class=form>
<tr><td>Email:</td><td><input type=text name=USERNAME value='%USERNAME%'> <b>@</b> %DOMAINS_SEL%</td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=COMMENTS value='%COMMENTS%'></td></tr>
<tr><td>$_LIMIT:</td><td>$_COUNT: <input type=text name=MAILS_LIMIT value='%MAILS_LIMIT%' size=7> $_SIZE (Mb): <input type=text name=BOX_SIZE size=7 value='%BOX_SIZE%'></td></tr>
<tr><td>$_ANTIVIRUS:</td><td><input type=checkbox name=ANTIVIRUS value='1' %ANTIVIRUS%></td></tr>
<tr><td>$_ANTISPAM:</td><td><input type=checkbox name=ANTISPAM value='1' %ANTISPAM%></td></tr>
<tr><td>$_SEND_MAIL:</td><td><input type=checkbox name=SEND_MAIL value='1' %SEND_MAIL%></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><td>$_EXPIRE</td><td><input type=text name=EXPIRE value='%EXPIRE%'></td></tr>
<tr><td>$_REGISTRATION:</td><td>%CREATE_DATE%</td></tr>
<tr><td>$_CHANGED:</td><td>%CHANGE_DATE%</td></tr>
<tr><th colspan=2><hr></th></tr>
%PASSWORD%

<tr><th colspan=2><hr></th></tr>
<tr><th colspan=2 class=even><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table>

</form>
