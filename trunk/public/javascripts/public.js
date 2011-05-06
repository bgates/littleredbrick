document.observe('dom:loaded', setPageEffects);

function setPageEffects(){
  heightFix();
  if($('signup_submit')) submission();
}
function heightFix(){
  //get height of content_wrap and content; if content_wrap is too short, set its overflow to hidden and increase its height to be = content
  var minHeight = ($('content_wrap').getHeight() + parseInt($('content_wrap').getStyle('padding-top')));
  if(minHeight > (document.height || document.body.scrollHeight)){
    $('wrapper').setStyle({height: minHeight + 'px'});
  }
}
function submission(){
  Event.addBehavior({
    '#signup_submit:click' : function(){
      this.setAttribute('originalValue', this.value);
      this.disabled=true;
      this.value='Processing your order...';
      var result = (this.form.onsubmit ? (this.form.onsubmit() ? this.form.submit() : false) : this.form.submit());
      if (result == false) {
        this.value = this.getAttribute('originalValue');
        this.disabled = false }
      return result;
    }
  });
}
