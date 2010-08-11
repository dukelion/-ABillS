<FORM action='$SELF_URL' METHOD='POST'  >
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='SURVEY' value='$FORM{SURVEY}'/>

<TABLE>
<tr><td>$_NUM:</td><td><input type=text name=NUM value='%NUM%'></td></tr>
<tr><td>$_QUESTION:</td><td><input type=text name=QUESTION value='%QUESTION%' size=40></td></tr>
<tr><td>$_PARAMS (;):</td><td><textarea name=PARAMS rows=6 cols=45>%PARAMS%</textarea></td></tr>
<tr><td>$_COMMENTS:</td><td><textarea name=COMMENTS rows=6 cols=45>%COMMENTS%</textarea></td></tr>
<tr><td>$_USER $_COMMENTS:</td><td><input type=checkbox name=USER_COMMENTS value=1 %USER_COMMENTS%></td></tr>
</TABLE>

<input type=submit name='%ACTION%' value='%ACTION_LNG%'>

</form>
