



<script type=\"text/javascript\">
var windowTitle = document.title;
var windowBlured;


	document.onblur=function()
	{
		windowBlured = 1;
		//alert(windowBlured);
	}
	document.onfocus=function() 
	{
		windowBlured = undefined;
	}

	window.onblur=function()
	{
		windowBlured = 1;
		//alert(windowBlured);
	}
	window.onfocus=function() 
	{
		windowBlured = undefined;
	}
 
	function closePopupWindow(){
	
		return false;
	}
  
	function setNotepadNotice(dateNotice, msg, title, date)
	{	
		//alert('123');
		// + 10000
		//(Math.round(new Date().getTime() / 1000)) >= dateNotice && Math.round((new Date()).getTime() / 1000) <= dateNotice + 40
		if (Math.round(+new Date()/1000) >= dateNotice && Math.round(+new Date()/1000)  < dateNotice + 10) 
		{
			//alert (Math.round(+new Date()/1000) + ' > ' + dateNotice);
			if(windowBlured != undefined)
			{			
				alert('Напоминание');
				windowBlured = undefined;
			}
			var popupWindow = document.getElementById('popup_content');	
			
			if(date != undefined)
			{
				var newDate = document.createTextNode(date);
				var newElement = document.createElement('P');
				newElement.className = 'popup_date';
				newElement.appendChild(newDate);
				popupWindow.appendChild(newElement);
			}

			
			if(title != undefined)
			{
				var newTitle = document.createTextNode(title);
				var newElem = document.createElement('P');
				newElem.className = 'popup_title';
				newElem.appendChild(newTitle);
				popupWindow.appendChild(newElem);
			}

			
			
			if(msg != undefined)
			{
				var newText = document.createTextNode(msg);
				popupWindow.appendChild(newText);
			}
			document.title = '(Напоминание) ' + windowTitle;
			document.getElementById('open_popup_block').style.display='block';
			
		} 
		else 
		{
			if (dateNotice && Math.round(+new Date()/1000) < dateNotice + 20)
			{
				//alert (Math.round(+new Date()/1000)+ 10800 + ' > ' + dateNotice);          		  
				window.setTimeout( function() { setNotepadNotice(dateNotice, msg, title, date) } , 6000);
			} 	
		}		
		
	}

	function closePopupWindow() 
	{
		var popupWindow = document.getElementById('popup_content');	
		while(popupWindow.childNodes.length > 3) {
			popupWindow.removeChild(popupWindow.lastChild);
		}
		document.getElementById('open_popup_block').style.display='none';
		document.title = windowTitle;
		return false;
	}
	
	

	
window.onload = function() {
%NOTICE%

}	

</script>

<div id=\"open_popup_block\">
		<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">
			<tr>
				<td class=\"top_left0\"></td>
				<td class=\"top0\"></td>
				<td class=\"top_right0\"></td>
			</tr>
			<tr>
				<td class=\"left0\"></td>
				<td id=\"popup_content\">

					<a 
						onClick=\"closePopupWindow()\" 
						title=\"Закрыть окно\" 
						id=\"close_popup_window\">
						Закрыть <img  id=\"close_popup_window_img\" src=\"/img/popup_window/close.png\" title=\"Закрыть окно\"  /> 
					</a>
				<!-- текст -->
				
				<!-- /текст -->
					
				</td>
				<td class=\"right0\"></td>
			</tr>
			<tr>
				<td class=\"bottom_left0\"></td>
				<td class=\"bottom0\"></td>
				<td class=\"bottom_right0\"></td>
			</tr>
		</table>
</div>
	
	
	
