Prototype.Browser.IE6 = Prototype.Browser.IE && parseInt(navigator.userAgent.substring(navigator.userAgent.indexOf("MSIE")+5)) == 6;

Prototype.Browser.IE8 = Prototype.Browser.IE && !Prototype.Browser.IE6 && (function(){ 
  var elem = document.createElement('div');
  elem.innerHTML = '<!--[if IE 7]><div class="ie7"></div><![endif]--><!--[if IE 8]><div class="ie8"></div><![endif]-->';
  var __IE__ = parseInt(elem.firstChild.className.substring(2), 0);
  elem = null;
  return __IE__ == 8
  })();

document.observe('dom:loaded', setPageEffects);
//TODO: gzip this and css
//TODO: general form submission that blocks resubmissions
//TODO: selecting filled input clears text or at least highlights it all
function setPageEffects(){
  unscrollable();
  flash();
  if ($('administrators_index')) deleteWarningAdmin();
  if ($('assignments_edit') || $('assignments_update')) deleteWarningAssignment();
  if ($$('body[id*=select]').size() > 0 || $('enter_upload') || $('teaching_load_upload')) prepProgressBar1();//or if there's an error
  if ($$('body[id*=describe]').size() > 0) prepProgressBar2();
  if ($('department_initial')) setupCatalog();
  if ($('departments_edit') || $('departments_new') || $('departments_create')) setAddSubjectLink();
  if ($('enter_details')) insertAddRowLink();
  if ($('events_index')) eventToggler();
  if ($('events_edit') || $('events_update')) deleteWarningEvent();
  if ($('first_row_toggle')) toggleFirstRow();
  if ($('forums_edit') || $('forums_update')) deleteWarningForum();
  if ($('gradebook_show') || $('gradebook_update')) setupGradebook();
  //var fileInputs = $$('#content input[type="file"]'); skip because of browser inconsistency
  //if (fileInputs.size() > 0 && Prototype.Browser.Gecko) setupFileInputs(fileInputs);
  var inputs = $('content').select('input');
  if (inputs.size() > 0) removeErrorOnChange();
  if ($('marks_edit') || $('marks_update')) deleteWarningMark();
  if ($('parents_edit') || $('parents_update')) deleteWarningParent();
  if ($('progress_graph')) resizeProgressGraph();
  if ($('reported_grades_index')) setReportedGradeForms();
  if ($('rollbook_sort')) createSortable($('list'));
  if ($('search') || $('staging_show')) setSearchAutocomplete();
  if ($('sections_show')) {deleteWarningEnrollment(); setUnenrollmentLink();}
  if ($('students_edit') || $('students_update')) deleteWarningStudent();
  if ($('students_show')) setupGradeProgression();
  if ($('teachers_edit') || $('teachers_update')) deleteWarningTeacher();
  if ($('teaching_load_edit') || $('teaching_load_new')) teachingLoad();
  if ($('terms_show')) deleteWarningMP();
  if ($('topics_edit') || $('topics_update')) deleteWarningTopic();
  if ($('tracks_edit') || $('tracks_update')) {setNextMarkingPeriod();deleteWarningTrack();}
  if ($('styleswitch')) Event.addBehavior({
    '#styleswitch a:click' : function(){
      var title = this.href.toQueryParams()['stylesheet'];
      activeCSS(title);
      return false}
  });
  if ($('unenroll_button')) deleteWarningEnrollmentTwo();
  if ($('users_show')) deleteWarningModerator();
  if ($('video')){
    obj=document.getElementsByTagName('object');
    for (var i=0; i<obj.length; ++i)
      obj[i].outerHTML=obj[i].outerHTML;
    setTimeout("var frames = document.getElementsByTagName('embed')[0].TotalFrames(); var min = parseInt(frames/600);var sec = (frames / 600 - min)*60;console.log(min + ':' + sec);",2000);
  }
}
function activeCSS(title){
  $A(document.getElementsByTagName("link")).each(function(stylesheet){
    if ($(stylesheet).readAttribute("title") && stylesheet.readAttribute("rel").match("stylesheet" + "\\b")) {
      stylesheet.disabled = true;
      if(stylesheet.readAttribute("title") == title) {
        stylesheet.disabled = false;
      }
    }
  });
  new Ajax.Request('/session/style?stylesheet=' + title);
}
function createSortable(elm){
  new Insertion.After($$('h2')[0], '<p>Click and drag a name to move it in the list. When the names are in the proper order, click "return to gradebook". If you simply want to alphabetize the entire list, click the "Alphabetize" button.</p>');
  Sortable.create(elm, {
    onUpdate: function(){
      new Ajax.Request(elm.up().action,
      {
        evalScripts: true,
        parameters: Sortable.serialize(elm)
      })
    }
  })
}
function deleteWarning(msg, form){
  Event.observe(form, 'submit', function(event) {
    Event.stop(event);
    deleteWarningSend(msg, form);
  });
}
function deleteWarningSend(msg, form) {
    Dialog.confirm("<div id='errorExplanation'><h2>Warning</h2><p>" + msg + "</p></div>", {
      zIndex: 1001,
      width: 300,
      okLabel: "Delete",
      buttonClass: "button",
      className: 'error',
      destroyOnClose: true,
      id: "deleteDialog",
      showEffect: Effect.Grow,
      showEffectOptions: {transition: Effect.Transitions.spring, duration: 1},
      hideEffect: Effect.Shrink,
      hideEffectOptions: {duration: 1},
      cancel: function(win) {return false},
      ok: function(win) {
        var button = $$('#deleteDialog input')[0];
        button.value = '......';
        button.disable();
        new Ajax.Request(form.action, {
          evalScripts: true,
          parameters: Form.serialize(form),
          onComplete: function(){ Dialog.closeInfo()}
        });
      }
    });
}
function deleteWarningAdmin(){
  $$('.button-to').each(function(form){
    var msg = form.down('input.button').hasClassName('teacher') ? 'Are you sure you want to delete this teacher&#39;s administrative privileges? The teacher will still be able to log in and edit personal data, grades, and assignments, but will not be allowed to edit other school or term data.' : 'Are you sure you want to delete this account? Doing so will prevent this user from logging in again.';
    deleteWarning(msg, form);
  });
}
function deleteWarningAssignment(){
  $$('.button-to').each(function(form){
    var msg = 'Are you sure you want to delete this assignment? All the grades for it will be destroyed as well. (Student marking period grades will be recalculated automatically to account for the removal of the assignment.)';
    deleteWarning(msg, form);
  });
}
function deleteWarningEnrollment(){
  $$('form.button-to').each(function(form){
    var student = form.next().innerHTML.split(/,\s*/).reverse().join(' ');
    deleteWarning("Removing " + student + " from the class will destroy all records of his/her grades for the class. You should do this only if you are sure " + student.split(' ')[0] + " was enrolled by mistake, or all the grades have been recorded elsewhere.", form);
  });
}
function deleteWarningEnrollmentTwo(){
  var form = $$('form')[0];
  var student = $$('h1 a')[0].innerHTML;
  deleteWarning("Removing " + student + " from the class will destroy all records of his/her grades for the class. You should do this only if you are sure " + student.split(' ')[0] + " was enrolled by mistake, or all the grades have been recorded elsewhere.", form);
}
function deleteWarningEvent(){
  var form = $$('.button-to')[0];
  deleteWarning("Are you sure you want to delete this event?", form);
}
function deleteWarningForum(){
  var form = $$('.button-to')[0];
  deleteWarning("Destroying this forum will destroy all the topics and messages contained in it. You should do this only if there is nothing worthwhile in the entire forum.", form);
}
function deleteWarningMark(){
  var form = $$('.button-to')[0];
  if(form){deleteWarning("Destroying this mark will destroy all student records of it in this class. You should do this only if the mark is not needed.", form);}
}
function deleteWarningModerator(){
  $$('.button-to').each(function(form){
    deleteWarning("Are you sure you want to delete this user&#39;s moderation privileges? The user will still be able to participate in this forum, but will not be allowed to edit or delete posts by other users.", form);
  });
}
function deleteWarningMP(){
  if($('remove_mp_button') == null) return;
  var mps = $('remove_mp_button').up(4).down('thead').down().next().immediateDescendants().length - 2;
  if(mps < 2) return;
  var form = $('remove_mp_button').up();
  deleteWarning("Deleting marking period " + mps + " will move all assignments created for this marking period to marking period " + (mps - 1) + ", and all teacher records for marking period " + mps + " overall grades will be destroyed. You should do this only if you are sure those grades are not needed, or have been recorded elsewhere.", form);
}
function deleteWarningParent(){
  var parent = $('parent_first_name').value + ' ' + $('parent_last_name').value;
  var parent_form = $('delete_parent');
  if(parent_form){
    deleteWarning('Deleting this account will prevent anyone from logging in as ' + parent + ' . You should do this only if no one will use the account.', parent_form.up());
  } else{
    $$('.child').each(function(button){
      deleteWarning('Deleting this relationship will mean that ' + parent + ' may no longer check the performance of this student. Doing this will not remove either the parent or child accounts.', button.up());
    });
  }
}
function deleteWarningReportedGrade(){
  $$('.button.delete').each(function(button){
    deleteWarning('Deleting this grade will destroy all teacher records of the grade in every section in this term. You should do this only if you are sure those grades are not needed, or have been recorded elsewhere.', button.up());
  });
}
function deleteWarningSection(link){
  var form = $form({
    action: link.href,
    method: 'post',
    style: 'display:none'},
    $input({
      name: '_method',
      value: 'delete'}
    )
  );
  new Insertion.After(link, form);
  deleteWarningSend('Deleting this section will destroy all records of its assignments and grades. You should not do this unless the section no longer exists, and any transfer grades have already been accounted for in other classes.', form);
}
function deleteWarningStudent(){
  var form = $('delete_student').up();
  deleteWarning("Deleting this student will destroy all of his/her grade records for all classes. You should do this only if the student is not enrolled at the school.", form);
}
function deleteWarningTeacher(){
  var form = $('delete_teacher').up();
  deleteWarning("Deleting this teacher will destroy all of his/her grade records for all classes. You should do this only if the teacher has no active classes.", form);
}
function deleteWarningTopic(){
  var form = $$('.button-to')[0];
  deleteWarning("Are you sure you want to delete this topic? That will also destroy all the posts made in response to it.", form);
}
function deleteWarningTrack(){
  if($('delete_track') == null) return ;
  var form = $('delete_track').up();
  deleteWarning("Deleting this track will destroy all sections created for it. You should do this only if you are sure records for this track are not needed or have been recorded elsewhere.", form);
}
function eventToggler(){
  Event.addBehavior({
    'input:click' : function(){
      var a = $$('a.' + this.classNames());
      if(a[0] && a[0].visible()){
        a.invoke('blindUp');
      } else {
        a.invoke('blindDown',{transition: Effect.Transitions.spring});
      }
    }
  });
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
function heightFix(){
  //get height of content_wrap and content; if content_wrap is too short, set its overflow to hidden and increase its height to be = content
  var minHeight = ($('content_wrap').getHeight() + parseInt($('content_wrap').getStyle('padding-top')));
  if(minHeight > (document.height || document.body.scrollHeight)){
    $('wrapper').setStyle({height: minHeight + 'px'});
  }
}
function insertAddRowLink(){
  if($$('#enter_details_table tr').all(function(row){return row.select('.fieldWithErrors').length > 0})) {
    var insert = $tr({style: 'display:none'}, $td($a({href: '#insertable', id: 'insertion'}, 'Add more')));
    new Insertion.Bottom($('enter_details_table'), insert);
    insert.appear();
    Event.observe('insertion', 'click', function(event) {
      var template = $('insertion').up(1).previous().innerHTML;
      var replace = /\d\d/.exec(template)[0];
      var replacement = parseInt(replace)+1;
      var insertable = '<tr>' + template.replace(/([[_])\d+/g, '$1' + replacement) + '</tr>';
      new Insertion.Before(insert,insertable);
    });
  }
}
function observeForm(elm, method){
  new Form.EventObserver(elm, function(element, value) {
    element.disable();
    new Ajax.Request(element.action, {
      method: method,
      evalScripts: true,
      parameters: value,
      onComplete: function(){element.enable()}
    });
  });
}
function prepProgressBar1(){
  var btn = $$('form input[value="Upload"]')[0];
  btn.disable();
  Event.addBehavior({
    'form input[type="file"]:click' : function(){
      var btn = $$('form input[value="Upload"]')[0];
      btn.enable();
    },
    'form input[value="Upload"]:click' : function(){
      progressBar();
    }
  });
}
function prepProgressBar2(){
  Event.addBehavior({
    'form:submit' : function(){
      progressBar()
    }
  });
}
function progressBar(){
  Dialog.alert("<p>Uploading. One moment please....<br><img src=\"/images/progressbar_long_green.gif\" title='Not long now...' id='hack'></p>", {
    zIndex: 1001,
    width: 300,
    okLabel: "Cancel",
    buttonClass: "button",
    id: "modal_notice",
    destroyOnClose: true,
    showEffect: Effect.Grow,
    showEffectOptions: {transition: Effect.Transitions.spring, duration: 1},
    hideEffect: Effect.Shrink,
    hideEffectOptions: {duration: 1},
    ok: function(win) {return true}
  });
  $('hack').src = '/images/none';
  $('hack').src = '/images/progressbar_long_green.gif';
}
function removeErrorOnChange(){
  Event.addBehavior({
    'input:focus, textarea:focus, select:focus' : function(){
      this.removeClassName('fieldWithErrors');
    }
  });
}
function resizeProgressGraph() {
  if($('content').getWidth() * 0.38 < 300){ 
    $('progress_graph').setStyle({
      width: ($('content').getWidth() * 0.36 + 'px'),
      margin: 0
    })
  }
}
function safariAndIE8DoNotNeedChange(){
  return !Object.isElement($('enter_describe_file')) && !Object.isElement($('enter_import_users')) && !Object.isElement($('rollbook_describe_file')) && !Object.isElement($('rollbook_import_enrollment')) && !Object.isElement($('students_index')) && !Object.isElement($('teachers_index'));
}
function setAddSubjectLink(){
  Event.addBehavior({
    '#new_subject:click' : function(){
      var n = (this.classNames().toArray()[0] || '');
      var input = $li({
        style: 'display: none'},
        $input({
          id: 'department_new_subjects_name',
          type: 'text',
          size: '30',
          name: 'department[new_subjects][][name]'
        })
      );
      this.insert({ before: input});
      this.previous().grow({direction: 'top-left', transition: Effect.Transitions.spring, duration: 3});
      return false
    }
  });
}
function setNextMarkingPeriod(){//this isn't working - the calendar setting the input value doesn't register as a change event for some reason
  $$('input[name]').each(function(elm){
    if(elm.name.match(/finish/) && elm.up(4).next()) {
      Event.observe(elm, 'change', function(){
        date = parseDateString(elm.value);
        date.setDate(date.getDate()+1);
        if(date.getDay() > 5) {date.setDate(date.getDate()+1)}
        if(date.getDay() == 0) {date.setDate(date.getDate()+2)}
        nextDate = (date.getFullYear() + '-' + (date.getMonth() + 1) + '-' + date.getDate());
        elm.up(4).next().down().next(1).down(3).value = nextDate;
      });
    }
  });
}
function setReportedGradeForms() {
  Event.addBehavior({
    '#list a:click' : function(){
      if(this.hasClassName('cancel')){
        this.up(3).hide();
        this.up(3).previous().show();
      } else {
        this.hide();
        this.next().show();
      }
      return false
    },
    '#insert_form:submit' : function(){
      var text = Form.serialize(this);
      this.disable();
      var form = this;
      new Ajax.Request(form.action, {
        evalScripts: true,
        parameters: text,
        onSuccess: function(){form.enable()}
      });
      return false
    },
    '#list form.edit:submit' : function () {
      var text = Form.serialize(this);
      this.disable();
      var form = this;
      new Ajax.Request(form.action, {
        evalScripts: true,
        parameters: text,
        onSuccess: function(){form.enable()}
      });
      return false
    }
  });
  deleteWarningReportedGrade();
}
function setSearchAutocomplete(){
  var AutoCompletable = Behavior.create({
    initialize: function() {
      this.element.insert({
        after: $div({ className: "auto_complete" })
      });
      var search = this.element.up().action;
      var create = search.sub(/search/,'');
      new Ajax.Autocompleter(this.element, this.element.next(".auto_complete"), search, {
        minChars: 3,
        method: 'get',
        onShow: function(element, update){
          Position.clone(element, update, {setHeight: false, setLeft: false, setTop: false});
          Effect.Appear(update,{duration:0.15});
        },
        afterUpdateElement: function(element, value){
          element.up().disable();
          new Ajax.Request(create, {
            method: 'post',
            parameters: {id: value.id},
            onComplete: function(){element.up().enable();element.clear()}
          })
        }
      });
    }
  });
  if($('search')){Event.addBehavior({'#search': AutoCompletable()})}
  Event.addBehavior({'.search': AutoCompletable()});
}
function setUnenrollmentLink(){
  Event.addBehavior({
    '#unenrollment:click' : function(){
      if($$('form.button-to input[style]').toArray()[0].visible()) {
        $$('form.button-to input[style]').each(function(f){ Effect.Shrink(f, {direction:'bottom-left'})});
        this.innerHTML = 'Remove student';
      } else {
        $$('form.button-to input[style]').each(function(f){ Effect.Grow(f, {direction:'bottom-left'})});
        this.innerHTML = 'stop';
        var dialog = Dialog.alert("<p>To unenroll a student, click the <img src='/images/sub_16.png' title='delete symbol'> beside his/her name.</p>", {
          zIndex: 1001,
          width: 300,
          okLabel: "OK",
          buttonClass: "button",
          id: "modal_notice",
          destroyOnClose: true,
          showEffect: Effect.Grow,
          showEffectOptions: {transition: Effect.Transitions.spring, duration: 1},
          hideEffect: Effect.Shrink,
          hideEffectOptions: {duration: 1},
          ok: function(win) {return true}
        });
      }
      return false;
    }
  });
}
function setupCatalog() {
  $$('#content .new_department').each(function(dt){
    var delete_link = $a({
      href: 'javascript:void(0)',
      title: 'Delete department',
      className: 'delete_dept'},
      'remove'
      );
      dt.insert({bottom: delete_link});
  });
  $$('#content .subjects').each(function(ul){
    var insert_link = $li($a({
      href: 'javascript:void(0)',
      title: 'Add subject',
      className: 'add_sub'},
      'add subject'
      ));
      ul.down().insert({bottom: insert_link})
  });
  Event.addBehavior({
  'a.delete_dept:click' : function(){
    var row = this.up(1);
    var tbody = row.up();
    row.shrink({queue: 'front'});
    row.nextSiblings().invoke('toggleClassName', 'odd');
    row.nextSiblings().invoke('toggleClassName', 'even');
    row.remove({queue: 'end', delay: 5});
    return false;
  },
  'a.add_sub:click': function(){
     var li = this.up();
     var id = new Date().getTime();
     var subj_input = this.up().previous('li').down().clone();
     subj_input.id = subj_input.id.replace(/\d+(?!.*\d+)/, id);
     subj_input.value = '';
     subj_input.name = subj_input.name.replace(/\d+(?!.*\d+)/, id);
     var ins = $li({style: 'display:none;'}, subj_input);
     li.insert({ before: ins});
     li.previous().grow({direction: 'bottom-left', transition: Effect.Transitions.spring, duration: 3});
  },
  'a#new_department:click': function(){
    var depts = $$('tbody tr');
    var id = new Date().getTime();
    var striped = (depts.length) % 2 == 0 ? 'odd' : 'even';
    var dept_input = depts[0].down(1).clone();
    dept_input.id = dept_input.id.replace(/\d+/, id);
    dept_input.value = '';
    dept_input.name = dept_input.name.replace(/\d+/, id);
    var dept = $td({className: 'department'},
        dept_input
    );
    var subj_input = depts[0].down().next().down(2).clone();
    subj_input.id = subj_input.id.replace(/\d+/g, id);
    subj_input.value = '';
    subj_input.name = subj_input.name.replace(/\d+/g, id);
    var subj = $td({className: 'subject'},
      $ul({},
      $li(subj_input),
      $li($a({
      href: 'javascript:void(0)',
      title: 'Add subject',
      className: 'add_sub'},
      'add subject'
      )))
    );
    var row = $tr({className: striped, style: 'display:none'}, dept, subj);
    $$('#subjects tbody')[0].insert({bottom: row});
    if(Prototype.Browser.IE6){
      row.setStyle({display: 'block'});
    } else if(Prototype.Browser.IE) {
      row.setStyle({display: 'table-row'});
    } else {
      row.grow({direction: 'top-left', transition: Effect.Transitions.spring, duration: 3});
    }
    Event.addBehavior.reload();
    return false;
  }
  });
}
function setupFileInputs(fileInputs){
  Element.remove('original');
  var fakeFileUpload = $div({
    className: 'fakefile'},
    $input(),
    $img({
      src: '/images/browse.png'
    }),
    $input({
      type: 'submit',
      className: 'button',
      value: 'Upload',
      name: 'Upload',
      style: 'margin: 5px 0 2px 5px'
    })
  );
  fileInputs.each(function(elm){
    if (elm.parentNode.className == 'fileinputs') $continue;
    elm.className = 'file hidden';
    var clone = fakeFileUpload.cloneNode(true);
    elm.parentNode.appendChild(clone);
    elm.relatedElement = clone.getElementsByTagName('input')[0];
    elm.onchange = elm.onmouseout = function () {
      this.relatedElement.value = this.value;
    }
  });
}
function setupGradebook(){
  Event.addBehavior({
    'input:focus' : function(){
      if(this.value == '-') this.value = '';
    }
  })
}
function teachingLoad(){
  observeForm('department', 'get');
  var indicator = $img({
    src: '/images/indicator_16.gif',
    style: 'display:none;clear:both;position:absolute;left: 2em'
  });
  $('add_link').insert({ after: indicator});
  teachingLoadReset();
  var button = $$('#sections input.button')[0];
  Event.observe(button, 'click', teachingLoadSubmit.bind(button));
  Event.addBehavior({
    '.delete:click': function(){ deleteWarningSection(this);return false}
  });
}
function teachingLoadSubmit(){
  this.setAttribute('originalValue', this.value);
  this.disabled=true;
  this.value='...';
  result = (this.form.onsubmit ? (this.form.onsubmit() ? this.form.submit() : false) : this.form.submit());
  if (result == false) {
    this.value = this.getAttribute('originalValue');
    this.disabled = false }
  return result;
}
function teachingLoadReset(){
  Event.addBehavior({
      '#add_link:click': function(){
      this.fade();
      this.next('img').appear();
      new Ajax.Request(this.href, {
        evalScripts: true,
        parameters: Form.serialize($('department')),
        method: 'get',
        onComplete: function(){
          var link = $('add_link');
          link.next('img').fade();
          link.appear()
        }
      });
      return false;
    },
    '.new_section:click': function(){
      var hack = this;
      this.up(1).squish({afterFinish: function(){hack.up(1).remove()}});
      return false;
    }
  });
}
function toggleFirstRow(){
  var row = $$('thead tr').last();
  toggleThe(row, ($('header_row').getValue() == 'true'));
  Event.addBehavior({
    '#header_row:click': function(){
      toggleThe(row, true);
    }
  });
  function toggleThe(row, condition){
    if(!$('first_row')){
      var replacement = $tr({className: 'even', id: 'first_row', style: 'display: none'}); 
      row.immediateDescendants().each(function(elm){replacement.appendChild($td(elm.innerHTML.strip()))});
      replacement.firstDescendant().addClassName('text');
      new Insertion.Top($$('tbody')[0], replacement);
    }
    if(condition){
      row.toggle();
      $('first_row').toggle();
    }
  }
}
function unscrollable(){
  if(Prototype.Browser.WebKit || Prototype.Browser.KHTML || Prototype.Browser.IE8){
    if(safariAndIE8DoNotNeedChange()){
      $$('.scrollableTable').invoke('addClassName', 'scrollike');
      $$('.scrollableTable table').invoke('setStyle', 'width: 100%');
      $$('.scrollableTable').invoke('removeClassName', 'scrollableTable');
    }
    var gradebook = 0;
    if($('gradebook_show') || $('gradebook_update') || $('sections_show') || $('enter_describe_file') || $('rollbook_describe_file')){
      var gradebook = 1;
      var notice = ($('notice'))? $('notice') : $('error');
      if(notice){
        var gradebook = notice.getHeight();
        if($('sections_show')){
          var preceding_elm = $$('table')[0];
        } else {
          var preceding_elm = $$('form')[0];
        }
        preceding_elm.insert({before: notice.remove()});
      }
    } 
    if($('marks_index')){
      var gradebook = 1;
      var notice = ($('notice'))? $('notice') : $('error');
      if(notice){
        var gradebook = notice.getHeight();
        $$('.scrollike')[0].insert({before: notice.remove()});
      }
    } 
    if($('enter_describe_file') || $('rollbook_describe_file') || $('gradebook_describe_file')){
      $('wrapper').setStyle({height: $$('table')[0].getHeight() + 200 + 'px'});
    }
    heightFix();
    if(gradebook > 0) {
      var table = $$('table')[0];
      var wrapper = $('wrapper');
      var newHeight = table.getHeight() + table.cumulativeOffset()[1] + gradebook;
      if(wrapper.getHeight() < newHeight){
        $('wrapper').setStyle({height: (newHeight)/12 + 'em'});
      }
    }
  }
  else {
    heightFix();
  }
}
function whiteout(obj) {
  var selected_index = obj.options[obj.selectedIndex].index;
  var selects = document.getElementsByClassName('columns');
  var selectArray = $A(selects.without(obj));

  for (var i = 0; i < obj.options.length; i++) {
      if (obj.options[i].value == 'First name') var first = i;
      if (obj.options[i].value == 'Last name') var last = i;
      if (obj.options[i].value == 'Full name') var full = i;
      if (obj.options[i].value == 'Name(last, first)') var lf = i;
    }
  var v = obj.options[obj.selectedIndex].value;
  selectArray.each( function(selector) {
    if(selector.options[selector.selectedIndex].index == selected_index) {
      selector.options[0].selected = true;
    }
    if(v != 'Ignore') {
      selector.options[selected_index].style.color = '#999999';
      selector.options[selected_index].disabled = true;
      }
    var check_options = $A(selector.options);
    check_options.each( function(opt) { //find the option that has just been deselected, and enable it for the other selects
      if(opt.disabled == true && obj[opt.index].disabled == false && obj[opt.index].selected == false) {
        opt.disabled = false;
        opt.style.color = '#000000';
      }
    });
    if(v == 'First name' || v == 'Last name') {
      [full,lf].each(function(a_name) {
      selector.options[a_name].style.color = '#999999';
      selector.options[a_name].disabled = true;
        });
      }
    if(v == 'Full name' || v == 'Name(last, first)') {
      [first,last,full,lf].each(function(a_name) {
      selector.options[a_name].style.color = '#999999';
      selector.options[a_name].disabled = true;
        });
      }
  });
}
TableKit.Sortable.addSortType(new TableKit.Sortable.Type('date-us-2', {
  pattern: /^(?:sun|mon|tue|wed|thu|fri|sat)\,?\s(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s\d{1,2}(\s\d{4})?(?:\s\d{2}\:\d{2}(?:\:\d{2})?(?:\sGMT(?:[+-]\d{4})?)?)?/i, //Mon, Dec 18 1995 17:28:35pm
  normal: function(v) {
    if(!this.pattern.test(v)) {return 0;}
    var r = v.match(/^(?:sun|mon|tue|wed|thu|fri|sat)\,?\s(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s(\d{1,2})(\s\d{4})?(?:(\d{1,2})\:(\d{2})(?:\:(\d{2}))?\s?([a|p]?m?))?/i);
    var mo_num = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'].indexOf(r[1].toLowerCase()) + 1;
    var day_num = parseInt(r[2], 10);
    var yr_num = r[3] ? r[3] : new Date().getYear() + 1900;
    var hr_num = r[4] ? r[4] : 0;
    if(r[7] && r[7].toLowerCase().indexOf('p') !== -1) {
      hr_num = parseInt(r[4],10) + 12;
    }
    var min_num = r[5] ? r[5] : 0;
    var sec_num = r[6] ? r[6] : 0;
    return new Date(yr_num, mo_num, day_num, hr_num, min_num, sec_num, 0).valueOf();
  }
}));
TableKit.Sortable.detectors = $w('date-us-2 date-iso date date-eu date-au time currency datasize number casesensitivetext text');
