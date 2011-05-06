document.observe('dom:loaded', setPasswordEffects);

function setPasswordEffects(){
  if ($('password_label')) {
    Password.init();
  }
}
var Password = {
  init: function(){
    this.label = $('password_label');
    this.a = $a({
      style: 'text-decoration:underline; cursor:pointer'
    });
    this.pwd = $(this.label.readAttribute('for'));
    var div = $div({
      id: 'password_toggler',
      style: 'display:block;left:25%;top:-3em;min-height:0px'
      }, '(',(this.a),')'
    );
    var id = this.pwd.id;
    var insert = $div({
      id:'password_wrapper', 
      style: 'position:static;display:block;width:150px;min-height:0px'
      },
      $div({
        id: id + '_text', 
        style: 'display:block'
      }),
      $div({
        id: id + '_bar',
        style:'display:block;border: 0px solid white; font-size: 1px; height: 2px; width: 100%;min-height:0px'
      })
    );
    var insertion_pt = this.label.up();
    new Insertion.Bottom(insertion_pt, div);
    new Insertion.Bottom(insertion_pt, insert);
    this.toggleConfirmation();
    Event.observe(insertion_pt.up(2), 'submit', this.conditionalMirror.bind(this));
    Event.observe(this.a, 'click', this.toggleConfirmation.bind(this));
  },
  shows: function(elm) { return elm.type == 'text'; },
  mirror: function(elm) { this.confirm().value = elm.value; },
  conditionalMirror: function() {
    var elm = $(this.label.readAttribute('for'));
    if (Password.shows(elm)) Password.mirror(elm);
  },
  confirm: function(){return this.label.up().next().down('input')},
  toggleConfirmation: function() {
    var confirm = this.confirm();
    confirm.up().toggle();
    var pwd = $($('password_label').readAttribute('for'));
    var shows = this.shows(pwd);
    var replace = $input({
      type: (shows ? 'password' : 'text'),
      name: pwd.name,
      size: pwd.size
    });
    this.a.innerHTML = shows ?  "Show what I type" : "Hide what I type";
    this.mirror(pwd);
    pwd.replace(replace);
    replace.id = this.label.readAttribute('for');
    replace.value = pwd.value;
    Event.observe(replace, 'keyup', function(e){runPassword(e.target.value, replace.id)});
  }
}
function runPassword(strPassword, strFieldID) {
  var score = checkPassword(strPassword);

  var ctlBar = $(strFieldID + "_bar");
  var ctlText = $(strFieldID + "_text");
  if (!ctlBar || !ctlText) {return}

  ctlBar.style.width = score + "%";

  if (score >= 90) { var text = "Very Secure"; var color = "#0ca908";}

  else if (score >= 80) { var text = "Secure"; var color = "#7ff67c";}

  else if (score >= 70) { var text = "Very Strong"; var color = "#1740ef";}

  else if (score >= 60) { var text = "Strong"; var color = "#5a74e3";}

  else if (score >= 50) { var text = "Average"; var color = "#e3cb00";}

  else if (score >= 25) { var text = "Weak"; var color = "#e7d61a";}

  else { var text = "Very Weak"; var color = "#e71a1a";}

  ctlBar.style.backgroundColor = color;
  ctlText.innerHTML = "<span title='Increase your password strength by having a combination of uppercase and lowercase letters, numbers, and symbols (!@#$)' style='color: " + color + ";'>" + text + " - " + score + "</span>";
}
function checkPassword(pwd) {
  var m_strUpperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  var m_strLowerCase = "abcdefghijklmnopqrstuvwxyz";
  var m_strNumber = "0123456789";
  var m_strCharacters = "!@#$%^&*?_~"

  var score = 0;
  if(pwd.length < 4) {score += 5}
  if(pwd.length > 3 && pwd.length < 8) {score += 10}
  if(pwd.length > 7) {score += 25}

  var upperCount = countContain(pwd, m_strUpperCase);
  var lowerCount = countContain(pwd, m_strLowerCase);
  var lowerUpperCount = upperCount + lowerCount;

  if (upperCount == 0 && lowerCount != 0) { score += 10;}
  else if (upperCount != 0 && lowerCount != 0) { score += 20;}

  var numberCount = countContain(pwd, m_strNumber);
  if (numberCount == 1) { score += 10;}
  if (numberCount >= 2) { score += 20;}

  var characterCount = countContain(pwd, m_strCharacters);
  if (characterCount == 1) { score += 10;}
  if (characterCount > 1) { score += 25;}

  if (numberCount != 0 && lowerUpperCount != 0) { score += 2;}

  if (numberCount != 0 && lowerUpperCount != 0 && characterCount != 0) { score += 3;}

  if (numberCount != 0 && upperCount != 0 && lowerCount != 0 && characterCount != 0)
  { score += 5;}

  return score;
}
function countContain(pwd, strCheck) {
  var count = 0;
  for (i = 0; i < pwd.length; i++) {
    if (strCheck.indexOf(pwd.charAt(i)) > -1) {
      count++;
    }
  }
  return count;
}
