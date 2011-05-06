document.observe('dom:loaded', setPageEffects);

function setPageEffects(){
  if($('signup_submit')) prepareSignup();
  flash();
  heightFix();
}
function prepareSignup(){
  removeErrorOnChange();
  var trialExpirationDate = new Date();
  trialExpirationDate.setDate(trialExpirationDate.getDate()+30);
  var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  var address = '<h3>You will log in at this address</h3>' +
	        '<p>http://<span id="site_address">NAME</span>.littleredbrick.com</p>'
  if($('agreement')){
    var text = '<h3>Your plan is $<span class="cost"></span>/month</h3>' +
           '<p><span class="highlight">You will be billed at the end of each month.</span> If you keep your account open past that time you&#39;ll be charged $<span class="cost"></span>/month for the service. If you don&#39;t want to continue using the service, just cancel before you&#39;re billed on ' + months[trialExpirationDate.getMonth()] + ' ' + trialExpirationDate.getDate() + ', ' + trialExpirationDate.getFullYear() + ' and you won&#39;t be charged. We will contact you during the month to arrange payment.</p>' +
	   '<h3>The service is month-to-month, cancel at any time</h3>' +
	   '<p>You will not have to pay sign-up fees or cancellation fees, or sign long-term contracts.</p>' + address
    $('agreement').down().insert({ after: text});
    var limit = $('school_teacher_limit');
    (setCost.bind(limit))();
    Event.observe(limit, 'change', setCost.bind(limit));
  } else {
    var text = '<h3>Your plan is Free</h3>' +
               '<p><span class="highlight">You can allow all of your students, their parents, and any of your school&#39;s administrators access to the account you are setting up.</span> Parents may only see grade and assignment information for their own children, and students may only see information about themselves.</p>' +
               '<h3>You can upgrade to let your entire school use the service at any time</h3>' +
               '<p>If other teachers at your school would like to sign up with you, teacher accounts can be created at a cost of $10/month, per teacher. You will not have to pay sign-up fees or cancellation fees, or sign long-term contracts.</p>' + address
    $('personal_agreement').down().insert({ after: text});
  }
  var name = $('school_domain_name');
  (setAddress.bind(name))();
  Event.observe(name, 'change', setAddress.bind(name));
  var button = $('signup_submit');
  button.disable();
  button.setStyle({color: '#bbb'});
  Event.observe(button, 'click', signup.bind(button));
  Event.observe($('signup_accepts_eula'), 'click', signupToggle.bind(button));
}
function setAddress(){
  $('site_address').innerHTML = $F(this)
}
function setCost(){
  var cost = $F(this);
  $$('.cost').each(function(elm){
    elm.innerHTML = cost + '0';
  })
}
function signup(){
  Password.conditionalMirror();
  this.setAttribute('originalValue', this.value);
  this.disabled=true;
  this.value='Processing your order...';
  result = (this.form.onsubmit ? (this.form.onsubmit() ? this.form.submit() : false) : this.form.submit());
  if (result == false) {
    this.value = this.getAttribute('originalValue');
    this.disabled = false }
  return result;
}
function signupToggle() {
  if($F('signup_accepts_eula') == '1'){
    this.enable();
    this.setStyle({color: '#666'})
  } else {
    this.disable();
    this.setStyle({color: '#bbb'})
  }
}
function removeErrorOnChange(){
  Event.addBehavior({
    'input:focus' : function(){
      this.removeClassName('fieldWithErrors');
    }
  });
}
function heightFix(){
  //get height of content_wrap and content; if content_wrap is too short, set its overflow to hidden and increase its height to be = content
  var currentHeight = $('content_wrap').getHeight();
  var minHeight = (currentHeight + parseInt($('content_wrap').getStyle('padding-top')));
  if(minHeight > (document.height || document.body.scrollHeight)){
    if(Prototype.Browser.IE){
      var desiredHeight = $('wrapper').descendants().invoke('getHeight').max();
      $('wrapper').setStyle({height: desiredHeight + 'px'});
      $('content_wrap').setStyle({height: currentHeight});
    } else {
      $('wrapper').setStyle({height: minHeight + 'px'});
    }
  }
}
function flash(){
  if($('notice')){ flashForward() }
  if($('error')){ flashError() }
  if($('errorExplanation')){ flashErrorX() }
}
function flashError(){
  var forward = new Effect.Transform([{'#error': 'background:#a35858;color:#fff8f8;border:#a35858;'}, {'#error *': 'background:#a35858;color:#fff8f8;'}], {afterFinish: flashErrorRevert()});
  forward.play();
}
function flashErrorRevert(){
  var rev = new Effect.Transform([{'#error': 'background:#fff8f8;color:#a35858;border:#bd6666;'}, {'#error *': 'background:#fff8f8;color:#a35858;'}], {queue: 'end', delay: 1});
  rev.play();
}
function flashErrorX(){
  var forward = new Effect.Transform([{'#errorExplanation': 'background:#bd6666;color:#fff;border:#bd6666;'}, {'#errorExplanation p': 'color:#fff8f8;'}, {'#errorExplanation ul li': 'color:#fff8f8;'}, {'#errorExplanation h2': 'color:#fff;'}], {afterFinish: flashErrorRevertX()});
  forward.play();
}
function flashErrorRevertX(){
  var rev = new Effect.Transform([{'#errorExplanation': 'background:#fff8f8;color:#a35858;border:#bd6666;'}, {'#errorExplanation h2': 'background:#bd6666;color:#fff8f8;'}, {'#errorExplanation p': 'color: #a35858'}, {'#errorExplanation ul li': 'color: #a35858'}], {queue: 'end', delay: 1});
  rev.play();
}
function flashForward(){
  var forward = new Effect.Transform([{'#notice': 'background:#4a7f8a;color:#f8f8ff;border:#4a7f8a'}, {'#notice *': 'background:#4a7f8a;color:#f8f8ff;'}], {afterFinish: flashRevert()});
  forward.play();
}
function flashRevert(){
  var rev = new Effect.Transform([{'#notice': 'background:#f8f8ff;color:#4a7f8a;border:#66aebd;'}, {'#notice *': 'background:#f8f8ff;color:#4a7f8a;'}], {queue: 'end', delay: 1});
  rev.play();
}
