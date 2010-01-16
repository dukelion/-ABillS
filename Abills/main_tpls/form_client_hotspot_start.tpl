<html>
<style type=\"text/css\">

body {
  background-color: #FFFFFF;
  color: #000000;
  font-family: Arial, Tahoma, Verdana, Helvetica, sans-serif;
  font-size: 14px;
  /* this attribute sets the basis for all the other scrollbar colors (Internet
Explorer 5.5+ only) */
}


A:hover {text-decoration: none; color: #000000;}

.link_button {
  font-family:  Arial, Tahoma,Verdana, Helvetica, sans-serif;
  background-color: EEEEEE;
  color: 000000;
  border-color : #9F9F9F;
  font-size: 11px;
  padding: 2px;
  border: 1px outset;
  text-decoration: none;
  padding:1px 5px;
}

a.link_button:hover {
  background:#ccc;
  background-color: #DEDEDE;
  border:1px solid #666;
}

input, textarea {
        font-family : Verdana, Arial, sans-serif;
        font-size : 12px;
        color : #000000;
        border-color : #9F9F9F;
        border : 1px solid #9F9F9F;
        background : #EEEEEE;
}


select {
        font-family : Verdana, Arial, sans-serif;
        font-size : 12px;
        color : #000000;
        border-color : #C0C0C0;
        border : 1px solid #C0C0C0;
        background : #EEEEEE;
}

</style>
<body style='margin: 0' bgcolor='#FFFFFF' text='#000000' link='#0000A0'  vlink='#000088'>

<script type=\"text/javascript\">
     function selectLanguage() {
              sLanguage       = '';

              try {
                frm = document.forms[0];
                if(frm.language)
                  sLanguage = frm.language.options[frm.language.selectedIndex].value;
                  sLocation = '$SELF_URL?NAS_ID=$FORM{NAS_ID}&DOMAIN_ID=$FORM{DOMAIN_ID}&language='+sLanguage;
                  location.replace(sLocation);
                } catch(err) {
                        alert('Your brownser do not support JS');
                }
        }
</script>


<center>
<form action='$SELF_URL' METHOD='post'>
<TABLE width=100% border='0' cellpadding='0' cellspacing='0'>
<TR BGCOLOR=$_COLORS[2]><TD align=right>&nbsp;$_LANGUAGE: %SEL_LANGUAGE%</TD></TR>
</TABLE>
</form>

<h1>Hotspot Start Page </h1>
Domain ID: %DOMAIN_ID% Domain name: %DOMAIN_NAME%<br>

<p>
<a class=link_button href='http://192.168.182.1/prelogin'>Login with valid access</a>
<a class=link_button href='$SELF_URL?GUEST_ACCOUNT=1&DOMAIN_ID=%DOMAIN_ID%%PAGE_QS%'>$_GUEST_ACCOUNT</a>
</p>
%ADDRESS_STREET% %ADDRESS_BUILD% %ADDRESS_FLAT%


<form action=$SELF_URL>
<input type=hidden name=DOMAIN_ID value=%DOMAIN_ID%>
<input type=hidden name=NAS_ID value=%NAS_ID%>
<input type=hidden name=language value=$FORM{language}>
<table width=400>
<tr><th class=title bgcolor=$_COLORS[0] colspan=2>$_ICARDS $_INFO</th></tr>
<tr><td>PIN:</td><td><input type=text name=PIN value='' size=30><input type=submit name=1 value='$_INFO'></td></tr>


%SELL_POINTS%


</center>

</table>


</body>
</html>
