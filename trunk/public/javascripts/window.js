var Window=Class.create();
Window.keepMultiModalWindow=false;
Window.hasEffectLib=(typeof Effect!="undefined");
Window.resizeEffectDuration=0.4;
Window.prototype={initialize:function(){
var id;
var _2=0;
if(arguments.length>0){
if(typeof arguments[0]=="string"){
id=arguments[0];
_2=1;
}else{
id=arguments[0]?arguments[0].id:null;
}
}
if(!id){
id="window_"+new Date().getTime();
}
if($(id)){
alert("Window "+id+" is already registered in the DOM! Make sure you use setDestroyOnClose() or destroyOnClose: true in the constructor");
}
this.options=Object.extend({className:"dialog",blurClassName:null,minWidth:100,minHeight:20,resizable:true,closable:true,minimizable:true,maximizable:true,draggable:true,userData:null,showEffect:(Window.hasEffectLib?Effect.Appear:Element.show),hideEffect:(Window.hasEffectLib?Effect.Fade:Element.hide),showEffectOptions:{},hideEffectOptions:{},effectOptions:null,parent:document.body,title:"&nbsp;",url:null,onload:Prototype.emptyFunction,width:200,height:300,opacity:1,recenterAuto:true,wiredDrag:false,closeCallback:null,destroyOnClose:false,gridX:1,gridY:1},arguments[_2]||{});
if(this.options.blurClassName){
this.options.focusClassName=this.options.className;
}
if(typeof this.options.top=="undefined"&&typeof this.options.bottom=="undefined"){
this.options.top=this._round(Math.random()*500,this.options.gridY);
}
if(typeof this.options.left=="undefined"&&typeof this.options.right=="undefined"){
this.options.left=this._round(Math.random()*500,this.options.gridX);
}
if(this.options.effectOptions){
Object.extend(this.options.hideEffectOptions,this.options.effectOptions);
Object.extend(this.options.showEffectOptions,this.options.effectOptions);
if(this.options.showEffect==Element.Appear){
this.options.showEffectOptions.to=this.options.opacity;
}
}
if(Window.hasEffectLib){
if(this.options.showEffect==Effect.Appear){
this.options.showEffectOptions.to=this.options.opacity;
}
if(this.options.hideEffect==Effect.Fade){
this.options.hideEffectOptions.from=this.options.opacity;
}
}
if(this.options.hideEffect==Element.hide){
this.options.hideEffect=function(){
Element.hide(this.element);
if(this.options.destroyOnClose){
this.destroy();
}
}.bind(this);
}
if(this.options.parent!=document.body){
this.options.parent=$(this.options.parent);
}
this.element=this._createWindow(id);
this.element.win=this;
this.eventMouseDown=this._initDrag.bindAsEventListener(this);
this.eventMouseUp=this._endDrag.bindAsEventListener(this);
this.eventMouseMove=this._updateDrag.bindAsEventListener(this);
this.eventOnLoad=this._getWindowBorderSize.bindAsEventListener(this);
this.eventMouseDownContent=this.toFront.bindAsEventListener(this);
this.eventResize=this._recenter.bindAsEventListener(this);
this.topbar=$(this.element.id+"_top");
this.bottombar=$(this.element.id+"_bottom");
this.content=$(this.element.id+"_content");
Event.observe(this.topbar,"mousedown",this.eventMouseDown);
Event.observe(this.bottombar,"mousedown",this.eventMouseDown);
Event.observe(this.content,"mousedown",this.eventMouseDownContent);
Event.observe(window,"load",this.eventOnLoad);
Event.observe(window,"resize",this.eventResize);
Event.observe(window,"scroll",this.eventResize);
Event.observe(this.options.parent,"scroll",this.eventResize);
if(this.options.draggable){
var _3=this;
[this.topbar,this.topbar.up().previous(),this.topbar.up().next()].each(function(_4){
_4.observe("mousedown",_3.eventMouseDown);
_4.addClassName("top_draggable");
});
[this.bottombar.up(),this.bottombar.up().previous(),this.bottombar.up().next()].each(function(_5){
_5.observe("mousedown",_3.eventMouseDown);
_5.addClassName("bottom_draggable");
});
}
if(this.options.resizable){
this.sizer=$(this.element.id+"_sizer");
Event.observe(this.sizer,"mousedown",this.eventMouseDown);
}
this.useLeft=null;
this.useTop=null;
if(typeof this.options.left!="undefined"){
this.element.setStyle({left:parseFloat(this.options.left)+"px"});
this.useLeft=true;
}else{
this.element.setStyle({right:parseFloat(this.options.right)+"px"});
this.useLeft=false;
}
if(typeof this.options.top!="undefined"){
this.element.setStyle({top:parseFloat(this.options.top)+"px"});
this.useTop=true;
}else{
this.element.setStyle({bottom:parseFloat(this.options.bottom)+"px"});
this.useTop=false;
}
this.storedLocation=null;
this.setOpacity(this.options.opacity);
if(this.options.zIndex){
this.setZIndex(this.options.zIndex);
}
if(this.options.destroyOnClose){
this.setDestroyOnClose(true);
}
this._getWindowBorderSize();
this.width=this.options.width;
this.height=this.options.height;
this.visible=false;
this.constraint=false;
this.constraintPad={top:0,left:0,bottom:0,right:0};
if(this.width&&this.height){
this.setSize(this.options.width,this.options.height);
}
this.setTitle(this.options.title);
Windows.register(this);
},destroy:function(){
this._notify("onDestroy");
Event.stopObserving(this.topbar,"mousedown",this.eventMouseDown);
Event.stopObserving(this.bottombar,"mousedown",this.eventMouseDown);
Event.stopObserving(this.content,"mousedown",this.eventMouseDownContent);
Event.stopObserving(window,"load",this.eventOnLoad);
Event.stopObserving(window,"resize",this.eventResize);
Event.stopObserving(window,"scroll",this.eventResize);
Event.stopObserving(this.content,"load",this.options.onload);
if(this._oldParent){
var _6=this.getContent();
var _7=null;
for(var i=0;i<_6.childNodes.length;i++){
_7=_6.childNodes[i];
if(_7.nodeType==1){
break;
}
_7=null;
}
if(_7){
this._oldParent.appendChild(_7);
}
this._oldParent=null;
}
if(this.sizer){
Event.stopObserving(this.sizer,"mousedown",this.eventMouseDown);
}
if(this.options.url){
this.content.src=null;
}
if(this.iefix){
Element.remove(this.iefix);
}
Element.remove(this.element);
Windows.unregister(this);
},setCloseCallback:function(_9){
this.options.closeCallback=_9;
},getContent:function(){
return this.content;
},setContent:function(id,_b,_c){
var _d=$(id);
if(null==_d){
throw "Unable to find element '"+id+"' in DOM";
}
this._oldParent=_d.parentNode;
var d=null;
var p=null;
if(_b){
d=Element.getDimensions(_d);
}
if(_c){
p=Position.cumulativeOffset(_d);
}
var _10=this.getContent();
this.setHTMLContent("");
_10=this.getContent();
_10.appendChild(_d);
_d.show();
if(_b){
this.setSize(d.width,d.height);
}
if(_c){
this.setLocation(p[1]-this.heightN,p[0]-this.widthW);
}
},setHTMLContent:function(_11){
if(this.options.url){
this.content.src=null;
this.options.url=null;
var _12="<div id=\""+this.getId()+"_content\" class=\""+this.options.className+"_content\"> </div>";
$(this.getId()+"_table_content").innerHTML=_12;
this.content=$(this.element.id+"_content");
}
this.getContent().innerHTML=_11;
},setAjaxContent:function(url,_14,_15,_16){
this.showFunction=_15?"showCenter":"show";
this.showModal=_16||false;
_14=_14||{};
this.setHTMLContent("");
this.onComplete=_14.onComplete;
if(!this._onCompleteHandler){
this._onCompleteHandler=this._setAjaxContent.bind(this);
}
_14.onComplete=this._onCompleteHandler;
new Ajax.Request(url,_14);
_14.onComplete=this.onComplete;
},_setAjaxContent:function(_17){
Element.update(this.getContent(),_17.responseText);
if(this.onComplete){
this.onComplete(_17);
}
this.onComplete=null;
this[this.showFunction](this.showModal);
},setURL:function(url){
if(this.options.url){
this.content.src=null;
}
this.options.url=url;
var _19="<iframe frameborder='0' name='"+this.getId()+"_content'  id='"+this.getId()+"_content' src='"+url+"' width='"+this.width+"' height='"+this.height+"'> </iframe>";
$(this.getId()+"_table_content").innerHTML=_19;
this.content=$(this.element.id+"_content");
},getURL:function(){
return this.options.url?this.options.url:null;
},refresh:function(){
if(this.options.url){
$(this.element.getAttribute("id")+"_content").src=this.options.url;
}
},setCookie:function(_1a,_1b,_1c,_1d,_1e){
_1a=_1a||this.element.id;
this.cookie=[_1a,_1b,_1c,_1d,_1e];
var _1f=WindowUtilities.getCookie(_1a);
if(_1f){
var _20=_1f.split(",");
var x=_20[0].split(":");
var y=_20[1].split(":");
var w=parseFloat(_20[2]),h=parseFloat(_20[3]);
var _24=_20[4];
var _25=_20[5];
this.setSize(w,h);
if(_24=="true"){
this.doMinimize=true;
}else{
if(_25=="true"){
this.doMaximize=true;
}
}
this.useLeft=x[0]=="l";
this.useTop=y[0]=="t";
this.element.setStyle(this.useLeft?{left:x[1]}:{right:x[1]});
this.element.setStyle(this.useTop?{top:y[1]}:{bottom:y[1]});
}
},getId:function(){
return this.element.id;
},setDestroyOnClose:function(){
this.options.destroyOnClose=true;
},setConstraint:function(_26,_27){
this.constraint=_26;
this.constraintPad=Object.extend(this.constraintPad,_27||{});
if(this.useTop&&this.useLeft){
this.setLocation(parseFloat(this.element.style.top),parseFloat(this.element.style.left));
}
},_initDrag:function(_28){
if(Event.element(_28)==this.sizer&&this.isMinimized()){
return;
}
if(Event.element(_28)!=this.sizer&&this.isMaximized()){
return;
}
if(Prototype.Browser.IE&&this.heightN==0){
this._getWindowBorderSize();
}
this.pointer=[this._round(Event.pointerX(_28),this.options.gridX),this._round(Event.pointerY(_28),this.options.gridY)];
if(this.options.wiredDrag){
this.currentDrag=this._createWiredElement();
}else{
this.currentDrag=this.element;
}
if(Event.element(_28)==this.sizer){
this.doResize=true;
this.widthOrg=this.width;
this.heightOrg=this.height;
this.bottomOrg=parseFloat(this.element.getStyle("bottom"));
this.rightOrg=parseFloat(this.element.getStyle("right"));
this._notify("onStartResize");
}else{
this.doResize=false;
var _29=$(this.getId()+"_close");
if(_29&&Position.within(_29,this.pointer[0],this.pointer[1])){
this.currentDrag=null;
return;
}
this.toFront();
if(!this.options.draggable){
return;
}
this._notify("onStartMove");
}
Event.observe(document,"mouseup",this.eventMouseUp,false);
Event.observe(document,"mousemove",this.eventMouseMove,false);
WindowUtilities.disableScreen("__invisible__","__invisible__",this.overlayOpacity);
document.body.ondrag=function(){
return false;
};
document.body.onselectstart=function(){
return false;
};
this.currentDrag.show();
Event.stop(_28);
},_round:function(val,_2b){
return _2b==1?val:val=Math.floor(val/_2b)*_2b;
},_updateDrag:function(_2c){
var _2d=[this._round(Event.pointerX(_2c),this.options.gridX),this._round(Event.pointerY(_2c),this.options.gridY)];
var dx=_2d[0]-this.pointer[0];
var dy=_2d[1]-this.pointer[1];
if(this.doResize){
var w=this.widthOrg+dx;
var h=this.heightOrg+dy;
dx=this.width-this.widthOrg;
dy=this.height-this.heightOrg;
if(this.useLeft){
w=this._updateWidthConstraint(w);
}else{
this.currentDrag.setStyle({right:(this.rightOrg-dx)+"px"});
}
if(this.useTop){
h=this._updateHeightConstraint(h);
}else{
this.currentDrag.setStyle({bottom:(this.bottomOrg-dy)+"px"});
}
this.setSize(w,h);
this._notify("onResize");
}else{
this.pointer=_2d;
if(this.useLeft){
var _32=parseFloat(this.currentDrag.getStyle("left"))+dx;
var _33=this._updateLeftConstraint(_32);
this.pointer[0]+=_33-_32;
this.currentDrag.setStyle({left:_33+"px"});
}else{
this.currentDrag.setStyle({right:parseFloat(this.currentDrag.getStyle("right"))-dx+"px"});
}
if(this.useTop){
var top=parseFloat(this.currentDrag.getStyle("top"))+dy;
var _35=this._updateTopConstraint(top);
this.pointer[1]+=_35-top;
this.currentDrag.setStyle({top:_35+"px"});
}else{
this.currentDrag.setStyle({bottom:parseFloat(this.currentDrag.getStyle("bottom"))-dy+"px"});
}
this._notify("onMove");
}
if(this.iefix){
this._fixIEOverlapping();
}
this._removeStoreLocation();
Event.stop(_2c);
},_endDrag:function(_36){
WindowUtilities.enableScreen("__invisible__");
if(this.doResize){
this._notify("onEndResize");
}else{
this._notify("onEndMove");
}
Event.stopObserving(document,"mouseup",this.eventMouseUp,false);
Event.stopObserving(document,"mousemove",this.eventMouseMove,false);
Event.stop(_36);
this._hideWiredElement();
this._saveCookie();
document.body.ondrag=null;
document.body.onselectstart=null;
},_updateLeftConstraint:function(_37){
if(this.constraint&&this.useLeft&&this.useTop){
var _38=this.options.parent==document.body?WindowUtilities.getPageSize().windowWidth:this.options.parent.getDimensions().width;
if(_37<this.constraintPad.left){
_37=this.constraintPad.left;
}
if(_37+this.width+this.widthE+this.widthW>_38-this.constraintPad.right){
_37=_38-this.constraintPad.right-this.width-this.widthE-this.widthW;
}
}
return _37;
},_updateTopConstraint:function(top){
if(this.constraint&&this.useLeft&&this.useTop){
var _3a=this.options.parent==document.body?WindowUtilities.getPageSize().windowHeight:this.options.parent.getDimensions().height;
var h=this.height+this.heightN+this.heightS;
if(top<this.constraintPad.top){
top=this.constraintPad.top;
}
if(top+h>_3a-this.constraintPad.bottom){
top=_3a-this.constraintPad.bottom-h;
}
}
return top;
},_updateWidthConstraint:function(w){
if(this.constraint&&this.useLeft&&this.useTop){
var _3d=this.options.parent==document.body?WindowUtilities.getPageSize().windowWidth:this.options.parent.getDimensions().width;
var _3e=parseFloat(this.element.getStyle("left"));
if(_3e+w+this.widthE+this.widthW>_3d-this.constraintPad.right){
w=_3d-this.constraintPad.right-_3e-this.widthE-this.widthW;
}
}
return w;
},_updateHeightConstraint:function(h){
if(this.constraint&&this.useLeft&&this.useTop){
var _40=this.options.parent==document.body?WindowUtilities.getPageSize().windowHeight:this.options.parent.getDimensions().height;
var top=parseFloat(this.element.getStyle("top"));
if(top+h+this.heightN+this.heightS>_40-this.constraintPad.bottom){
h=_40-this.constraintPad.bottom-top-this.heightN-this.heightS;
}
}
return h;
},_createWindow:function(id){
var _43=this.options.className;
var win=document.createElement("div");
win.setAttribute("id",id);
win.className="dialog";
var _45;
if(this.options.url){
_45="<iframe frameborder=\"0\" name=\""+id+"_content\"  id=\""+id+"_content\" src=\""+this.options.url+"\"> </iframe>";
}else{
_45="<div id=\""+id+"_content\" class=\""+_43+"_content\"> </div>";
}
var _46=this.options.closable?"<div class='"+_43+"_close' id='"+id+"_close' onclick='Windows.close(\""+id+"\", event)'> </div>":"";
var _47=this.options.minimizable?"<div class='"+_43+"_minimize' id='"+id+"_minimize' onclick='Windows.minimize(\""+id+"\", event)'> </div>":"";
var _48=this.options.maximizable?"<div class='"+_43+"_maximize' id='"+id+"_maximize' onclick='Windows.maximize(\""+id+"\", event)'> </div>":"";
var _49=this.options.resizable?"class='"+_43+"_sizer' id='"+id+"_sizer'":"class='"+_43+"_se'";
var _4a="../themes/default/blank.gif";
win.innerHTML=_46+_47+_48+"      <table id='"+id+"_row1' class=\"top table_window\">        <tr>          <td class='"+_43+"_nw'></td>          <td class='"+_43+"_n'><div id='"+id+"_top' class='"+_43+"_title title_window'>"+this.options.title+"</div></td>          <td class='"+_43+"_ne'></td>        </tr>      </table>      <table id='"+id+"_row2' class=\"mid table_window\">        <tr>          <td class='"+_43+"_w'></td>            <td id='"+id+"_table_content' class='"+_43+"_content' valign='top'>"+_45+"</td>          <td class='"+_43+"_e'></td>        </tr>      </table>        <table id='"+id+"_row3' class=\"bot table_window\">        <tr>          <td class='"+_43+"_sw'></td>            <td class='"+_43+"_s'><div id='"+id+"_bottom' class='status_bar'><span style='float:left; width:1px; height:1px'></span></div></td>            <td "+_49+"></td>        </tr>      </table>    ";
Element.hide(win);
this.options.parent.insertBefore(win,this.options.parent.firstChild);
Event.observe($(id+"_content"),"load",this.options.onload);
return win;
},changeClassName:function(_4b){
var _4c=this.options.className;
var id=this.getId();
$A(["_close","_minimize","_maximize","_sizer","_content"]).each(function(_4e){
this._toggleClassName($(id+_4e),_4c+_4e,_4b+_4e);
}.bind(this));
this._toggleClassName($(id+"_top"),_4c+"_title",_4b+"_title");
$$("#"+id+" td").each(function(td){
td.className=td.className.sub(_4c,_4b);
});
this.options.className=_4b;
},_toggleClassName:function(_50,_51,_52){
if(_50){
_50.removeClassName(_51);
_50.addClassName(_52);
}
},setLocation:function(top,_54){
top=this._updateTopConstraint(top);
_54=this._updateLeftConstraint(_54);
var e=this.currentDrag||this.element;
e.setStyle({top:top+"px"});
e.setStyle({left:_54+"px"});
this.useLeft=true;
this.useTop=true;
},getLocation:function(){
var _56={};
if(this.useTop){
_56=Object.extend(_56,{top:this.element.getStyle("top")});
}else{
_56=Object.extend(_56,{bottom:this.element.getStyle("bottom")});
}
if(this.useLeft){
_56=Object.extend(_56,{left:this.element.getStyle("left")});
}else{
_56=Object.extend(_56,{right:this.element.getStyle("right")});
}
return _56;
},getSize:function(){
return {width:this.width,height:this.height};
},setSize:function(_57,_58,_59){
_57=parseFloat(_57);
_58=parseFloat(_58);
if(!this.minimized&&_57<this.options.minWidth){
_57=this.options.minWidth;
}
if(!this.minimized&&_58<this.options.minHeight){
_58=this.options.minHeight;
}
if(this.options.maxHeight&&_58>this.options.maxHeight){
_58=this.options.maxHeight;
}
if(this.options.maxWidth&&_57>this.options.maxWidth){
_57=this.options.maxWidth;
}
if(this.useTop&&this.useLeft&&Window.hasEffectLib&&Effect.ResizeWindow&&_59){
new Effect.ResizeWindow(this,null,null,_57,_58,{duration:Window.resizeEffectDuration});
}else{
this.width=_57;
this.height=_58;
var e=this.currentDrag?this.currentDrag:this.element;
e.setStyle({width:_57+this.widthW+this.widthE+"px"});
e.setStyle({height:_58+this.heightN+this.heightS+"px"});
if(!this.currentDrag||this.currentDrag==this.element){
var _5b=$(this.element.id+"_content");
_5b.setStyle({height:_58+"px"});
_5b.setStyle({width:_57+"px"});
}
}
},updateHeight:function(){
this.setSize(this.width,this.content.scrollHeight,true);
},updateWidth:function(){
this.setSize(this.content.scrollWidth,this.height,true);
},toFront:function(){
if(this.element.style.zIndex<Windows.maxZIndex){
this.setZIndex(Windows.maxZIndex+1);
}
if(this.iefix){
this._fixIEOverlapping();
}
},getBounds:function(_5c){
if(!this.width||!this.height||!this.visible){
this.computeBounds();
}
var w=this.width;
var h=this.height;
if(!_5c){
w+=this.widthW+this.widthE;
h+=this.heightN+this.heightS;
}
var _5f=Object.extend(this.getLocation(),{width:w+"px",height:h+"px"});
return _5f;
},computeBounds:function(){
if(!this.width||!this.height){
var _60=WindowUtilities._computeSize(this.content.innerHTML,this.content.id,this.width,this.height,0,this.options.className);
if(this.height){
this.width=_60+5;
}else{
this.height=_60+5;
}
}
this.setSize(this.width,this.height);
if(this.centered){
this._center(this.centerTop,this.centerLeft);
}
},show:function(_61){
this.visible=true;
if(_61){
if(typeof this.overlayOpacity=="undefined"){
var _62=this;
setTimeout(function(){
_62.show(_61);
},10);
return;
}
Windows.addModalWindow(this);
this.modal=true;
this.setZIndex(Windows.maxZIndex+1);
Windows.unsetOverflow(this);
}else{
if(!this.element.style.zIndex){
this.setZIndex(Windows.maxZIndex+1);
}
}
if(this.oldStyle){
this.getContent().setStyle({overflow:this.oldStyle});
}
this.computeBounds();
this._notify("onBeforeShow");
if(this.options.showEffect!=Element.show&&this.options.showEffectOptions){
this.options.showEffect(this.element,this.options.showEffectOptions);
}else{
this.options.showEffect(this.element);
}
this._checkIEOverlapping();
WindowUtilities.focusedWindow=this;
this._notify("onShow");
},showCenter:function(_63,top,_65){
this.centered=true;
this.centerTop=top;
this.centerLeft=_65;
this.show(_63);
},isVisible:function(){
return this.visible;
},_center:function(top,_67){
var _68=WindowUtilities.getWindowScroll(this.options.parent);
var _69=WindowUtilities.getPageSize(this.options.parent);
if(typeof top=="undefined"){
top=(_69.windowHeight-(this.height+this.heightN+this.heightS))/2;
}
top+=_68.top;
if(typeof _67=="undefined"){
_67=(_69.windowWidth-(this.width+this.widthW+this.widthE))/2;
}
_67+=_68.left;
this.setLocation(top,_67);
this.toFront();
},_recenter:function(_6a){
if(this.centered){
var _6b=WindowUtilities.getPageSize(this.options.parent);
var _6c=WindowUtilities.getWindowScroll(this.options.parent);
if(this.pageSize&&this.pageSize.windowWidth==_6b.windowWidth&&this.pageSize.windowHeight==_6b.windowHeight&&this.windowScroll.left==_6c.left&&this.windowScroll.top==_6c.top){
return;
}
this.pageSize=_6b;
this.windowScroll=_6c;
if($("overlay_modal")){
$("overlay_modal").setStyle({height:(_6b.pageHeight+"px")});
}
if(this.options.recenterAuto){
this._center(this.centerTop,this.centerLeft);
}
}
},hide:function(){
this.visible=false;
if(this.modal){
Windows.removeModalWindow(this);
Windows.resetOverflow();
}
this.oldStyle=this.getContent().getStyle("overflow")||"auto";
this.getContent().setStyle({overflow:"hidden"});
this.options.hideEffect(this.element,this.options.hideEffectOptions);
if(this.iefix){
this.iefix.hide();
}
if(!this.doNotNotifyHide){
this._notify("onHide");
}
},close:function(){
if(this.visible){
if(this.options.closeCallback&&!this.options.closeCallback(this)){
return;
}
if(this.options.destroyOnClose){
var _6d=this.destroy.bind(this);
if(this.options.hideEffectOptions.afterFinish){
var _6e=this.options.hideEffectOptions.afterFinish;
this.options.hideEffectOptions.afterFinish=function(){
_6e();
_6d();
};
}else{
this.options.hideEffectOptions.afterFinish=function(){
_6d();
};
}
}
Windows.updateFocusedWindow();
this.doNotNotifyHide=true;
this.hide();
this.doNotNotifyHide=false;
this._notify("onClose");
}
},minimize:function(){
if(this.resizing){
return;
}
var r2=$(this.getId()+"_row2");
if(!this.minimized){
this.minimized=true;
var dh=r2.getDimensions().height;
this.r2Height=dh;
var h=this.element.getHeight()-dh;
if(this.useLeft&&this.useTop&&Window.hasEffectLib&&Effect.ResizeWindow){
new Effect.ResizeWindow(this,null,null,null,this.height-dh,{duration:Window.resizeEffectDuration});
}else{
this.height-=dh;
this.element.setStyle({height:h+"px"});
r2.hide();
}
if(!this.useTop){
var _72=parseFloat(this.element.getStyle("bottom"));
this.element.setStyle({bottom:(_72+dh)+"px"});
}
}else{
this.minimized=false;
var dh=this.r2Height;
this.r2Height=null;
if(this.useLeft&&this.useTop&&Window.hasEffectLib&&Effect.ResizeWindow){
new Effect.ResizeWindow(this,null,null,null,this.height+dh,{duration:Window.resizeEffectDuration});
}else{
var h=this.element.getHeight()+dh;
this.height+=dh;
this.element.setStyle({height:h+"px"});
r2.show();
}
if(!this.useTop){
var _72=parseFloat(this.element.getStyle("bottom"));
this.element.setStyle({bottom:(_72-dh)+"px"});
}
this.toFront();
}
this._notify("onMinimize");
this._saveCookie();
},maximize:function(){
if(this.isMinimized()||this.resizing){
return;
}
if(Prototype.Browser.IE&&this.heightN==0){
this._getWindowBorderSize();
}
if(this.storedLocation!=null){
this._restoreLocation();
if(this.iefix){
this.iefix.hide();
}
}else{
this._storeLocation();
Windows.unsetOverflow(this);
var _73=WindowUtilities.getWindowScroll(this.options.parent);
var _74=WindowUtilities.getPageSize(this.options.parent);
var _75=_73.left;
var top=_73.top;
if(this.options.parent!=document.body){
_73={top:0,left:0,bottom:0,right:0};
var dim=this.options.parent.getDimensions();
_74.windowWidth=dim.width;
_74.windowHeight=dim.height;
top=0;
_75=0;
}
if(this.constraint){
_74.windowWidth-=Math.max(0,this.constraintPad.left)+Math.max(0,this.constraintPad.right);
_74.windowHeight-=Math.max(0,this.constraintPad.top)+Math.max(0,this.constraintPad.bottom);
_75+=Math.max(0,this.constraintPad.left);
top+=Math.max(0,this.constraintPad.top);
}
var _78=_74.windowWidth-this.widthW-this.widthE;
var _79=_74.windowHeight-this.heightN-this.heightS;
if(this.useLeft&&this.useTop&&Window.hasEffectLib&&Effect.ResizeWindow){
new Effect.ResizeWindow(this,top,_75,_78,_79,{duration:Window.resizeEffectDuration});
}else{
this.setSize(_78,_79);
this.element.setStyle(this.useLeft?{left:_75}:{right:_75});
this.element.setStyle(this.useTop?{top:top}:{bottom:top});
}
this.toFront();
if(this.iefix){
this._fixIEOverlapping();
}
}
this._notify("onMaximize");
this._saveCookie();
},isMinimized:function(){
return this.minimized;
},isMaximized:function(){
return (this.storedLocation!=null);
},setOpacity:function(_7a){
if(Element.setOpacity){
Element.setOpacity(this.element,_7a);
}
},setZIndex:function(_7b){
this.element.setStyle({zIndex:_7b});
Windows.updateZindex(_7b,this);
},setTitle:function(_7c){
if(!_7c||_7c==""){
_7c="&nbsp;";
}
Element.update(this.element.id+"_top",_7c);
},getTitle:function(){
return $(this.element.id+"_top").innerHTML;
},setStatusBar:function(_7d){
var _7e=$(this.getId()+"_bottom");
if(typeof (_7d)=="object"){
if(this.bottombar.firstChild){
this.bottombar.replaceChild(_7d,this.bottombar.firstChild);
}else{
this.bottombar.appendChild(_7d);
}
}else{
this.bottombar.innerHTML=_7d;
}
},_checkIEOverlapping:function(){
if(!this.iefix&&(navigator.appVersion.indexOf("MSIE")>0)&&(navigator.userAgent.indexOf("Opera")<0)&&(this.element.getStyle("position")=="absolute")){
new Insertion.After(this.element.id,"<iframe id=\""+this.element.id+"_iefix\" "+"style=\"display:none;position:absolute;filter:progid:DXImageTransform.Microsoft.Alpha(opacity=0);\" "+"src=\"javascript:false;\" frameborder=\"0\" scrolling=\"no\"></iframe>");
this.iefix=$(this.element.id+"_iefix");
}
if(this.iefix){
setTimeout(this._fixIEOverlapping.bind(this),50);
}
},_fixIEOverlapping:function(){
Position.clone(this.element,this.iefix);
this.iefix.style.zIndex=this.element.style.zIndex-1;
this.iefix.show();
},_getWindowBorderSize:function(_7f){
var div=this._createHiddenDiv(this.options.className+"_n");
this.heightN=Element.getDimensions(div).height;
div.parentNode.removeChild(div);
var div=this._createHiddenDiv(this.options.className+"_s");
this.heightS=Element.getDimensions(div).height;
div.parentNode.removeChild(div);
var div=this._createHiddenDiv(this.options.className+"_e");
this.widthE=Element.getDimensions(div).width;
div.parentNode.removeChild(div);
var div=this._createHiddenDiv(this.options.className+"_w");
this.widthW=Element.getDimensions(div).width;
div.parentNode.removeChild(div);
var div=document.createElement("div");
div.className="overlay_"+this.options.className;
document.body.appendChild(div);
var _81=this;
setTimeout(function(){
_81.overlayOpacity=($(div).getStyle("opacity"));
div.parentNode.removeChild(div);
},10);
if(Prototype.Browser.IE){
this.heightS=$(this.getId()+"_row3").getDimensions().height;
this.heightN=$(this.getId()+"_row1").getDimensions().height;
}
if(Prototype.Browser.WebKit&&Prototype.Browser.WebKitVersion<420){
this.setSize(this.width,this.height);
}
if(this.doMaximize){
this.maximize();
}
if(this.doMinimize){
this.minimize();
}
},_createHiddenDiv:function(_82){
var _83=document.body;
var win=document.createElement("div");
win.setAttribute("id",this.element.id+"_tmp");
win.className=_82;
win.style.display="none";
win.innerHTML="";
_83.insertBefore(win,_83.firstChild);
return win;
},_storeLocation:function(){
if(this.storedLocation==null){
this.storedLocation={useTop:this.useTop,useLeft:this.useLeft,top:this.element.getStyle("top"),bottom:this.element.getStyle("bottom"),left:this.element.getStyle("left"),right:this.element.getStyle("right"),width:this.width,height:this.height};
}
},_restoreLocation:function(){
if(this.storedLocation!=null){
this.useLeft=this.storedLocation.useLeft;
this.useTop=this.storedLocation.useTop;
if(this.useLeft&&this.useTop&&Window.hasEffectLib&&Effect.ResizeWindow){
new Effect.ResizeWindow(this,this.storedLocation.top,this.storedLocation.left,this.storedLocation.width,this.storedLocation.height,{duration:Window.resizeEffectDuration});
}else{
this.element.setStyle(this.useLeft?{left:this.storedLocation.left}:{right:this.storedLocation.right});
this.element.setStyle(this.useTop?{top:this.storedLocation.top}:{bottom:this.storedLocation.bottom});
this.setSize(this.storedLocation.width,this.storedLocation.height);
}
Windows.resetOverflow();
this._removeStoreLocation();
}
},_removeStoreLocation:function(){
this.storedLocation=null;
},_saveCookie:function(){
if(this.cookie){
var _85="";
if(this.useLeft){
_85+="l:"+(this.storedLocation?this.storedLocation.left:this.element.getStyle("left"));
}else{
_85+="r:"+(this.storedLocation?this.storedLocation.right:this.element.getStyle("right"));
}
if(this.useTop){
_85+=",t:"+(this.storedLocation?this.storedLocation.top:this.element.getStyle("top"));
}else{
_85+=",b:"+(this.storedLocation?this.storedLocation.bottom:this.element.getStyle("bottom"));
}
_85+=","+(this.storedLocation?this.storedLocation.width:this.width);
_85+=","+(this.storedLocation?this.storedLocation.height:this.height);
_85+=","+this.isMinimized();
_85+=","+this.isMaximized();
WindowUtilities.setCookie(_85,this.cookie);
}
},_createWiredElement:function(){
if(!this.wiredElement){
if(Prototype.Browser.IE){
this._getWindowBorderSize();
}
var div=document.createElement("div");
div.className="wired_frame "+this.options.className+"_wired_frame";
div.style.position="absolute";
this.options.parent.insertBefore(div,this.options.parent.firstChild);
this.wiredElement=$(div);
}
if(this.useLeft){
this.wiredElement.setStyle({left:this.element.getStyle("left")});
}else{
this.wiredElement.setStyle({right:this.element.getStyle("right")});
}
if(this.useTop){
this.wiredElement.setStyle({top:this.element.getStyle("top")});
}else{
this.wiredElement.setStyle({bottom:this.element.getStyle("bottom")});
}
var dim=this.element.getDimensions();
this.wiredElement.setStyle({width:dim.width+"px",height:dim.height+"px"});
this.wiredElement.setStyle({zIndex:Windows.maxZIndex+30});
return this.wiredElement;
},_hideWiredElement:function(){
if(!this.wiredElement||!this.currentDrag){
return;
}
if(this.currentDrag==this.element){
this.currentDrag=null;
}else{
if(this.useLeft){
this.element.setStyle({left:this.currentDrag.getStyle("left")});
}else{
this.element.setStyle({right:this.currentDrag.getStyle("right")});
}
if(this.useTop){
this.element.setStyle({top:this.currentDrag.getStyle("top")});
}else{
this.element.setStyle({bottom:this.currentDrag.getStyle("bottom")});
}
this.currentDrag.hide();
this.currentDrag=null;
if(this.doResize){
this.setSize(this.width,this.height);
}
}
},_notify:function(_88){
if(this.options[_88]){
this.options[_88](this);
}else{
Windows.notify(_88,this);
}
}};
var Windows={windows:[],modalWindows:[],observers:[],focusedWindow:null,maxZIndex:0,overlayShowEffectOptions:{duration:0.5},overlayHideEffectOptions:{duration:0.5},addObserver:function(_89){
this.removeObserver(_89);
this.observers.push(_89);
},removeObserver:function(_8a){
this.observers=this.observers.reject(function(o){
return o==_8a;
});
},notify:function(_8c,win){
this.observers.each(function(o){
if(o[_8c]){
o[_8c](_8c,win);
}
});
},getWindow:function(id){
return this.windows.detect(function(d){
return d.getId()==id;
});
},getFocusedWindow:function(){
return this.focusedWindow;
},updateFocusedWindow:function(){
this.focusedWindow=this.windows.length>=2?this.windows[this.windows.length-2]:null;
},register:function(win){
this.windows.push(win);
},addModalWindow:function(win){
if(this.modalWindows.length==0){
WindowUtilities.disableScreen(win.options.className,"overlay_modal",win.overlayOpacity,win.getId(),win.options.parent);
}else{
if(Window.keepMultiModalWindow){
$("overlay_modal").style.zIndex=Windows.maxZIndex+1;
Windows.maxZIndex+=1;
WindowUtilities._hideSelect(this.modalWindows.last().getId());
}else{
this.modalWindows.last().element.hide();
}
WindowUtilities._showSelect(win.getId());
}
this.modalWindows.push(win);
},removeModalWindow:function(win){
this.modalWindows.pop();
if(this.modalWindows.length==0){
WindowUtilities.enableScreen();
}else{
if(Window.keepMultiModalWindow){
this.modalWindows.last().toFront();
WindowUtilities._showSelect(this.modalWindows.last().getId());
}else{
this.modalWindows.last().element.show();
}
}
},register:function(win){
this.windows.push(win);
},unregister:function(win){
this.windows=this.windows.reject(function(d){
return d==win;
});
},closeAll:function(){
this.windows.each(function(w){
Windows.close(w.getId());
});
},closeAllModalWindows:function(){
WindowUtilities.enableScreen();
this.modalWindows.each(function(win){
if(win){
win.close();
}
});
},minimize:function(id,_9a){
var win=this.getWindow(id);
if(win&&win.visible){
win.minimize();
}
Event.stop(_9a);
},maximize:function(id,_9d){
var win=this.getWindow(id);
if(win&&win.visible){
win.maximize();
}
Event.stop(_9d);
},close:function(id,_a0){
var win=this.getWindow(id);
if(win){
win.close();
}
if(_a0){
Event.stop(_a0);
}
},blur:function(id){
var win=this.getWindow(id);
if(!win){
return;
}
if(win.options.blurClassName){
win.changeClassName(win.options.blurClassName);
}
if(this.focusedWindow==win){
this.focusedWindow=null;
}
win._notify("onBlur");
},focus:function(id){
var win=this.getWindow(id);
if(!win){
return;
}
if(this.focusedWindow){
this.blur(this.focusedWindow.getId());
}
if(win.options.focusClassName){
win.changeClassName(win.options.focusClassName);
}
this.focusedWindow=win;
win._notify("onFocus");
},unsetOverflow:function(_a6){
this.windows.each(function(d){
d.oldOverflow=d.getContent().getStyle("overflow")||"auto";
d.getContent().setStyle({overflow:"hidden"});
});
if(_a6&&_a6.oldOverflow){
_a6.getContent().setStyle({overflow:_a6.oldOverflow});
}
},resetOverflow:function(){
this.windows.each(function(d){
if(d.oldOverflow){
d.getContent().setStyle({overflow:d.oldOverflow});
}
});
},updateZindex:function(_a9,win){
if(_a9>this.maxZIndex){
this.maxZIndex=_a9;
if(this.focusedWindow){
this.blur(this.focusedWindow.getId());
}
}
this.focusedWindow=win;
if(this.focusedWindow){
this.focus(this.focusedWindow.getId());
}
}};
var Dialog={dialogId:null,onCompleteFunc:null,callFunc:null,parameters:null,confirm:function(_ab,_ac){
if(_ab&&typeof _ab!="string"){
Dialog._runAjaxRequest(_ab,_ac,Dialog.confirm);
return;
}
_ab=_ab||"";
_ac=_ac||{};
var _ad=_ac.okLabel?_ac.okLabel:"Ok";
var _ae=_ac.cancelLabel?_ac.cancelLabel:"Cancel";
_ac=Object.extend(_ac,_ac.windowParameters||{});
_ac.windowParameters=_ac.windowParameters||{};
_ac.className=_ac.className||"alert";
var _af="class ='"+(_ac.buttonClass?_ac.buttonClass+" ":"")+" ok_button'";
var _b0="class ='"+(_ac.buttonClass?_ac.buttonClass+" ":"")+" cancel_button'";
var _ab="      <div class='"+_ac.className+"_message'>"+_ab+"</div>        <div class='"+_ac.className+"_buttons'>          <input type='button' value='"+_ad+"' onclick='Dialog.okCallback()' "+_af+"/>          <input type='button' value='"+_ae+"' onclick='Dialog.cancelCallback()' "+_b0+"/>        </div>    ";
return this._openDialog(_ab,_ac);
},alert:function(_b1,_b2){
if(_b1&&typeof _b1!="string"){
Dialog._runAjaxRequest(_b1,_b2,Dialog.alert);
return;
}
_b1=_b1||"";
_b2=_b2||{};
var _b3=_b2.okLabel?_b2.okLabel:"Ok";
_b2=Object.extend(_b2,_b2.windowParameters||{});
_b2.windowParameters=_b2.windowParameters||{};
_b2.className=_b2.className||"alert";
var _b4="class ='"+(_b2.buttonClass?_b2.buttonClass+" ":"")+" ok_button'";
var _b1="      <div class='"+_b2.className+"_message'>"+_b1+"</div>        <div class='"+_b2.className+"_buttons'>          <input type='button' value='"+_b3+"' onclick='Dialog.okCallback()' "+_b4+"/>        </div>";
return this._openDialog(_b1,_b2);
},info:function(_b5,_b6){
if(_b5&&typeof _b5!="string"){
Dialog._runAjaxRequest(_b5,_b6,Dialog.info);
return;
}
_b5=_b5||"";
_b6=_b6||{};
_b6=Object.extend(_b6,_b6.windowParameters||{});
_b6.windowParameters=_b6.windowParameters||{};
_b6.className=_b6.className||"alert";
var _b5="<div id='modal_dialog_message' class='"+_b6.className+"_message'>"+_b5+"</div>";
if(_b6.showProgress){
_b5+="<div id='modal_dialog_progress' class='"+_b6.className+"_progress'>  </div>";
}
_b6.ok=null;
_b6.cancel=null;
return this._openDialog(_b5,_b6);
},setInfoMessage:function(_b7){
$("modal_dialog_message").update(_b7);
},closeInfo:function(){
Windows.close(this.dialogId);
},_openDialog:function(_b8,_b9){
var _ba=_b9.className;
if(!_b9.height&&!_b9.width){
_b9.width=WindowUtilities.getPageSize(_b9.options.parent||document.body).pageWidth/2;
}
if(_b9.id){
this.dialogId=_b9.id;
}else{
var t=new Date();
this.dialogId="modal_dialog_"+t.getTime();
_b9.id=this.dialogId;
}
if(!_b9.height||!_b9.width){
var _bc=WindowUtilities._computeSize(_b8,this.dialogId,_b9.width,_b9.height,5,_ba);
if(_b9.height){
_b9.width=_bc+5;
}else{
_b9.height=_bc+5;
}
}
_b9.effectOptions=_b9.effectOptions;
_b9.resizable=_b9.resizable||false;
_b9.minimizable=_b9.minimizable||false;
_b9.maximizable=_b9.maximizable||false;
_b9.draggable=_b9.draggable||false;
_b9.closable=_b9.closable||false;
var win=new Window(_b9);
win.getContent().innerHTML=_b8;
win.showCenter(true,_b9.top,_b9.left);
win.setDestroyOnClose();
win.cancelCallback=_b9.onCancel||_b9.cancel;
win.okCallback=_b9.onOk||_b9.ok;
return win;
},_getAjaxContent:function(_be){
Dialog.callFunc(_be.responseText,Dialog.parameters);
},_runAjaxRequest:function(_bf,_c0,_c1){
if(_bf.options==null){
_bf.options={};
}
Dialog.onCompleteFunc=_bf.options.onComplete;
Dialog.parameters=_c0;
Dialog.callFunc=_c1;
_bf.options.onComplete=Dialog._getAjaxContent;
new Ajax.Request(_bf.url,_bf.options);
},okCallback:function(){
var win=Windows.focusedWindow;
if(!win.okCallback||win.okCallback(win)){
$$("#"+win.getId()+" input").each(function(_c3){
_c3.onclick=null;
});
win.close();
}
},cancelCallback:function(){
var win=Windows.focusedWindow;
$$("#"+win.getId()+" input").each(function(_c5){
_c5.onclick=null;
});
win.close();
if(win.cancelCallback){
win.cancelCallback(win);
}
}};
if(Prototype.Browser.WebKit){
var array=navigator.userAgent.match(new RegExp(/AppleWebKit\/([\d\.\+]*)/));
Prototype.Browser.WebKitVersion=parseFloat(array[1]);
}
var WindowUtilities={getWindowScroll:function(_c6){
var T,L,W,H;
_c6=_c6||document.body;
if(_c6!=document.body){
T=_c6.scrollTop;
L=_c6.scrollLeft;
W=_c6.scrollWidth;
H=_c6.scrollHeight;
}else{
var w=window;
with(w.document){
if(w.document.documentElement&&documentElement.scrollTop){
T=documentElement.scrollTop;
L=documentElement.scrollLeft;
}else{
if(w.document.body){
T=body.scrollTop;
L=body.scrollLeft;
}
}
if(w.innerWidth){
W=w.innerWidth;
H=w.innerHeight;
}else{
if(w.document.documentElement&&documentElement.clientWidth){
W=documentElement.clientWidth;
H=documentElement.clientHeight;
}else{
W=body.offsetWidth;
H=body.offsetHeight;
}
}
}
}
return {top:T,left:L,width:W,height:H};
},getPageSize:function(_c9){
_c9=_c9||document.body;
var _ca,windowHeight;
var _cb,pageWidth;
if(_c9!=document.body){
_ca=_c9.getWidth();
windowHeight=_c9.getHeight();
pageWidth=_c9.scrollWidth;
_cb=_c9.scrollHeight;
}else{
var _cc,yScroll;
if(window.innerHeight&&window.scrollMaxY){
_cc=document.body.scrollWidth;
yScroll=window.innerHeight+window.scrollMaxY;
}else{
if(document.body.scrollHeight>document.body.offsetHeight){
_cc=document.body.scrollWidth;
yScroll=document.body.scrollHeight;
}else{
_cc=document.body.offsetWidth;
yScroll=document.body.offsetHeight;
}
}
if(self.innerHeight){
_ca=self.innerWidth;
windowHeight=self.innerHeight;
}else{
if(document.documentElement&&document.documentElement.clientHeight){
_ca=document.documentElement.clientWidth;
windowHeight=document.documentElement.clientHeight;
}else{
if(document.body){
_ca=document.body.clientWidth;
windowHeight=document.body.clientHeight;
}
}
}
if(yScroll<windowHeight){
_cb=windowHeight;
}else{
_cb=yScroll;
}
if(_cc<_ca){
pageWidth=_ca;
}else{
pageWidth=_cc;
}
}
return {pageWidth:pageWidth,pageHeight:_cb,windowWidth:_ca,windowHeight:windowHeight};
},disableScreen:function(_cd,_ce,_cf,_d0,_d1){
WindowUtilities.initLightbox(_ce,_cd,function(){
this._disableScreen(_cd,_ce,_cf,_d0);
}.bind(this),_d1||document.body);
},_disableScreen:function(_d2,_d3,_d4,_d5){
var _d6=$(_d3);
var _d7=WindowUtilities.getPageSize(_d6.parentNode);
if(_d5&&Prototype.Browser.IE){
WindowUtilities._hideSelect();
WindowUtilities._showSelect(_d5);
}
_d6.style.height=(_d7.pageHeight+"px");
_d6.style.display="none";
if(_d3=="overlay_modal"&&Window.hasEffectLib&&Windows.overlayShowEffectOptions){
_d6.overlayOpacity=_d4;
new Effect.Appear(_d6,Object.extend({from:0,to:_d4},Windows.overlayShowEffectOptions));
}else{
_d6.style.display="block";
}
},enableScreen:function(id){
id=id||"overlay_modal";
var _d9=$(id);
if(_d9){
if(id=="overlay_modal"&&Window.hasEffectLib&&Windows.overlayHideEffectOptions){
new Effect.Fade(_d9,Object.extend({from:_d9.overlayOpacity,to:0},Windows.overlayHideEffectOptions));
}else{
_d9.style.display="none";
_d9.parentNode.removeChild(_d9);
}
if(id!="__invisible__"){
WindowUtilities._showSelect();
}
}
},_hideSelect:function(id){
if(Prototype.Browser.IE){
id=id==null?"":"#"+id+" ";
$$(id+"select").each(function(_db){
if(!WindowUtilities.isDefined(_db.oldVisibility)){
_db.oldVisibility=_db.style.visibility?_db.style.visibility:"visible";
_db.style.visibility="hidden";
}
});
}
},_showSelect:function(id){
if(Prototype.Browser.IE){
id=id==null?"":"#"+id+" ";
$$(id+"select").each(function(_dd){
if(WindowUtilities.isDefined(_dd.oldVisibility)){
try{
_dd.style.visibility=_dd.oldVisibility;
}
catch(e){
_dd.style.visibility="visible";
}
_dd.oldVisibility=null;
}else{
if(_dd.style.visibility){
_dd.style.visibility="visible";
}
}
});
}
},isDefined:function(_de){
return typeof (_de)!="undefined"&&_de!=null;
},initLightbox:function(id,_e0,_e1,_e2){
if($(id)){
Element.setStyle(id,{zIndex:Windows.maxZIndex+1});
Windows.maxZIndex++;
_e1();
}else{
var _e3=document.createElement("div");
_e3.setAttribute("id",id);
_e3.className="overlay_"+_e0;
_e3.style.display="none";
_e3.style.position="absolute";
_e3.style.top="0";
_e3.style.left="0";
_e3.style.zIndex=Windows.maxZIndex+1;
Windows.maxZIndex++;
_e3.style.width="100%";
_e2.insertBefore(_e3,_e2.firstChild);
if(Prototype.Browser.WebKit&&id=="overlay_modal"){
setTimeout(function(){
_e1();
},10);
}else{
_e1();
}
}
},setCookie:function(_e4,_e5){
document.cookie=_e5[0]+"="+escape(_e4)+((_e5[1])?"; expires="+_e5[1].toGMTString():"")+((_e5[2])?"; path="+_e5[2]:"")+((_e5[3])?"; domain="+_e5[3]:"")+((_e5[4])?"; secure":"");
},getCookie:function(_e6){
var dc=document.cookie;
var _e8=_e6+"=";
var _e9=dc.indexOf("; "+_e8);
if(_e9==-1){
_e9=dc.indexOf(_e8);
if(_e9!=0){
return null;
}
}else{
_e9+=2;
}
var end=document.cookie.indexOf(";",_e9);
if(end==-1){
end=dc.length;
}
return unescape(dc.substring(_e9+_e8.length,end));
},_computeSize:function(_eb,id,_ed,_ee,_ef,_f0){
var _f1=document.body;
var _f2=document.createElement("div");
_f2.setAttribute("id",id);
_f2.className=_f0+"_content";
if(_ee){
_f2.style.height=_ee+"px";
}else{
_f2.style.width=_ed+"px";
}
_f2.style.position="absolute";
_f2.style.top="0";
_f2.style.left="0";
_f2.style.display="none";
_f2.innerHTML=_eb;
_f1.insertBefore(_f2,_f1.firstChild);
var _f3;
if(_ee){
_f3=$(_f2).getDimensions().width+_ef;
}else{
_f3=$(_f2).getDimensions().height+_ef;
}
_f1.removeChild(_f2);
return _f3;
}};
if (typeof(Streamlined) == "undefined") {
  Streamlined = {}
}

Streamlined.Windows = {
  open_window: function(title_prefix, server_url, model) {
    if(model == null) {
      model = '00';
    }
    id = "show_win_" + model;
    if($(id)) {
        return;
    }
    win2 = new Window(id, {
      className: 'mac_os_x',
      title: title_prefix + " " + model,
      width:500, height:300, top:200, left: 200,
      zIndex:1001, opacity:1, resizable: true,
      hideEffect: Effect.Fade,
      url: server_url
    });
      win2.setDestroyOnClose();
      win2.show();
  },

  open_local_window: function(title_prefix, content, model) {
      id= "show_win_" + model;
      if($(id)) {
          return;
      }
    win2 = new Window(id, {
      className: 'mac_os_x',
      title: title_prefix + " " + model,
      width:500, height:300, top:200, left: 200,
      zIndex:1001, opacity:1, resizable: true,
      hideEffect: Effect.Fade
    });
    win2.getContent().innerHTML = content;
    win2.setDestroyOnClose();
    win2.show();
  },

  open_local_window_from_url: function(title_prefix, url, model) {
    new Ajax.Request(url, {
      method: "get",
      onComplete: function(request) {
        Streamlined.Windows.open_local_window(title_prefix, request.responseText, model);
      }
    });
  }
}
