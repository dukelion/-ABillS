<FORM action='$SELF_URL' METHOD=POST>
<input type=hidden name=FORGOT_PASSWD value=1>
<TABLE width='400' cellspacing='0' cellpadding='0' border='0'><TR><TD bgcolor='#E1E1E1'>
<TABLE width='100%' cellspacing='0' cellpadding='0' border='0'>

<tr bgcolor='$_COLORS[0]'><th align='right' colspan='2'>$_PASSWORD_RECOVERY</th></tr>
<tr bgcolor='$_COLORS[1]'><th align='left'>$_LOGIN:</th><th> <input type=text name=LOGIN value='' size=30> </th></tr>
<tr bgcolor='$_COLORS[1]'><th align='left'>E-Mail:</th><th> <input type=text name=EMAIL value='' size=30> </th></tr>
<tr bgcolor='$_COLORS[1]'><th align='center' colspan='2'><input type=submit name='SEND' value=$_SEND></th></tr>


</table>
</td></tr></table>

</FORM>
