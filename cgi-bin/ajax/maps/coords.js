var dotCnt = 1;

function coordsClear() {
    for ( i = 1; i < 5; i++ ) {
	xid=document.getElementById("hx"+i);
        yid=document.getElementById("hy"+i);
        xid.value = "";
	yid.value = "";
    }
    dotCnt = 1;
}

function getCoords() {
// вызывается при перемещении курсора
// над слоем с картой
// координаты слоя с картой
// в окне браузера
    
    imageMapX = findPosX(imageMap);
    imageMapY = findPosY(imageMap);
    imageMap.onmousemove = moveDot;
    imageMap.onmouseover = moveDot;
	        
// точку надо убирать, если курсор
// покинул слой с картой
	        
   imageMap.onmouseout = function (){
	myDot.style.display="none";
   };
	        
// координаты точки надо запомнить
    imageMap.onclick = coordsFix;
}
	        
	        
	        
function coordsFix() {
// функция фиксирует координаты точки при клике
    if  (dotCnt < 5) {
	xid=document.getElementById("hx"+dotCnt);
	yid=document.getElementById("hy"+dotCnt);
	xid.value = myForm.coordX.value;
	yid.value = myForm.coordY.value;
	++dotCnt;
// точка показывается
	myDot2.style.display="block";
// и позициоируется
	myDot2.style.left = myForm.coordX.value+"px";
	myDot2.style.top = myForm.coordY.value+"px";
    }
}
						 
function moveDot(cursor) {
// функция перемещения точки над слоем с картой
// точку надо показать
    myDot.style.display="block";
    if(!cursor) var cursor = window.event;
    myForm.coordX.value = "";
    myForm.coordY.value = "";
    var x = 0;
    var y = 0;
    
    if (cursor.pageX || cursor.pageY) {
		x = cursor.pageX;
		y = cursor.pageY;
    }
    else if (cursor.clientX || cursor.clientY) {
		x = cursor.clientX + document.body.scrollLeft;
		y = cursor.clientY + document.body.scrollTop;
    }
    x -= imageMapX;
    y -= imageMapY;
    x -= dX;
    y -= dY;
// для наглядности координаты точки
// показываются во временых полях формы
// справа "X" и "Y"
    (x < 0) ? myForm.coordX.value = 0 : myForm.coordX.value = x;
    (y < 0) ? myForm.coordY.value = 0 : myForm.coordY.value = y;
// если курсор не покинул слой с картой,
// точка перемещается с курсором
    if (x > 0 && y > 0 && x < mapWdt && y  < mapHgt) {
	myDot.style.left = x+"px";
	myDot.style.top = y+"px";
    }
}
						     
function getObj(name) {
// функция захвата объекта, используется при инициализации
    if (document.getElementById) return document.getElementById(name);
	else if (document.all) return document.all[name];
	else if (document.layers) return document.layers[name];
        else return false;
    }

function findPosX(obj) {
// X-координата слоя
    var currleft = 0;
    if (obj.offsetParent)
	    while (obj.offsetParent) {
	    currleft += obj.offsetLeft
	    obj = obj.offsetParent;
	    }
    else if (obj.x) currleft += obj.x;
	    return currleft;
    }

function findPosY(obj) {
// Y-координата слоя
    var currtop = 0;
    if (obj.offsetParent)
            while (obj.offsetParent) {
	    currtop += obj.offsetTop
	    obj = obj.offsetParent;
    }
    else if (obj.y) currtop += obj.y;
            return currtop;
    }

function init() { // инициализация
// смещение для точки
    dX = 3;
    dY = 3;
// форма
    myForm = getObj("mapForm");
// слой с картой
    imageMap = getObj("schemePlace");
    imageMap.onmouseover = getCoords;
// ширина и высота слоя - смещение
// чтобы точка за пределы картинки
// даже не думала уходить
    mapWdt = imageMap.offsetWidth - dX;
    mapHgt = imageMap.offsetHeight - dY;
// точки
    myDot = getObj("magDot");
    myDot2 = getObj("magDot2");
    var counter = 0;
}
								 
// ожидание загрузки страницы
// и вызов функции инициализации
try {
    window.addEventListener("load", init, false);
} catch(e) {
    window.onload = init;
}
