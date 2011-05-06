Event.addBehavior({
  'td.vcard span.edit a:click' : function(){
    var id = this.href.sub(/.*posts\/(.*)\/edit.*/,"#{1}");
    if (!EditForm.isEditing(id)) {
      EditForm.init(id);
      new Ajax.Request(this.href, {
        evalScripts:true,
        method:'get'
      });
    }
    return false;
  }
});
var EditForm = {
  // show the form
  init: function(postId) {
    $('edit-post-' + postId + '_spinner').show();
    this.post = $('post-body-' + postId).innerHTML;
    this.clearReplyId();
  },

  // sets the current post id we're editing
  setReplyId: function(postId) {
    //$('edit').setAttribute('post_id', postId.toString());
    this.post_id = postId.toString();
    this.contents = $$('#edit form textarea')[0].innerHTML;
    $('posts-' + postId).addClassName('editing');
    if($('reply')) $('reply').blindUp({afterFinish: function(){$('reply').addClassName('hide')}});
  },

  // clears the current post id
  clearReplyId: function() {
    var currentId = this.currentReplyId();
    if(!currentId || currentId == '') return;
    if($('edit')) $('edit').up().insert(this.post);
    var row = $('posts-' + currentId);
    if(row) row.removeClassName('editing');
    //$('edit').setAttribute('post_id', '');
    this.post_id = '';
  },

  // gets the current post id we're editing
  currentReplyId: function() {
    //return $('edit').getAttribute('post_id');
    return this.post_id;
  },

  // checks whether we're editing this post already
  isEditing: function(postId) {
    if (this.currentReplyId() == postId.toString())
    {
      $('edit').show();
      $('edit_post_body').focus();
      return true;
    }
    return false;
  },

  // close reply, clear current reply id
  cancel: function() {
    this.clearReplyId();
    if($('edit')) $('edit').blindUp();
  }
}
Event.addBehavior({
  'a#post_reply:click': function(){
    ReplyForm.init();
    return false;
  },
  'input#monitor_checkbox:click': function(){
    if (this.checked) {
      new Ajax.Request(this.up().action, {
        evalScripts:true
      })
    } else {
      new Ajax.Request(this.up().action, {
        evalScripts:true,
        method:'delete'
    })}
  },
  'form[data-remote]:submit': function() {
    new Ajax.Request(this.action, {
      parameters: Form.serialize(this)
    });
    return false;
  },
  'a#cancel_reply:click': function(){
    $('reply').blindUp({afterFinish: function(){$('reply').addClassName('hide')}});
  }
 
});

var ReplyForm = {
  // yes, i use setTimeout for a reason
  init: function() {
    EditForm.cancel();
    if($('reply').hasClassName('hide')){
      $('reply').hide().removeClassName('hide').blindDown({transition: Effect.Transitions.spring});
    }
    if(!Prototype.Browser.IE){$('post_body').focus();}
    // for Safari which is sometime weird
//    setTimeout('$(\"post_body\").focus();',50);
  }
}
