<FORM action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{ID}'>
<input type='hidden' name='FILENAME' value='%FILENAME%'>
<input type='hidden' name='FILEPATH' value='%PATH%'>
<input type='hidden' name='extdb_type' value='$FORM{extdb_type}'>
<input type='hidden' name='COUNTRY' value='%COUNTRY%'>



<TABLE width='90%' border='0'>
<tr><td>$_NAME:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>$_ORIGIN_NAME:</td><td><input type='text' name='ORIGIN_NAME' value='%ORIGIN_NAME%'></td></tr>
<tr><td>$_YEAR:</td><td><input type='text' name='YEAR' value='%YEAR%'></td></tr>
<tr><td>$_COUNTRY:</td><td>%COUNTRY_SEL% %COUNTRY%</td></tr>
<tr><td>$_GENRE:</td><td>%GENRES% %GENRE%</td></tr>
<tr><td>$_PRODUCER:</td><td><input type='text' name='PRODUCER' value='%PRODUCER%'></td></tr>
<tr><td>$_ACTORS:</td><td><input type='text' name='ACTORS' value='%ACTORS%'></td></tr>
<tr bgcolor='$_COLORS[0]'><th colspan=2>:$_DESCRIBE:</th></tr>
<tr><th colspan=2><textarea name='DESCR' cols='80' rows='5'>%DESCR%</textarea></th></tr>
<tr><td>$_STUDIO:</td><td><input type='text' name='STUDIO' value='%STUDIO%'></td></tr>
<tr><td>$_DURATION:</td><td><input type='text' name='DURATION' value='%DURATION%'></td></tr>
<tr><td>$_LANGUAGE:</td><td>%LANGUAGE_SEL%</td></tr>
<tr><td>$_COMMENTS:</td><td><input type='text' name='COMMENTS' value='%COMMENTS%'></td></tr>
<tr><td>$_EXTRA:</td><td><input type='text' name='EXTRA' value='%EXTRA%'></td></tr>
<tr bgcolor='$_COLORS[0]'><th colspan=2>FILE</th></tr>
<tr><td>$_SIZE:</td><td>%SIZE%</td></tr>
<tr><td>$_FORMAT:</td><td><input type='text' name='FILE_FORMAT' value='%FILE_FORMAT%'></td></tr>
<tr><td>$_QUALITY:</td><td><input type='text' name='FILE_QUALITY' value='%FILE_QUALITY%'></td></tr>
<tr><td>$_VSIZE:</td><td><input type='text' name='FILE_VSIZE' value='%FILE_VSIZE%'></td></tr>
<tr><td>$_SOUND:</td><td><input type='text' name='FILE_SOUND' value='%FILE_SOUND%'></td></tr>
<tr bgcolor='$_COLORS[2]'><td>$_COVER:</td><td><input type='text' name='COVER' value='%COVER%'></td></tr>
<tr bgcolor='$_COLORS[2]'><td>$_COVER 2:</td><td><input type='text' name='COVER_SMALL' value='%COVER_SMALL%'></td></tr>
<tr><th colspan=2><img src='%COVER_SMALL%' alt='%NAME%'></th></tr>
<tr><th colspan=2><img src='%COVER%' alt='%NAME%'></th></tr>
<tr><td>$_PARENT:</td><td><input type='text' name='PARENT' value='%PARENT%'></td></tr>

<tr bgcolor='$_COLORS[0]'><th colspan=2>$_DOWNLOAD:</th></tr>
<tr><th colspan=2>%DOWNLOAD%</th></tr>

<tr bgcolor='$_COLORS[0]'><th colspan=2>$_INFO:</th></tr>
<tr><th colspan=2>%EXT_CHECK%</th></tr>
<tr><td>$_RENAME_FILE:</td><td><input type=checkbox name=RENAME_FILE value=1 checked></td>
<tr><td>$_PIN_ACCESS:</td><td><input type=checkbox name=PIN_ACCESS value=1></td>
</TABLE>

<input type='submit' name='%ACTION%' value='%LNG_ACTION%'>
</FORM>
