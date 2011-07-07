var marked_row = new Array;
var confirmMsg = '';




function checkval(url) {

  var val;
  var field = document.getElementById('pagevalue').value;
  if (field == '')
      return alert('Как так, вы же ничего не ввели');

  val = parseInt(field);
  

  
  if (isNaN(val))
      return alert('Это не число!');

  if (val != field)
      return alert('Это не число!');

  if (val <= 0)
      return alert('Мы - за движение вперед! Введите положительное число');

	window.location = url + val;
}

function showHidePageJump() {
	if (document.getElementById('pageJumpWindow').style.display == 'block') {
		document.getElementById('pageJumpWindow').style.display = 'none';	
	} else { 
		document.getElementById('pageJumpWindow').style.display = 'block';	
	}
}



/**
*/
function keyDown(e) { 
  if(e.keyCode == 17)
    ctrl = true;
  else if(e.keyCode == 13 && ctrl)
	document.getElementById('go').click();
}

/**

*/
function keyUp(e){
  if(e.keyCode == 17) 
    ctrl = false;
}



/**
 * Displays an confirmation box beforme to submit a "DROP/DELETE/ALTER" query.
 * This function is called while clicking links
 *
 * @param   object   the link
 * @param   object   the sql query to submit
 *
 * @return  boolean  whether to run the query or not
 */
function confirmLink(theLink, Message, CustomMsg)
{
    if (CustomMsg != undefined ) {
      confirmMsg = CustomMsg;
     }
    //else {
    // 	confirmMsg = confirmMsg + ' :\n';
    // }

    var is_confirmed = confirm(confirmMsg + Message);
    if (is_confirmed) {
        theLink.href += '&is_js_confirmed=1';
    }

    return is_confirmed;
} // end of the 'confirmLink()' function


/**
 * Generate a new password, which may then be copied to the form
 * with suggestPasswordCopy().
 *
 * @param   string   the form name
 *
 * @return  boolean  always true
 */
function suggestPassword(input_pwchars, input_passwordlength) {
    var pwchars = "abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ.,:";
    var passwordlength = 8;    // do we want that to be dynamic?  no, keep it simple :)
    var passwd = document.getElementById('generated_pw');

    if (input_pwchars != '') {
    	pwchars = input_pwchars;
     }
    
    if (input_passwordlength != '') {
    	passwordlength = input_passwordlength;
     }


    
    passwd.value = '';

    for ( i = 0; i < passwordlength; i++ ) {
        passwd.value += pwchars.charAt( Math.floor( Math.random() * pwchars.length ) )
    }
    return passwd.value;
}

/**
 * Copy the generated password (or anything in the field) to the form
 *
 * @param   string   the form name
 *
 * @return  boolean  always true
 */
function suggestPasswordCopy() {
    document.getElementById('text_pma_pw').value = document.getElementById('generated_pw').value;
    document.getElementById('text_pma_pw2').value = document.getElementById('generated_pw').value;
    return true;
}

/**
 * Copy one input form to other
 *
 * @param   string   the form name
 *
 * @return  boolean  always true
 */
function CopyInputField(from, to) {
    document.getElementById(to).value = document.getElementById(from).value;
    return true;
}

/*
* Disable button after click
* @param obj, object text
*
* @return  boolean  always true
*/

function obj_disable(obj, text) {
  if (obj.disabled) {obj.disabled = false;}
  else obj.disabled = true;

  if (text != '') obj.value=text ;  

  return true;
}


/**
 * This array is used to remember mark status of rows in browse mode
 */
var marked_row = new Array;

/**
 * enables highlight and marking of rows in data tables
 *
 */
function PMA_markRowsInit() {
    // for every table row ...
    var rows = document.getElementsByTagName('tr');
    for ( var i = 0; i < rows.length; i++ ) {
        // ... with the class 'odd' or 'even' ...
        if ( 'odd' != rows[i].className.substr(0,3) && 'even' != rows[i].className.substr(0,4) ) {
            continue;
        }
        // ... add event listeners ...
        // ... to highlight the row on mouseover ...
        if ( navigator.appName == 'Microsoft Internet Explorer' ) {
            // but only for IE, other browsers are handled by :hover in css
            rows[i].onmouseover = function() {
                this.className += ' hover';
            }
            rows[i].onmouseout = function() {
                this.className = this.className.replace( ' hover', '' );
            }
        }
        // Do not set click events if not wanted
        if (rows[i].className.search(/noclick/) != -1) {
            continue;
        }
        // ... and to mark the row on click ...
        rows[i].onmousedown = function(event) {
            var unique_id;
            var checkbox;
            var table;

            // Somehow IE8 has this not set
            if (!event) var event = window.event
			
            checkbox = this.getElementsByTagName( 'input' )[0];
            if ( checkbox && checkbox.type == 'checkbox' ) {
                unique_id = checkbox.name + checkbox.value;
            } else if ( this.id.length > 0 ) {
                unique_id = this.id;
            } else {
                return;
            }

            if ( typeof(marked_row[unique_id]) == 'undefined' || !marked_row[unique_id] ) {
                marked_row[unique_id] = true;
            } else {
                marked_row[unique_id] = false;
            }

            if ( marked_row[unique_id] ) {
                this.className += ' marked';
            } else {
                this.className = this.className.replace(' marked', '');
            }

            if ( checkbox && checkbox.disabled == false ) {
                checkbox.checked = marked_row[unique_id];
                if (typeof(event) == 'object') {
                    table = this.parentNode;
                    i = 0;
                    while (table.tagName.toLowerCase() != 'table' && i < 20) {
                        i++;
                        table = table.parentNode;
                    }

                    if (event.shiftKey == true && table.lastClicked != undefined) {
                        if (event.preventDefault) { event.preventDefault(); } else { event.returnValue = false; }
                        i = table.lastClicked;

                        if (i < this.rowIndex) {
                            i++;
                        } else {
                            i--;
                        }

                        while (i != this.rowIndex) {
                            table.rows[i].onmousedown();
                            if (i < this.rowIndex) {
                                i++;
                            } else {
                                i--;
                            }
                        }
                    }

                    table.lastClicked = this.rowIndex;
                }
            }
        }

        // ... and disable label ...
        var labeltag = rows[i].getElementsByTagName('label')[0];
        if ( labeltag ) {
            labeltag.onclick = function() {
                return false;
            }
        }
        // .. and checkbox clicks
        var checkbox = rows[i].getElementsByTagName('input')[0];
        if ( checkbox ) {
            checkbox.onclick = function() {
                // opera does not recognize return false;
                this.checked = ! this.checked;
            }
        }
    }
}
window.onload=PMA_markRowsInit;



function tmenudata0()
{
 this.animation_jump = 15
 this.animation_delay = 2
 this.imgage_gap = 3
 this.plus_image = "plus.gif"
 this.minus_image = "minus.gif"
 this.pm_width_height = "10,10"
 this.icon_width_height = "16,16"
 this.indent = 20; 
 this.use_hand_cursor = true; 
 this.main_item_styles = "text-decoration:none; \
 font-weight:normal; \
 font-family:Arial; \
 font-size:14px; \
 color:#FF0000; \
 padding:2px; "
 
 this.sub_item_styles = "text-decoration:none; \
 font-weight:normal; \
 font-family:Arial; \
 font-size:12px; \
 color:#807F80; "
 this.main_container_styles = "padding:0px;"
 this.sub_container_styles = "padding-top:4px; padding-bottom:4px;"
 this.main_link_styles = "color:#0000FF; text-decoration:none;"
 this.main_link_hover_styles = "color:#FF0000; text-decoration:underline;"
 this.sub_link_styles = ""
 this.sub_link_hover_styles = ""
 this.main_expander_hover_styles = "text-decoration:underline;";
 this.sub_expander_hover_styles = "";}




ulm_ie=window.showHelp;ulm_opera=window.opera;ulm_strict=((ulm_ie || ulm_opera)&&(document.compatMode=="CSS1Compat")); ulm_mac=navigator.userAgent.indexOf("Mac")+1;is_animating=false; cc3=new Object();cc4=new Object(); 
cc0=document.getElementsByTagName("UL");for(mi=0;mi<cc0.length; mi++){if(cc1=cc0[mi].id){if(cc1.indexOf("tmenu")>-1){cc1=cc1.substring(5); cc2=new window["tmenudata"+cc1];cc3["img"+cc1]=new Image();cc3["img"+cc1].src=cc2.plus_image;cc4["img"+cc1]=new Image(); cc4["img"+cc1].src=cc2.minus_image;if(!(ulm_mac && ulm_ie)){t_cc9=cc0[mi].getElementsByTagName("UL");for(mj=0;mj<t_cc9.length; mj++){cc23=document.createElement("DIV");cc23.className="uldivs"; cc23.appendChild(t_cc9[mj].cloneNode(1));t_cc9[mj].parentNode.replaceChild(cc23,t_cc9[mj]); }}cc5(cc0[mi].childNodes,cc1+"_",cc2,cc1); cc6(cc1,cc2);cc0[mi].style.display="block"; }}};function cc5(cc9,cc10,cc2,cc11){eval("cc8=new Array("+cc2.pm_width_height+")");this.cc7=0;for(this.li=0;this.li<cc9.length; this.li++){if(cc9[this.li].tagName=="LI"){this.level=cc10.split("_").length-1; cc9[this.li].style.cursor="default";this.cc12=false;this.cc13=cc9[this.li].childNodes; for(this.ti=0;this.ti<this.cc13.length;this.ti++){lookfor="DIV"; if(ulm_mac && ulm_ie)lookfor="UL";if(this.cc13[this.ti].tagName==lookfor){this.tfs=this.cc13[this.ti].firstChild; if(ulm_mac && ulm_ie)this.tfs=this.cc13[this.ti];this.usource=cc3["img"+cc11].src; if((gev=cc9[this.li].getAttribute("expanded"))&&(parseInt(gev))){this.usource=cc4["img"+cc11].src; }else this.tfs.style.display="none";if(cc2.folder_image){create_images(cc2,cc11,cc2.icon_width_height,cc2.folder_image,cc9[this.li]); this.ti=this.ti+2;}this.cc14=document.createElement("IMG");this.cc14.setAttribute("width",cc8[0]); this.cc14.setAttribute("height",cc8[1]);this.cc14.className="plusminus"; this.cc14.src=this.usource;this.cc14.onclick=cc16;this.cc14.onselectstart=function(){return false}; this.cc14.setAttribute("cc2_id",cc11);this.cc15=document.createElement("div"); this.cc15.style.display="inline";this.cc15.style.paddingLeft=cc2.imgage_gap+"px"; cc9[this.li].insertBefore(this.cc15,cc9[this.li].firstChild); cc9[this.li].insertBefore(this.cc14,cc9[this.li].firstChild); this.ti+=2;new cc5(this.tfs.childNodes,cc10+this.cc7+"_",cc2,cc11);this.cc12=1; }else if(this.cc13[this.ti].tagName=="SPAN"){this.cc13[this.ti].onselectstart=function(){return false}; this.cc13[this.ti].onclick=cc16;this.cc13[this.ti].setAttribute("cc2_id",cc11); this.cname="cc24";if(this.level>1)this.cname="cc25";if(this.level> 1)this.cc13[this.ti].onmouseover=function(){this.className="cc25"; };else this.cc13[this.ti].onmouseover=function(){this.className="cc24"; };this.cc13[this.ti].onmouseout=function(){this.className="";}; }}if(!this.cc12){if(cc2.document_image){create_images(cc2,cc11,cc2.icon_width_height,cc2.document_image,cc9[this.li]); }this.cc15=document.createElement("div");this.cc15.style.display="inline"; if(ulm_ie)this.cc15.style.width=cc2.imgage_gap+cc8[0]+"px";else this.cc15.style.paddingLeft=cc2.imgage_gap+cc8[0]+"px"; cc9[this.li].insertBefore(this.cc15,cc9[this.li].firstChild);}this.cc7++; }}};function create_images(cc2,cc11,iwh,iname,liobj){eval("tary=new Array("+iwh+")");this.cc15=document.createElement("div");this.cc15.style.display="inline"; this.cc15.style.paddingLeft=cc2.imgage_gap+"px"; liobj.insertBefore(this.cc15,liobj.firstChild); this.fi=document.createElement("IMG");this.fi.setAttribute("width",tary[0]); this.fi.setAttribute("height",tary[1]);this.fi.setAttribute("cc2_id",cc11); this.fi.className="plusminus";this.fi.src=iname;this.fi.style.verticalAlign="middle"; this.fi.onclick=cc16;liobj.insertBefore(this.fi,liobj.firstChild); };function cc16(){if(is_animating)return;cc18=this.getAttribute("cc2_id"); cc2=new window["tmenudata"+cc18];cc17=this.parentNode.getElementsByTagName("UL"); if(parseInt(this.parentNode.getAttribute("expanded"))){this.parentNode.setAttribute("expanded",0); if(ulm_mac && ulm_ie){cc17[0].style.display="none";}else {cc27=cc17[0].parentNode;cc27.style.overflow="hidden";cc26=cc27; cc27.style.height=cc17[0].offsetHeight;cc27.style.position="relative"; cc17[0].style.position="relative";is_animating=1;setTimeout("cc29("+(-cc2.animation_jump)+",false,"+cc2.animation_delay+")",0); }this.parentNode.firstChild.src=cc3["img"+cc18].src;}else {this.parentNode.setAttribute("expanded",1);if(ulm_mac && ulm_ie){cc17[0].style.display="block";}else {cc27=cc17[0].parentNode;cc27.style.height="1px";cc27.style.overflow="hidden"; cc27.style.position="relative";cc26=cc27;cc17[0].style.position="relative"; cc17[0].style.display="block";cc28=cc17[0].offsetHeight;cc17[0].style.top=-cc28+"px"; is_animating=1;setTimeout("cc29("+cc2.animation_jump+",1,"+cc2.animation_delay+")",0); }this.parentNode.firstChild.src=cc4["img"+cc18].src;}};function cc29(inc,expand,delay){cc26.style.height=(cc26.offsetHeight+inc)+"px"; cc26.firstChild.style.top=(cc26.firstChild.offsetTop+inc)+"px"; if( (expand &&(cc26.offsetHeight<(cc28)))||(!expand &&(cc26.offsetHeight>Math.abs(inc))) )setTimeout("cc29("+inc+","+expand+","+delay+")",delay);else {if(expand){cc26.style.overflow="visible"; if((ulm_ie)||(ulm_opera && !ulm_strict))cc26.style.height="0px";else cc26.style.height="auto";cc26.firstChild.style.top=0+"px";}else {cc26.firstChild.style.display="none"; cc26.style.height="0px";}is_animating=false;}};function cc6(id,cc2){np_refix="#tmenu"+id;cc20="<style type='text/css'>";cc19="";if(ulm_ie)cc19="height:0px;font-size:1px; ";cc20+=np_refix+" {width:100%;"+cc19+"-moz-user-select:none;margin:0px;padding:0px; list-style:none;"+cc2.main_container_styles+"}";cc20+=np_refix+" li{white-space:nowrap; list-style:none;margin:0px;padding:0px;"+cc2.main_item_styles+"}"; cc20+=np_refix+" ul li{"+cc2.sub_item_styles+"}";cc20+=np_refix+" ul{list-style:none;margin:0px;padding:0px;padding-left:"+cc2.indent+"px; "+cc2.sub_container_styles+"}";cc20+=np_refix+" a{"+cc2.main_link_styles+"}";cc20+=np_refix+" a:hover{"+cc2.main_link_hover_styles+"}";cc20+=np_refix+" ul a{"+cc2.sub_link_styles+"}";cc20+=np_refix+" ul a:hover{"+cc2.sub_link_hover_styles+"}";cc20+=".cc24 {"+cc2.main_expander_hover_styles+"}";if(cc2.sub_expander_hover_styles)cc20+=".cc25 {"+cc2.sub_expander_hover_styles+"}"; else cc20+=".cc25 {"+cc2.main_expander_hover_styles+"}";if(cc2.use_hand_cursor)cc20+=np_refix+" li span,.plusminus{cursor:hand; cursor:pointer;}";else cc20+=np_refix+" li span,.plusminus{cursor:default;}";document.write(cc20+"</style> ");}


try { var nl=document.getElementById('menuDiv').getElementsByTagName('a'); var found=-1; var url=document.location.href+'/'; var len=0; for (var i=0;i<nl.length;i++){ if (url.indexOf(nl[i].href)>=0){ if (found==-1 || len<nl[i].href.length){ found=i; len=nl[i].href.length; } } } if (found>=0){ nl[found].className='ma'; } } catch(e){}
<!-- end javascrip sliding menu-->


