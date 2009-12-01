<FORM ACTION=$SELF_URL METHOD=POST>
<input type=hidden name=index value=$index>

<TABLE>


<tr>
  <td>$_REQUEST_DATE:</td><td><input type=text name=REQUEST_DATE value='%REQUEST_DATE%'</td>
  <td>$_REGISTRATION:</td><td><input type=text name=REGISTRATION value='%REGISTRATION%'</td>
</tr>

<tr><th colspan=4 class=form_title align=right>$_ADDRESS <input type=checkbox name=ADDRESS value=1 checked></th></tr>
<tr>
  <td>$_LOCATION:</td><td><input type=text name=_LOCATION value='%LOCATION%'></td>
  <td>$_DISTRICT:</td><td><input type=text name=DISTRICT value='%DISTRICT%'></td>
</tr>

<tr>
  <td>$_ADDRESS_STREET:</td><td><input type=text name=ADDRESS_STREET value='%ADDRESS_STREET%'></td>
  <td>$_ADDRESS_BUILD:</td><td><input type=text name=ADDRESS_BUILD value='%ADDRESS_BUILD%'></td>
</tr>

<tr>
  <td>$_ENTRANCE:</td><td><input type=text name='ENTRANCE' value='%ENTRANCE%' size=7> $FLOR: <input type=text name='FLOR' value='%FLOR%' size=7></td>
  <td>$_ADDRESS_FLAT:</td><td><input type=text name=ADDRESS_FLAT value='%ADDRESS_FLAT%'></td>
</tr>

<tr><th colspan=4 class=form_title>Internet <input type=checkbox name=INTERNET value=1 checked></th></tr>

<tr>
  <td>$_TARIF_PLAN:</td><td><input type=text name='TP_ID' value='%_ENTRANCE%' size=7> $_PRE $_TARIF_PLAN: <input type=text name='PRE_TP_ID' value='%PRE_TP_ID%' size=7></td>
  <td>$_TARIF_PLAN $_CHANGED:</td><td><input type=text name=TARIF_PLAN_CHANGED value='%TARIF_PLAN_CHANGED%'></td>
</tr>

<tr><th colspan=4 class=form_title>$_PAYMENTS <input type=checkbox name=PAYMENTS value=1 checked></th></tr>
<tr>
  <td>$_LAST_PAYMENT:</td><td><input type=text name=LAST_PAYMENT_DATE value='%LAST_PAYMENT_DATE%'></td>
  <td>$_PAYMENTS $_TYPE:</td><td>%LAST_PAYMENT_METHOD_SEL%</td>
</tr>



<tr>
  <td>$_SUM:</td><td><input type=text name=LAST_PAYMENT_SUM value='%LAST_PAYMENT_SUM%'></td>
  <td>$_PAYMENT_TO_DATE:</td><td><input type=text name=PAYMENT_TO_DATE value='%PAYMENT_TO_DATE%'></td>
</tr>


<tr>
  <td>$_DEBTS_DAYS:</td><td><input type=text name=DEBTS_DAYS value='%DEBTS_DAYS%'></td>
  <td></td><td></td>
</tr>


<tr><th colspan=4 class=form_title>$_OTHER <input type=checkbox name=OTHER value=1 checked></th></tr>
<tr>
  <td>$_STATUS:</td><td>%STATUS_SEL%</td>
  <td></td><td></td>
</tr>

<tr>
  <td>$_FORUM_ACTIVITY:</td><td><input type=text name=FORUM value='%FORUM%'></td>
  <td></td><td></td>
</tr>

<tr>
  <td>$_BONUS:</td><td><input type=text name=BONUS value='%BONUS%'></td>
  <td></td><td></td>
</tr>



<tr>
  <td>$_DISABLE $_DATE:</td><td><input type=text name=DISABLE_DATE value='%DISABLE_DATE%'></td>
  <td>$_DISABLE $_COMMENTS:</td><td><input type=text name=DISABLE_REASON value='%DISABLE_REASON%'></td>
</tr>


<tr bgcolor=$_COLORS[2]>
  <td>$_ROWS:</td><td><input type=text name=PAGE_ROWS value='$LIST_PARAMS{PAGE_ROWS}'></td>
  <td> </td><td> </td>
</tr>
</TABLE>

<input type=submit name=search value=$_SEARCH>
</FORM>