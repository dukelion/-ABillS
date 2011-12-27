<form action='$SELF_URL'  METHOD='POST'>
<input type='hidden' name='index' value='$index'>
%HIDDDEN_INPUT%
<table width=450> 
<tr><td>$_PASSWD:</td><td><input type='password' id='text_pma_pw' name='newpassword' title='$_PASSWD' onchange=\"pred_password.value = 'userdefined';\" /></td></tr>
<tr><td>$_CONFIRM_PASSWD:</td><td><input type='password' name='confirm' id='text_pma_pw2' title='$_CONFIRM' onchange=\"pred_password.value = 'userdefined';\" /></td></tr>
<tr><td>  <input type='button' id='button_generate_password' value='$_GENERED_PARRWORD' onclick=\"suggestPassword('%PW_CHARS%', '%PW_LENGTH%')\" />
          <input type='button' id='button_copy_password' value='Copy' onclick=\"suggestPasswordCopy(this.form)\" />
</td><td><input type='text' name='generated_pw' id='generated_pw' /></td></tr>
</table>
%BACK_BUTTON% <input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
