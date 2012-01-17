<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data'>
<input type='hidden' name='qindex' value='$index'/>
<input type='hidden' name='UID' value='$FORM{UID}'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='PARENT' value='%PARENT%'/>

<TABLE width='100%' class=form>
<TR><TD class=cel_border valign='top'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0' style='height: 100%'>
<!-- <tr class='odd'><TD>%THREADS%</td></tr> -->

<tr><th colspan=4 align=left class='even'> > %SUBJECT%</th></tr>
<tr><td colspan=4>

<table cellspacing='1' cellpadding='0' border='0' width=100%>
<tr><td  class='odd'>ID:</td><td  class='odd'>%ID%</td><td  class='odd'>$_CHAPTERS:</td><td  class='odd'>%CHAPTER%</td></tr>
<tr><td  class='odd'>$_STATUS:</td><td  class='odd'>%STATE_SEL%</td><td  class='odd'>$_PRIORITY:</td><td  class='odd'>%PRIORITY_SEL%</td></tr>
<tr><td  class='odd'>$_CREATED:</td><td  class='odd'>%DATETIME%</td><td  class='odd'>$_CLOSED:</td><td  class='odd'>%CLOSED_DATE%</td></tr>
</table>

</th></tr>
<tr><th colspan=4 align=left class='odd'>&nbsp;</th></tr>
<tr class='total'><td colspan=4> 
<table cellspacing='1' cellpadding='0' border='0' width=100%>
<tr><th align=left class='odd'>$_FIO:</th><th align=left  class='odd'> %FIO% </th></tr>
<tr><th align=left class='odd'>$_COMPANY:</th><td class='odd'> %COMPANY%</td></tr>
<tr><th align=left class='odd'>$_PHONE:</th><td class='odd'> %PHONE% </td></tr>
<tr><th align=left class='odd'>$_ADDRESS:</th><td class='odd'> %ADDRESS_STREET%  %ADDRESS_BUILD% %ADDRESS_FLAT%</td></tr>
<tr><th align=left class='odd'>E-mail:</th><td class='odd'> %EMAIL%</td></tr>
</table>
</td></tr>
<tr><td class='odd' colspan='4'>&nbsp; %REQUEST%</td></tr>
<tr><td class='even' colspan='4' class=small></td></tr>
<tr><td colspan='4' class='even' align=center><textarea cols=70 rows=20 name=COMMENTS>%COMMENTS%</textarea></td></tr>
<tr><td colspan='4' class='odd' align=center><input type=submit name=change value=$_CHANGE></td></tr>
</TABLE>

</TD>
</TR>
</TABLE>
</form>

<div class='noprint' align=center>
<p>
<a href=\"javascript:window.print();\" class='print rightAlignText'>$_PRINT</a> 
<a href=\"javascript:window.close();\" class='del rightAlignText'>$_CLOSE</a>
</p>
</div>
