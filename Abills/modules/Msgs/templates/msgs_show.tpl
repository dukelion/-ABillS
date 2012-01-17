<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data' name=add_message>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='UID' value='$FORM{UID}'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='PARENT' value='%PARENT%'/>
<input type='hidden' name='CHAPTER' value='%CHAPTER%'/>
<input type='hidden' name='INNER_MSG' value='%INNER_MSG%'/>


<TABLE width='100%' cellspacing='0' cellpadding='0' border='0'>

<TR><TD bgcolor='#FFFFFF' valign='top'>
<TABLE width='100%' class=form>
<!-- <tr bgcolor=$_COLORS[1]><TD>%THREADS%</td></tr> -->
<tr><th colspan=4 align=left class='even'> > %SUBJECT%</th></tr>
<tr><td colspan=4>
<table cellspacing='1' cellpadding='0' border='0' width=100%>
<tr><td  class='odd'>ID:</td><td class='odd'>%ID%</td><td  class='odd'>$_CHAPTERS:</td><td  class='odd'>%CHAPTER_NAME%</td></tr>
<tr><td  class='odd'>$_STATUS:</td><td class='odd'>%STATE_NAME%</td><td  class='odd'>$_PRIORITY:</td><td  class='odd'>%PRIORITY_TEXT%</td></tr>
<tr><td  class='odd'>$_CREATED:</td><td class='odd'>%DATE%</td><td  class='odd'>$_UPDATED:</td><td  class='odd'>%UPDATED%</td></tr>
</table>
</th></tr>
<!-- <tr><th colspan=4 align=left class='odd'>&nbsp;</th></tr> -->
<tr class='total'><td colspan=4> 
<table cellspacing='1' cellpadding='0' border='0' width=100%>
<tr><th align=left class=title_color> %LOGIN% </th></tr>
<tr><td class=medium align=left>$_ADDED: %DATE%</td></tr>
</table>
</td></tr>
<tr><td class='odd' colspan='4'>%MESSAGE%</td></tr>
<tr><td class=medium  colspan='4'>%ATTACHMENT%</td></tr>
<tr><td colspan='4' class='odd'>%REPLY%</td></tr>
</TABLE>

</TD><td width='200' valign='top' class='even'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0' class=form>
<tr><td>


%EXT_INFO%


</td></tr></TABLE>


</td></TR></TABLE>




</form>
