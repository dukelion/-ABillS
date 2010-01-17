<script type='text/javascript'>
        function selectLanguage() {
                sLanguage       = '';

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

<FORM action='$SELF_URL' METHOD=POST ID='REGISTRATION'>
<input type=hidden name=index value=$index>
<input type=hidden name=DOMAIN_ID value=$FORM{DOMAIN_ID}>

<TABLE width=500 cellspacing=0 cellpadding=0 border=0>
<TR><TD bgcolor=#E1E1E1>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<TR><TD bgcolor=#FFFFFF>
<table width=100%>
<tr><th colspan=2 class=form_title>$_REGISTRATION</th></tr>
<tr><td align=right width=50%>$_LANGUAGE:</td><td  width=50%>%SEL_LANGUAGE%</td></tr>
<tr><td align=right>$_LOGIN:</td><td><input type=text name='LOGIN' value='%LOGIN%'></td></tr>
<tr><td align=right>$_FIO:</td><td><input type=text name='FIO' value='%FIO%'></td></tr>
<tr><td align=right>E-MAIL:</td><td><input type=text name='EMAIL' value='%EMAIL%'></td></tr>
<tr><td align=right>$_TARIF_PLAN:</td><td>%TP_SEL%</td></tr>
%PAYMENTS%

<tr><th colspan=2 bgcolor=$_COLORS[0]>$_RULES</th></tr>
<tr><th colspan=2><textarea cols=60 rows=8></textarea></th></tr>
<tr><td align=right>$_ACCEPT:</td><td><input type='checkbox' name='ACCEPT_RULES' value='1'></td></tr>

%CAPTCHA%

<tr><td colspan=2 align=center><input type=submit name=reg value='$_REGISTRATION'></td></tr>
</table>

</td></tr></table>
</td></tr></table>




</FORM>
