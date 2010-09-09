var marked_row = new Array;
var confirmMsg  = 'Do you really want delete';

/**
 * Displays an confirmation box beforme to submit a "DROP/DELETE/ALTER" query.
 * This function is called while clicking links
 *
 * @param   object   the link
 * @param   object   the sql query to submit
 *
 * @return  boolean  whether to run the query or not
 */
function confirmLink(theLink, theSqlQuery, CustomMsg)
{
    if (CustomMsg != '') {
        confirmMsg = CustomMsg;
     }
    else {
    	confirmMsg = confirmMsg + ' :\n';
     }

    var is_confirmed = confirm(confirmMsg + theSqlQuery);
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
