<SCRIPT TYPE=\"text/javascript\">
<!-- 

// individual template parameters can be modified via the calendar variable
o_cal.a_tpl.yearscroll = false;
o_cal.a_tpl.weekstart  = 1;
o_cal.a_tpl.months     = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
o_cal.a_tpl.weekdays   = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Суб'];

-->
</SCRIPT>


<FORM ACTION=$SELF_URL METHOD=POST NAME=marketing_report2>
<input type=hidden name=index value=$index>

<TABLE>
<tr>
  <td>$_REQUEST_DATE:</td><td><input type=text name=REQUEST_DATE value='%REQUEST_DATE%' size=12>
  <script language='JavaScript'>var o_cal = new tcal ({	'formname': 'marketing_report2',	'controlname': 'REQUEST_DATE'	});</script>
  </td>
  <td>$_REGISTRATION:</td><td><input type=text name=REGISTRATION value='%REGISTRATION%' size=12>
  <script language='JavaScript'>var o_cal = new tcal ({	'formname': 'marketing_report2',	'controlname': 'REGISTRATION'	});</script>
  </td>
</tr>

<tr><th colspan=4 class=form_title align=right>$_ADDRESS <input type=checkbox name=ADDRESS value=1 checked></th></tr>
<tr>
  <td>$_LOCATION:</td><td><input type=text name=_LOCATION value='%LOCATION%'></td>
  <td>$_DISTRICT:</td><td>%DISTRICT_SEL%
  <!-- <input type=text name=DISTRICT value='%DISTRICT%'> --></td>
</tr>

<tr>
  <td>$_ADDRESS_STREET:</td><td>%ADDRESS_STREET_SEL%
  <!-- <input type=text name=ADDRESS_STREET value='%ADDRESS_STREET%'> -->
  </td>
  <td>$_ADDRESS_BUILD:</td><td>%ADDRESS_BUILD_SEL%
  <input type=text name=ADDRESS_BUILD value='%ADDRESS_BUILD%'>
  </td>
</tr>

<tr>
  <td>$_ENTRANCE:</td><td><input type=text name='ENTRANCE' value='%ENTRANCE%' size=7> $FLOR: <input type=text name='FLOR' value='%FLOR%' size=7></td>
  <td>$_ADDRESS_FLAT:</td><td><input type=text name=ADDRESS_FLAT value='%ADDRESS_FLAT%'></td>
</tr>

<tr><th colspan=4 class=form_title>Internet <input type=checkbox name=INTERNET value=1 checked></th></tr>

<tr><td colspan=2>$_TARIF_PLAN:</td><td colspan=2>%TP_ID_SEL% </td></tr>
<tr><td colspan=2>$_PRE_TP: </td><td colspan=2>%PRE_TP_ID_SEL%</td></tr>

<tr> <td colspan=2 colspan=2>$_TARIF_PLAN $_CHANGED:</td><td colspan=2><input type=text name=TARIF_PLAN_CHANGED value='%TARIF_PLAN_CHANGED%' size=12>
  <script language='JavaScript'>var o_cal = new tcal ({	'formname': 'marketing_report2',	'controlname': 'TARIF_PLAN_CHANGED'	});</script>
</td></tr>

<tr><th colspan=4 class=form_title>$_PAYMENTS <input type=checkbox name=PAYMENTS value=1 checked></th></tr>
<tr>
  <td>$_LAST_PAYMENT:</td><td><input type=text name=LAST_PAYMENT_DATE value='%LAST_PAYMENT_DATE%' size=12>
  <script language='JavaScript'>var o_cal = new tcal ({	'formname': 'marketing_report2',	'controlname': 'LAST_PAYMENT_DATE'	});</script>
  </td>
  <td>$_PAYMENTS $_TYPE:</td><td>%LAST_PAYMENT_METHOD_SEL%</td>
</tr>

<tr>
  <td>$_SUM:</td><td><input type=text name=LAST_PAYMENT_SUM value='%LAST_PAYMENT_SUM%'></td>
  <td>$_PAYMENT_TO_DATE:</td><td><input type=text name=PAYMENT_TO_DATE value='%PAYMENT_TO_DATE%' size=12>
  <script language='JavaScript'>var o_cal = new tcal ({	'formname': 'marketing_report2',	'controlname': 'PAYMENT_TO_DATE'	});</script>
  </td>
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
  <td>$_DISABLE $_DATE:</td><td><input type=text name=DISABLE_DATE value='%DISABLE_DATE%' size=12>
  <script language='JavaScript'>var o_cal = new tcal ({	'formname': 'marketing_report2',	'controlname': 'DISABLE_DATE'	});</script>
  </td>
  <td>$_DISABLE $_COMMENTS:</td><td><input type=text name=DISABLE_REASON value='%DISABLE_REASON%'></td>
</tr>


<tr bgcolor=$_COLORS[2]>
  <td>$_ROWS:</td><td><input type=text name=PAGE_ROWS value='$LIST_PARAMS{PAGE_ROWS}'></td>
  <td> </td><td> </td>
</tr>
</TABLE>

<input type=submit name=search value=$_SEARCH>
</FORM>