<script type='text/javascript'>
        function selectLanguage() {
                sLanguage       = '';

                try {
                        frm = document.forms[0];
                        if(frm.language)
                                sLanguage = frm.language.options[frm.language.selectedIndex].value;
                        sLocation = '$SELF_URL?DOMAIN_ID=$FORM{DOMAIN_ID}&module=Dv&language='+sLanguage;
                        location.replace(sLocation);
                } catch(err) {
                        alert('Your brownser do not support JS');
                }
        }
</script>


<FORM action='$SELF_URL' METHOD=POST ID='REGISTRATION'>
<input type=hidden name=index value=$index>
<input type=hidden name=DOMAIN_ID value=$FORM{DOMAIN_ID}>
<input type=hidden name=module value=Dv>

<TABLE width=500 class=form>
<tr><th colspan=2 class=form_title>$_REGISTRATION - Internet</th></tr>
<tr><td align=right width=50%>$_LANGUAGE:</td><td  width=50%>%SEL_LANGUAGE%</td></tr>
<tr><td align=right>$_LOGIN:</td><td><input type=text name='LOGIN' value='%LOGIN%'></td></tr>
<tr><td align=right>$_FIO:</td><td><input type=text name='FIO' value='%FIO%' size=40></td></tr>
<tr><td align=right>E-MAIL:</td><td><input type=text name='EMAIL' value='%EMAIL%'></td></tr>
<tr><td align=right>$_TARIF_PLAN:</td><td>%TP_SEL%</td></tr>
%PAYMENTS%

<tr><th colspan=2 class='title_color'>$_RULES</th></tr>
<tr><th colspan=2><textarea cols=60 rows=8></textarea></th></tr>
<tr><td align=right>$_ACCEPT:</td><td><input type='checkbox' name='ACCEPT_RULES' value='1'></td></tr>

%CAPTCHA%

<tr><td colspan=2 align=center><input type=submit name=reg value='$_REGISTRATION'></td></tr>
</table>





</FORM>
