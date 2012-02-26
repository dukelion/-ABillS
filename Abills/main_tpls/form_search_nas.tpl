        <form action=$SELF_URL METHOD=post id=POPUP_FORM>
                <input type=hidden name='POPUP' value='1'>
                <input type=hidden name='NAS_SEARCH' value='1'>
                <TABLE class=form>
                        <TR><th class=form_title colspan=2>SEARCH</th></TR>
                        <TR><TD>IP</TD><TD><input type=text name=NAS_IP value='%NAS_IP%'></TD></TR>
                        <TR><TD>NAME :</TD><TD><input type=text name=NAS_NAME value='%NAS_NAME%'></TD></TR>
                        <TR><TD>Radius NAS-Identifier:</TD><TD><input type=text name=NAS_INDENTIFIER value='%NAS_INDENTIFIER%'></TD></TR>
                        <TR><TD>TYPE:</TD><TD>%SEL_TYPE%</TD></TR>
                        <TR><TD>MAC:</TD><TD><input type=text name=MAC_AJAX value='%MAC%'></TD></TR>
                        <TR><TD>$_GROUP:</TD><TD>%NAS_GROUPS_SEL%</TD></TR>
                        
                </TABLE>
                <br />
                <input type=submit name='action' value='SEARCH' id='search_nas'>
        </form>

