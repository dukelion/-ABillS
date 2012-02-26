<form action=$SELF_URL METHOD=POST>
<input type=hidden name='index' value='$index'>
<input type=hidden name='ID' value='$FORM{chg}'>
<table class=form>

<tr><td>$_REQUIRED_SCORE:</td><td>%REQUIRED_SCORE_SEL%</td></tr>
<tr><td>$_REWRITE_HEADER:</td><td><input type=text name=REWRITE_HEADER value='%REWRITE_HEADER%'></td></tr>
<tr><td>$_REPORT_SAFE:</td><td>%REPORT_SAFE_SEL%</td></tr>
<tr><td>$_USER_IN_WHITELIST:</td><td><input type=text name=USER_IN_WHITELIST value='%USER_IN_WHITELIST%'></td></tr>
<tr><td>$_USER_IN_BLACKLIST:</td><td><input type=text name=USER_IN_BLACKLIST value='%USER_IN_BLACKLIST%'></td></tr>
<tr><td>$_OK_LOCALES:</td><td><input type=text name=OK_LOCALES value='%OK_LOCALES%'></td></tr>
<tr><th colspan=2 bgcolor='$_COLORS[0]'>$_AUTO_LEARN</th></tr>


<tr><td>$_USE_BAYES:</td><td><input type=checkbox name=USE_BAYES value='1', %USE_BAYES%></td></tr>
<tr><td>$_BAYES_AUTO_LEARN:</td><td><input type=checkbox name=BAYES_AUTO_LEARN value='1' %BAYES_AUTO_LEARN%></td></tr>
<tr><td>$_BAYES_AUTO_LEARN_THRESHOLD_NONSPAM:</td><td>%BAYES_AUTO_LEARN_THRESHOLD_NONSPAM_SEL%</td></tr>
<tr><td>$_BAYES_AUTO_LEARN_THRESHOLD_SPAM:</td><td>%BAYES_AUTO_LEARN_THRESHOLD_SPAM_SEL%</td></tr>
<tr><td>$_USE_AUTO_WHITELIST:</td><td><input type=checkbox name=USE_AUTO_WHITELIST value='1' %USE_AUTO_WHITELIST%></td></tr>
<tr><td>$_AUTO_WHITELIST_FACTOR:</td><td>%AUTO_WHITELIST_FACTOR_SEL%</td></tr>

<tr><th colspan=2 bgcolor='$_COLORS[0]'>$_NETWORK_CHECK</th></tr>

<tr><td>$_USE_DCC</td><td><input type=checkbox name=USE_DCC value='1' %USE_DCC%></td></tr>
<tr><td>$_USE_PYZOR</td><td><input type=checkbox name=USE_PYZOR value='1' %USE_PYZOR%></td></tr>
<tr><td>$_USE_RAZOR2</td><td><input type=checkbox name=USE_RAZOR2 value='1' %USE_RAZOR2%></td></tr>

<!--
<tr><td>ID:</td><td> %ID%</td></tr>
<tr><td>$_USER (\$GLOBAL - $_ALL):</td><td><input type=text name=USER_NAME value='%USER_NAME%'></td></tr>
<tr><td>$_OPTIONS:</td><td><input type=text name=PREFERENCE value='%PREFERENCE%'></td></tr>
<tr><td>$_VALUE:</td><td><input type=text name=VALUE value='%VALUE%'></td></tr>
<tr><td>$_COMMENTS:</td><td><input type=text name=COMMENTS value='%COMMENTS%'></td></tr>
<tr><td>$_ADDED:</td><td>%ADD%</td></tr>
<tr><td>$_CHANGED:</td><td>%CHANGED%</td></tr>
-->

<tr><th class=even colspan=2><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table>

</form>
