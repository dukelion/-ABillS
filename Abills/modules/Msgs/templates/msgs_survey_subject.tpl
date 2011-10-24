<FORM action='$SELF_URL' METHOD='POST'  >
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='SURVEY_ID' value='%SURVEY_ID%'/>

<TABLE>
<tr><td>$_NAME:</td><td><input type=text name=NAME value='%NAME%'></td></tr>
<tr><td>$_COMMENTS:</td><td><textarea name=COMMENTS rows=6 cols=45>%COMMENTS%</textarea></td></tr>
</TABLE>

<input type=submit name='%ACTION%' value='%LNG_ACTION%'>

</form>
