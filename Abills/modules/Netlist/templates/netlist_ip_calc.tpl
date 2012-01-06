<FORM action=$SELF_URL METHOD=POST> 
<input type=hidden name='index' value='$index'> 

<table class=form>
<tr><td>IP: </td><td><input type=text name=IP_D1 value='%IP_D1%' size=5>.
<input type=text name=IP_D2 value='%IP_D2%' size=5>.
<input type=text name=IP_D3 value='%IP_D3%' size=5>.
<input type=text name=IP_D4 value='%IP_D4%' size=5></td></tr>
<tr><td>MASK: </td><td>%MASK_SEL%</td></tr>
<tr><td>MASK Bits: </td><td>%MASK_BITS_SEL%</td></tr>

<tr><td>Number of subnets: </td><td>%SUBNET_NUMBER_SEL%</td></tr>
<tr><td>Hosts per  Subnet: </td><td>%HOSTS_NUMBER_SEL%</td></tr>
<tr><td>Subnet Bit Mask: </td><td><input type=text name=SBM value='%SBM%' size=55></td></tr>

<tr><th class=even colspan=2><input type=submit name='SHOW' value='$_SHOW'> </th></tr>
</table>

</FORM>
