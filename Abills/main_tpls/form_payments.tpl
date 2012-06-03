<script language=\"JavaScript\" type=\"text/javascript\">
<!--
function postthread(param) {
       param = document.getElementById(param);
//       var id = setTimeout(param.disabled=true,10);
       param.value='$_IN_PROGRESS...';
       param.style.backgroundColor='#dddddd'; 
}
-->
</script>

<div class='noprint'>
<form action='$SELF_URL' METHOD='POST' name='user' onsubmit=\"postthread('submitbutton');\">
<input type=hidden name=index value=$index>
<input type=hidden name=subf value=$FORM{subf}>
<input type=hidden name=OP_SID value=%OP_SID%>
<input type=hidden name=UID value=%UID%>
<input type=hidden name=step value=$FORM{step}>

<TABLE class='form'>
<TR><TH class='form_title' colspan=3>$_PAYMENTS</TH></TR>
<TR><TD colspan=2>$_SUM:</TD><TD><input type=text name=SUM value='$FORM{SUM}'></TD></TR>
<TR><TD rowspan=2>$_DESCRIBE:</TD><TD>$_USER:</TD><TD><input type=text name=DESCRIBE value='%DESCRIBE%' size=40></TD></TR>
<TR> <TD>$_INNER:</TD><TD><input type=text name=INNER_DESCRIBE size=40></TD></TR>
<TR><TD colspan=2>$_EXCHANGE_RATE:</TD><TD>%SEL_ER%</TD></TR>
<TR><TD colspan=3><hr size=1></TD></TR>
<TR><TD colspan=2>$_PAYMENT_METHOD:</TD><TD>%SEL_METHOD%</TD></TR>
<TR><TD colspan=2>EXT ID:</TD><TD><input type=text name='EXT_ID' value='%EXT_ID%'></TD></TR>
%DATE%
%EXT_DATA%



%DOCS_ACCOUNT_ELEMENT%

<TR><TH class='even' colspan=3>%BACK_BUTTON% <input type=submit name=%ACTION% value='%LNG_ACTION%' ID='submitbutton'></TH></TR>
</TABLE>

</form>
</div>
