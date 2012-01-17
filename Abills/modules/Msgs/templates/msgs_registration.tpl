<script type='text/javascript'>
        function selectLanguage() {
                sLanguage       = '';

                try {
                        frm = document.forms[0];
                        if(frm.language)
                                sLanguage = frm.language.options[frm.language.selectedIndex].value;
                        sLocation = '$SELF_URL?DOMAIN_ID=$FORM{DOMAIN_ID}&module=Msgs&language='+sLanguage;
                        location.replace(sLocation);
                } catch(err) {
                        alert('Your brownser do not support JS');
                }
        }
</script>


<FORM action='$SELF_URL' METHOD=POST ID='REGISTRATION'>
<input type=hidden name=index value=$index>
<input type=hidden name=DOMAIN_ID value=$FORM{DOMAIN_ID}>
<input type=hidden name=module value=Msgs>

<table width=600 class=form>
<tr><th colspan=2 class=form_title>$_REGISTRATION - $_MESSAGES</th></tr>
<tr><td align=right width=50%>$_LANGUAGE:</td><td  width=50%>%SEL_LANGUAGE%</td></tr>
<tr><td align=right>$_LOGIN:</td><td><input type=text name='LOGIN' value='%LOGIN%'></td></tr>
<tr><td align=right>$_FIO:</td><td><input type=text name='FIO' value='%FIO%' size=40></td></tr>
<tr><td align=right>$_PHONE:</td><td><input type=text name='PHONE' value='%PHONE%'></td></tr>

<tr><td align=right>$_CITY:</td><td><input type=text name=CITY value='%CITY%'></td></tr> 
<tr><td align=right>$_ZIP:</td><td><input type=text name=ZIP value='%ZIP%' size=8></td></TR>
<tr><td align=right>$_ADDRESS_STREET:</td><td><input type=text name=ADDRESS_STREET value='%ADDRESS_STREET%' size=40>

<tr><td align=right>$_ADDRESS_BUILD:</td><td><input type=text name=ADDRESS_BUILD value='%ADDRESS_BUILD%' size=8> $_ADDRESS_FLAT:<input type=text name=ADDRESS_FLAT value='' size=8></td></TR>
<tr><td align=right>E-MAIL:</td><td><input type=text name='EMAIL' value='%EMAIL%'></td></tr>

%PAYMENTS%

<tr><th colspan=2 class='title_color'>$_RULES</th></tr>
<tr><th colspan=2><textarea cols=60 rows=8></textarea></th></tr>
<tr><td align=right>$_ACCEPT:</td><td><input type='checkbox' name='ACCEPT_RULES' value='1'></td></tr>

%CAPTCHA%

<tr><th colspan=2 class=even><input type=submit name=reg value='$_REGISTRATION'></th></tr>
</table>



</FORM>
