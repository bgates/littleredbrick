var configDateType="iso";
var configAutoRollOver=true;
var calendarFormatString="";
var calendarIfFormat="";
function dateBocksKeyListener(_1){
var _2=_1.keyCode?_1.keyCode:_1.which?_1.which:_1.charCode;
if(_2==13||_2==10){
return false;
}
}
switch(configDateType){
case "us":
calendarIfFormat="%m/%d/%Y";
calendarFormatString="mm/dd/yyyy";
break;
case "de":
calendarIfFormat="%m.%d.%Y";
calendarFormatString="mm.dd.yyyy";
break;
case "iso":
default:
calendarIfFormat="%Y-%m-%d";
calendarFormatString="yyyy-mm-dd";
break;
}
function windowProperties(_3){
var _4=new RegExp("");
_4.compile("(?:^|,)([^=]+)=(\\d+|yes|no|auto)","gim");
var _5=new Object();
var _6;
while((_6=_4.exec(_3))!=null){
var _7=_6[2];
if(_7==("yes"||"1")){
_5[_6[1]]=true;
}else{
if((!isNaN(_7)&&_7!=0)||("auto"==_7)){
_5[_6[1]]=_7;
}
}
}
return _5;
}
function windowOpenCenter(_8,_9,_a){
try{
var _b=windowProperties(_a);
w=parseInt(_b["width"]);
h=parseInt(_b["height"]);
w=w>0?w:640;
h=h>0?h:480;
if(screen){
t=(screen.height-h)/2;
l=(screen.width-w)/2;
}else{
t=250;
l=250;
}
_a=(w>0?",width="+w:"")+(h>0?",height="+h:"")+(t>0?",top="+t:"")+(l>0?",left="+l:"")+","+_a.replace(/,(width=\s*\d+\s*|height=\s*\d+\s*|top=\s*\d+\s*||left=\s*\d+\s*)/gi,"");
return window.open(_8,_9,_a);
}
catch(e){
}
}
Array.prototype.filter=function(_e){
var _f=[];
for(var i=0;i<this.length;i++){
if(_e(this[i])){
_f[_f.length]=this[i];
}
}
return _f;
};
var monthNames="January February March April May June July August September October November December".split(" ");
var weekdayNames="Sunday Monday Tuesday Wednesday Thursday Friday Saturday".split(" ");
function parseMonth(_12){
var _13=monthNames.filter(function(_14){
return new RegExp("^"+_12,"i").test(_14);
});
if(_13.length==0){
throw new Error("Invalid month string");
}
if(_13.length<1){
throw new Error("Ambiguous month");
}
return monthNames.indexOf(_13[0]);
}
function parseWeekday(_15){
var _16=weekdayNames.filter(function(_17){
return new RegExp("^"+_15,"i").test(_17);
});
if(_16.length==0){
throw new Error("Invalid day string");
}
if(_16.length<1){
throw new Error("Ambiguous weekday");
}
return weekdayNames.indexOf(_16[0]);
}
function DateInRange(_18,mm,dd){
if(mm<0||mm>11){
throw new Error("Invalid month value.  Valid months values are 1 to 12");
}
if(!configAutoRollOver){
var d=(11==mm)?new Date(_18+1,0,0):new Date(_18,mm+1,0);
if(dd<1||dd>d.getDate()){
throw new Error("Invalid date value.  Valid date values for "+monthNames[mm]+" are 1 to "+d.getDate().toString());
}
}
return true;
}
function getDateObj(_1c,mm,dd){
var obj=new Date();
obj.setDate(1);
obj.setYear(_1c);
obj.setMonth(mm);
obj.setDate(dd);
return obj;
}
var dateParsePatterns=[{re:/^tod|now/i,handler:function(){
return new Date();
}},{re:/^tom/i,handler:function(){
var d=new Date();
d.setDate(d.getDate()+1);
return d;
}},{re:/^yes/i,handler:function(){
var d=new Date();
d.setDate(d.getDate()-1);
return d;
}},{re:/^(\d{1,2})(st|nd|rd|th)?$/i,handler:function(_22){
var d=new Date();
var _24=d.getFullYear();
var dd=parseInt(_22[1],10);
var mm=d.getMonth();
if(DateInRange(_24,mm,dd)){
return getDateObj(_24,mm,dd);
}
}},{re:/^(\d{1,2})(?:st|nd|rd|th)? (?:of\s)?(\w+)$/i,handler:function(_27){
var d=new Date();
var _29=d.getFullYear();
var dd=parseInt(_27[1],10);
var mm=parseMonth(_27[2]);
if(DateInRange(_29,mm,dd)){
return getDateObj(_29,mm,dd);
}
}},{re:/^(\d{1,2})(?:st|nd|rd|th)? (?:of )?(\w+),? (\d{4})$/i,handler:function(_2c){
var d=new Date();
d.setDate(parseInt(_2c[1],10));
d.setMonth(parseMonth(_2c[2]));
d.setYear(_2c[3]);
return d;
}},{re:/^(\w+) (\d{1,2})(?:st|nd|rd|th)?$/i,handler:function(_2e){
var d=new Date();
var _30=d.getFullYear();
var dd=parseInt(_2e[2],10);
var mm=parseMonth(_2e[1]);
if(DateInRange(_30,mm,dd)){
return getDateObj(_30,mm,dd);
}
}},{re:/^(\w+) (\d{1,2})(?:st|nd|rd|th)?,? (\d{4})$/i,handler:function(_33){
var _34=parseInt(_33[3],10);
var dd=parseInt(_33[2],10);
var mm=parseMonth(_33[1]);
if(DateInRange(_34,mm,dd)){
return getDateObj(_34,mm,dd);
}
}},{re:/((next|last)\s(week|month|year))/i,handler:function(_37){
var _38=new Date();
var dd=_38.getDate();
var mm=_38.getMonth();
var _3b=_38.getFullYear();
switch(_37[3]){
case "week":
var _3c=(_37[2]=="next")?(dd+7):(dd-7);
_38.setDate(_3c);
break;
case "month":
var _3d=(_37[2]=="next")?(mm+1):(mm-1);
_38.setMonth(_3d);
break;
case "year":
var _3e=(_37[2]=="next")?(_3b+1):(_3b-1);
_38.setYear(_3e);
break;
}
return _38;
}},{re:/^next (\w+)$/i,handler:function(_3f){
var d=new Date();
var day=d.getDay();
var _42=parseWeekday(_3f[1]);
var _43=_42-day;
if(_42<=day){
_43+=7;
}
d.setDate(d.getDate()+_43);
return d;
}},{re:/^last (\w+)$/i,handler:function(_44){
var d=new Date();
var wd=d.getDay();
var nwd=parseWeekday(_44[1]);
var _48=(-1*(wd+7-nwd))%7;
if(0==_48){
_48=-7;
}
d.setDate(d.getDate()+_48);
return d;
}},{re:/(\d{1,2})\/(\d{1,2})\/(\d{4})/,handler:function(_49){
var _4a=parseInt(_49[3],10);
var dd=parseInt(_49[2],10);
var mm=parseInt(_49[1],10)-1;
if(DateInRange(_4a,mm,dd)){
return getDateObj(_4a,mm,dd);
}
}},{re:/(\d{1,2})\/(\d{1,2})\/(\d{1,2})/,handler:function(_4d){
var d=new Date();
var _4f=d.getFullYear()-(d.getFullYear()%100)+parseInt(_4d[3],10);
var dd=parseInt(_4d[2],10);
var mm=parseInt(_4d[1],10)-1;
if(DateInRange(_4f,mm,dd)){
return getDateObj(_4f,mm,dd);
}
}},{re:/(\d{1,2})\/(\d{1,2})/,handler:function(_52){
var d=new Date();
var _54=d.getFullYear();
var dd=parseInt(_52[2],10);
var mm=parseInt(_52[1],10)-1;
if(DateInRange(_54,mm,dd)){
return getDateObj(_54,mm,dd);
}
}},{re:/(\d{1,2})-(\d{1,2})-(\d{4})/,handler:function(_57){
var _58=parseInt(_57[3],10);
var dd=parseInt(_57[2],10);
var mm=parseInt(_57[1],10)-1;
if(DateInRange(_58,mm,dd)){
return getDateObj(_58,mm,dd);
}
}},{re:/(\d{1,2})\.(\d{1,2})\.(\d{4})/,handler:function(_5b){
var dd=parseInt(_5b[1],10);
var mm=parseInt(_5b[2],10)-1;
var _5e=parseInt(_5b[3],10);
if(DateInRange(_5e,mm,dd)){
return getDateObj(_5e,mm,dd);
}
}},{re:/(\d{4})-(\d{1,2})-(\d{1,2})/,handler:function(_5f){
var _60=parseInt(_5f[1],10);
var dd=parseInt(_5f[3],10);
var mm=parseInt(_5f[2],10)-1;
if(DateInRange(_60,mm,dd)){
return getDateObj(_60,mm,dd);
}
}},{re:/(\d{1,2})-(\d{1,2})-(\d{1,2})/,handler:function(_63){
var d=new Date();
var _65=d.getFullYear()-(d.getFullYear()%100)+parseInt(_63[1],10);
var dd=parseInt(_63[3],10);
var mm=parseInt(_63[2],10)-1;
if(DateInRange(_65,mm,dd)){
return getDateObj(_65,mm,dd);
}
}},{re:/(\d{1,2})-(\d{1,2})/,handler:function(_68){
var d=new Date();
var _6a=d.getFullYear();
var dd=parseInt(_68[2],10);
var mm=parseInt(_68[1],10)-1;
if(DateInRange(_6a,mm,dd)){
return getDateObj(_6a,mm,dd);
}
}},{re:/(^mon.*|^tue.*|^wed.*|^thu.*|^fri.*|^sat.*|^sun.*)/i,handler:function(_6d){
var d=new Date();
var day=d.getDay();
var _70=parseWeekday(_6d[1]);
var _71=_70-day;
if(_70<=day){
_71+=7;
}
d.setDate(d.getDate()+_71);
return d;
}},];
function parseDateString(s){
for(var i=0;i<dateParsePatterns.length;i++){
var re=dateParsePatterns[i]['re'];
var _75=dateParsePatterns[i].handler;
var _76=re.exec(s);
if(_76){
return _75(_76);
}
}
throw new Error("Invalid date string");
}
function magicDateOnlyOnSubmit(id,_78){
var _79=_78.keyCode?_78.keyCode:_78.which?_78.which:_78.charCode;
if(_79==13||_79==10){
magicDate(id);
}
}
function magicDate(id,_7b){
var _7c=$(id);
var _7d=_7c.id+"Msg";
try{
var d=parseDateString(_7c.value);
var day=(d.getDate()<=9)?"0"+d.getDate().toString():d.getDate();
var _80=((d.getMonth()+1)<=9)?"0"+(d.getMonth()+1):(d.getMonth()+1);
switch(configDateType){
case "us":
_7c.value=_80+"/"+day+"/"+d.getFullYear();
break;
case "de":
_7c.value=_80+"."+day+"."+d.getFullYear();
break;
case "iso":
default:
_7c.value=d.getFullYear()+"-"+_80+"-"+day;
break;
}
_7c.className="";
$(_7d).innerHTML=d.toDateString();
$(_7d).className="normal";
}
catch(e){
_7c.className="fieldWithErrors";
var _81=e.message;
if(_81.indexOf("is null or not an object")>-1){
_81="Invalid date string";
}
$(_7d).innerHTML=_81;
$(_7d).className="error";
}
}
Calendar=function(_82,_83,_84,_85){
this.activeDiv=null;
this.currentDateEl=null;
this.getDateStatus=null;
this.getDateToolTip=null;
this.getDateText=null;
this.timeout=null;
this.onSelected=_84||null;
this.onClose=_85||null;
this.dragging=false;
this.hidden=false;
this.minYear=1970;
this.dateFormat=Calendar._TT["DEF_DATE_FORMAT"];
this.ttDateFormat=Calendar._TT["TT_DATE_FORMAT"];
this.isPopup=true;
this.weekNumbers=true;
this.firstDayOfWeek=typeof _82=="number"?_82:Calendar._FD;
this.showsOtherMonths=false;
this.dateStr=_83;
this.ar_days=null;
this.showsTime=false;
this.time24=true;
this.yearStep=2;
this.hiliteToday=true;
this.multiple=null;
this.table=null;
this.element=null;
this.tbody=null;
this.firstdayname=null;
this.monthsCombo=null;
this.yearsCombo=null;
this.hilitedMonth=null;
this.activeMonth=null;
this.hilitedYear=null;
this.activeYear=null;
this.dateClicked=false;
if(typeof Calendar._SDN=="undefined"){
if(typeof Calendar._SDN_len=="undefined"){
Calendar._SDN_len=3;
}
var ar=new Array();
for(var i=8;i>0;){
ar[--i]=Calendar._DN[i].substr(0,Calendar._SDN_len);
}
Calendar._SDN=ar;
if(typeof Calendar._SMN_len=="undefined"){
Calendar._SMN_len=3;
}
ar=new Array();
for(var i=12;i>0;){
ar[--i]=Calendar._MN[i].substr(0,Calendar._SMN_len);
}
Calendar._SMN=ar;
}
};
Calendar._C=null;
Calendar.is_ie=Prototype.Browser.IE;
Calendar.is_ie5=(Calendar.is_ie&&/msie 5\.0/i.test(navigator.userAgent));
Calendar.is_opera=/opera/i.test(navigator.userAgent);
Calendar.is_khtml=/Konqueror|Safari|KHTML/i.test(navigator.userAgent);
Calendar.getAbsolutePos=function(el){
var SL=0,ST=0;
var _8a=/^div$/i.test(el.tagName);
if(_8a&&el.scrollLeft){
SL=el.scrollLeft;
}
if(_8a&&el.scrollTop){
ST=el.scrollTop;
}
var r={x:el.offsetLeft-SL,y:el.offsetTop-ST};
if(el.offsetParent){
var tmp=this.getAbsolutePos(el.offsetParent);
r.x+=tmp.x;
r.y+=tmp.y;
}
return r;
};
Calendar.isRelated=function(el,evt){
var _8f=evt.relatedTarget;
if(!_8f){
var _90=evt.type;
if(_90=="mouseover"){
_8f=evt.fromElement;
}else{
if(_90=="mouseout"){
_8f=evt.toElement;
}
}
}
while(_8f){
if(_8f==el){
return true;
}
_8f=_8f.parentNode;
}
return false;
};
Calendar.removeClass=function(el,_92){
$(el).removeClassName(_92);
};
Calendar.addClass=function(el,_97){
$(el).addClassName(_97);
};
Calendar.getElement=function(ev){
var f=Calendar.is_ie?window.event.srcElement:ev.currentTarget;
while(f.nodeType!=1||/^div$/i.test(f.tagName)){
f=f.parentNode;
}
return f;
};
Calendar.getTargetElement=function(ev){
var f=Calendar.is_ie?window.event.srcElement:ev.target;
while(f.nodeType!=1){
f=f.parentNode;
}
return f;
};
Calendar.stopEvent=function(ev){
Event.stop(ev);
return false;
};
Calendar.addEvent=function(el,_9e,_9f){
if(el.attachEvent){
el.attachEvent("on"+_9e,_9f);
}else{
if(el.addEventListener){
el.addEventListener(_9e,_9f,true);
}else{
el["on"+_9e]=_9f;
}
}
};
Calendar.removeEvent=function(el,_a1,_a2){
if(el.detachEvent){
el.detachEvent("on"+_a1,_a2);
}else{
if(el.removeEventListener){
el.removeEventListener(_a1,_a2,true);
}else{
el["on"+_a1]=null;
}
}
};
Calendar.createElement=function(_a3,_a4){
var el=null;
if(document.createElementNS){
el=document.createElementNS("http://www.w3.org/1999/xhtml",_a3);
}else{
el=document.createElement(_a3);
}
if(typeof _a4!="undefined"){
_a4.appendChild(el);
}
return el;
};
Calendar._add_evs=function(el){
with(Calendar){
addEvent(el,"mouseover",dayMouseOver);
addEvent(el,"mousedown",dayMouseDown);
addEvent(el,"mouseout",dayMouseOut);
if(is_ie){
addEvent(el,"dblclick",dayMouseDblClick);
el.setAttribute("unselectable",true);
}
}
};
Calendar.findMonth=function(el){
if(typeof el.month!="undefined"){
return el;
}else{
if(typeof el.parentNode.month!="undefined"){
return el.parentNode;
}
}
return null;
};
Calendar.findYear=function(el){
if(typeof el.year!="undefined"){
return el;
}else{
if(typeof el.parentNode.year!="undefined"){
return el.parentNode;
}
}
return null;
};
Calendar.showMonthsCombo=function(){
var cal=Calendar._C;
if(!cal){
return false;
}
var cal=cal;
var cd=cal.activeDiv;
var mc=cal.monthsCombo;
if(cal.hilitedMonth){
Calendar.removeClass(cal.hilitedMonth,"hilite");
}
if(cal.activeMonth){
Calendar.removeClass(cal.activeMonth,"active");
}
var mon=cal.monthsCombo.getElementsByTagName("div")[cal.date.getMonth()];
Calendar.addClass(mon,"active");
cal.activeMonth=mon;
var s=mc.style;
s.display="block";
if(cd.navtype<0){
s.left=cd.offsetLeft+"px";
}else{
var mcw=mc.offsetWidth;
if(typeof mcw=="undefined"){
mcw=50;
}
s.left=(cd.offsetLeft+cd.offsetWidth-mcw)+"px";
}
s.top=(cd.offsetTop+cd.offsetHeight)+"px";
};
Calendar.showYearsCombo=function(fwd){
var cal=Calendar._C;
if(!cal){
return false;
}
var cal=cal;
var cd=cal.activeDiv;
var yc=cal.yearsCombo;
if(cal.hilitedYear){
Calendar.removeClass(cal.hilitedYear,"hilite");
}
if(cal.activeYear){
Calendar.removeClass(cal.activeYear,"active");
}
cal.activeYear=null;
var Y=cal.date.getFullYear()+(fwd?1:-1);
var yr=yc.firstChild;
var _b5=false;
for(var i=12;i>0;--i){
if(Y>=cal.minYear&&Y<=cal.maxYear){
yr.innerHTML=Y;
yr.year=Y;
yr.style.display="block";
_b5=true;
}else{
yr.style.display="none";
}
yr=yr.nextSibling;
Y+=fwd?cal.yearStep:-cal.yearStep;
}
if(_b5){
var s=yc.style;
s.display="block";
if(cd.navtype<0){
s.left=cd.offsetLeft+"px";
}else{
var ycw=yc.offsetWidth;
if(typeof ycw=="undefined"){
ycw=50;
}
s.left=(cd.offsetLeft+cd.offsetWidth-ycw)+"px";
}
s.top=(cd.offsetTop+cd.offsetHeight)+"px";
}
};
Calendar.tableMouseUp=function(ev){
var cal=Calendar._C;
if(!cal){
return false;
}
if(cal.timeout){
clearTimeout(cal.timeout);
}
var el=cal.activeDiv;
if(!el){
return false;
}
var _bc=Calendar.getTargetElement(ev);
ev||(ev=window.event);
Calendar.removeClass(el,"active");
if(_bc==el||_bc.parentNode==el){
Calendar.cellClick(el,ev);
}
var mon=Calendar.findMonth(_bc);
var _be=null;
if(mon){
_be=new Date(cal.date);
if(mon.month!=_be.getMonth()){
_be.setMonth(mon.month);
cal.setDate(_be);
cal.dateClicked=false;
cal.callHandler();
}
}else{
var _bf=Calendar.findYear(_bc);
if(_bf){
_be=new Date(cal.date);
if(_bf.year!=_be.getFullYear()){
_be.setFullYear(_bf.year);
cal.setDate(_be);
cal.dateClicked=false;
cal.callHandler();
}
}
}
with(Calendar){
removeEvent(document,"mouseup",tableMouseUp);
removeEvent(document,"mouseover",tableMouseOver);
removeEvent(document,"mousemove",tableMouseOver);
cal._hideCombos();
_C=null;
return stopEvent(ev);
}
};
Calendar.tableMouseOver=function(ev){
var cal=Calendar._C;
if(!cal){
return;
}
var el=cal.activeDiv;
var _c3=Calendar.getTargetElement(ev);
if(_c3==el||_c3.parentNode==el){
Calendar.addClass(el,"hilite active");
Calendar.addClass(el.parentNode,"rowhilite");
}else{
if(typeof el.navtype=="undefined"||(el.navtype!=50&&(el.navtype==0||Math.abs(el.navtype)>2))){
Calendar.removeClass(el,"active");
}
Calendar.removeClass(el,"hilite");
Calendar.removeClass(el.parentNode,"rowhilite");
}
ev||(ev=window.event);
if(el.navtype==50&&_c3!=el){
var pos=Calendar.getAbsolutePos(el);
var w=el.offsetWidth;
var x=ev.clientX;
var dx;
var _c8=true;
if(x>pos.x+w){
dx=x-pos.x-w;
_c8=false;
}else{
dx=pos.x-x;
}
if(dx<0){
dx=0;
}
var _c9=el._range;
var _ca=el._current;
var _cb=Math.floor(dx/10)%_c9.length;
for(var i=_c9.length;--i>=0;){
if(_c9[i]==_ca){
break;
}
}
while(_cb-->0){
if(_c8){
if(--i<0){
i=_c9.length-1;
}
}else{
if(++i>=_c9.length){
i=0;
}
}
}
var _cd=_c9[i];
el.innerHTML=_cd;
cal.onUpdateTime();
}
var mon=Calendar.findMonth(_c3);
if(mon){
if(mon.month!=cal.date.getMonth()){
if(cal.hilitedMonth){
Calendar.removeClass(cal.hilitedMonth,"hilite");
}
Calendar.addClass(mon,"hilite");
cal.hilitedMonth=mon;
}else{
if(cal.hilitedMonth){
Calendar.removeClass(cal.hilitedMonth,"hilite");
}
}
}else{
if(cal.hilitedMonth){
Calendar.removeClass(cal.hilitedMonth,"hilite");
}
var _cf=Calendar.findYear(_c3);
if(_cf){
if(_cf.year!=cal.date.getFullYear()){
if(cal.hilitedYear){
Calendar.removeClass(cal.hilitedYear,"hilite");
}
Calendar.addClass(_cf,"hilite");
cal.hilitedYear=_cf;
}else{
if(cal.hilitedYear){
Calendar.removeClass(cal.hilitedYear,"hilite");
}
}
}else{
if(cal.hilitedYear){
Calendar.removeClass(cal.hilitedYear,"hilite");
}
}
}
return Calendar.stopEvent(ev);
};
Calendar.tableMouseDown=function(ev){
if(Calendar.getTargetElement(ev)==Calendar.getElement(ev)){
return Calendar.stopEvent(ev);
}
};
Calendar.calDragIt=function(ev){
var cal=Calendar._C;
if(!(cal&&cal.dragging)){
return false;
}
var _d3;
var _d4;
if(Calendar.is_ie){
_d4=window.event.clientY+document.body.scrollTop;
_d3=window.event.clientX+document.body.scrollLeft;
}else{
_d3=ev.pageX;
_d4=ev.pageY;
}
cal.hideShowCovered();
var st=cal.element.style;
st.left=(_d3-cal.xOffs)+"px";
st.top=(_d4-cal.yOffs)+"px";
return Calendar.stopEvent(ev);
};
Calendar.calDragEnd=function(ev){
var cal=Calendar._C;
if(!cal){
return false;
}
cal.dragging=false;
with(Calendar){
removeEvent(document,"mousemove",calDragIt);
removeEvent(document,"mouseup",calDragEnd);
tableMouseUp(ev);
}
cal.hideShowCovered();
};
Calendar.dayMouseDown=function(ev){
var el=Calendar.getElement(ev);
if(el.disabled){
return false;
}
var cal=el.calendar;
cal.activeDiv=el;
Calendar._C=cal;
if(el.navtype!=300){
with(Calendar){
if(el.navtype==50){
el._current=el.innerHTML;
addEvent(document,"mousemove",tableMouseOver);
}else{
addEvent(document,Calendar.is_ie5?"mousemove":"mouseover",tableMouseOver);
}
addClass(el,"hilite active");
addEvent(document,"mouseup",tableMouseUp);
}
}else{
if(cal.isPopup){
cal._dragStart(ev);
}
}
if(el.navtype==-1||el.navtype==1){
if(cal.timeout){
clearTimeout(cal.timeout);
}
cal.timeout=setTimeout("Calendar.showMonthsCombo()",250);
}else{
if(el.navtype==-2||el.navtype==2){
if(cal.timeout){
clearTimeout(cal.timeout);
}
cal.timeout=setTimeout((el.navtype>0)?"Calendar.showYearsCombo(true)":"Calendar.showYearsCombo(false)",250);
}else{
cal.timeout=null;
}
}
return Calendar.stopEvent(ev);
};
Calendar.dayMouseDblClick=function(ev){
Calendar.cellClick(Calendar.getElement(ev),ev||window.event);
if(Calendar.is_ie){
document.selection.empty();
}
};
Calendar.dayMouseOver=function(ev){
var el=Calendar.getElement(ev);
if(Calendar.isRelated(el,ev)||Calendar._C||el.disabled){
return false;
}
if(el.ttip){
if(el.ttip.substr(0,1)=="_"){
el.ttip=el.caldate.print(el.calendar.ttDateFormat)+el.ttip.substr(1);
}
el.calendar.tooltips.innerHTML=el.ttip;
}
if(el.navtype!=300){
Calendar.addClass(el,"hilite");
if(el.caldate){
Calendar.addClass(el.parentNode,"rowhilite");
}
}
return Calendar.stopEvent(ev);
};
Calendar.dayMouseOut=function(ev){
with(Calendar){
var el=getElement(ev);
if(isRelated(el,ev)||_C||el.disabled){
return false;
}
removeClass(el,"hilite");
if(el.caldate){
removeClass(el.parentNode,"rowhilite");
}
if(el.calendar){
el.calendar.tooltips.innerHTML=_TT["SEL_DATE"];
}
return stopEvent(ev);
}
};
Calendar.cellClick=function(el,ev){
var cal=el.calendar;
var _e3=false;
var _e4=false;
var _e5=null;
if(typeof el.navtype=="undefined"){
if(cal.currentDateEl){
Calendar.removeClass(cal.currentDateEl,"selected");
Calendar.addClass(el,"selected");
_e3=(cal.currentDateEl==el);
if(!_e3){
cal.currentDateEl=el;
}
}
cal.date.setDateOnly(el.caldate);
_e5=cal.date;
var _e6=!(cal.dateClicked=!el.otherMonth);
if(!_e6&&!cal.currentDateEl){
cal._toggleMultipleDate(new Date(_e5));
}else{
_e4=!el.disabled;
}
if(_e6){
cal._init(cal.firstDayOfWeek,_e5);
}
}else{
if(el.navtype==200){
Calendar.removeClass(el,"hilite");
cal.callCloseHandler();
return;
}
_e5=new Date(cal.date);
if(el.navtype==0){
_e5.setDateOnly(new Date());
}
cal.dateClicked=false;
var _e7=_e5.getFullYear();
var mon=_e5.getMonth();
function setMonth(m){
var day=_e5.getDate();
var max=_e5.getMonthDays(m);
if(day>max){
_e5.setDate(max);
}
_e5.setMonth(m);
}
switch(el.navtype){
case 400:
Calendar.removeClass(el,"hilite");
var _ec=Calendar._TT["ABOUT"];
if(typeof _ec!="undefined"){
_ec+=cal.showsTime?Calendar._TT["ABOUT_TIME"]:"";
}else{
_ec="Help and about box text is not translated into this language.\n"+"If you know this language and you feel generous please update\n"+"the corresponding file in \"lang\" subdir to match calendar-en.js\n"+"and send it back to <mihai_bazon@yahoo.com> to get it into the distribution  ;-)\n\n"+"Thank you!\n"+"http://dynarch.com/mishoo/calendar.epl\n";
}
alert(_ec);
return;
case -2:
if(_e7>cal.minYear){
_e5.setFullYear(_e7-1);
}
break;
case -1:
if(mon>0){
setMonth(mon-1);
}else{
if(_e7-->cal.minYear){
_e5.setFullYear(_e7);
setMonth(11);
}
}
break;
case 1:
if(mon<11){
setMonth(mon+1);
}else{
if(_e7<cal.maxYear){
_e5.setFullYear(_e7+1);
setMonth(0);
}
}
break;
case 2:
if(_e7<cal.maxYear){
_e5.setFullYear(_e7+1);
}
break;
case 100:
cal.setFirstDayOfWeek(el.fdow);
return;
case 50:
var _ed=el._range;
var _ee=el.innerHTML;
for(var i=_ed.length;--i>=0;){
if(_ed[i]==_ee){
break;
}
}
if(ev&&ev.shiftKey){
if(--i<0){
i=_ed.length-1;
}
}else{
if(++i>=_ed.length){
i=0;
}
}
var _f0=_ed[i];
el.innerHTML=_f0;
cal.onUpdateTime();
return;
case 0:
if((typeof cal.getDateStatus=="function")&&cal.getDateStatus(_e5,_e5.getFullYear(),_e5.getMonth(),_e5.getDate())){
return false;
}
break;
}
if(!_e5.equalsTo(cal.date)){
cal.setDate(_e5);
_e4=true;
}else{
if(el.navtype==0){
_e4=_e3=true;
}
}
}
if(_e4){
ev&&cal.callHandler();
}
if(_e3){
Calendar.removeClass(el,"hilite");
ev&&cal.callCloseHandler();
}
};
Calendar.prototype.create=function(_f1){
var _f2=null;
if(!_f1){
_f2=document.getElementsByTagName("body")[0];
this.isPopup=true;
}else{
_f2=_f1;
this.isPopup=false;
}
this.date=this.dateStr?new Date(this.dateStr):new Date();
var _f3=$table({cellSpacing:0, cellPadding:0});//Calendar.createElement("table");
this.table=_f3;
_f3.calendar=this;
Calendar.addEvent(_f3,"mousedown",Calendar.tableMouseDown);

var div = $div({className: 'popup_calendar', style: 'position:absolute;display:none'});
this.element = div;
div.appendChild(_f3);
var _f5=Calendar.createElement("thead",_f3);
var _f6=null;
var row=null;
var cal=this;
var hh=function(_fa,cs,_fc){
_f6=Calendar.createElement("td",row);
_f6.colSpan=cs;
_f6.className="calendarbutton";
if(_fc!=0&&Math.abs(_fc)<=2){
_f6.className+=" nav";
}
Calendar._add_evs(_f6);
_f6.calendar=cal;
_f6.navtype=_fc;
_f6.innerHTML="<div unselectable='on'>"+_fa+"</div>";
return _f6;
};
row=Calendar.createElement("tr",_f5);
var _fd=6;
(this.isPopup)&&--_fd;
(this.weekNumbers)&&++_fd;
hh("?",1,400).ttip=Calendar._TT["INFO"];
this.title=hh("",_fd,300);
this.title.className="title";
if(this.isPopup){
this.title.ttip=Calendar._TT["DRAG_TO_MOVE"];
this.title.style.cursor="move";
hh("&#x00d7;",1,200).ttip=Calendar._TT["CLOSE"];
}
row=Calendar.createElement("tr",_f5);
row.className="headrow";
this._nav_py=hh("&#x00ab;",1,-2);
this._nav_py.ttip=Calendar._TT["PREV_YEAR"];
this._nav_pm=hh("&#x2039;",1,-1);
this._nav_pm.ttip=Calendar._TT["PREV_MONTH"];
this._nav_now=hh(Calendar._TT["TODAY"],this.weekNumbers?4:3,0);
this._nav_now.ttip=Calendar._TT["GO_TODAY"];
this._nav_nm=hh("&#x203a;",1,1);
this._nav_nm.ttip=Calendar._TT["NEXT_MONTH"];
this._nav_ny=hh("&#x00bb;",1,2);
this._nav_ny.ttip=Calendar._TT["NEXT_YEAR"];
row=Calendar.createElement("tr",_f5);
row.className="daynames";
if(this.weekNumbers){
_f6=Calendar.createElement("td",row);
_f6.className="name wn";
_f6.innerHTML=Calendar._TT["WK"];
}
for(var i=7;i>0;--i){
_f6=Calendar.createElement("td",row);
if(!i){
_f6.navtype=100;
_f6.calendar=this;
Calendar._add_evs(_f6);
}
}
this.firstdayname=(this.weekNumbers)?row.firstChild.nextSibling:row.firstChild;
this._displayWeekdays();
var _ff=Calendar.createElement("tbody",_f3);
this.tbody=_ff;
for(i=6;i>0;--i){
row=Calendar.createElement("tr",_ff);
if(this.weekNumbers){
_f6=Calendar.createElement("td",row);
}
for(var j=7;j>0;--j){
_f6=Calendar.createElement("td",row);
_f6.calendar=this;
Calendar._add_evs(_f6);
}
}
if(this.showsTime){
row=Calendar.createElement("tr",_ff);
row.className="time";
_f6=Calendar.createElement("td",row);
_f6.className="time";
_f6.colSpan=2;
_f6.innerHTML=Calendar._TT["TIME"]||"&nbsp;";
_f6=Calendar.createElement("td",row);
_f6.className="time";
_f6.colSpan=this.weekNumbers?4:3;
(function(){
function makeTimePart(_101,init,_103,_104){
var part=Calendar.createElement("span",_f6);
part.className=_101;
part.innerHTML=init;
part.calendar=cal;
part.ttip=Calendar._TT["TIME_PART"];
part.navtype=50;
part._range=[];
if(typeof _103!="number"){
part._range=_103;
}else{
for(var i=_103;i<=_104;++i){
var txt;
if(i<10&&_104>=10){
txt="0"+i;
}else{
txt=""+i;
}
part._range[part._range.length]=txt;
}
}
Calendar._add_evs(part);
return part;
}
var hrs=cal.date.getHours();
var mins=cal.date.getMinutes();
var t12=!cal.time24;
var pm=(hrs>12);
if(t12&&pm){
hrs-=12;
}
var H=makeTimePart("hour",hrs,t12?1:0,t12?12:23);
var span=Calendar.createElement("span",_f6);
span.innerHTML=":";
span.className="colon";
var M=makeTimePart("minute",mins,0,59);
var AP=null;
_f6=Calendar.createElement("td",row);
_f6.className="time";
_f6.colSpan=2;
if(t12){
AP=makeTimePart("ampm",pm?"pm":"am",["am","pm"]);
}else{
_f6.innerHTML="&nbsp;";
}
cal.onSetTime=function(){
var pm,hrs=this.date.getHours(),mins=this.date.getMinutes();
if(t12){
pm=(hrs>=12);
if(pm){
hrs-=12;
}
if(hrs==0){
hrs=12;
}
AP.innerHTML=pm?"pm":"am";
}
H.innerHTML=(hrs<10)?("0"+hrs):hrs;
M.innerHTML=(mins<10)?("0"+mins):mins;
};
cal.onUpdateTime=function(){
var date=this.date;
var h=parseInt(H.innerHTML,10);
if(t12){
if(/pm/i.test(AP.innerHTML)&&h<12){
h+=12;
}else{
if(/am/i.test(AP.innerHTML)&&h==12){
h=0;
}
}
}
var d=date.getDate();
var m=date.getMonth();
var y=date.getFullYear();
date.setHours(h);
date.setMinutes(parseInt(M.innerHTML,10));
date.setFullYear(y);
date.setMonth(m);
date.setDate(d);
this.dateClicked=false;
this.callHandler();
};
})();
}else{
this.onSetTime=this.onUpdateTime=function(){
};
}
var _116=Calendar.createElement("tfoot",_f3);
row=Calendar.createElement("tr",_116);
row.className="footrow";
_f6=hh(Calendar._TT["SEL_DATE"],this.weekNumbers?8:7,300);
_f6.className="ttip";
if(this.isPopup){
_f6.ttip=Calendar._TT["DRAG_TO_MOVE"];
_f6.style.cursor="move";
}
this.tooltips=_f6;
div=Calendar.createElement("div",this.element);
this.monthsCombo=div;
div.className="combo";
for(i=0;i<Calendar._MN.length;++i){
var mn=Calendar.createElement("div");
mn.className=Calendar.is_ie?"label-IEfix":"label";
mn.month=i;
mn.innerHTML=Calendar._SMN[i];
div.appendChild(mn);
}
div=Calendar.createElement("div",this.element);
this.yearsCombo=div;
div.className="combo";
for(i=12;i>0;--i){
var yr=Calendar.createElement("div");
yr.className=Calendar.is_ie?"label-IEfix":"label";
div.appendChild(yr);
}
this._init(this.firstDayOfWeek,this.date);
_f2.appendChild(this.element);
};
Calendar._keyEvent=function(ev){
var cal=window._dynarch_popupCalendar;
if(!cal||cal.multiple){
return false;
}
(Calendar.is_ie)&&(ev=window.event);
var act=(Calendar.is_ie||ev.type=="keypress"),K=ev.keyCode;
if(ev.ctrlKey){
switch(K){
case 37:
act&&Calendar.cellClick(cal._nav_pm);
break;
case 38:
act&&Calendar.cellClick(cal._nav_py);
break;
case 39:
act&&Calendar.cellClick(cal._nav_nm);
break;
case 40:
act&&Calendar.cellClick(cal._nav_ny);
break;
default:
return false;
}
}else{
switch(K){
case 32:
Calendar.cellClick(cal._nav_now);
break;
case 27:
act&&cal.callCloseHandler();
break;
case 37:
case 38:
case 39:
case 40:
if(act){
var prev,x,y,ne,el,step;
prev=K==37||K==38;
step=(K==37||K==39)?1:7;
function setVars(){
el=cal.currentDateEl;
var p=el.pos;
x=p&15;
y=p>>4;
ne=cal.ar_days[y][x];
}
setVars();
function prevMonth(){
var date=new Date(cal.date);
date.setDate(date.getDate()-step);
cal.setDate(date);
}
function nextMonth(){
var date=new Date(cal.date);
date.setDate(date.getDate()+step);
cal.setDate(date);
}
while(1){
switch(K){
case 37:
if(--x>=0){
ne=cal.ar_days[y][x];
}else{
x=6;
K=38;
continue;
}
break;
case 38:
if(--y>=0){
ne=cal.ar_days[y][x];
}else{
prevMonth();
setVars();
}
break;
case 39:
if(++x<7){
ne=cal.ar_days[y][x];
}else{
x=0;
K=40;
continue;
}
break;
case 40:
if(++y<cal.ar_days.length){
ne=cal.ar_days[y][x];
}else{
nextMonth();
setVars();
}
break;
}
break;
}
if(ne){
if(!ne.disabled){
Calendar.cellClick(ne);
}else{
if(prev){
prevMonth();
}else{
nextMonth();
}
}
}
}
break;
case 13:
if(act){
Calendar.cellClick(cal.currentDateEl,ev);
}
break;
default:
return false;
}
}
return Calendar.stopEvent(ev);
};
Calendar.prototype._init=function(_120,date){
var _122=new Date(),TY=_122.getFullYear(),TM=_122.getMonth(),TD=_122.getDate();
this.table.style.visibility="hidden";
var year=date.getFullYear();
if(year<this.minYear){
year=this.minYear;
date.setFullYear(year);
}else{
if(year>this.maxYear){
year=this.maxYear;
date.setFullYear(year);
}
}
this.firstDayOfWeek=_120;
this.date=new Date(date);
var _124=date.getMonth();
var mday=date.getDate();
var _126=date.getMonthDays();
date.setDate(1);
var day1=(date.getDay()-this.firstDayOfWeek)%7;
if(day1<0){
day1+=7;
}
date.setDate(-day1);
date.setDate(date.getDate()+1);
var row=this.tbody.firstChild;
var MN=Calendar._SMN[_124];
var _12a=this.ar_days=new Array();
var _12b=Calendar._TT["WEEKEND"];
var _12c=this.multiple?(this.datesCells={}):null;
for(var i=0;i<6;++i,row=row.nextSibling){
var cell=row.firstChild;
if(this.weekNumbers){
cell.className="day wn";
cell.innerHTML=date.getWeekNumber();
cell=cell.nextSibling;
}
row.className="daysrow";
var _12f=false,iday,dpos=_12a[i]=[];
for(var j=0;j<7;++j,cell=cell.nextSibling,date.setDate(iday+1)){
iday=date.getDate();
var wday=date.getDay();
cell.className="day";
cell.pos=i<<4|j;
dpos[j]=cell;
var _132=(date.getMonth()==_124);
if(!_132){
if(this.showsOtherMonths){
cell.className+=" othermonth";
cell.otherMonth=true;
}else{
cell.className="emptycell";
cell.innerHTML="&nbsp;";
cell.disabled=true;
continue;
}
}else{
cell.otherMonth=false;
_12f=true;
}
cell.disabled=false;
cell.innerHTML=this.getDateText?this.getDateText(date,iday):iday;
if(_12c){
_12c[date.print("%Y%m%d")]=cell;
}
if(this.getDateStatus){
var _133=this.getDateStatus(date,year,_124,iday);
if(this.getDateToolTip){
var _134=this.getDateToolTip(date,year,_124,iday);
if(_134){
cell.title=_134;
}
}
if(_133===true){
cell.className+=" disabled";
cell.disabled=true;
}else{
if(/disabled/i.test(_133)){
cell.disabled=true;
}
cell.className+=" "+_133;
}
}
if(!cell.disabled){
cell.caldate=new Date(date);
cell.ttip="_";
if(!this.multiple&&_132&&iday==mday&&this.hiliteToday){
cell.className+=" selected";
this.currentDateEl=cell;
}
if(date.getFullYear()==TY&&date.getMonth()==TM&&iday==TD){
cell.className+=" today";
cell.ttip+=Calendar._TT["PART_TODAY"];
}
if(_12b.indexOf(wday.toString())!=-1){
cell.className+=cell.otherMonth?" oweekend":" pop_weekend";
}
}
}
if(!(_12f||this.showsOtherMonths)){
row.className="emptyrow";
}
}
this.title.innerHTML=Calendar._MN[_124]+", "+year;
this.onSetTime();
this.table.style.visibility="visible";
this._initMultipleDates();
};
Calendar.prototype._initMultipleDates=function(){
if(this.multiple){
if(Prototype){
this.muliple.each(function(_135){
var cell=this.datesCells[_135.key];
var d=_135.value;
if(!d){
return;
}
if(cell){
cell.className+=" selected";
}
});
}else{
for(var i in this.multiple){
var cell=this.datesCells[i];
var d=this.multiple[i];
if(!d){
continue;
}
if(cell){
cell.className+=" selected";
}
}
}
}
};
Calendar.prototype._toggleMultipleDate=function(date){
if(this.multiple){
var ds=date.print("%Y%m%d");
var cell=this.datesCells[ds];
if(cell){
var d=this.multiple[ds];
if(!d){
Calendar.addClass(cell,"selected");
this.multiple[ds]=date;
}else{
Calendar.removeClass(cell,"selected");
delete this.multiple[ds];
}
}
}
};
Calendar.prototype.setDateToolTipHandler=function(_13f){
this.getDateToolTip=_13f;
};
Calendar.prototype.setDate=function(date){
if(!date.equalsTo(this.date)){
this._init(this.firstDayOfWeek,date);
}
};
Calendar.prototype.refresh=function(){
this._init(this.firstDayOfWeek,this.date);
};
Calendar.prototype.setFirstDayOfWeek=function(_141){
this._init(_141,this.date);
this._displayWeekdays();
};
Calendar.prototype.setDateStatusHandler=Calendar.prototype.setDisabledHandler=function(_142){
this.getDateStatus=_142;
};
Calendar.prototype.setRange=function(a,z){
this.minYear=a;
this.maxYear=z;
};
Calendar.prototype.callHandler=function(){
if(this.onSelected){
this.onSelected(this,this.date.print(this.dateFormat));
}
};
Calendar.prototype.callCloseHandler=function(){
if(this.onClose){
this.onClose(this);
}
this.hideShowCovered();
};
Calendar.prototype.destroy=function(){
var el=this.element.parentNode;
el.removeChild(this.element);
Calendar._C=null;
window._dynarch_popupCalendar=null;
};
Calendar.prototype.reparent=function(_146){
var el=this.element;
el.parentNode.removeChild(el);
_146.appendChild(el);
};
Calendar._checkCalendar=function(ev){
var _149=window._dynarch_popupCalendar;
if(!_149){
return false;
}
var el=Calendar.is_ie?Calendar.getElement(ev):Calendar.getTargetElement(ev);
for(;el!=null&&el!=_149.element;el=el.parentNode){
}
if(el==null){
window._dynarch_popupCalendar.callCloseHandler();
return Calendar.stopEvent(ev);
}
};
Calendar.prototype.show=function(){
var rows=this.table.getElementsByTagName("tr");
for(var i=rows.length;i>0;){
var row=rows[--i];
Calendar.removeClass(row,"rowhilite");
var _14e=row.getElementsByTagName("td");
for(var j=_14e.length;j>0;){
var cell=_14e[--j];
Calendar.removeClass(cell,"hilite");
Calendar.removeClass(cell,"active");
}
}
this.element.style.display="block";
this.hidden=false;
if(this.isPopup){
window._dynarch_popupCalendar=this;
Calendar.addEvent(document,"keydown",Calendar._keyEvent);
Calendar.addEvent(document,"keypress",Calendar._keyEvent);
Calendar.addEvent(document,"mousedown",Calendar._checkCalendar);
}
this.hideShowCovered();
};
Calendar.prototype.hide=function(){
if(this.isPopup){
Calendar.removeEvent(document,"keydown",Calendar._keyEvent);
Calendar.removeEvent(document,"keypress",Calendar._keyEvent);
Calendar.removeEvent(document,"mousedown",Calendar._checkCalendar);
}
this.element.style.display="none";
this.hidden=true;
this.hideShowCovered();
};
Calendar.prototype.showAt=function(x,y){
var s=this.element.style;
s.left=x+"px";
s.top=y+"px";
this.show();
};
Calendar.prototype.showAtElement=function(el,opts){
var self=this;
var p=Calendar.getAbsolutePos(el);
if(!opts||typeof opts!="string"){
this.showAt(p.x,p.y+el.offsetHeight);
return true;
}
function fixPosition(box){
if(box.x<0){
box.x=0;
}
if(box.y<0){
box.y=0;
}
var cp=document.createElement("div");
var s=cp.style;
s.position="absolute";
s.right=s.bottom=s.width=s.height="0px";
document.body.appendChild(cp);
var br=Calendar.getAbsolutePos(cp);
document.body.removeChild(cp);
if(Calendar.is_ie){
br.y+=document.body.scrollTop;
br.x+=document.body.scrollLeft;
}else{
br.y+=window.scrollY;
br.x+=window.scrollX;
}
var tmp=box.x+box.width-br.x;
if(tmp>0){
box.x-=tmp;
}
tmp=box.y+box.height-br.y;
if(tmp>0){
box.y-=tmp;
}
}
this.element.style.display="block";
Calendar.continuation_for_the_fucking_khtml_browser=function(){
var w=self.element.offsetWidth;
var h=self.element.offsetHeight;
self.element.style.display="none";
var _15f=opts.substr(0,1);
var _160="l";
if(opts.length>1){
_160=opts.substr(1,1);
}
switch(_15f){
case "T":
p.y-=h;
break;
case "B":
p.y+=el.offsetHeight;
break;
case "C":
p.y+=(el.offsetHeight-h)/2;
break;
case "t":
p.y+=el.offsetHeight-h;
break;
case "b":
break;
}
switch(_160){
case "L":
p.x-=w;
break;
case "R":
p.x+=el.offsetWidth;
break;
case "C":
p.x+=(el.offsetWidth-w)/2;
break;
case "l":
p.x+=el.offsetWidth-w;
break;
case "r":
break;
}
p.width=w;
p.height=h+40;
self.monthsCombo.style.display="none";
fixPosition(p);
self.showAt(p.x,p.y);
};
if(Calendar.is_khtml){
setTimeout("Calendar.continuation_for_the_fucking_khtml_browser()",10);
}else{
Calendar.continuation_for_the_fucking_khtml_browser();
}
};
Calendar.prototype.setDateFormat=function(str){
this.dateFormat=str;
};
Calendar.prototype.setTtDateFormat=function(str){
this.ttDateFormat=str;
};
Calendar.prototype.parseDate=function(str,fmt){
if(!fmt){
fmt=this.dateFormat;
}
this.setDate(Date.parseDate(str,fmt));
};
Calendar.prototype.hideShowCovered=function(){
if(!Calendar.is_ie&&!Calendar.is_opera){
return;
}
function getVisib(obj){
var _166=obj.style.visibility;
if(!_166){
if(document.defaultView&&typeof (document.defaultView.getComputedStyle)=="function"){
if(!Calendar.is_khtml){
_166=document.defaultView.getComputedStyle(obj,"").getPropertyValue("visibility");
}else{
_166="";
}
}else{
if(obj.currentStyle){
_166=obj.currentStyle.visibility;
}else{
_166="";
}
}
}
return _166;
}
var tags=new Array("applet","iframe","select");
var el=this.element;
var p=Calendar.getAbsolutePos(el);
var EX1=p.x;
var EX2=el.offsetWidth+EX1;
var EY1=p.y;
var EY2=el.offsetHeight+EY1;
for(var k=tags.length;k>0;){
var ar=document.getElementsByTagName(tags[--k]);
var cc=null;
for(var i=ar.length;i>0;){
cc=ar[--i];
p=Calendar.getAbsolutePos(cc);
var CX1=p.x;
var CX2=cc.offsetWidth+CX1;
var CY1=p.y;
var CY2=cc.offsetHeight+CY1;
if(this.hidden||(CX1>EX2)||(CX2<EX1)||(CY1>EY2)||(CY2<EY1)){
if(!cc.__msh_save_visibility){
cc.__msh_save_visibility=getVisib(cc);
}
cc.style.visibility=cc.__msh_save_visibility;
}else{
if(!cc.__msh_save_visibility){
cc.__msh_save_visibility=getVisib(cc);
}
cc.style.visibility="hidden";
}
}
}
};
Calendar.prototype._displayWeekdays=function(){
var fdow=this.firstDayOfWeek;
var cell=this.firstdayname;
var _178=Calendar._TT["WEEKEND"];
for(var i=0;i<7;++i){
cell.className="day name";
var _17a=(i+fdow)%7;
if(i){
cell.ttip=Calendar._TT["DAY_FIRST"].replace("%s",Calendar._DN[_17a]);
cell.navtype=100;
cell.calendar=this;
cell.fdow=_17a;
Calendar._add_evs(cell);
}
if(_178.indexOf(_17a.toString())!=-1){
Calendar.addClass(cell,"pop_weekend");
}
cell.innerHTML=Calendar._SDN[(i+fdow)%7];
cell=cell.nextSibling;
}
};
Calendar.prototype._hideCombos=function(){
this.monthsCombo.style.display="none";
this.yearsCombo.style.display="none";
};
Calendar.prototype._dragStart=function(ev){
if(this.dragging){
return;
}
this.dragging=true;
var posX;
var posY;
if(Calendar.is_ie){
posY=window.event.clientY+document.body.scrollTop;
posX=window.event.clientX+document.body.scrollLeft;
}else{
posY=ev.clientY+window.scrollY;
posX=ev.clientX+window.scrollX;
}
var st=this.element.style;
this.xOffs=posX-parseInt(st.left);
this.yOffs=posY-parseInt(st.top);
with(Calendar){
addEvent(document,"mousemove",calDragIt);
addEvent(document,"mouseup",calDragEnd);
}
};
Date._MD=new Array(31,28,31,30,31,30,31,31,30,31,30,31);
Date.SECOND=1000;
Date.MINUTE=60*Date.SECOND;
Date.HOUR=60*Date.MINUTE;
Date.DAY=24*Date.HOUR;
Date.WEEK=7*Date.DAY;
Date.parseDate=function(str,fmt){
var _181=new Date();
var y=0;
var m=-1;
var d=0;
var a=str.split(/\W+/);
var b=fmt.match(/%./g);
var i=0,j=0;
var hr=0;
var min=0;
for(i=0;i<a.length;++i){
if(!a[i]){
continue;
}
switch(b[i]){
case "%d":
case "%e":
d=parseInt(a[i],10);
break;
case "%m":
m=parseInt(a[i],10)-1;
break;
case "%Y":
case "%y":
y=parseInt(a[i],10);
(y<100)&&(y+=(y>29)?1900:2000);
break;
case "%b":
case "%B":
for(j=0;j<12;++j){
if(Calendar._MN[j].substr(0,a[i].length).toLowerCase()==a[i].toLowerCase()){
m=j;
break;
}
}
break;
case "%H":
case "%I":
case "%k":
case "%l":
hr=parseInt(a[i],10);
break;
case "%P":
case "%p":
if(/pm/i.test(a[i])&&hr<12){
hr+=12;
}else{
if(/am/i.test(a[i])&&hr>=12){
hr-=12;
}
}
break;
case "%M":
min=parseInt(a[i],10);
break;
}
}
if(isNaN(y)){
y=_181.getFullYear();
}
if(isNaN(m)){
m=_181.getMonth();
}
if(isNaN(d)){
d=_181.getDate();
}
if(isNaN(hr)){
hr=_181.getHours();
}
if(isNaN(min)){
min=_181.getMinutes();
}
if(y!=0&&m!=-1&&d!=0){
return new Date(y,m,d,hr,min,0);
}
y=0;
m=-1;
d=0;
for(i=0;i<a.length;++i){
if(a[i].search(/[a-zA-Z]+/)!=-1){
var t=-1;
for(j=0;j<12;++j){
if(Calendar._MN[j].substr(0,a[i].length).toLowerCase()==a[i].toLowerCase()){
t=j;
break;
}
}
if(t!=-1){
if(m!=-1){
d=m+1;
}
m=t;
}
}else{
if(parseInt(a[i],10)<=12&&m==-1){
m=a[i]-1;
}else{
if(parseInt(a[i],10)>31&&y==0){
y=parseInt(a[i],10);
(y<100)&&(y+=(y>29)?1900:2000);
}else{
if(d==0){
d=a[i];
}
}
}
}
}
if(y==0){
y=_181.getFullYear();
}
if(m!=-1&&d!=0){
return new Date(y,m,d,hr,min,0);
}
return _181;
};
Date.prototype.getMonthDays=function(_18b){
var year=this.getFullYear();
if(typeof _18b=="undefined"){
_18b=this.getMonth();
}
if(((0==(year%4))&&((0!=(year%100))||(0==(year%400))))&&_18b==1){
return 29;
}else{
return Date._MD[_18b];
}
};
Date.prototype.getDayOfYear=function(){
var now=new Date(this.getFullYear(),this.getMonth(),this.getDate(),0,0,0);
var then=new Date(this.getFullYear(),0,0,0,0,0);
var time=now-then;
return Math.floor(time/Date.DAY);
};
Date.prototype.getWeekNumber=function(){
var d=new Date(this.getFullYear(),this.getMonth(),this.getDate(),0,0,0);
var DoW=d.getDay();
d.setDate(d.getDate()-(DoW+6)%7+3);
var ms=d.valueOf();
d.setMonth(0);
d.setDate(4);
return Math.round((ms-d.valueOf())/(7*86400000))+1;
};
Date.prototype.equalsTo=function(date){
return ((this.getFullYear()==date.getFullYear())&&(this.getMonth()==date.getMonth())&&(this.getDate()==date.getDate())&&(this.getHours()==date.getHours())&&(this.getMinutes()==date.getMinutes()));
};
Date.prototype.setDateOnly=function(date){
var tmp=new Date(date);
this.setDate(1);
this.setFullYear(tmp.getFullYear());
this.setMonth(tmp.getMonth());
this.setDate(tmp.getDate());
};
Date.prototype.print=function(str){
var m=this.getMonth();
var d=this.getDate();
var y=this.getFullYear();
var wn=this.getWeekNumber();
var w=this.getDay();
var s={};
var hr=this.getHours();
var pm=(hr>=12);
var ir=(pm)?(hr-12):hr;
var dy=this.getDayOfYear();
if(ir==0){
ir=12;
}
var min=this.getMinutes();
var sec=this.getSeconds();
s["%a"]=Calendar._SDN[w];
s["%A"]=Calendar._DN[w];
s["%b"]=Calendar._SMN[m];
s["%B"]=Calendar._MN[m];
s["%C"]=1+Math.floor(y/100);
s["%d"]=(d<10)?("0"+d):d;
s["%e"]=d;
s["%H"]=(hr<10)?("0"+hr):hr;
s["%I"]=(ir<10)?("0"+ir):ir;
s["%j"]=(dy<100)?((dy<10)?("00"+dy):("0"+dy)):dy;
s["%k"]=hr;
s["%l"]=ir;
s["%m"]=(m<9)?("0"+(1+m)):(1+m);
s["%M"]=(min<10)?("0"+min):min;
s["%n"]="\n";
s["%p"]=pm?"PM":"AM";
s["%P"]=pm?"pm":"am";
s["%s"]=Math.floor(this.getTime()/1000);
s["%S"]=(sec<10)?("0"+sec):sec;
s["%t"]="\t";
s["%U"]=s["%W"]=s["%V"]=(wn<10)?("0"+wn):wn;
s["%u"]=w+1;
s["%w"]=w;
s["%y"]=(""+y).substr(2,2);
s["%Y"]=y;
s["%%"]="%";
var re=/%./g;
if(!Calendar.is_ie5&&!Calendar.is_khtml){
return str.replace(re,function(par){
return s[par]||par;
});
}
var a=str.match(re);
for(var i=0;i<a.length;i++){
var tmp=s[a[i]];
if(tmp){
re=new RegExp(a[i],"g");
str=str.replace(re,tmp);
}
}
return str;
};
Date.prototype.__msh_oldSetFullYear=Date.prototype.setFullYear;
Date.prototype.setFullYear=function(y){
var d=new Date(this);
d.__msh_oldSetFullYear(y);
if(d.getMonth()!=this.getMonth()){
this.setDate(28);
}
this.__msh_oldSetFullYear(y);
};
window._dynarch_popupCalendar=null;
Calendar._DN=new Array("Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday");
Calendar._SDN=new Array("Sun","Mon","Tue","Wed","Thu","Fri","Sat","Sun");
Calendar._FD=0;
Calendar._MN=new Array("January","February","March","April","May","June","July","August","September","October","November","December");
Calendar._SMN=new Array("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
Calendar._TT={};
Calendar._TT["INFO"]="About the calendar";
Calendar._TT["ABOUT"]="DHTML Date/Time Selector\n"+"(c) dynarch.com 2002-2005 / Author: Mihai Bazon\n"+"For latest version visit: http://www.dynarch.com/projects/calendar/\n"+"Distributed under GNU LGPL.  See http://gnu.org/licenses/lgpl.html for details."+"\n\n"+"Date selection:\n"+"- Use the \xab, \xbb buttons to select year\n"+"- Use the "+String.fromCharCode(8249)+", "+String.fromCharCode(8250)+" buttons to select month\n"+"- Hold mouse button on any of the above buttons for faster selection.";
Calendar._TT["ABOUT_TIME"]="\n\n"+"Time selection:\n"+"- Click on any of the time parts to increase it\n"+"- or Shift-click to decrease it\n"+"- or click and drag for faster selection.";
Calendar._TT["PREV_YEAR"]="Prev. year (hold for menu)";
Calendar._TT["PREV_MONTH"]="Prev. month (hold for menu)";
Calendar._TT["GO_TODAY"]="Go Today";
Calendar._TT["NEXT_MONTH"]="Next month (hold for menu)";
Calendar._TT["NEXT_YEAR"]="Next year (hold for menu)";
Calendar._TT["SEL_DATE"]="Select date";
Calendar._TT["DRAG_TO_MOVE"]="Drag to move";
Calendar._TT["PART_TODAY"]=" (today)";
Calendar._TT["DAY_FIRST"]="Display %s first";
Calendar._TT["WEEKEND"]="0,6";
Calendar._TT["CLOSE"]="Close";
Calendar._TT["TODAY"]="Today";
Calendar._TT["TIME_PART"]="(Shift-)Click or drag to change value";
Calendar._TT["DEF_DATE_FORMAT"]="%Y-%m-%d";
Calendar._TT["TT_DATE_FORMAT"]="%a, %b %e";
Calendar._TT["WK"]="wk";
Calendar._TT["TIME"]="Time:";
Calendar.setup=function(_1aa){
function param_default(_1ab,def){
if(typeof _1aa[_1ab]=="undefined"){
_1aa[_1ab]=def;
}
}
param_default("inputField",null);
param_default("displayArea",null);
param_default("button",null);
param_default("help",null);
param_default("eventName","click");
param_default("ifFormat","%Y/%m/%d");
param_default("daFormat","%Y/%m/%d");
param_default("singleClick",true);
param_default("disableFunc",null);
param_default("dateStatusFunc",_1aa["disableFunc"]);
param_default("dateText",null);
param_default("firstDay",null);
param_default("align","Br");
param_default("range",[1900,2999]);
param_default("weekNumbers",true);
param_default("flat",null);
param_default("flatCallback",null);
param_default("onSelect",null);
param_default("onClose",null);
param_default("onUpdate",null);
param_default("date",null);
param_default("showsTime",false);
param_default("timeFormat","24");
param_default("electric",true);
param_default("step",2);
param_default("position",null);
param_default("cache",false);
param_default("showOthers",false);
param_default("multiple",null);
var tmp=["inputField","displayArea","button","help"];
for(var i=0;i<tmp.length;i++){
if(typeof _1aa[tmp[i]]=="string"){
_1aa[tmp[i]]=$(_1aa[tmp[i]]);
}
}
if(!(_1aa.flat||_1aa.multiple||_1aa.inputField||_1aa.displayArea||_1aa.button)){
alert("Calendar.setup:\n  Nothing to setup (no fields found).  Please check your code");
return false;
}
function onSelect(cal){
var p=cal.params;
var _1b1=(cal.dateClicked||p.electric);
if(_1b1&&p.inputField){
p.inputField.value=cal.date.print(p.ifFormat);
$(p.inputField.id + 'Msg').innerHTML = parseDateString(p.inputField.value).toDateString();
if(typeof p.inputField.onchange=="function"){
p.inputField.onchange();
}
}
if(_1b1&&p.displayArea){
p.displayArea.innerHTML=cal.date.print(p.daFormat);
}
if(_1b1&&typeof p.onUpdate=="function"){
p.onUpdate(cal);
}
if(_1b1&&p.flat){
if(typeof p.flatCallback=="function"){
p.flatCallback(cal);
}
}
if(_1b1&&p.singleClick&&cal.dateClicked){
cal.callCloseHandler();
}
}
if(_1aa.flat!=null){
if(typeof _1aa.flat=="string"){
_1aa.flat=$(_1aa.flat);
}
if(!_1aa.flat){
alert("Calendar.setup:\n  Flat specified but can't find parent.");
return false;
}
var cal=new Calendar(_1aa.firstDay,_1aa.date,_1aa.onSelect||onSelect);
cal.showsOtherMonths=_1aa.showOthers;
cal.showsTime=_1aa.showsTime;
cal.time24=(_1aa.timeFormat=="24");
cal.params=_1aa;
cal.weekNumbers=_1aa.weekNumbers;
cal.setRange(_1aa.range[0],_1aa.range[1]);
cal.setDateStatusHandler(_1aa.dateStatusFunc);
cal.getDateText=_1aa.dateText;
if(_1aa.ifFormat){
cal.setDateFormat(_1aa.ifFormat);
}
if(_1aa.inputField&&typeof _1aa.inputField.value=="string"){
cal.parseDate(_1aa.inputField.value);
}
cal.create(_1aa.flat);
cal.show();
return false;
}
//var _1b3=_1aa.help;
//_1b3["on"+_1aa.eventName]=function(){
//windowOpenCenter("/datebocks/help","dateBocksHelp","width=500,height=430,autocenter=true");
//};
var _1b4=_1aa.button||_1aa.displayArea||_1aa.inputField;
_1b4["on"+_1aa.eventName]=function(){
var _1b5=_1aa.inputField||_1aa.displayArea;
var _1b6=_1aa.inputField?_1aa.ifFormat:_1aa.daFormat;
var _1b7=false;
var cal=window.calendar;
if(_1b5){
_1aa.date=Date.parseDate(_1b5.value||_1b5.innerHTML,_1b6);
}
if(!(cal&&_1aa.cache)){
window.calendar=cal=new Calendar(_1aa.firstDay,_1aa.date,_1aa.onSelect||onSelect,_1aa.onClose||function(cal){
cal.hide();
});
cal.showsTime=_1aa.showsTime;
cal.time24=(_1aa.timeFormat=="24");
cal.weekNumbers=_1aa.weekNumbers;
_1b7=true;
}else{
if(_1aa.date){
cal.setDate(_1aa.date);
}
cal.hide();
}
if(_1aa.multiple){
cal.multiple={};
for(var i=_1aa.multiple.length;--i>=0;){
var d=_1aa.multiple[i];
var ds=d.print("%Y%m%d");
cal.multiple[ds]=d;
}
}
cal.showsOtherMonths=_1aa.showOthers;
cal.yearStep=_1aa.step;
cal.setRange(_1aa.range[0],_1aa.range[1]);
cal.params=_1aa;
cal.setDateStatusHandler(_1aa.dateStatusFunc);
cal.getDateText=_1aa.dateText;
cal.setDateFormat(_1b6);
if(_1b7){
cal.create();
}
cal.refresh();
if(!_1aa.position){
cal.showAtElement(_1aa.button||_1aa.displayArea||_1aa.inputField,_1aa.align);
}else{
cal.showAt(_1aa.position[0],_1aa.position[1]);
}
return false;
};
return cal;
};
function calendarSetup(){
var divs=$$('.dateBocks');
divs.each(function(div){
$A(div.getElementsByTagName('img')).each(function(img){
$(img.id).removeClassName('hide');
});
var input=div.down('input');
Calendar.setup({
inputField:input.id,
ifFormat:calendarIfFormat,
button:input.id+"Button",
help:input.id+"Help",
align:"Br",
singleClick:true
});
Event.observe(input,'change',function(){magicDate(input.id);});
Event.observe(input,'keypress',function(event){magicDateOnlyOnSubmit(input.id,event);return dateBocksKeyListener(event);});
Event.observe(input,'click',function(){input.select();});
$(input.id+'Msg').innerHTML=calendarFormatString;
var help=div.getElementsBySelector('[title="Help"]');
if(help[0]){
var img=help[0];
Event.observe(img, 'click', function(){
var win=new Window({id: 'calendar_help_window', className: "mac_os_x", url: "/datebocks/help",title: "The Calendar Widget", width:250, height:450, zIndex: 1001, top:0, left: 1, parent:$('wrapper'), destroyOnClose: true});
win.show();
});
}
});
}
Event.observe(window,'load',calendarSetup);
