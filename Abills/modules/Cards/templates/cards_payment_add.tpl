<form action='$SELF_URL' METHOD='POST' name='form_card_add'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='UID' value='$FORM{UID}'>
<table>
<tr><th class='form_title' colspan='2'>$_ICARDS</th></tr>
<tr><td>$_SERIAL:</td><td><input type='text' name='SERIAL' value='%SERIAL%'></td></tr>
<tr><td>PIN:</td><td><input type='text' name='PIN'></td></tr>
</table>

<input type='submit' name='add' value='$_ADD' ID='submitButton' onClick=\"this.form.add.disabled = true;  this.form.add.style.backgroundColor='#dddddd';\">
</form>
