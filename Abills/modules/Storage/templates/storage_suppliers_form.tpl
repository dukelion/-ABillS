<form action=$SELF_URL?index=$index&splid=%ID% name=\"suppliers_form\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<table border=\"0\" >
  <tr>
    <td>TESTING:</td>
    <td>%WND%</td>
  </tr>
  <tr>
    <td>$_NAME:</td>
    <td><input name=\"NAME\" type=\"text\" value=\"%NAME%\" /></td>
  </tr>
  <tr>
    <td>$_DATE:</td>
    <td><input name=\"DATE\" type=\"text\" value=\"%DATE%\" /></td>
  </tr>
  <tr>
    <td>$_OKPO_EDRPOY:</td>
    <td><input name=\"OKPO\" type=\"text\" value=\"%OKPO%\" /></td>
  </tr>
  <tr>
    <td>$_INDIVIDUAL_TAX_NUMBER:</td>
    <td><input name=\"INN\" type=\"text\" value=\"%INN%\" /></td>
  </tr>
  <tr>
    <td>$_CERTIFICATE_OF_INDIVIDUAL_TAX_NUMBER:</td>
    <td><input name=\"INN_SVID\" type=\"text\" value=\"%INN_SVID%\" /></td>
  </tr>
  <tr>
    <th colspan=\"2\" class=\"table_title\">$_BANK_ESSENTIAL:</th>
  </tr>
  <tr>
    <td>$_NAME_OF_BANK:</td>
    <td><input name=\"BANK_NAME\" type=\"text\" value=\"%BANK_NAME%\" /></td>
  </tr>
  <tr>
    <td>$_MFO:</td>
    <td><input name=\"MFO\" type=\"text\" value=\"%MFO%\" /></td>
  </tr>
  <tr>
    <td>$_ACCOUNT:</td>
    <td><input name=\"ACCOUNT\" type=\"text\" value=\"%ACCOUNT%\" /></td>
  </tr>
  <tr>
    <th colspan=\"2\" class=\"table_title\">$_CONTACTS:</th>
  </tr>
  <tr>
    <td>$_PHONE 1:</td>
    <td><input name=\"PHONE\" type=\"text\" value=\"%PHONE%\" /></td>
  </tr>
  <tr>
    <td>$_PHONE 2:</td>
    <td><input name=\"PHONE2\" type=\"text\" value=\"%PHONE2%\" /></td>
  </tr>
  <tr>
    <td>$_FAX:</td>
    <td><input name=\"FAX\" type=\"text\" value=\"%FAX%\" /></td>
  </tr>
  <tr>
    <td>$_WEBSITE:</td>
    <td><input name=\"URL\" type=\"text\" value=\"%URL%\" /></td>
  </tr>
  <tr>
    <td>E-mail:</td>
    <td><input name=\"EMAIL\" type=\"text\" value=\"%EMAIL%\" /></td>
  </tr>
  <tr>
    <td>ICQ:</td>
    <td><input name=\"ICQ\" type=\"text\" value=\"%ICQ%\" /></td>
  </tr>
  <tr>
    <th colspan=\"2\" class=\"table_title\">$_GUIDANCE:</th>
  </tr>
  <tr>
    <td>$_POSITION_MANAGER:</td>
    <td><input name=\"ACCOUNTANT\" type=\"text\" value=\"%ACCOUNTANT%\" /></td>
  </tr>
  <tr>
    <td>$_MANAGER:</td>
    <td><input name=\"DIRECTOR\" type=\"text\" value=\"%DIRECTOR%\" /></td>
  </tr>
  <tr>
    <td>$_ACCOUNTANT:</td>
    <td><input name=\"MANAGMENT\" type=\"text\" value=\"%MANAGMENT%\" /></td>
  </tr>
</table>
<input type=submit name=%ACTION% value=%ACTION_LNG%>
</form>