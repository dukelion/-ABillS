
# Base Templates

#**********************************************************
# templates
#**********************************************************
sub _include {
  my ($tpl, $module, $attr) = @_;
  my $result = '';

  if (-f '../../Abills/templates/'. $module . '_' . $tpl . '.tpl') {
    return tpl_content('../../Abills/templates/'. $module . '_' . $tpl . '.tpl');
   }
  elsif (-f '../Abills/templates/'. $module . '_' . $tpl .'.tpl') {
    return tpl_content('../Abills/templates/'. $module . '_' . $tpl. '.tpl');
   }
  elsif (-f $Bin .'/../Abills/templates/'. $module . '_' . $tpl .'.tpl') {
    return tpl_content($Bin .'/../Abills/templates/'. $module . '_' . $tpl .'.tpl');
   }
  elsif (defined($module)) {
    $tpl	= "modules/$module/templates/$tpl";
   }

  foreach my $prefix (@INC) {
     my $realfilename = "$prefix/Abills/$tpl.tpl";
     if (-f $realfilename) {
        return tpl_content($realfilename);
      }
   }

  return "No such template [$tpl]\n";
}


#**********************************************************
# templates
#**********************************************************
sub tpl_content {
  my ($filename) = @_;
  my $tpl_content = '';
  
  open(FILE, "$filename") || die "Can't open file '$filename' $!";
    while(<FILE>) {
      $tpl_content .= eval "\"$_\"";
    }
  close(FILE);
 	
	return $tpl_content;
}

#**********************************************************
# templates
#**********************************************************
sub templates {
  my ($tpl_name) = @_;

  if (-f "../../Abills/templates/_"."$tpl_name".".tpl") {
    return tpl_content("../../Abills/templates/_". "$tpl_name".".tpl");
   }
  elsif (-f "../Abills/templates/_"."$tpl_name".".tpl") {
    return tpl_content("../Abills/templates/_"."$tpl_name".".tpl");
   }
  
if ($tpl_name eq 'header') {

return qq{	
<tr class='HEADER' bgcolor='$_COLORS[3]'><td colspan='2'>
<div class='header'>
<form action='$SELF_URL'>
<table width='100%' border='0'>
  <tr><th align='left'>$_DATE: %DATE% %TIME% Admin: <a href='$SELF_URL?index=53'>$admin->{A_LOGIN}</a> / Online: <abbr title=\"%ONLINE_USERS%\"><a href='$SELF_URL?index=50' title='%ONLINE_USERS%'>Online: %ONLINE_COUNT%</a></abbr></th>  <th align='right'><input type='hidden' name='index' value='7'/><input type='hidden' name='search' value='1'/>
  Search: %SEL_TYPE% <input type='text' name='LOGIN_EXPR' value=''/> 
  (<b><a href='#' onclick=\"window.open('help.cgi?index=$index&amp;FUNCTION=$functions{$index}','help',
    'height=550,width=450,resizable=0,scrollbars=yes,menubar=no, status=yes');\">?</a></b>)</th></tr>
</table>
</form>
</div>
</td></tr>
%TECHWORK%

}
	
}
elsif ($tpl_name eq 'footer') {
return qq{
  <tr class=\"FOOTER\"><td colspan='2'><hr/> ABillS %VERSION%</td></tr>
 };
 }
elsif ($tpl_name eq 'form_pi') {
return qq{
<TABLE width='100%'>
<tr bgcolor='$_COLORS[0]'><TH align='right'>$_USER_INFO</TH></tr>
</TABLE>
<form action='$SELF_URL' method='post'>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value="%UID%">
<TABLE width=420 cellspacing=0 cellpadding=3>
<TR><TD>$_FIO:*</TD><TD><input type=text name=FIO value="%FIO%"></TD></TR>
<TR><TD>$_PHONE:</TD><TD><input type=text name=PHONE value="%PHONE%"></TD></TR>
<TR><TD>$_ADDRESS_STREET:</TD><TD><input type=text name=ADDRESS_STREET value="%ADDRESS_STREET%"></TD></TR>
<TR><TD>$_ADDRESS_BUILD:</TD><TD><input type=text name=ADDRESS_BUILD value="%ADDRESS_BUILD%"></TD></TR>
<TR><TD>$_ADDRESS_FLAT:</TD><TD><input type=text name=ADDRESS_FLAT value="%ADDRESS_FLAT%"></TD></TR>
<TR><TD>$_CITY:</TD><TD><input type=text name=CITY value="%CITY%"> $_ZIP: <input type=text name=ZIP value="%ZIP%" size=8></TD></TR>
<TR><TD>E-mail:</TD><TD><input type=text name=EMAIL value="%EMAIL%"></TD></TR>
<TR><TD>$_CONTRACT_ID:</TD><TD><input type=text name=CONTRACT_ID value="%CONTRACT_ID%"></TD></TR>
<TR><TH colspan='2' bgcolor='$_COLORS[2]'>$_PASPORT</TH></TR>
<TR><TD>$_NUM:</TD><TD><input type=text name=PASPORT_NUM value="%PASPORT_NUM%"></TD></TR>
<TR><TD>$_DATE:</TD><TD><input type=text name=PASPORT_DATE value="%PASPORT_DATE%"></TD></TR>
<TR><TD>$_GRANT:</TD><TD><textarea name=PASPORT_GRANT rows=3 cols=45>%PASPORT_GRANT%</textarea></TD></TR>
<TR><th colspan=2>:$_COMMENTS:</th></TR>
<TR><th colspan=2><textarea name=COMMENTS rows=5 cols=45>%COMMENTS%</textarea></th></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
};

 }
elsif ($tpl_name eq 'form_user_exdata') {
return qq{
   <tr bgcolor="$_COLORS[2]"><td>$_USER:*</td><td><input type="text" name="LOGIN" value=""></td></tr>
   <tr><td>$_BILL:</td><td><input type="checkbox" name="CREATE_BILL" %CREATE_BILL% value='1'> $_CREATE</td></tr>
  };
 }
elsif ($tpl_name eq 'form_user') {
return qq{

<form action="$SELF_URL" METHOD="POST">
<input type=hidden name="index" value="$index">
<input type=hidden name=COMPANY_ID value='%COMPANY_ID%'>
<TABLE width="420" cellspacing="0" cellpadding="3">
%EXDATA%
<TR><TD colspan=2>&nbsp;</TD></TR>

<TR><TD>$_CREDIT:</TD><TD><input type=text name=CREDIT value='%CREDIT%'></TD></TR>
<TR><TD>$_GROUPS:</TD><TD>%GID%:%G_NAME%</TD></TR>
<TR><TD>$_ACTIVATE:</TD><TD><input type=text name=ACTIVATE value='%ACTIVATE%'></TD></TR>
<TR><TD>$_EXPIRE:</TD><TD><input type=text name=EXPIRE value='%EXPIRE%'></TD></TR>
<TR><TD>$_REDUCTION (%):</TD><TD><input type=text name=REDUCTION value='%REDUCTION%'></TD></TR>
<TR><TD>$_DISABLE:</TD><TD><input type=checkbox name=DISABLE value='1' %DISABLE%></TD></TR>
<TR><TD>$_REGISTRATION</TD><TD>%REGISTRATION%</TD></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
};

 }

elsif ($tpl_name eq 'client_info') {
return qq{
<br/>
<TABLE width="600" cellspacing="0" cellpadding="0" border="0"><TR><TD bgcolor="#E1E1E1">
<TABLE width="100%" cellspacing="1" cellpadding="0" border="0">
<TR bgcolor="$_COLORS[2]"><TD><b>$_LOGIN:</b></TD><TD>%LOGIN%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD><b>$_DEPOSIT:</b></TD><TD>%DEPOSIT%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD><b>$_CREDIT:</b></TD><TD>%CREDIT%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD><b>$_REDUCTION:</b></TD><TD>%REDUCTION% %</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD><b>$_FIO:</b></TD><TD>%FIO%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD><b>$_PHONE:</b></TD><TD>%PHONE%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD><b>$_ADDRESS:</b></TD><TD>%ADDRESS_STREET%, %ADDRESS_BUILD%/%ADDRESS_FLAT%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD><b>E-mail:</b></TD><TD>%EMAIL%</TD></TR>
<TR bgcolor="#DDDDDD"><TD colspan="2">&nbsp;</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD><b>$_ACTIVATE:</b></TD><TD>%ACTIVATE%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD><b>$_EXPIRE:</b></TD><TD>%EXPIRE%</TD></TR>
<TR bgcolor="$_COLORS[1]"><th colspan="2">$_PAYMENTS</th></TR>
<TR bgcolor="$_COLORS[1]"><TD><b>$_DATE:</b></TD><TD>%PAYMENT_DATE%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD><b>$_SUM:</b></TD><TD>%PAYMENT_SUM%</TD></TR>
</TABLE>
</TD></TR></TABLE>
<br/>
};
 }

elsif ($tpl_name eq 'client_chg_form')  {

return qq{
<form action='$SELF_URL' method='post'>
<input type=hidden name=index value=$index>
<input type=hidden name=sid value="$sid">
<TABLE width=420 cellspacing=0 cellpadding=3>
<TR><TD>$_FIO:*</TD><TD><input type=text name=FIO value="%FIO%"></TD></TR>
<TR><TD>$_PHONE:</TD><TD><input type=text name=PHONE value="%PHONE%"></TD></TR>
<TR><TD>$_ADDRESS_STREET:</TD><TD><input type=text name=ADDRESS_STREET value="%ADDRESS_STREET%"></TD></TR>
<TR><TD>$_ADDRESS_BUILD:</TD><TD><input type=text name=ADDRESS_BUILD value="%ADDRESS_BUILD%"></TD></TR>
<TR><TD>$_ADDRESS_FLAT:</TD><TD><input type=text name=ADDRESS_FLAT value="%ADDRESS_FLAT%"></TD></TR>
<TR><TD>$_CITY:</TD><TD><input type=text name=CITY value="%CITY%"> $_ZIP: <input type=text name=ZIP value="%ZIP%" size=8></TD></TR>
<TR><TD>E-mail:</TD><TD><input type=text name=EMAIL value="%EMAIL%"></TD></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>

};
 
}
elsif ($tpl_name eq 'user_info') {
return qq{
<TABLE width="500" cellspacing="0" cellpadding="0" border="0"><TR><TD bgcolor="#E1E1E1">
<TABLE width="100%" cellspacing="1" cellpadding="0" border="0">
<TR bgcolor="$_COLORS[0]"><TH ALIGN=RIGHT COLSPAN="2">$_INFO</TH></TR>
<TR bgcolor="$_COLORS[1]"><TD>$_LOGIN:</TD><TD>%LOGIN%</TD></TR>
<tR bgcolor="$_COLORS[1]"><TD>UID:</TD><TD>%UID%</TD></TR>
<tR bgcolor="$_COLORS[1]"><TD>$_DEPOSIT:</TD><TD>%DEPOSIT%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>$_FIO:</TD><TD>%FIO%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>$_PHONE:</TD><TD>%PHONE%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>$_ADDRESS:</TD><TD>%ADDRESS%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>E-mail:</TD><TD>%EMAIL%</TD></TR>
<tR bgcolor="$_COLORS[1]"><TD>$_CREDIT:</TD><TD>%CREDIT%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>$_REDUCTION</TD><TD>%REDUCTION% %</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>$_ACTIVATE:</TD><TD>%ACTIVATE%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>$_EXPIRE:</TD><TD>%EXPIRE%</TD></TR>
<TR bgcolor="$_COLORS[1]"><th colspan="2">:$_COMMENTS:</th></TR>
<TR bgcolor="$_COLORS[1]"><td colspan="2">%COMMENTS%</td></TR>
<!-- <tR bgcolor="$_COLORS[1]"><TH colspan="2">Dilup / VPN</TH></TR>
<TR bgcolor="$_COLORS[1]"><TD>$_TARIF_PLAN:</TD><TD>%TP_ID%:%TP_NAME%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>$_SIMULTANEOUSLY:</TD><TD>%SIMULTANEONSLY%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>IP:</TD><TD>%IP%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>NETMASK:</TD><TD>%NETMASK%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>$_SPEED (Kb)</TD><TD>%SPEED%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>$_FILTERS</TD><TD>%FILTER_ID%</TD></TR>
<TR bgcolor="$_COLORS[1]"><TD>CID:</TD><TD>%CID%</TD></TR>
-->
</TABLE>
</TD></TR></TABLE>
};
 }

elsif ($tpl_name eq 'form_password') {
return qq{
<form action='$SELF_URL'  METHOD='POST'>
<input type='hidden' name='index' value='$index'>
%HIDDDEN_INPUT%
<table> 
<tr><td>$_PASSWD:</td><td><input type="password" id="text_pma_pw" name="newpassword" title="$_PASSWD" onchange="pred_password.value = 'userdefined';" /></td></tr>
<tr><td>$_CONFIRM_PASSWD:</td><td><input type="password" name="confirm" id="text_pma_pw2" title="$_CONFIRM" onchange="pred_password.value = 'userdefined';" /></td></tr>
<tr><td>  <input type="button" id="button_generate_password" value="$_GENERED_PARRWORD" onclick="suggestPassword('%PW_CHARS%', '%PW_LENGTH%')" />
          <input type="button" id="button_copy_password" value="Copy" onclick="suggestPasswordCopy(this.form)" />
</td><td><input type="text" name="generated_pw" id="generated_pw" /></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
}
}
elsif ($tpl_name eq 'form_payments') {
return qq{
<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name=index value=$index>
<input type=hidden name=subf value=$FORM{subf}>
<input type=hidden name=OP_SID value=%OP_SID%>
<input type=hidden name=UID value=%UID%>
<TABLE>
<TR><TD>$_SUM:</TD><TD><input type=text name=SUM></TD></TR>
<TR><TD>$_DESCRIBE:</TD><TD><input type=text name=DESCRIBE></TD></TR>
<TR><TD>$_EXCHANGE_RATE:</TD><TD>%SEL_ER%</TD></TR>
<TR><TD colspan=2><hr size=1></TD></TR>
<TR><TD>$_PAYMENT_METHOD:</TD><TD>%SEL_METHOD%</TD></TR>
<TR><TD>ID:</TD><TD><input type=text name=EXT_ID value='%EXT_ID%'></TD></TR>
</TABLE>
<input type=submit name=add value='$_ADD'>
</form>
</div>
};
 }
elsif ($tpl_name eq 'form_fees') {
return qq{
<div class='noprint'>
<form action="$SELF_URL">
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=index value='$index'>
<input type=hidden name=subf value='$FORM{subf}'>
%SHEDULE%
<TABLE>
<TR><TD>$_SUM:</TD><TD><input type="text" name="SUM"></TD></TR>
<TR><TD>$_DESCRIBE:</TD><TD><input type="text" name="DESCRIBE"></TD></TR>
<TR><TD>$_EXCHANGE_RATE:</TD><TD>%SEL_ER%</TD></TR>
%PERIOD_FORM%
</TABLE>
<input type=submit name='take' value='$_TAKE'>
</form>
</div>
}

}
elsif ($tpl_name eq 'tp') {
return qq{
<form action=$SELF_URL METHOD=POST>
<input type=hidden name=index value=70>
<input type=hidden name=chg value='%TP_ID%'>
<TABLE border=0>
  <TR><th>#</th><TD><input type=text name=TP_ID value='%TP_ID%'></TD></TR>
  <TR><TD>$_NAME:</TD><TD><input type=text name=NAME value='%NAME%'></TD></TR>
  <TR><TD>$_UPLIMIT:</TD><TD><input type=text name=ALERT value='%ALERT%'></TD></TR>

<!--
  <TR><TD>$_BEGIN:</TD><TD><input type=text name=BEGIN value='%BEGIN%'></TD></TR>
  <TR><TD>$_END:</TD><TD><input type=text name=END value='%END%'></TD></TR>
-->

  <TR><TD>$_DAY_FEE:</TD><TD><input type=text name=DAY_FEE value='%DAY_FEE%'></TD></TR>
  <TR><TD>$_MONTH_FEE:</TD><TD><input type=text name=MONTH_FEE value='%MONTH_FEE%'></TD></TR>
  <TR><TD>$_SIMULTANEOUSLY:</TD><TD><input type=text name=SIMULTANEOUSLY value='%SIMULTANEOUSLY%'></TD></TR>
  <TR><TD>$_HOUR_TARIF (1 Hour):</TD><TD><input type=text name=TIME_TARIF value='%TIME_TARIF%'></TD></TR>
  <TR><th colspan=2 bgcolor=$_COLORS[0]>$_TIME_LIMIT (sec)</th></TR> 
  <TR><TD>$_DAY</TD><TD><input type=text name=DAY_TIME_LIMIT value='%DAY_TIME_LIMIT%'></TD></TR> 
  <TR><TD>$_WEEK</TD><TD><input type=text name=WEEK_TIME_LIMIT value='%WEEK_TIME_LIMIT%'></TD></TR>
  <TR><TD>$_MONTH</TD><TD><input type=text name=MONTH_TIME_LIMIT value='%MONTH_TIME_LIMIT%'></TD></TR>
  <TR><th colspan=2 bgcolor=$_COLORS[0]>$_TRAF_LIMIT (Mb)</th></TR>
  <TR><TD>$_DAY</TD><TD><input type=text name=DAY_TRAF_LIMIT value='%DAY_TRAF_LIMIT%'></TD></TR>
  <TR><TD>$_WEEK</TD><TD><input type=text name=WEEK_TRAF_LIMIT value='%WEEK_TRAF_LIMIT%'></TD></TR>
  <TR><TD>$_MONTH</TD><TD><input type=text name=MONTH_TRAF_LIMIT value='%MONTH_TRAF_LIMIT%'></TD></TR>
  <TR><TD>$_OCTETS_DIRECTION</TD><TD>%SEL_OCTETS_DIRECTION%</TD></TR>
  <TR><th colspan=2 bgcolor=$_COLORS[0]>$_OTHER</th></TR>
  <TR><TD>$_ACTIVATE:</TD><TD><input type=text name=ACTIV_PRICE value='%ACTIV_PRICE%'></TD></TR>
  <TR><TD>$_CHANGE:</TD><TD><input type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'></TD></TR>
  <TR><TD>$_CREDIT_TRESSHOLD:</TD><TD><input type=text name=CREDIT_TRESSHOLD value='%CREDIT_TRESSHOLD%'></TD></TR>
  <TR><TD>$_MAX_SESSION_DURATION (sec.):</TD><TD><input type=text name=MAX_SESSION_DURATION value='%MAX_SESSION_DURATION%'></TD></TR>
  <TR><TD>$_FILTERS:</TD><TD><input type=text name=FILTER_ID value='%FILTER_ID%'></TD></TR>
  <TR><TD>$_AGE ($_DAYS):</TD><TD><input type=text name=AGE value='%AGE%'></TD></TR>
  <TR><TD>$_PAYMENT_TYPE:</TD><TD>%PAYMENT_TYPE_SEL%</TD></TR>
  <TR><TD>$_MIN_SESSION_COST:</TD><TD><input type=text name=MIN_SESSION_COST value='%MIN_SESSION_COST%'></TD></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
};
 }
#elsif($tpl_name eq 'tt') {
#
#return qq{ <form action=$SELF_URL method=POST>
#<input type=hidden name=index value='70'>
#<input type=hidden name=subf value='73'>
#<input type=hidden name=TP_ID value='%TP_ID%'>
#<input type=hidden name=tt value='%TI_ID%'>
#
#<TABLE BORDER=0 CELLSPACING=1 CELLPADDING=0>
#<TR bgcolor=$_COLORS[1]><th colspan=7 align=right>$_TRAFIC_TARIFS</th></TR>
#<TR bgcolor=$_COLORS[0]><th>#</th><th>$_TRAFIC_TARIFS IN (1 Mb)</th><th>$_TRAFIC_TARIFS OUT (1 Mb)</th><th>$_PREPAID (Mb)</th><th>$_SPEED (Kbits)</th><th>$_DESCRIBE</th><th>NETS</th></TR>
#<TR><TD bgcolor=$_COLORS[0]>0</TD>
#<TD valign=top><input type=text name='TT_PRICE_IN_0' value='%TT_PRICE_IN_0%'></TD>
#<TD valign=top><input type=text name='TT_PRICE_OUT_0' value='%TT_PRICE_OUT_0%'></TD>
#<TD valign=top><input type=text size=12 name='TT_PREPAID_0' value='%TT_PREPAID_0%'></TD>
#<TD valign=top><input type=text size=12 name='TT_SPEED_0' value='%TT_SPEED_0%'></TD>
#<TD valign=top><input type=text name='TT_DESCRIBE_0' value='%TT_DESCRIBE_0%'></TD>
#<TD><textarea cols=20 rows=4 name='TT_NETS_0'>%TT_NETS_0%</textarea></TD></TR>
#
#<TR><TD bgcolor=$_COLORS[0]>1</TD>
#<TD valign=top><input type=text name='TT_PRICE_IN_1' value='%TT_PRICE_IN_1%'></TD>
#<TD valign=top><input type=text name='TT_PRICE_OUT_1' value='%TT_PRICE_OUT_1%'></TD>
#<TD valign=top><input type=text size=12 name='TT_PREPAID_1' value='%TT_PREPAID_1%'></TD>
#<TD valign=top><input type=text size=12 name='TT_SPEED_1' value='%TT_SPEED_1%'></TD>
#<TD valign=top><input type=text name='TT_DESCRIBE_1' value='%TT_DESCRIBE_1%'></TD>
#<TD><textarea cols=20 rows=4 name='TT_NETS_1'>%TT_NETS_1%</textarea></TD></TR>
#
#<TR><TD bgcolor=$_COLORS[0]>2</TD>
#<TD valign=top>&nbsp;</TD>
#<TD valign=top>&nbsp;</TD>
#<TD valign=top>&nbsp;</TD>
#<TD valign=top><input type=text size=12 name='TT_SPEED_2' value='%TT_SPEED_2%'></TD>
#<TD valign=top><input type=text name='TT_DESCRIBE_2' value='%TT_DESCRIBE_2%'></TD>
#<TD><textarea cols=20 rows=4 name='TT_NETS_2'>%TT_NETS_2%</textarea></TD></TR>
#
#</TABLE>
#<input type=submit name='change' value='$_CHANGE'>
#</form>\n};
# }

elsif ($tpl_name eq 'ti') {
return qq{
<div class='noprint'>
<form action="$SELF_URL">
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='%TP_ID%'>
<input type=hidden name='TI_ID' value='%TI_ID%'>
 <TABLE width=400 cellspacing=1 cellpadding=0 border=0>
 <TR><TD>$_DAY:</TD><TD>%SEL_DAYS%</TD></TR>
 <TR><TD>$_BEGIN:</TD><TD><input type=text name=TI_BEGIN value='%TI_BEGIN%'></TD></TR>
 <TR><TD>$_END:</TD><TD><input type=text name=TI_END value='%TI_END%'></TD></TR>
 <TR><TD>$_HOUR_TARIF (0.00<!--  / 0% -->):</TD><TD><input type=text name=TI_TARIF value='%TI_TARIF%'></TD></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>
};
 }
elsif ($tpl_name eq 'form_admin') {
return qq{
<form action='$SELF_URL'>
<input type=hidden name='index' value='50'>
<input type=hidden name='AID' value='%AID%'>
<TABLE>
<TR><TD>ID:</TD><TD><input type=text name=A_LOGIN value="%A_LOGIN%"></TD></TR>
<TR><TD>$_FIO:</TD><TD><input type=text name=A_FIO value="%A_FIO%"></TD></TR>
<TR><TD>$_DISABLE:</TD><TD><input type=checkbox name=DISABLE value='1' %DISABLE%></TD></TR>
<TR><TD>$_PHONE:</TD><TD><input type=text name=A_PHONE value='%A_PHONE%'></TD></TR>
<TR><TD>E-Mail</TD><TD><input type=text name=EMAIL value='%EMAIL%'></TD></TR>
<tr><TD>$_GROUPS:</TD><TD>%GROUP_SEL%</TD></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
};
}
elsif ($tpl_name eq 'form_nas') {
return qq{
<div class="noprint">
<form action=$SELF_URL METHOD=post>
<input type=hidden name="index" value="60">
<input type=hidden name="NAS_ID" value="%NAS_ID%">
<TABLE>
<TR><TD>ID</TD><TD>%NAS_ID%</TD></TR>
<TR><TD>IP</TD><TD><input type=text name=NAS_IP value='%NAS_IP%'></TD></TR>
<TR><TD>$_NAME:</TD><TD><input type=text name=NAS_NAME value="%NAS_NAME%"></TD></TR>
<TR><TD>Radius NAS-Identifier:</TD><TD><input type=text name=NAS_INDENTIFIER value="%NAS_INDENTIFIER%"></TD></TR>
<TR><TD>$_DESCRIBE:</TD><TD><input type=text name=NAS_DESCRIBE value="%NAS_DESCRIBE%"></TD></TR>
<TR><TD>$_TYPE:</TD><TD>%SEL_TYPE%</TD></TR>
<TR><TD>$_AUTH:</TD><TD>%SEL_AUTH_TYPE%</TD></TR>
<TR><TD>External Accounting:</TD><TD>%NAS_EXT_ACCT%</TD></TR>
<TR><TD>Alive (sec.):</TD><TD><input type=text name=NAS_ALIVE value='%NAS_ALIVE%'></TD></TR>
<TR><TD>$_DISABLE:</TD><TD><input type=checkbox name=NAS_DISABLE value=1 %NAS_DISABLE%></TD></TR>
<TR><th colspan=2>:$_MANAGE:</th></TR>
<TR><TD>IP:PORT:</TD><TD><input type=text name=NAS_MNG_IP_PORT value="%NAS_MNG_IP_PORT%"></TD></TR>
<TR><TD>$_USER:</TD><TD><input type=text name=NAS_MNG_USER value="%NAS_MNG_USER%"></TD></TR>
<TR><TD>$_PASSWD:</TD><TD><input type=password name=NAS_MNG_PASSWORD value=""></TD></TR>
<TR><th colspan=2>RADIUS $_PARAMS (,)</th></TR>
<TR><th colspan=2><textarea cols=50 rows=4 name=NAS_RAD_PAIRS>%NAS_RAD_PAIRS%</textarea></th></TR>
</TABLE>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</form>
</div>
};

}
elsif ($tpl_name eq 'form_company') {
return qq{	
<form action="$SELF_URL" METHOD="POST">
<input type=hidden name="index" value='13'>
<input type=hidden name="COMPANY_ID" value='%COMPANY_ID%'>
<Table>
<TR><TD>$_NAME:</TD><TD><input type=text name=COMPANY_NAME value="%COMPANY_NAME%"></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_ADDRESS:</TD><TD><input type='text' name='ADDRESS' value='%ADDRESS%' size='60'></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_PHONE:</TD><TD><input type='text' name='PHONE' value='%PHONE%' size='60'></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_BILL:</TD><TD>%BILL_ID%</TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_DEPOSIT:</TD><TD>%DEPOSIT%</TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_CREDIT:</TD><TD><input type=text name=CREDIT value='%CREDIT%'></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_VAT (%):</TD><TD><input type=text name=VAT value='%VAT%'></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_TAX_NUMBER:</TD><TD><input type=text name=TAX_NUMBER value='%TAX_NUMBER%' size=60></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_ACCOUNT:</TD><TD><input type=text name=BANK_ACCOUNT value='%BANK_ACCOUNT%' size=60></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_BANK_NAME:</TD><TD><input type=text name=BANK_NAME value='%BANK_NAME%' size=60></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_COR_BANK_ACCOUNT:</TD><TD><input type=text name=COR_BANK_ACCOUNT value='%COR_BANK_ACCOUNT%' size=60></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_BANK_BIC:</TD><TD><input type=text name=BANK_BIC value='%BANK_BIC%' size=60></TD></TR>
<TR><TD>$_CONTRACT_ID:</TD><TD><input type=text name=CONTRACT_ID value="%CONTRACT_ID%"></TD></TR>
<TR bgcolor=$_COLORS[1]><TD>$_DISABLE:</TD><TD><input type=checkbox name=DISABLE value='1' %DISABLE%></TD></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
}
}
elsif ($tpl_name eq 'chg_tp') {
return qq{
<form action="$SELF_URL" METHOD="POST">
<input type=hidden name=sid value='$sid'>
<input type=hidden name=UID value='%UID%'>
<input type=hidden name=m value='%m%'>
<input type=hidden name='index' value='$index'>
<TABLE width=500 border=0>
<TR><TD>$_FROM:</TD><TD bgcolor="$_COLORS[2]">$user->{TP_ID} %TP_NAME% <!-- [<a href='$SELF?index=$index&TP_ID=%TP_ID%' title='$_TARIF_PLANS'>$_TARIF_PLANS</a>] --></TD></TR>
<TR><TD>$_TO:</TD><TD>%TARIF_PLAN_SEL%</TD></TR>
%PARAMS%
</TABLE>
<input type=submit name=%ACTION% value=\"%LNG_ACTION%\">
</form>
}
}
elsif ($tpl_name eq 'services') {
return qq{
<form action="$SELF_URL" METHOD="POST">
<input type=hidden name='index' value='$index'>
%SERVICES%
<input type=submit name=%ACTION% value=\"%LNG_ACTION%\">
</form>
}
}
elsif ($tpl_name eq 'form_er') {
return qq{
<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=op    value=er>
<input type=hidden name=chg   value="$FORM{chg}"> 
<table>
<tr><td>$_MONEY:</td><td><input type=text name=ER_NAME value='%ER_NAME%'></td></tr>
<tr><td>$_SHORT_NAME:</td><td><input type=text name=ER_SHORT_NAME value='%ER_SHORT_NAME%'></td></tr>
<tr><td>$_EXCHANGE_RATE:</td><td><input type=text name=ER_RATE value='%ER_RATE%'></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>

}
}

elsif ($tpl_name eq 'chg_company') {
return qq{
<form action=$SELF_URL>
<input type=hidden name=index value=11>
<input type=hidden name=UID value=%UID%>
<input type=hidden name='user_f' value='chg_company'>
<Table>
<TR><TD>$_COMPANY:</TD><TD>%COMPANY_NAME%</TD></TR>
<TR><TD>$_TO:</TD><TD>%SEL_COMPANIES%</TD></TR>
</TABLE>
<input type='submit' name='change' value='$_CHANGE'>
</form>
}
}
elsif ($tpl_name eq 'chg_group') {
return qq{
<form action=$SELF_URL>
<input type='hidden' name='index' value='11'>
<input type='hidden' name='UID' value='%UID%'>
<input type='hidden' name='user_f' value='chg_group'>
<Table>
<TR><TD>$_GROUP:</TD><TD>%GID%:%G_NAME%</TD></TR>
<TR><TD>$_TO:</TD><TD>%SEL_GROUPS%</TD></TR>
</TABLE>
<input type='submit' name='change' value='$_CHANGE'>
</form>
}
}
elsif ($tpl_name eq 'form_search') {
return qq{
<div class='noprint'>

<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
%HIDDEN_FIELDS%
<TABLE>

<TR bgcolor='$_COLORS[0]'><TH colspan='2' align='right'>$_SEARCH</TH></TR>
%SEL_TYPE%
<TR><TD>$_LOGIN:</TD><TD><input type='text' name='LOGIN_EXPR' value='%LOGIN_EXPR%'></TD></TR>
<tr><TD>$_PERIOD:</TD><TD>
<TABLE width='100%'>
<TR><TD>$_FROM: </TD><TD>%FROM_DATE%</TD></TR>
<TR><TD>$_TO:</TD><TD>%TO_DATE%</TD></TR>
</TABLE>
</TD></TR>
<TR><TD colspan=2>&nbsp;</TD></TR>
<TR><TD>$_ROWS:</TD><TD><input type='text' name='PAGE_ROWS' value='$PAGE_ROWS'></TD></TR>
%SEARCH_FORM%
</TABLE>
<input type='submit' name='search' value='$_SEARCH'>
</form>
</div>
};
	
}

elsif ($tpl_name eq 'form_search_users') {
return qq{
<!-- USERS -->
<tr><td colspan='2'><hr/></td></tr>
<tr><td colspan='2'>
<table border=0>
<tr><td colspan='2'>$_FIO (*):</td><td><input type='text' name='FIO' value='%FIO%'/></td><th bgcolor='$_COLORS[0]' colspan='2'>$_ADDRESS:</th></tr>
<tr><td colspan='2'>$_CONTRACT_ID (*):</td><td><input type='text' name='CONTRACT_ID' value='%CONTRACT_ID%'/></td><td bgcolor='$_COLORS[2]'>$_ADDRESS_STREET:</td><td><input type='text' name='ADDRESS_STREET' value='%ADDRESS_STREET%'/></td></tr>
<tr><td colspan='2'>$_PHONE (>, <, *):</td><td><input type='text' name='PHONE' value='%PHONE%'/></td><td  bgcolor='$_COLORS[2]'>$_ADDRESS_BUILD:</td><td><input type='text' name='ADDRESS_BUILD' value='%ADDRESS_BUILD%'/></td> </tr>
<tr><td colspan='2'>$_COMMENTS (*):</td><td><input type='text' name='COMMENTS' value='%COMMENTS%'/></td><td bgcolor='$_COLORS[2]'>$_ADDRESS_FLAT:</td><td><input type='text' name='ADDRESS_FLAT' value='%ADDRESS_FLAT%'/></td></tr>
<tr><td colspan='2'>$_GROUP:</td><td>%GROUPS_SEL%</td><td bgcolor='$_COLORS[2]'>$_CITY:</td><td><input type='text' name='CITY' value='%CITY%'/></td></tr>
<tr><td colspan='2'>$_DEPOSIT (>, <):</td><td><input type='text' name='DEPOSIT' value='%DEPOSIT%'/></td><td bgcolor='$_COLORS[2]'>$_ZIP:</td><td> <input type='text' name='ZIP' value='%ZIP%'  size='8' /></td></tr>

<tr><td colspan='2'>BILL ID (>, <):</td><td><input type='text' name='BILL_ID' value='%BILL_ID%'/></td></tr>

<tr><td colspan='2'>$_CREDIT (>, <):</td><td><input type='text' name='CREDIT' value='%CREDIT%'/></td><th colspan='2' bgcolor=$_COLORS[0]>$_PASPORT</th></tr>
<tr><td colspan='2'>$_PAYMENTS $_DATE ((>, <) YYYY-MM-DD):</td><td><input type='text' name='PAYMENTS' value='%PAYMENTS%'/></td><TD bgcolor='$_COLORS[2]'>$_NUM:</TD><TD><input type=text name=PASPORT_NUM value="%PASPORT_NUM%"></TD></tr>

<tr><td colspan='2'>$_DISABLE:</td><td><input type='checkbox' name='DISABLE' value='1'/></td><TD bgcolor='$_COLORS[2]'>$_DATE:</TD><TD><input type=text name=PASPORT_DATE value="%PASPORT_DATE%"></TD></tr>
<tr><td colspan='2'>$_REGISTRATION (<>):</td><td><input type='text' name='REGISTRATION' value='%REGISTRATION%'/></td><TD bgcolor='$_COLORS[2]'>$_GRANT:</TD><TD><input type=text name=PASPORT_GRANT value='%PASPORT_GRANT%'></TD></tr>
<tr><td colspan='2'>$_ACTIVATE (<>):</td><td><input type='text' name='ACTIVATE' value='%ACTIVATE%'/></td></tr>
<tr><td colspan='2'>$_EXPIRE (<>):</td><td><input type='text' name='EXPIRE' value='%EXPIRE%'/></td></tr>
</table>
</td></tr>
};
}

elsif ($tpl_name eq 'form_search_payments') {
return qq{
<!-- PAYMENTS -->
<tr><td colspan='2'><hr/></td></tr>
<tr><td>$_OPERATOR (ID):</td><td><input type='text' name='A_LOGIN' value='%A_LOGIN%'/></td></tr>
<tr><td>$_DESCRIBE (*):</td><td><input type='text' name='DESCRIBE' value='%DESCRIBE%'/></td></tr>
<tr><td>$_SUM (&lt;, &gt;):</td><td><input type='text' name='SUM' value='%SUM%'/></td></tr>
<tr><td>$_PAYMENT_METHOD:</td><td>%SEL_METHOD%</td></tr>
<tr><td>$_PAYMENTS ID (&lt;, &gt;):</td><td><input type='text' name='ID' value='%ID%'/></td></tr>
<tr><td>EXT ID:</td><td><input type='text' name='EXT_ID' value='%EXT_ID%'/></td></tr>
};
}

elsif ($tpl_name eq 'form_search_fees') {
return qq{
<!-- FEES -->
<tr><td colspan='2'><hr/></td></tr>
<tr><td>$_OPERATOR (ID):</td><td><input type='text' name='A_LOGIN' value='%A_LOGIN%'/></td></tr>
<tr><td>$_DESCRIBE (*):</td><td><input type='text' name='DESCRIBE' value='%DESCRIBE%'/></td></tr>
<tr><td>$_SUM (<,>):</td><td><input type='text' name='SUM' value='%SUM%'/></td></tr>
};
}

elsif ($tpl_name eq 'history_search') {
return qq{
 	 <tr><td colspan=2><hr></td></tr>
   <tr><td>$_ADMIN:</td><td><input type='text' name='ADMIN' value='%ADMIN%'></td></tr>
   <tr><td>$_CHANGE (*)</td><td><input type='text' name='ACTION' value='%ACTION%'></td></tr>
   <tr><td>$_MODULES:</td><td>%MODULES_SEL%</td></tr>
};
}
elsif ($tpl_name eq 'form_search_simple') {
return qq{
<form action=$SELF_URL>
<input type=hidden name=index value=$index>
%HIDDEN_FIELDS%
<TABLE>
<TR bgcolor='$_COLORS[0]'><TH colspan='2' align='right'>$_SEARCH</TH></TR>
%SEARCH_FORM%
<TR><TD>$_ROWS:</TD><TD><input type=text name=PAGE_ROWS value=$PAGE_ROWS></TD></TR>
</TABLE>
<input type=submit name=search value=$_SEARCH>
</form>
};
}
elsif ($tpl_name eq 'form_ip_pools') {
return qq{
<form action="$SELF_URL" METHOD="post">
<input type="hidden" name="index" value="61"/>
<input type="hidden" name="NAS_ID" value="%NAS_ID%"/>
<TABLE>
<TR><TD>FIRST IP:</TD><TD><input type="text" name="NAS_IP_SIP" value="%NAS_IP_SIP%"/></TD></TR>
<TR><TD>COUNT:</TD><TD><input type="text" name="NAS_IP_COUNT" value="%NAS_IP_COUNT%"/></TD></TR>
</TABLE>
<input type="submit" name="add" value="$_ADD" class="button"/>
</form>

};
}
elsif ($tpl_name eq 'form_groups'){
return qq{
<form action="$SELF_URL" METHOD="post">
<input type="hidden" name="index" value="27"/>
<input type="hidden" name="chg" value="%GID%"/>
<TABLE>
<TR><TD>GID:</TD><TD><input type="text" name="GID" value="%GID%"/></TD></TR>
<TR><TD>$_NAME:</TD><TD><input type="text" name="G_NAME" value="%G_NAME%"/></TD></TR>
<TR><TD>$_DESCRIBE:</TD><TD><input type="text" name="G_DESCRIBE" value="%G_DESCRIBE%"></TD></TR>
</TABLE>
<input type="submit" name="%ACTION%" value="%LNG_ACTION%" class="button"/>
</form>
};
}
elsif($tpl_name eq 'form_user_login') {
return qq{
<script type=\"text/javascript\">
	function selectLanguage() {
		sLanguage	= '';
		
		try {
			frm = document.forms[0];
			if(frm.language)
				sLanguage = frm.language.options[frm.language.selectedIndex].value;
			sLocation = '$SELF_URL?language='+sLanguage;
			location.replace(sLocation);
		} catch(err) {
			alert('Your brownser do not support JS');
		}
	}
</script>

<form action="$SELF_URL" METHOD="post">
<TABLE width="400"  cellspacing="0" cellpadding="0" border="0"><TR><TD bgcolor="$_COLORS[4]">
<TABLE width="100%" cellspacing="1" cellpadding="0" border="0"><TR><TD bgcolor="$_COLORS[1]">
<TABLE width="100%" cellspacing="0" cellpadding="0" border="0">
<TR><TD>$_LANGUAGE:</TD><TD>%SEL_LANGUAGE%</TD></TR>
<TR><TD>$_LOGIN:</TD><TD><input type="text" name="user"></TD></TR>
<TR><TD>$_PASSWD:</TD><TD><input type="password" name="passwd"></TD></TR>
<tr><th colspan="2"><input type="submit" name="logined" value="$_ENTER"></th></TR>
</TABLE>
</TD></TR></TABLE>
</TD></TR></TABLE>
</form>
};
}
elsif ($tpl_name eq 'groups_sel') {
return qq{
<form action="$SELF_URL" METHOD="POST">
<input type=hidden name="index" value="$index"/>
<TABLE width="100%" cellspacing="0" cellpadding="0" border="0">
<TR><TD bgcolor="$_COLORS[1]">
<TABLE width="100%" cellspacing="1" cellpadding="0" border="0">
<TR><TD>$_GROUP:</TD><TD>%GROUPS_SEL% <input type="submit" name="SHOW" value="$_SHOW" class="button"/></TD></TR>
</TABLE>
</TD></TR></TABLE>
</form>
};
}
elsif ($tpl_name eq 'chg_bill') {
return qq{
<form action="$SELF_URL">
<input type=hidden name="index" value="$index"/>
<input type=hidden name="UID" value="%UID%"/>
<input type=hidden name="COMPANY_ID" value="$FORM{COMPANY_ID}"/>
<Table width=300>
<TR><TD>$_BILL:</TD><TD>%BILL_ID%:%LOGIN%</TD></TR>
<TR><TD>$_CREATE:</TD><TD><input type="checkbox" name="create" value="1"/></TD></TR>
<TR><TD>$_TO:</TD><TD>%SEL_BILLS%</TD></TR>
</TABLE>
%CREATE_BTN%
<input type="submit" name="change" value="$_CHANGE" class="button"/>
</form>
}
}
elsif ($tpl_name eq 'users_start') {
return qq{
<TABLE width="100%" border="0">
<TR bgcolor="$_COLORS[0]"><TD align="right"><h3>ABillS</h3></TD></TR>
</TABLE>
<TABLE width="100%">
<TR><TD align="center">

%BODY%

</TD></TR></TABLE>
<hr/>
}
}

elsif ($tpl_name eq 'users_main') {
return qq{
<TABLE border="0" WIDTH="100%" style='margin: 0' CELLSPACING='0' CELLPADDING='0'>
<TR BGCOLOR="$_COLORS[2]"><TD>LOGIN: %LOGIN%</TD><TD align="right">$_DATE: %DATE% $_TIME: %TIME%</TD></TR></TABLE>
<TABLE border="0" width="100%" style='margin: 0'>
<TR><TD width="200" valign="top" bgcolor="$_COLORS[2]">%MENU%</TD><TD align="center">
%BODY%
</TD></TR></TABLE>
}
}
elsif($tpl_name eq 'mail_form') {
return qq{
<form action='$SELF_URL' METHOD='post'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='UID' value='$FORM{UID}'>
<table>
%EXTRA%
<tr><td>$_SUBJECT:</td><td><input type='text' name='SUBJECT' value='%SUBJECT%' size='40'></td></tr>
<tr><td>$_FROM:</td><td><input type='text' name='FROM' value='%FROM%' size='40'></td></tr>
<tr><th colspan='2' bgcolor='$_COLORS[0]'>$_MESSAGE</th></tr>
<tr><th colspan='2'><textarea name='TEXT' rows='15' cols='80'></textarea></th></tr>
<tr><td>PRIORITY:</td><td>%PRIORITY_SEL%</td></tr>
%PERIOD_FORM%
%EXTRA2%
</table>
<input type='submit' name='sent' value='$_SEND'>
</form>
	
 } 
 }


elsif($tpl_name eq 'admin_report_day') {
return qq{
Daily Admin Report /%DATE%/
Hostname: %HOSTNAME%

$_PAYMENTS
=========================================================
%PAYMENTS%

$_FEES
=========================================================
%FEES%

$_SHEDULE
=========================================================
%SHEDULE%

USERS_WARNING_MESSAGES
=========================================================
%USERS_WARNINGS%

$_CLOSED
=========================================================
%CLOSED%

$_USED
=========================================================
%MODULES%

=========================================================
%GT%

};

}
elsif($tpl_name eq 'admin_report_month') {

return qq{
Monthly Admin Report /%DATE%/
Hostname: %HOSTNAME%

$_PAYMENTS
=========================================================
%PAYMENTS%


$_FEES
=========================================================
%FEES%


USERS_WARNING_MESSAGES
=========================================================
%USERS_WARNINGS%


$_CLOSED
=========================================================
%CLOSED%


$_USED
=========================================================
%MODULES%


=========================================================
%GT%
};
}
elsif ($tpl_name eq 'help_form') {
return qq{
<center>
<form action='$SELF_URL' METHOD=post>
<input type=hidden name='index' value="$FORM{index}">
<input type=hidden name='FUNCTION' value="$FORM{FUNCTION}">
<input type=hidden name='language' value='%LANGUAGE%'>
<table border='0'>
<tr><td>$_SUBJECT: </td><td><input type=text name=TITLE value='%TITLE%' size=40></td></tr>
<tr><th colspan='2' bgcolor="$_COLORS[0]">$_HELP</th></tr>
<tr><th colspan='2'><textarea name='HELP' cols='50' rows='4'>%HELP%</textarea></th></tr>
<tr><td colspan='2'>%LANGUAGE%</td></tr>
<tr><th colspan='2'><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>
</form>
</center>
}
}

elsif ($tpl_name eq 'form_tp_group') {
return qq{
<form action='$SELF_URL' METHOD='post'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%GID%'/>
<TABLE>
<TR><TD>GID:</TD><TD><input type='text' name='GID' value='%GID%'/></TD></TR>
<TR><TD>$_NAME:</TD><TD><input type='text' name='NAME' value='%NAME%'/></TD></TR>
<TR><TD>$_USER_CHG_TP:</TD><TD><input type='checkbox' name='USER_CHG_TP' value='1' %USER_CHG_TP%></TD></TR>
</TABLE>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='button'/>
</form>
}
}

elsif ($tpl_name eq 'form_bruteforce_message') {
	return qq{
  <TABLE width="400" border="0" cellpadding="0" cellspacing="0" class="noprint">
<tr><TD bgcolor="$_COLORS[9]">
<TABLE width="100%" border=0 cellpadding="2" cellspacing="1">
<tr><TD bgcolor="$_COLORS[1]">
<TABLE width="100%">
<tr bgcolor='#FF0000'><th>$_ERROR</th></tr>
<tr><td>
	  You try to brute password and system block your account.<br>
	  Please conntact system administrator.

</td></tr></table>
</TD></TR></TABLE>
</TD></TR></TABLE>

	};
}
elsif ($tpl_name eq 'help_info') {
return qq{
<table width="100%">
     	<tr bgcolor="$_COLORS[0]"><th align="left">%TITLE%</th></tr>
	    <tr><td>%HELP%</td></tr>
	    <tr><td align="right"><!-- <a href="$SELF_URL?index=$index&amp;FUNCTION=%FUNCTION%">$_CHANGE</a> --> %LANGUAGE%</td></tr>
</table>
<hr>

}
}
elsif ($tpl_name eq 'forgot_passwd') {
return qq{
<FORM action='$SELF_URL' METHOD=POST>
<input type=hidden name=FORGOT_PASSWD value=1>
<TABLE width="400" cellspacing="0" cellpadding="0" border="0"><TR><TD bgcolor="#E1E1E1">
<TABLE width="100%" cellspacing="1" cellpadding="0" border="0">

<tr bgcolor="$_COLORS[0]"><th align="right" colspan="2">$_PASSWORD_RECOVERY</th></tr>
<tr bgcolor="$_COLORS[1]"><th align="left">$_LOGIN:</th><th> <input type=text name=LOGIN value='' size=30> </th></tr>
<tr bgcolor="$_COLORS[1]"><th align="left">E-Mail:</th><th> <input type=text name=EMAIL value='' size=30> </th></tr>
<tr bgcolor="$_COLORS[1]"><th align="center" colspan="2"><input type=submit name="SEND" value=$_SEND></th></tr>


</table>
</td></tr></table>

</FORM>

}
}
elsif ($tpl_name eq 'passwd_recovery') {
return qq{
Password Recovery:
===========================================================
  %MESSAGE%


DATE: $DATE
===========================================================
$PROGRAM
}
}

return "No such template [$tpl_name]";

}




1

