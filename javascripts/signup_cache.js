/*  Prototype JavaScript framework, version 1.6.1_rc3
 *  (c) 2005-2009 Sam Stephenson
 *
 *  Prototype is freely distributable under the terms of an MIT-style license.
 *  For details, see the Prototype web site: http://www.prototypejs.org/
 *
 *--------------------------------------------------------------------------*/

var Prototype = {
  Version: '1.6.1_rc3',

  Browser: (function(){
    var ua = navigator.userAgent;
    var isOpera = Object.prototype.toString.call(window.opera) == '[object Opera]';
    return {
      IE:             !!window.attachEvent && !isOpera,
      Opera:          isOpera,
      WebKit:         ua.indexOf('AppleWebKit/') > -1,
      Gecko:          ua.indexOf('Gecko') > -1 && ua.indexOf('KHTML') === -1,
      KHTML:          /Konqueror/.test(ua) && /KHTML/.test(ua), 
      MobileSafari:   /Apple.*Mobile.*Safari/.test(ua)
    }
  })(),

  BrowserFeatures: {
    XPath: !!document.evaluate,
    SelectorsAPI: !!document.querySelector,
    ElementExtensions: (function() {
      var constructor = window.Element || window.HTMLElement;
      return !!(constructor && constructor.prototype);
    })(),
    SpecificElementExtensions: (function() {
      if (typeof window.HTMLDivElement !== 'undefined')
        return true;

      var div = document.createElement('div');
      var form = document.createElement('form');
      var isSupported = false;

      if (div['__proto__'] && (div['__proto__'] !== form['__proto__'])) {
        isSupported = true;
      }

      div = form = null;

      return isSupported;
    })()
  },

  ScriptFragment: '<script[^>]*>([\\S\\s]*?)<\/script>',
  JSONFilter: /^\/\*-secure-([\s\S]*)\*\/\s*$/,

  emptyFunction: function() { },
  K: function(x) { return x }
};

if (Prototype.Browser.MobileSafari)
  Prototype.BrowserFeatures.SpecificElementExtensions = false;


var Abstract = { };


var Try = {
  these: function() {
    var returnValue;

    for (var i = 0, length = arguments.length; i < length; i++) {
      var lambda = arguments[i];
      try {
        returnValue = lambda();
        break;
      } catch (e) { }
    }

    return returnValue;
  }
};

/* Based on Alex Arnell's inheritance implementation. */

var Class = (function() {
  function subclass() {};
  function create() {
    var parent = null, properties = $A(arguments);
    if (Object.isFunction(properties[0]))
      parent = properties.shift();

    function klass() {
      this.initialize.apply(this, arguments);
    }

    Object.extend(klass, Class.Methods);
    klass.superclass = parent;
    klass.subclasses = [];

    if (parent) {
      subclass.prototype = parent.prototype;
      klass.prototype = new subclass;
      parent.subclasses.push(klass);
    }

    for (var i = 0; i < properties.length; i++)
      klass.addMethods(properties[i]);

    if (!klass.prototype.initialize)
      klass.prototype.initialize = Prototype.emptyFunction;

    klass.prototype.constructor = klass;
    return klass;
  }

  function addMethods(source) {
    var ancestor   = this.superclass && this.superclass.prototype;
    var properties = Object.keys(source);

    if (!Object.keys({ toString: true }).length) {
      if (source.toString != Object.prototype.toString)
        properties.push("toString");
      if (source.valueOf != Object.prototype.valueOf)
        properties.push("valueOf");
    }

    for (var i = 0, length = properties.length; i < length; i++) {
      var property = properties[i], value = source[property];
      if (ancestor && Object.isFunction(value) &&
          value.argumentNames().first() == "$super") {
        var method = value;
        value = (function(m) {
          return function() { return ancestor[m].apply(this, arguments); };
        })(property).wrap(method);

        value.valueOf = method.valueOf.bind(method);
        value.toString = method.toString.bind(method);
      }
      this.prototype[property] = value;
    }

    return this;
  }

  return {
    create: create,
    Methods: {
      addMethods: addMethods
    }
  };
})();
(function() {

  function getClass(object) {
    return Object.prototype.toString.call(object)
     .match(/^\[object\s(.*)\]$/)[1];
  }

  function extend(destination, source) {
    for (var property in source)
      destination[property] = source[property];
    return destination;
  }

  function inspect(object) {
    try {
      if (isUndefined(object)) return 'undefined';
      if (object === null) return 'null';
      return object.inspect ? object.inspect() : String(object);
    } catch (e) {
      if (e instanceof RangeError) return '...';
      throw e;
    }
  }

  function toJSON(object) {
    var type = typeof object;
    switch (type) {
      case 'undefined':
      case 'function':
      case 'unknown': return;
      case 'boolean': return object.toString();
    }

    if (object === null) return 'null';
    if (object.toJSON) return object.toJSON();
    if (isElement(object)) return;

    var results = [];
    for (var property in object) {
      var value = toJSON(object[property]);
      if (!isUndefined(value))
        results.push(property.toJSON() + ': ' + value);
    }

    return '{' + results.join(', ') + '}';
  }

  function toQueryString(object) {
    return $H(object).toQueryString();
  }

  function toHTML(object) {
    return object && object.toHTML ? object.toHTML() : String.interpret(object);
  }

  function keys(object) {
    var results = [];
    for (var property in object)
      results.push(property);
    return results;
  }

  function values(object) {
    var results = [];
    for (var property in object)
      results.push(object[property]);
    return results;
  }

  function clone(object) {
    return extend({ }, object);
  }

  function isElement(object) {
    return !!(object && object.nodeType == 1);
  }

  function isArray(object) {
    return getClass(object) === "Array";
  }


  function isHash(object) {
    return object instanceof Hash;
  }

  function isFunction(object) {
    return typeof object === "function";
  }

  function isString(object) {
    return getClass(object) === "String";
  }

  function isNumber(object) {
    return getClass(object) === "Number";
  }

  function isUndefined(object) {
    return typeof object === "undefined";
  }

  extend(Object, {
    extend:        extend,
    inspect:       inspect,
    toJSON:        toJSON,
    toQueryString: toQueryString,
    toHTML:        toHTML,
    keys:          keys,
    values:        values,
    clone:         clone,
    isElement:     isElement,
    isArray:       isArray,
    isHash:        isHash,
    isFunction:    isFunction,
    isString:      isString,
    isNumber:      isNumber,
    isUndefined:   isUndefined
  });
})();
Object.extend(Function.prototype, (function() {
  var slice = Array.prototype.slice;

  function update(array, args) {
    var arrayLength = array.length, length = args.length;
    while (length--) array[arrayLength + length] = args[length];
    return array;
  }

  function merge(array, args) {
    array = slice.call(array, 0);
    return update(array, args);
  }

  function argumentNames() {
    var names = this.toString().match(/^[\s\(]*function[^(]*\(([^)]*)\)/)[1]
      .replace(/\/\/.*?[\r\n]|\/\*(?:.|[\r\n])*?\*\//g, '')
      .replace(/\s+/g, '').split(',');
    return names.length == 1 && !names[0] ? [] : names;
  }

  function bind(context) {
    if (arguments.length < 2 && Object.isUndefined(arguments[0])) return this;
    var __method = this, args = slice.call(arguments, 1);
    return function() {
      var a = merge(args, arguments);
      return __method.apply(context, a);
    }
  }

  function bindAsEventListener(context) {
    var __method = this, args = slice.call(arguments, 1);
    return function(event) {
      var a = update([event || window.event], args);
      return __method.apply(context, a);
    }
  }

  function curry() {
    if (!arguments.length) return this;
    var __method = this, args = slice.call(arguments, 0);
    return function() {
      var a = merge(args, arguments);
      return __method.apply(this, a);
    }
  }

  function delay(timeout) {
    var __method = this, args = slice.call(arguments, 1);
    timeout = timeout * 1000
    return window.setTimeout(function() {
      return __method.apply(__method, args);
    }, timeout);
  }

  function defer() {
    var args = update([0.01], arguments);
    return this.delay.apply(this, args);
  }

  function wrap(wrapper) {
    var __method = this;
    return function() {
      var a = update([__method.bind(this)], arguments);
      return wrapper.apply(this, a);
    }
  }

  function methodize() {
    if (this._methodized) return this._methodized;
    var __method = this;
    return this._methodized = function() {
      var a = update([this], arguments);
      return __method.apply(null, a);
    };
  }

  return {
    argumentNames:       argumentNames,
    bind:                bind,
    bindAsEventListener: bindAsEventListener,
    curry:               curry,
    delay:               delay,
    defer:               defer,
    wrap:                wrap,
    methodize:           methodize
  }
})());


Date.prototype.toJSON = function() {
  return '"' + this.getUTCFullYear() + '-' +
    (this.getUTCMonth() + 1).toPaddedString(2) + '-' +
    this.getUTCDate().toPaddedString(2) + 'T' +
    this.getUTCHours().toPaddedString(2) + ':' +
    this.getUTCMinutes().toPaddedString(2) + ':' +
    this.getUTCSeconds().toPaddedString(2) + 'Z"';
};


RegExp.prototype.match = RegExp.prototype.test;

RegExp.escape = function(str) {
  return String(str).replace(/([.*+?^=!:${}()|[\]\/\\])/g, '\\$1');
};
var PeriodicalExecuter = Class.create({
  initialize: function(callback, frequency) {
    this.callback = callback;
    this.frequency = frequency;
    this.currentlyExecuting = false;

    this.registerCallback();
  },

  registerCallback: function() {
    this.timer = setInterval(this.onTimerEvent.bind(this), this.frequency * 1000);
  },

  execute: function() {
    this.callback(this);
  },

  stop: function() {
    if (!this.timer) return;
    clearInterval(this.timer);
    this.timer = null;
  },

  onTimerEvent: function() {
    if (!this.currentlyExecuting) {
      try {
        this.currentlyExecuting = true;
        this.execute();
      } catch(e) {
        /* empty catch for clients that don't support try/finally */
      }
      finally {
        this.currentlyExecuting = false;
      }
    }
  }
});
Object.extend(String, {
  interpret: function(value) {
    return value == null ? '' : String(value);
  },
  specialChar: {
    '\b': '\\b',
    '\t': '\\t',
    '\n': '\\n',
    '\f': '\\f',
    '\r': '\\r',
    '\\': '\\\\'
  }
});

Object.extend(String.prototype, (function() {

  function prepareReplacement(replacement) {
    if (Object.isFunction(replacement)) return replacement;
    var template = new Template(replacement);
    return function(match) { return template.evaluate(match) };
  }

  function gsub(pattern, replacement) {
    var result = '', source = this, match;
    replacement = prepareReplacement(replacement);

    if (Object.isString(pattern))
      pattern = RegExp.escape(pattern);

    if (!(pattern.length || pattern.source)) {
      replacement = replacement('');
      return replacement + source.split('').join(replacement) + replacement;
    }

    while (source.length > 0) {
      if (match = source.match(pattern)) {
        result += source.slice(0, match.index);
        result += String.interpret(replacement(match));
        source  = source.slice(match.index + match[0].length);
      } else {
        result += source, source = '';
      }
    }
    return result;
  }

  function sub(pattern, replacement, count) {
    replacement = prepareReplacement(replacement);
    count = Object.isUndefined(count) ? 1 : count;

    return this.gsub(pattern, function(match) {
      if (--count < 0) return match[0];
      return replacement(match);
    });
  }

  function scan(pattern, iterator) {
    this.gsub(pattern, iterator);
    return String(this);
  }

  function truncate(length, truncation) {
    length = length || 30;
    truncation = Object.isUndefined(truncation) ? '...' : truncation;
    return this.length > length ?
      this.slice(0, length - truncation.length) + truncation : String(this);
  }

  function strip() {
    return this.replace(/^\s+/, '').replace(/\s+$/, '');
  }

  function stripTags() {
    return this.replace(/<\w+(\s+("[^"]*"|'[^']*'|[^>])+)?>|<\/\w+>/gi, '');
  }

  function stripScripts() {
    return this.replace(new RegExp(Prototype.ScriptFragment, 'img'), '');
  }

  function extractScripts() {
    var matchAll = new RegExp(Prototype.ScriptFragment, 'img');
    var matchOne = new RegExp(Prototype.ScriptFragment, 'im');
    return (this.match(matchAll) || []).map(function(scriptTag) {
      return (scriptTag.match(matchOne) || ['', ''])[1];
    });
  }

  function evalScripts() {
    return this.extractScripts().map(function(script) { return eval(script) });
  }

  function escapeHTML() {
    escapeHTML.text.data = this;
    return escapeHTML.div.innerHTML;
  }

  function unescapeHTML() {
    var div = document.createElement('div');
    div.innerHTML = this.stripTags();
    return div.childNodes[0] ? (div.childNodes.length > 1 ?
      $A(div.childNodes).inject('', function(memo, node) { return memo+node.nodeValue }) :
      div.childNodes[0].nodeValue) : '';
  }


  function toQueryParams(separator) {
    var match = this.strip().match(/([^?#]*)(#.*)?$/);
    if (!match) return { };

    return match[1].split(separator || '&').inject({ }, function(hash, pair) {
      if ((pair = pair.split('='))[0]) {
        var key = decodeURIComponent(pair.shift());
        var value = pair.length > 1 ? pair.join('=') : pair[0];
        if (value != undefined) value = decodeURIComponent(value);

        if (key in hash) {
          if (!Object.isArray(hash[key])) hash[key] = [hash[key]];
          hash[key].push(value);
        }
        else hash[key] = value;
      }
      return hash;
    });
  }

  function toArray() {
    return this.split('');
  }

  function succ() {
    return this.slice(0, this.length - 1) +
      String.fromCharCode(this.charCodeAt(this.length - 1) + 1);
  }

  function times(count) {
    return count < 1 ? '' : new Array(count + 1).join(this);
  }

  function camelize() {
    var parts = this.split('-'), len = parts.length;
    if (len == 1) return parts[0];

    var camelized = this.charAt(0) == '-'
      ? parts[0].charAt(0).toUpperCase() + parts[0].substring(1)
      : parts[0];

    for (var i = 1; i < len; i++)
      camelized += parts[i].charAt(0).toUpperCase() + parts[i].substring(1);

    return camelized;
  }

  function capitalize() {
    return this.charAt(0).toUpperCase() + this.substring(1).toLowerCase();
  }

  function underscore() {
    return this.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/,'#{1}_#{2}').gsub(/([a-z\d])([A-Z])/,'#{1}_#{2}').gsub(/-/,'_').toLowerCase();
  }

  function dasherize() {
    return this.gsub(/_/,'-');
  }

  function inspect(useDoubleQuotes) {
    var escapedString = this.gsub(/[\x00-\x1f\\]/, function(match) {
      var character = String.specialChar[match[0]];
      return character ? character : '\\u00' + match[0].charCodeAt().toPaddedString(2, 16);
    });
    if (useDoubleQuotes) return '"' + escapedString.replace(/"/g, '\\"') + '"';
    return "'" + escapedString.replace(/'/g, '\\\'') + "'";
  }

  function toJSON() {
    return this.inspect(true);
  }

  function unfilterJSON(filter) {
    return this.sub(filter || Prototype.JSONFilter, '#{1}');
  }

  function isJSON() {
    var str = this;
    if (str.blank()) return false;
    str = this.replace(/\\./g, '@').replace(/"[^"\\\n\r]*"/g, '');
    return (/^[,:{}\[\]0-9.\-+Eaeflnr-u \n\r\t]*$/).test(str);
  }

  function evalJSON(sanitize) {
    var json = this.unfilterJSON();
    try {
      if (!sanitize || json.isJSON()) return eval('(' + json + ')');
    } catch (e) { }
    throw new SyntaxError('Badly formed JSON string: ' + this.inspect());
  }

  function include(pattern) {
    return this.indexOf(pattern) > -1;
  }

  function startsWith(pattern) {
    return this.indexOf(pattern) === 0;
  }

  function endsWith(pattern) {
    var d = this.length - pattern.length;
    return d >= 0 && this.lastIndexOf(pattern) === d;
  }

  function empty() {
    return this == '';
  }

  function blank() {
    return /^\s*$/.test(this);
  }

  function interpolate(object, pattern) {
    return new Template(this, pattern).evaluate(object);
  }

  return {
    gsub:           gsub,
    sub:            sub,
    scan:           scan,
    truncate:       truncate,
    strip:          String.prototype.trim ? String.prototype.trim : strip,
    stripTags:      stripTags,
    stripScripts:   stripScripts,
    extractScripts: extractScripts,
    evalScripts:    evalScripts,
    escapeHTML:     escapeHTML,
    unescapeHTML:   unescapeHTML,
    toQueryParams:  toQueryParams,
    parseQuery:     toQueryParams,
    toArray:        toArray,
    succ:           succ,
    times:          times,
    camelize:       camelize,
    capitalize:     capitalize,
    underscore:     underscore,
    dasherize:      dasherize,
    inspect:        inspect,
    toJSON:         toJSON,
    unfilterJSON:   unfilterJSON,
    isJSON:         isJSON,
    evalJSON:       evalJSON,
    include:        include,
    startsWith:     startsWith,
    endsWith:       endsWith,
    empty:          empty,
    blank:          blank,
    interpolate:    interpolate
  };
})());

Object.extend(String.prototype.escapeHTML, {
  div:  document.createElement('div'),
  text: document.createTextNode('')
});

String.prototype.escapeHTML.div.appendChild(String.prototype.escapeHTML.text);

if ('<\n>'.escapeHTML() !== '&lt;\n&gt;') {
  String.prototype.escapeHTML = function() {
    return this.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  };
}

if ('&lt;\n&gt;'.unescapeHTML() !== '<\n>') {
  String.prototype.unescapeHTML = function() {
    return this.stripTags().replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&amp;/g,'&');
  };
}
var Template = Class.create({
  initialize: function(template, pattern) {
    this.template = template.toString();
    this.pattern = pattern || Template.Pattern;
  },

  evaluate: function(object) {
    if (object && Object.isFunction(object.toTemplateReplacements))
      object = object.toTemplateReplacements();

    return this.template.gsub(this.pattern, function(match) {
      if (object == null) return (match[1] + '');

      var before = match[1] || '';
      if (before == '\\') return match[2];

      var ctx = object, expr = match[3];
      var pattern = /^([^.[]+|\[((?:.*?[^\\])?)\])(\.|\[|$)/;
      match = pattern.exec(expr);
      if (match == null) return before;

      while (match != null) {
        var comp = match[1].startsWith('[') ? match[2].gsub('\\\\]', ']') : match[1];
        ctx = ctx[comp];
        if (null == ctx || '' == match[3]) break;
        expr = expr.substring('[' == match[3] ? match[1].length : match[0].length);
        match = pattern.exec(expr);
      }

      return before + String.interpret(ctx);
    });
  }
});
Template.Pattern = /(^|.|\r|\n)(#\{(.*?)\})/;

var $break = { };

var Enumerable = (function() {
  function each(iterator, context) {
    var index = 0;
    try {
      this._each(function(value) {
        iterator.call(context, value, index++);
      });
    } catch (e) {
      if (e != $break) throw e;
    }
    return this;
  }

  function eachSlice(number, iterator, context) {
    var index = -number, slices = [], array = this.toArray();
    if (number < 1) return array;
    while ((index += number) < array.length)
      slices.push(array.slice(index, index+number));
    return slices.collect(iterator, context);
  }

  function all(iterator, context) {
    iterator = iterator || Prototype.K;
    var result = true;
    this.each(function(value, index) {
      result = result && !!iterator.call(context, value, index);
      if (!result) throw $break;
    });
    return result;
  }

  function any(iterator, context) {
    iterator = iterator || Prototype.K;
    var result = false;
    this.each(function(value, index) {
      if (result = !!iterator.call(context, value, index))
        throw $break;
    });
    return result;
  }

  function collect(iterator, context) {
    iterator = iterator || Prototype.K;
    var results = [];
    this.each(function(value, index) {
      results.push(iterator.call(context, value, index));
    });
    return results;
  }

  function detect(iterator, context) {
    var result;
    this.each(function(value, index) {
      if (iterator.call(context, value, index)) {
        result = value;
        throw $break;
      }
    });
    return result;
  }

  function findAll(iterator, context) {
    var results = [];
    this.each(function(value, index) {
      if (iterator.call(context, value, index))
        results.push(value);
    });
    return results;
  }

  function grep(filter, iterator, context) {
    iterator = iterator || Prototype.K;
    var results = [];

    if (Object.isString(filter))
      filter = new RegExp(RegExp.escape(filter));

    this.each(function(value, index) {
      if (filter.match(value))
        results.push(iterator.call(context, value, index));
    });
    return results;
  }

  function include(object) {
    if (Object.isFunction(this.indexOf))
      if (this.indexOf(object) != -1) return true;

    var found = false;
    this.each(function(value) {
      if (value == object) {
        found = true;
        throw $break;
      }
    });
    return found;
  }

  function inGroupsOf(number, fillWith) {
    fillWith = Object.isUndefined(fillWith) ? null : fillWith;
    return this.eachSlice(number, function(slice) {
      while(slice.length < number) slice.push(fillWith);
      return slice;
    });
  }

  function inject(memo, iterator, context) {
    this.each(function(value, index) {
      memo = iterator.call(context, memo, value, index);
    });
    return memo;
  }

  function invoke(method) {
    var args = $A(arguments).slice(1);
    return this.map(function(value) {
      return value[method].apply(value, args);
    });
  }

  function max(iterator, context) {
    iterator = iterator || Prototype.K;
    var result;
    this.each(function(value, index) {
      value = iterator.call(context, value, index);
      if (result == null || value >= result)
        result = value;
    });
    return result;
  }

  function min(iterator, context) {
    iterator = iterator || Prototype.K;
    var result;
    this.each(function(value, index) {
      value = iterator.call(context, value, index);
      if (result == null || value < result)
        result = value;
    });
    return result;
  }

  function partition(iterator, context) {
    iterator = iterator || Prototype.K;
    var trues = [], falses = [];
    this.each(function(value, index) {
      (iterator.call(context, value, index) ?
        trues : falses).push(value);
    });
    return [trues, falses];
  }

  function pluck(property) {
    var results = [];
    this.each(function(value) {
      results.push(value[property]);
    });
    return results;
  }

  function reject(iterator, context) {
    var results = [];
    this.each(function(value, index) {
      if (!iterator.call(context, value, index))
        results.push(value);
    });
    return results;
  }

  function sortBy(iterator, context) {
    return this.map(function(value, index) {
      return {
        value: value,
        criteria: iterator.call(context, value, index)
      };
    }).sort(function(left, right) {
      var a = left.criteria, b = right.criteria;
      return a < b ? -1 : a > b ? 1 : 0;
    }).pluck('value');
  }

  function toArray() {
    return this.map();
  }

  function zip() {
    var iterator = Prototype.K, args = $A(arguments);
    if (Object.isFunction(args.last()))
      iterator = args.pop();

    var collections = [this].concat(args).map($A);
    return this.map(function(value, index) {
      return iterator(collections.pluck(index));
    });
  }

  function size() {
    return this.toArray().length;
  }

  function inspect() {
    return '#<Enumerable:' + this.toArray().inspect() + '>';
  }









  return {
    each:       each,
    eachSlice:  eachSlice,
    all:        all,
    every:      all,
    any:        any,
    some:       any,
    collect:    collect,
    map:        collect,
    detect:     detect,
    findAll:    findAll,
    select:     findAll,
    filter:     findAll,
    grep:       grep,
    include:    include,
    member:     include,
    inGroupsOf: inGroupsOf,
    inject:     inject,
    invoke:     invoke,
    max:        max,
    min:        min,
    partition:  partition,
    pluck:      pluck,
    reject:     reject,
    sortBy:     sortBy,
    toArray:    toArray,
    entries:    toArray,
    zip:        zip,
    size:       size,
    inspect:    inspect,
    find:       detect
  };
})();
function $A(iterable) {
  if (!iterable) return [];
  if ('toArray' in Object(iterable)) return iterable.toArray();
  var length = iterable.length || 0, results = new Array(length);
  while (length--) results[length] = iterable[length];
  return results;
}

function $w(string) {
  if (!Object.isString(string)) return [];
  string = string.strip();
  return string ? string.split(/\s+/) : [];
}

Array.from = $A;


(function() {
  var arrayProto = Array.prototype,
      slice = arrayProto.slice,
      _each = arrayProto.forEach; // use native browser JS 1.6 implementation if available

  function each(iterator) {
    for (var i = 0, length = this.length; i < length; i++)
      iterator(this[i]);
  }
  if (!_each) _each = each;

  function clear() {
    this.length = 0;
    return this;
  }

  function first() {
    return this[0];
  }

  function last() {
    return this[this.length - 1];
  }

  function compact() {
    return this.select(function(value) {
      return value != null;
    });
  }

  function flatten() {
    return this.inject([], function(array, value) {
      if (Object.isArray(value))
        return array.concat(value.flatten());
      array.push(value);
      return array;
    });
  }

  function without() {
    var values = slice.call(arguments, 0);
    return this.select(function(value) {
      return !values.include(value);
    });
  }

  function reverse(inline) {
    return (inline !== false ? this : this.toArray())._reverse();
  }

  function uniq(sorted) {
    return this.inject([], function(array, value, index) {
      if (0 == index || (sorted ? array.last() != value : !array.include(value)))
        array.push(value);
      return array;
    });
  }

  function intersect(array) {
    return this.uniq().findAll(function(item) {
      return array.detect(function(value) { return item === value });
    });
  }


  function clone() {
    return slice.call(this, 0);
  }

  function size() {
    return this.length;
  }

  function inspect() {
    return '[' + this.map(Object.inspect).join(', ') + ']';
  }

  function toJSON() {
    var results = [];
    this.each(function(object) {
      var value = Object.toJSON(object);
      if (!Object.isUndefined(value)) results.push(value);
    });
    return '[' + results.join(', ') + ']';
  }

  function indexOf(item, i) {
    i || (i = 0);
    var length = this.length;
    if (i < 0) i = length + i;
    for (; i < length; i++)
      if (this[i] === item) return i;
    return -1;
  }

  function lastIndexOf(item, i) {
    i = isNaN(i) ? this.length : (i < 0 ? this.length + i : i) + 1;
    var n = this.slice(0, i).reverse().indexOf(item);
    return (n < 0) ? n : i - n - 1;
  }

  function concat() {
    var array = slice.call(this, 0), item;
    for (var i = 0, length = arguments.length; i < length; i++) {
      item = arguments[i];
      if (Object.isArray(item) && !('callee' in item)) {
        for (var j = 0, arrayLength = item.length; j < arrayLength; j++)
          array.push(item[j]);
      } else {
        array.push(item);
      }
    }
    return array;
  }

  Object.extend(arrayProto, Enumerable);

  if (!arrayProto._reverse)
    arrayProto._reverse = arrayProto.reverse;

  Object.extend(arrayProto, {
    _each:     _each,
    clear:     clear,
    first:     first,
    last:      last,
    compact:   compact,
    flatten:   flatten,
    without:   without,
    reverse:   reverse,
    uniq:      uniq,
    intersect: intersect,
    clone:     clone,
    toArray:   clone,
    size:      size,
    inspect:   inspect,
    toJSON:    toJSON
  });

  var CONCAT_ARGUMENTS_BUGGY = (function() {
    return [].concat(arguments)[0][0] !== 1;
  })(1,2)

  if (CONCAT_ARGUMENTS_BUGGY) arrayProto.concat = concat;

  if (!arrayProto.indexOf) arrayProto.indexOf = indexOf;
  if (!arrayProto.lastIndexOf) arrayProto.lastIndexOf = lastIndexOf;
})();
function $H(object) {
  return new Hash(object);
};

var Hash = Class.create(Enumerable, (function() {
  function initialize(object) {
    this._object = Object.isHash(object) ? object.toObject() : Object.clone(object);
  }

  function _each(iterator) {
    for (var key in this._object) {
      var value = this._object[key], pair = [key, value];
      pair.key = key;
      pair.value = value;
      iterator(pair);
    }
  }

  function set(key, value) {
    return this._object[key] = value;
  }

  function get(key) {
    if (this._object[key] !== Object.prototype[key])
      return this._object[key];
  }

  function unset(key) {
    var value = this._object[key];
    delete this._object[key];
    return value;
  }

  function toObject() {
    return Object.clone(this._object);
  }

  function keys() {
    return this.pluck('key');
  }

  function values() {
    return this.pluck('value');
  }

  function index(value) {
    var match = this.detect(function(pair) {
      return pair.value === value;
    });
    return match && match.key;
  }

  function merge(object) {
    return this.clone().update(object);
  }

  function update(object) {
    return new Hash(object).inject(this, function(result, pair) {
      result.set(pair.key, pair.value);
      return result;
    });
  }

  function toQueryPair(key, value) {
    if (Object.isUndefined(value)) return key;
    return key + '=' + encodeURIComponent(String.interpret(value));
  }

  function toQueryString() {
    return this.inject([], function(results, pair) {
      var key = encodeURIComponent(pair.key), values = pair.value;

      if (values && typeof values == 'object') {
        if (Object.isArray(values))
          return results.concat(values.map(toQueryPair.curry(key)));
      } else results.push(toQueryPair(key, values));
      return results;
    }).join('&');
  }

  function inspect() {
    return '#<Hash:{' + this.map(function(pair) {
      return pair.map(Object.inspect).join(': ');
    }).join(', ') + '}>';
  }

  function toJSON() {
    return Object.toJSON(this.toObject());
  }

  function clone() {
    return new Hash(this);
  }

  return {
    initialize:             initialize,
    _each:                  _each,
    set:                    set,
    get:                    get,
    unset:                  unset,
    toObject:               toObject,
    toTemplateReplacements: toObject,
    keys:                   keys,
    values:                 values,
    index:                  index,
    merge:                  merge,
    update:                 update,
    toQueryString:          toQueryString,
    inspect:                inspect,
    toJSON:                 toJSON,
    clone:                  clone
  };
})());

Hash.from = $H;
Object.extend(Number.prototype, (function() {
  function toColorPart() {
    return this.toPaddedString(2, 16);
  }

  function succ() {
    return this + 1;
  }

  function times(iterator, context) {
    $R(0, this, true).each(iterator, context);
    return this;
  }

  function toPaddedString(length, radix) {
    var string = this.toString(radix || 10);
    return '0'.times(length - string.length) + string;
  }

  function toJSON() {
    return isFinite(this) ? this.toString() : 'null';
  }

  function abs() {
    return Math.abs(this);
  }

  function round() {
    return Math.round(this);
  }

  function ceil() {
    return Math.ceil(this);
  }

  function floor() {
    return Math.floor(this);
  }

  return {
    toColorPart:    toColorPart,
    succ:           succ,
    times:          times,
    toPaddedString: toPaddedString,
    toJSON:         toJSON,
    abs:            abs,
    round:          round,
    ceil:           ceil,
    floor:          floor
  };
})());

function $R(start, end, exclusive) {
  return new ObjectRange(start, end, exclusive);
}

var ObjectRange = Class.create(Enumerable, (function() {
  function initialize(start, end, exclusive) {
    this.start = start;
    this.end = end;
    this.exclusive = exclusive;
  }

  function _each(iterator) {
    var value = this.start;
    while (this.include(value)) {
      iterator(value);
      value = value.succ();
    }
  }

  function include(value) {
    if (value < this.start)
      return false;
    if (this.exclusive)
      return value < this.end;
    return value <= this.end;
  }

  return {
    initialize: initialize,
    _each:      _each,
    include:    include
  };
})());



var Ajax = {
  getTransport: function() {
    return Try.these(
      function() {return new XMLHttpRequest()},
      function() {return new ActiveXObject('Msxml2.XMLHTTP')},
      function() {return new ActiveXObject('Microsoft.XMLHTTP')}
    ) || false;
  },

  activeRequestCount: 0
};

Ajax.Responders = {
  responders: [],

  _each: function(iterator) {
    this.responders._each(iterator);
  },

  register: function(responder) {
    if (!this.include(responder))
      this.responders.push(responder);
  },

  unregister: function(responder) {
    this.responders = this.responders.without(responder);
  },

  dispatch: function(callback, request, transport, json) {
    this.each(function(responder) {
      if (Object.isFunction(responder[callback])) {
        try {
          responder[callback].apply(responder, [request, transport, json]);
        } catch (e) { }
      }
    });
  }
};

Object.extend(Ajax.Responders, Enumerable);

Ajax.Responders.register({
  onCreate:   function() { Ajax.activeRequestCount++ },
  onComplete: function() { Ajax.activeRequestCount-- }
});
Ajax.Base = Class.create({
  initialize: function(options) {
    this.options = {
      method:       'post',
      asynchronous: true,
      contentType:  'application/x-www-form-urlencoded',
      encoding:     'UTF-8',
      parameters:   '',
      evalJSON:     true,
      evalJS:       true
    };
    Object.extend(this.options, options || { });

    this.options.method = this.options.method.toLowerCase();

    if (Object.isString(this.options.parameters))
      this.options.parameters = this.options.parameters.toQueryParams();
    else if (Object.isHash(this.options.parameters))
      this.options.parameters = this.options.parameters.toObject();
  }
});
Ajax.Request = Class.create(Ajax.Base, {
  _complete: false,

  initialize: function($super, url, options) {
    $super(options);
    this.transport = Ajax.getTransport();
    this.request(url);
  },

  request: function(url) {
    this.url = url;
    this.method = this.options.method;
    var params = Object.clone(this.options.parameters);

    if (!['get', 'post'].include(this.method)) {
      params['_method'] = this.method;
      this.method = 'post';
    }

    this.parameters = params;

    if (params = Object.toQueryString(params)) {
      if (this.method == 'get')
        this.url += (this.url.include('?') ? '&' : '?') + params;
      else if (/Konqueror|Safari|KHTML/.test(navigator.userAgent))
        params += '&_=';
    }

    try {
      var response = new Ajax.Response(this);
      if (this.options.onCreate) this.options.onCreate(response);
      Ajax.Responders.dispatch('onCreate', this, response);

      this.transport.open(this.method.toUpperCase(), this.url,
        this.options.asynchronous);

      if (this.options.asynchronous) this.respondToReadyState.bind(this).defer(1);

      this.transport.onreadystatechange = this.onStateChange.bind(this);
      this.setRequestHeaders();

      this.body = this.method == 'post' ? (this.options.postBody || params) : null;
      this.transport.send(this.body);

      /* Force Firefox to handle ready state 4 for synchronous requests */
      if (!this.options.asynchronous && this.transport.overrideMimeType)
        this.onStateChange();

    }
    catch (e) {
      this.dispatchException(e);
    }
  },

  onStateChange: function() {
    var readyState = this.transport.readyState;
    if (readyState > 1 && !((readyState == 4) && this._complete))
      this.respondToReadyState(this.transport.readyState);
  },

  setRequestHeaders: function() {
    var headers = {
      'X-Requested-With': 'XMLHttpRequest',
      'X-Prototype-Version': Prototype.Version,
      'Accept': 'text/javascript, text/html, application/xml, text/xml, */*'
    };

    if (this.method == 'post') {
      headers['Content-type'] = this.options.contentType +
        (this.options.encoding ? '; charset=' + this.options.encoding : '');

      /* Force "Connection: close" for older Mozilla browsers to work
       * around a bug where XMLHttpRequest sends an incorrect
       * Content-length header. See Mozilla Bugzilla #246651.
       */
      if (this.transport.overrideMimeType &&
          (navigator.userAgent.match(/Gecko\/(\d{4})/) || [0,2005])[1] < 2005)
            headers['Connection'] = 'close';
    }

    if (typeof this.options.requestHeaders == 'object') {
      var extras = this.options.requestHeaders;

      if (Object.isFunction(extras.push))
        for (var i = 0, length = extras.length; i < length; i += 2)
          headers[extras[i]] = extras[i+1];
      else
        $H(extras).each(function(pair) { headers[pair.key] = pair.value });
    }

    for (var name in headers)
      this.transport.setRequestHeader(name, headers[name]);
  },

  success: function() {
    var status = this.getStatus();
    return !status || (status >= 200 && status < 300);
  },

  getStatus: function() {
    try {
      return this.transport.status || 0;
    } catch (e) { return 0 }
  },

  respondToReadyState: function(readyState) {
    var state = Ajax.Request.Events[readyState], response = new Ajax.Response(this);

    if (state == 'Complete') {
      try {
        this._complete = true;
        (this.options['on' + response.status]
         || this.options['on' + (this.success() ? 'Success' : 'Failure')]
         || Prototype.emptyFunction)(response, response.headerJSON);
      } catch (e) {
        this.dispatchException(e);
      }

      var contentType = response.getHeader('Content-type');
      if (this.options.evalJS == 'force'
          || (this.options.evalJS && this.isSameOrigin() && contentType
          && contentType.match(/^\s*(text|application)\/(x-)?(java|ecma)script(;.*)?\s*$/i)))
        this.evalResponse();
    }

    try {
      (this.options['on' + state] || Prototype.emptyFunction)(response, response.headerJSON);
      Ajax.Responders.dispatch('on' + state, this, response, response.headerJSON);
    } catch (e) {
      this.dispatchException(e);
    }

    if (state == 'Complete') {
      this.transport.onreadystatechange = Prototype.emptyFunction;
    }
  },

  isSameOrigin: function() {
    var m = this.url.match(/^\s*https?:\/\/[^\/]*/);
    return !m || (m[0] == '#{protocol}//#{domain}#{port}'.interpolate({
      protocol: location.protocol,
      domain: document.domain,
      port: location.port ? ':' + location.port : ''
    }));
  },

  getHeader: function(name) {
    try {
      return this.transport.getResponseHeader(name) || null;
    } catch (e) { return null; }
  },

  evalResponse: function() {
    try {
      return eval((this.transport.responseText || '').unfilterJSON());
    } catch (e) {
      this.dispatchException(e);
    }
  },

  dispatchException: function(exception) {
    (this.options.onException || Prototype.emptyFunction)(this, exception);
    Ajax.Responders.dispatch('onException', this, exception);
  }
});

Ajax.Request.Events =
  ['Uninitialized', 'Loading', 'Loaded', 'Interactive', 'Complete'];








Ajax.Response = Class.create({
  initialize: function(request){
    this.request = request;
    var transport  = this.transport  = request.transport,
        readyState = this.readyState = transport.readyState;

    if((readyState > 2 && !Prototype.Browser.IE) || readyState == 4) {
      this.status       = this.getStatus();
      this.statusText   = this.getStatusText();
      this.responseText = String.interpret(transport.responseText);
      this.headerJSON   = this._getHeaderJSON();
    }

    if(readyState == 4) {
      var xml = transport.responseXML;
      this.responseXML  = Object.isUndefined(xml) ? null : xml;
      this.responseJSON = this._getResponseJSON();
    }
  },

  status:      0,

  statusText: '',

  getStatus: Ajax.Request.prototype.getStatus,

  getStatusText: function() {
    try {
      return this.transport.statusText || '';
    } catch (e) { return '' }
  },

  getHeader: Ajax.Request.prototype.getHeader,

  getAllHeaders: function() {
    try {
      return this.getAllResponseHeaders();
    } catch (e) { return null }
  },

  getResponseHeader: function(name) {
    return this.transport.getResponseHeader(name);
  },

  getAllResponseHeaders: function() {
    return this.transport.getAllResponseHeaders();
  },

  _getHeaderJSON: function() {
    var json = this.getHeader('X-JSON');
    if (!json) return null;
    json = decodeURIComponent(escape(json));
    try {
      return json.evalJSON(this.request.options.sanitizeJSON ||
        !this.request.isSameOrigin());
    } catch (e) {
      this.request.dispatchException(e);
    }
  },

  _getResponseJSON: function() {
    var options = this.request.options;
    if (!options.evalJSON || (options.evalJSON != 'force' &&
      !(this.getHeader('Content-type') || '').include('application/json')) ||
        this.responseText.blank())
          return null;
    try {
      return this.responseText.evalJSON(options.sanitizeJSON ||
        !this.request.isSameOrigin());
    } catch (e) {
      this.request.dispatchException(e);
    }
  }
});

Ajax.Updater = Class.create(Ajax.Request, {
  initialize: function($super, container, url, options) {
    this.container = {
      success: (container.success || container),
      failure: (container.failure || (container.success ? null : container))
    };

    options = Object.clone(options);
    var onComplete = options.onComplete;
    options.onComplete = (function(response, json) {
      this.updateContent(response.responseText);
      if (Object.isFunction(onComplete)) onComplete(response, json);
    }).bind(this);

    $super(url, options);
  },

  updateContent: function(responseText) {
    var receiver = this.container[this.success() ? 'success' : 'failure'],
        options = this.options;

    if (!options.evalScripts) responseText = responseText.stripScripts();

    if (receiver = $(receiver)) {
      if (options.insertion) {
        if (Object.isString(options.insertion)) {
          var insertion = { }; insertion[options.insertion] = responseText;
          receiver.insert(insertion);
        }
        else options.insertion(receiver, responseText);
      }
      else receiver.update(responseText);
    }
  }
});

Ajax.PeriodicalUpdater = Class.create(Ajax.Base, {
  initialize: function($super, container, url, options) {
    $super(options);
    this.onComplete = this.options.onComplete;

    this.frequency = (this.options.frequency || 2);
    this.decay = (this.options.decay || 1);

    this.updater = { };
    this.container = container;
    this.url = url;

    this.start();
  },

  start: function() {
    this.options.onComplete = this.updateComplete.bind(this);
    this.onTimerEvent();
  },

  stop: function() {
    this.updater.options.onComplete = undefined;
    clearTimeout(this.timer);
    (this.onComplete || Prototype.emptyFunction).apply(this, arguments);
  },

  updateComplete: function(response) {
    if (this.options.decay) {
      this.decay = (response.responseText == this.lastText ?
        this.decay * this.options.decay : 1);

      this.lastText = response.responseText;
    }
    this.timer = this.onTimerEvent.bind(this).delay(this.decay * this.frequency);
  },

  onTimerEvent: function() {
    this.updater = new Ajax.Updater(this.container, this.url, this.options);
  }
});



function $(element) {
  if (arguments.length > 1) {
    for (var i = 0, elements = [], length = arguments.length; i < length; i++)
      elements.push($(arguments[i]));
    return elements;
  }
  if (Object.isString(element))
    element = document.getElementById(element);
  return Element.extend(element);
}

if (Prototype.BrowserFeatures.XPath) {
  document._getElementsByXPath = function(expression, parentElement) {
    var results = [];
    var query = document.evaluate(expression, $(parentElement) || document,
      null, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
    for (var i = 0, length = query.snapshotLength; i < length; i++)
      results.push(Element.extend(query.snapshotItem(i)));
    return results;
  };
}

/*--------------------------------------------------------------------------*/

if (!window.Node) var Node = { };

if (!Node.ELEMENT_NODE) {
  Object.extend(Node, {
    ELEMENT_NODE: 1,
    ATTRIBUTE_NODE: 2,
    TEXT_NODE: 3,
    CDATA_SECTION_NODE: 4,
    ENTITY_REFERENCE_NODE: 5,
    ENTITY_NODE: 6,
    PROCESSING_INSTRUCTION_NODE: 7,
    COMMENT_NODE: 8,
    DOCUMENT_NODE: 9,
    DOCUMENT_TYPE_NODE: 10,
    DOCUMENT_FRAGMENT_NODE: 11,
    NOTATION_NODE: 12
  });
}


(function(global) {

  var SETATTRIBUTE_IGNORES_NAME = (function(){
    var elForm = document.createElement("form");
    var elInput = document.createElement("input");
    var root = document.documentElement;
    elInput.setAttribute("name", "test");
    elForm.appendChild(elInput);
    root.appendChild(elForm);
    var isBuggy = elForm.elements
      ? (typeof elForm.elements.test == "undefined")
      : null;
    root.removeChild(elForm);
    elForm = elInput = null;
    return isBuggy;
  })();

  var element = global.Element;
  global.Element = function(tagName, attributes) {
    attributes = attributes || { };
    tagName = tagName.toLowerCase();
    var cache = Element.cache;
    if (SETATTRIBUTE_IGNORES_NAME && attributes.name) {
      tagName = '<' + tagName + ' name="' + attributes.name + '">';
      delete attributes.name;
      return Element.writeAttribute(document.createElement(tagName), attributes);
    }
    if (!cache[tagName]) cache[tagName] = Element.extend(document.createElement(tagName));
    return Element.writeAttribute(cache[tagName].cloneNode(false), attributes);
  };
  Object.extend(global.Element, element || { });
  if (element) global.Element.prototype = element.prototype;
})(this);

Element.cache = { };
Element.idCounter = 1;

Element.Methods = {
  visible: function(element) {
    return $(element).style.display != 'none';
  },

  toggle: function(element) {
    element = $(element);
    Element[Element.visible(element) ? 'hide' : 'show'](element);
    return element;
  },


  hide: function(element) {
    element = $(element);
    element.style.display = 'none';
    return element;
  },

  show: function(element) {
    element = $(element);
    element.style.display = '';
    return element;
  },

  remove: function(element) {
    element = $(element);
    element.parentNode.removeChild(element);
    return element;
  },

  update: (function(){

    var SELECT_ELEMENT_INNERHTML_BUGGY = (function(){
      var el = document.createElement("select"),
          isBuggy = true;
      el.innerHTML = "<option value=\"test\">test</option>";
      if (el.options && el.options[0]) {
        isBuggy = el.options[0].nodeName.toUpperCase() !== "OPTION";
      }
      el = null;
      return isBuggy;
    })();

    var TABLE_ELEMENT_INNERHTML_BUGGY = (function(){
      try {
        var el = document.createElement("table");
        if (el && el.tBodies) {
          el.innerHTML = "<tbody><tr><td>test</td></tr></tbody>";
          var isBuggy = typeof el.tBodies[0] == "undefined";
          el = null;
          return isBuggy;
        }
      } catch (e) {
        return true;
      }
    })();

    var SCRIPT_ELEMENT_REJECTS_TEXTNODE_APPENDING = (function () {
      var s = document.createElement("script"),
          isBuggy = false;
      try {
        s.appendChild(document.createTextNode(""));
        isBuggy = !s.firstChild ||
          s.firstChild && s.firstChild.nodeType !== 3;
      } catch (e) {
        isBuggy = true;
      }
      s = null;
      return isBuggy;
    })();

    function update(element, content) {
      element = $(element);

      if (content && content.toElement)
        content = content.toElement();

      if (Object.isElement(content))
        return element.update().insert(content);

      content = Object.toHTML(content);

      var tagName = element.tagName.toUpperCase();

      if (tagName === 'SCRIPT' && SCRIPT_ELEMENT_REJECTS_TEXTNODE_APPENDING) {
        element.text = content;
        return element;
      }

      if (SELECT_ELEMENT_INNERHTML_BUGGY || TABLE_ELEMENT_INNERHTML_BUGGY) {
        if (tagName in Element._insertionTranslations.tags) {
          while (element.firstChild) {
            element.removeChild(element.firstChild);
          }
          Element._getContentFromAnonymousElement(tagName, content.stripScripts())
            .each(function(node) {
              element.appendChild(node)
            });
        }
        else {
          element.innerHTML = content.stripScripts();
        }
      }
      else {
        element.innerHTML = content.stripScripts();
      }

      content.evalScripts.bind(content).defer();
      return element;
    }

    return update;
  })(),

  replace: function(element, content) {
    element = $(element);
    if (content && content.toElement) content = content.toElement();
    else if (!Object.isElement(content)) {
      content = Object.toHTML(content);
      var range = element.ownerDocument.createRange();
      range.selectNode(element);
      content.evalScripts.bind(content).defer();
      content = range.createContextualFragment(content.stripScripts());
    }
    element.parentNode.replaceChild(content, element);
    return element;
  },

  insert: function(element, insertions) {
    element = $(element);

    if (Object.isString(insertions) || Object.isNumber(insertions) ||
        Object.isElement(insertions) || (insertions && (insertions.toElement || insertions.toHTML)))
          insertions = {bottom:insertions};

    var content, insert, tagName, childNodes;

    for (var position in insertions) {
      content  = insertions[position];
      position = position.toLowerCase();
      insert = Element._insertionTranslations[position];

      if (content && content.toElement) content = content.toElement();
      if (Object.isElement(content)) {
        insert(element, content);
        continue;
      }

      content = Object.toHTML(content);

      tagName = ((position == 'before' || position == 'after')
        ? element.parentNode : element).tagName.toUpperCase();

      childNodes = Element._getContentFromAnonymousElement(tagName, content.stripScripts());

      if (position == 'top' || position == 'after') childNodes.reverse();
      childNodes.each(insert.curry(element));

      content.evalScripts.bind(content).defer();
    }

    return element;
  },

  wrap: function(element, wrapper, attributes) {
    element = $(element);
    if (Object.isElement(wrapper))
      $(wrapper).writeAttribute(attributes || { });
    else if (Object.isString(wrapper)) wrapper = new Element(wrapper, attributes);
    else wrapper = new Element('div', wrapper);
    if (element.parentNode)
      element.parentNode.replaceChild(wrapper, element);
    wrapper.appendChild(element);
    return wrapper;
  },

  inspect: function(element) {
    element = $(element);
    var result = '<' + element.tagName.toLowerCase();
    $H({'id': 'id', 'className': 'class'}).each(function(pair) {
      var property = pair.first(), attribute = pair.last();
      var value = (element[property] || '').toString();
      if (value) result += ' ' + attribute + '=' + value.inspect(true);
    });
    return result + '>';
  },

  recursivelyCollect: function(element, property) {
    element = $(element);
    var elements = [];
    while (element = element[property])
      if (element.nodeType == 1)
        elements.push(Element.extend(element));
    return elements;
  },

  ancestors: function(element) {
    return Element.recursivelyCollect(element, 'parentNode');
  },

  descendants: function(element) {
    return Element.select(element, "*");
  },

  firstDescendant: function(element) {
    element = $(element).firstChild;
    while (element && element.nodeType != 1) element = element.nextSibling;
    return $(element);
  },

  immediateDescendants: function(element) {
    if (!(element = $(element).firstChild)) return [];
    while (element && element.nodeType != 1) element = element.nextSibling;
    if (element) return [element].concat($(element).nextSiblings());
    return [];
  },

  previousSiblings: function(element) {
    return Element.recursivelyCollect(element, 'previousSibling');
  },

  nextSiblings: function(element) {
    return Element.recursivelyCollect(element, 'nextSibling');
  },

  siblings: function(element) {
    element = $(element);
    return Element.previousSiblings(element).reverse()
      .concat(Element.nextSiblings(element));
  },

  match: function(element, selector) {
    if (Object.isString(selector))
      selector = new Selector(selector);
    return selector.match($(element));
  },

  up: function(element, expression, index) {
    element = $(element);
    if (arguments.length == 1) return $(element.parentNode);
    var ancestors = Element.ancestors(element);
    return Object.isNumber(expression) ? ancestors[expression] :
      Selector.findElement(ancestors, expression, index);
  },

  down: function(element, expression, index) {
    element = $(element);
    if (arguments.length == 1) return Element.firstDescendant(element);
    return Object.isNumber(expression) ? Element.descendants(element)[expression] :
      Element.select(element, expression)[index || 0];
  },

  previous: function(element, expression, index) {
    element = $(element);
    if (arguments.length == 1) return $(Selector.handlers.previousElementSibling(element));
    var previousSiblings = Element.previousSiblings(element);
    return Object.isNumber(expression) ? previousSiblings[expression] :
      Selector.findElement(previousSiblings, expression, index);
  },

  next: function(element, expression, index) {
    element = $(element);
    if (arguments.length == 1) return $(Selector.handlers.nextElementSibling(element));
    var nextSiblings = Element.nextSiblings(element);
    return Object.isNumber(expression) ? nextSiblings[expression] :
      Selector.findElement(nextSiblings, expression, index);
  },


  select: function(element) {
    var args = Array.prototype.slice.call(arguments, 1);
    return Selector.findChildElements(element, args);
  },

  adjacent: function(element) {
    var args = Array.prototype.slice.call(arguments, 1);
    return Selector.findChildElements(element.parentNode, args).without(element);
  },

  identify: function(element) {
    element = $(element);
    var id = Element.readAttribute(element, 'id');
    if (id) return id;
    do { id = 'anonymous_element_' + Element.idCounter++ } while ($(id));
    Element.writeAttribute(element, 'id', id);
    return id;
  },

  readAttribute: (function(){

    var iframeGetAttributeThrowsError = (function(){
      var el = document.createElement('iframe'),
          isBuggy = false;

      document.documentElement.appendChild(el);
      try {
        el.getAttribute('type', 2);
      } catch(e) {
        isBuggy = true;
      }
      document.documentElement.removeChild(el);
      el = null;
      return isBuggy;
    })();

    return function(element, name) {
      element = $(element);
      if (iframeGetAttributeThrowsError &&
          name === 'type' &&
          element.tagName.toUpperCase() == 'IFRAME') {
        return element.getAttribute('type');
      }
      if (Prototype.Browser.IE) {
        var t = Element._attributeTranslations.read;
        if (t.values[name]) return t.values[name](element, name);
        if (t.names[name]) name = t.names[name];
        if (name.include(':')) {
          return (!element.attributes || !element.attributes[name]) ? null :
           element.attributes[name].value;
        }
      }
      return element.getAttribute(name);
    }
  })(),

  writeAttribute: function(element, name, value) {
    element = $(element);
    var attributes = { }, t = Element._attributeTranslations.write;

    if (typeof name == 'object') attributes = name;
    else attributes[name] = Object.isUndefined(value) ? true : value;

    for (var attr in attributes) {
      name = t.names[attr] || attr;
      value = attributes[attr];
      if (t.values[attr]) name = t.values[attr](element, value);
      if (value === false || value === null)
        element.removeAttribute(name);
      else if (value === true)
        element.setAttribute(name, name);
      else element.setAttribute(name, value);
    }
    return element;
  },

  getHeight: function(element) {
    return Element.getDimensions(element).height;
  },

  getWidth: function(element) {
    return Element.getDimensions(element).width;
  },

  classNames: function(element) {
    return new Element.ClassNames(element);
  },

  hasClassName: function(element, className) {
    if (!(element = $(element))) return;
    var elementClassName = element.className;
    return (elementClassName.length > 0 && (elementClassName == className ||
      new RegExp("(^|\\s)" + className + "(\\s|$)").test(elementClassName)));
  },

  addClassName: function(element, className) {
    if (!(element = $(element))) return;
    if (!Element.hasClassName(element, className))
      element.className += (element.className ? ' ' : '') + className;
    return element;
  },

  removeClassName: function(element, className) {
    if (!(element = $(element))) return;
    element.className = element.className.replace(
      new RegExp("(^|\\s+)" + className + "(\\s+|$)"), ' ').strip();
    return element;
  },

  toggleClassName: function(element, className) {
    if (!(element = $(element))) return;
    return Element[Element.hasClassName(element, className) ?
      'removeClassName' : 'addClassName'](element, className);
  },

  cleanWhitespace: function(element) {
    element = $(element);
    var node = element.firstChild;
    while (node) {
      var nextNode = node.nextSibling;
      if (node.nodeType == 3 && !/\S/.test(node.nodeValue))
        element.removeChild(node);
      node = nextNode;
    }
    return element;
  },

  empty: function(element) {
    return $(element).innerHTML.blank();
  },

  descendantOf: function(element, ancestor) {
    element = $(element), ancestor = $(ancestor);

    if (element.compareDocumentPosition)
      return (element.compareDocumentPosition(ancestor) & 8) === 8;

    if (ancestor.contains)
      return ancestor.contains(element) && ancestor !== element;

    while (element = element.parentNode)
      if (element == ancestor) return true;

    return false;
  },

  scrollTo: function(element) {
    element = $(element);
    var pos = Element.cumulativeOffset(element);
    window.scrollTo(pos[0], pos[1]);
    return element;
  },

  getStyle: function(element, style) {
    element = $(element);
    style = style == 'float' ? 'cssFloat' : style.camelize();
    var value = element.style[style];
    if (!value || value == 'auto') {
      var css = document.defaultView.getComputedStyle(element, null);
      value = css ? css[style] : null;
    }
    if (style == 'opacity') return value ? parseFloat(value) : 1.0;
    return value == 'auto' ? null : value;
  },

  getOpacity: function(element) {
    return $(element).getStyle('opacity');
  },

  setStyle: function(element, styles) {
    element = $(element);
    var elementStyle = element.style, match;
    if (Object.isString(styles)) {
      element.style.cssText += ';' + styles;
      return styles.include('opacity') ?
        element.setOpacity(styles.match(/opacity:\s*(\d?\.?\d*)/)[1]) : element;
    }
    for (var property in styles)
      if (property == 'opacity') element.setOpacity(styles[property]);
      else
        elementStyle[(property == 'float' || property == 'cssFloat') ?
          (Object.isUndefined(elementStyle.styleFloat) ? 'cssFloat' : 'styleFloat') :
            property] = styles[property];

    return element;
  },

  setOpacity: function(element, value) {
    element = $(element);
    element.style.opacity = (value == 1 || value === '') ? '' :
      (value < 0.00001) ? 0 : value;
    return element;
  },

  getDimensions: function(element) {
    element = $(element);
    var display = Element.getStyle(element, 'display');
    if (display != 'none' && display != null) // Safari bug
      return {width: element.offsetWidth, height: element.offsetHeight};

    var els = element.style;
    var originalVisibility = els.visibility;
    var originalPosition = els.position;
    var originalDisplay = els.display;
    els.visibility = 'hidden';
    if (originalPosition != 'fixed') // Switching fixed to absolute causes issues in Safari
      els.position = 'absolute';
    els.display = 'block';
    var originalWidth = element.clientWidth;
    var originalHeight = element.clientHeight;
    els.display = originalDisplay;
    els.position = originalPosition;
    els.visibility = originalVisibility;
    return {width: originalWidth, height: originalHeight};
  },

  makePositioned: function(element) {
    element = $(element);
    var pos = Element.getStyle(element, 'position');
    if (pos == 'static' || !pos) {
      element._madePositioned = true;
      element.style.position = 'relative';
      if (Prototype.Browser.Opera) {
        element.style.top = 0;
        element.style.left = 0;
      }
    }
    return element;
  },

  undoPositioned: function(element) {
    element = $(element);
    if (element._madePositioned) {
      element._madePositioned = undefined;
      element.style.position =
        element.style.top =
        element.style.left =
        element.style.bottom =
        element.style.right = '';
    }
    return element;
  },

  makeClipping: function(element) {
    element = $(element);
    if (element._overflow) return element;
    element._overflow = Element.getStyle(element, 'overflow') || 'auto';
    if (element._overflow !== 'hidden')
      element.style.overflow = 'hidden';
    return element;
  },

  undoClipping: function(element) {
    element = $(element);
    if (!element._overflow) return element;
    element.style.overflow = element._overflow == 'auto' ? '' : element._overflow;
    element._overflow = null;
    return element;
  },

  cumulativeOffset: function(element) {
    var valueT = 0, valueL = 0;
    do {
      valueT += element.offsetTop  || 0;
      valueL += element.offsetLeft || 0;
      element = element.offsetParent;
    } while (element);
    return Element._returnOffset(valueL, valueT);
  },

  positionedOffset: function(element) {
    var valueT = 0, valueL = 0;
    do {
      valueT += element.offsetTop  || 0;
      valueL += element.offsetLeft || 0;
      element = element.offsetParent;
      if (element) {
        if (element.tagName.toUpperCase() == 'BODY') break;
        var p = Element.getStyle(element, 'position');
        if (p !== 'static') break;
      }
    } while (element);
    return Element._returnOffset(valueL, valueT);
  },

  absolutize: function(element) {
    element = $(element);
    if (Element.getStyle(element, 'position') == 'absolute') return element;

    var offsets = Element.positionedOffset(element);
    var top     = offsets[1];
    var left    = offsets[0];
    var width   = element.clientWidth;
    var height  = element.clientHeight;

    element._originalLeft   = left - parseFloat(element.style.left  || 0);
    element._originalTop    = top  - parseFloat(element.style.top || 0);
    element._originalWidth  = element.style.width;
    element._originalHeight = element.style.height;

    element.style.position = 'absolute';
    element.style.top    = top + 'px';
    element.style.left   = left + 'px';
    element.style.width  = width + 'px';
    element.style.height = height + 'px';
    return element;
  },

  relativize: function(element) {
    element = $(element);
    if (Element.getStyle(element, 'position') == 'relative') return element;

    element.style.position = 'relative';
    var top  = parseFloat(element.style.top  || 0) - (element._originalTop || 0);
    var left = parseFloat(element.style.left || 0) - (element._originalLeft || 0);

    element.style.top    = top + 'px';
    element.style.left   = left + 'px';
    element.style.height = element._originalHeight;
    element.style.width  = element._originalWidth;
    return element;
  },

  cumulativeScrollOffset: function(element) {
    var valueT = 0, valueL = 0;
    do {
      valueT += element.scrollTop  || 0;
      valueL += element.scrollLeft || 0;
      element = element.parentNode;
    } while (element);
    return Element._returnOffset(valueL, valueT);
  },

  getOffsetParent: function(element) {
    if (element.offsetParent) return $(element.offsetParent);
    if (element == document.body) return $(element);

    while ((element = element.parentNode) && element != document.body)
      if (Element.getStyle(element, 'position') != 'static')
        return $(element);

    return $(document.body);
  },

  viewportOffset: function(forElement) {
    var valueT = 0, valueL = 0;

    var element = forElement;
    do {
      valueT += element.offsetTop  || 0;
      valueL += element.offsetLeft || 0;

      if (element.offsetParent == document.body &&
        Element.getStyle(element, 'position') == 'absolute') break;

    } while (element = element.offsetParent);

    element = forElement;
    do {
      if (!Prototype.Browser.Opera || (element.tagName && (element.tagName.toUpperCase() == 'BODY'))) {
        valueT -= element.scrollTop  || 0;
        valueL -= element.scrollLeft || 0;
      }
    } while (element = element.parentNode);

    return Element._returnOffset(valueL, valueT);
  },

  clonePosition: function(element, source) {
    var options = Object.extend({
      setLeft:    true,
      setTop:     true,
      setWidth:   true,
      setHeight:  true,
      offsetTop:  0,
      offsetLeft: 0
    }, arguments[2] || { });

    source = $(source);
    var p = Element.viewportOffset(source);

    element = $(element);
    var delta = [0, 0];
    var parent = null;
    if (Element.getStyle(element, 'position') == 'absolute') {
      parent = Element.getOffsetParent(element);
      delta = Element.viewportOffset(parent);
    }

    if (parent == document.body) {
      delta[0] -= document.body.offsetLeft;
      delta[1] -= document.body.offsetTop;
    }

    if (options.setLeft)   element.style.left  = (p[0] - delta[0] + options.offsetLeft) + 'px';
    if (options.setTop)    element.style.top   = (p[1] - delta[1] + options.offsetTop) + 'px';
    if (options.setWidth)  element.style.width = source.offsetWidth + 'px';
    if (options.setHeight) element.style.height = source.offsetHeight + 'px';
    return element;
  }
};

Object.extend(Element.Methods, {
  getElementsBySelector: Element.Methods.select,

  childElements: Element.Methods.immediateDescendants
});

Element._attributeTranslations = {
  write: {
    names: {
      className: 'class',
      htmlFor:   'for'
    },
    values: { }
  }
};

if (Prototype.Browser.Opera) {
  Element.Methods.getStyle = Element.Methods.getStyle.wrap(
    function(proceed, element, style) {
      switch (style) {
        case 'left': case 'top': case 'right': case 'bottom':
          if (proceed(element, 'position') === 'static') return null;
        case 'height': case 'width':
          if (!Element.visible(element)) return null;

          var dim = parseInt(proceed(element, style), 10);

          if (dim !== element['offset' + style.capitalize()])
            return dim + 'px';

          var properties;
          if (style === 'height') {
            properties = ['border-top-width', 'padding-top',
             'padding-bottom', 'border-bottom-width'];
          }
          else {
            properties = ['border-left-width', 'padding-left',
             'padding-right', 'border-right-width'];
          }
          return properties.inject(dim, function(memo, property) {
            var val = proceed(element, property);
            return val === null ? memo : memo - parseInt(val, 10);
          }) + 'px';
        default: return proceed(element, style);
      }
    }
  );

  Element.Methods.readAttribute = Element.Methods.readAttribute.wrap(
    function(proceed, element, attribute) {
      if (attribute === 'title') return element.title;
      return proceed(element, attribute);
    }
  );
}

else if (Prototype.Browser.IE) {
  Element.Methods.getOffsetParent = Element.Methods.getOffsetParent.wrap(
    function(proceed, element) {
      element = $(element);
      try { element.offsetParent }
      catch(e) { return $(document.body) }
      var position = element.getStyle('position');
      if (position !== 'static') return proceed(element);
      element.setStyle({ position: 'relative' });
      var value = proceed(element);
      element.setStyle({ position: position });
      return value;
    }
  );

  $w('positionedOffset viewportOffset').each(function(method) {
    Element.Methods[method] = Element.Methods[method].wrap(
      function(proceed, element) {
        element = $(element);
        try { element.offsetParent }
        catch(e) { return Element._returnOffset(0,0) }
        var position = element.getStyle('position');
        if (position !== 'static') return proceed(element);
        var offsetParent = element.getOffsetParent();
        if (offsetParent && offsetParent.getStyle('position') === 'fixed')
          offsetParent.setStyle({ zoom: 1 });
        element.setStyle({ position: 'relative' });
        var value = proceed(element);
        element.setStyle({ position: position });
        return value;
      }
    );
  });

  Element.Methods.cumulativeOffset = Element.Methods.cumulativeOffset.wrap(
    function(proceed, element) {
      try { element.offsetParent }
      catch(e) { return Element._returnOffset(0,0) }
      return proceed(element);
    }
  );

  Element.Methods.getStyle = function(element, style) {
    element = $(element);
    style = (style == 'float' || style == 'cssFloat') ? 'styleFloat' : style.camelize();
    if (style != 'position') {
      var value = element.style[style];
      if (!value && element.currentStyle) value = element.currentStyle[style];
    }
    if (style == 'opacity') {
      if (value = (element.getStyle('filter') || '').match(/alpha\(opacity=(.*)\)/))
        if (value[1]) return parseFloat(value[1]) / 100;
      return 1.0;
    }

    if (value == 'auto') {
      if ((style == 'width' || style == 'height') && (element.getStyle('display') != 'none'))
        return element['offset' + style.capitalize()] + 'px';
      return null;
    }
    return value;
  };

  Element.Methods.setOpacity = function(element, value) {
    function stripAlpha(filter){
      return filter.replace(/alpha\([^\)]*\)/gi,'');
    }
    element = $(element);
    var currentStyle = element.currentStyle;
    if ((currentStyle && !currentStyle.hasLayout) ||
      (!currentStyle && element.style.zoom == 'normal'))
        element.style.zoom = 1;

    var filter = element.getStyle('filter'), style = element.style;
    if (value == 1 || value === '') {
      (filter = stripAlpha(filter)) ?
        style.filter = filter : style.removeAttribute('filter');
      return element;
    } else if (value < 0.00001) value = 0;
    style.filter = stripAlpha(filter) +
      'alpha(opacity=' + (value * 100) + ')';
    return element;
  };

  Element._attributeTranslations = (function(){

    var classProp = 'className';
    var forProp = 'for';

    var el = document.createElement('div');

    el.setAttribute(classProp, 'x');

    if (el.className !== 'x') {
      el.setAttribute('class', 'x');
      if (el.className === 'x') {
        classProp = 'class';
      }
    }
    el = null;

    el = document.createElement('label');
    el.setAttribute(forProp, 'x');
    if (el.htmlFor !== 'x') {
      el.setAttribute('htmlFor', 'x');
      if (el.htmlFor === 'x') {
        forProp = 'htmlFor';
      }
    }
    el = null;

    return {
      read: {
        names: {
          'class':      classProp,
          'className':  classProp,
          'for':        forProp,
          'htmlFor':    forProp
        },
        values: {
          _getAttr: function(element, attribute) {
            return element.getAttribute(attribute, 2);
          },
          _getAttrNode: function(element, attribute) {
            var node = element.getAttributeNode(attribute);
            return node ? node.value : "";
          },
          _getEv: (function(){

            var el = document.createElement('div');
            el.onclick = Prototype.emptyFunction;
            var value = el.getAttribute('onclick');
            var f;

            if (String(value).indexOf('{') > -1) {
              f = function(element, attribute) {
                attribute = element.getAttribute(attribute);
                if (!attribute) return null;
                attribute = attribute.toString();
                attribute = attribute.split('{')[1];
                attribute = attribute.split('}')[0];
                return attribute.strip();
              }
            }
            else if (value === '') {
              f = function(element, attribute) {
                attribute = element.getAttribute(attribute);
                if (!attribute) return null;
                return attribute.strip();
              }
            }
            el = null;
            return f;
          })(),
          _flag: function(element, attribute) {
            return $(element).hasAttribute(attribute) ? attribute : null;
          },
          style: function(element) {
            return element.style.cssText.toLowerCase();
          },
          title: function(element) {
            return element.title;
          }
        }
      }
    }
  })();

  Element._attributeTranslations.write = {
    names: Object.extend({
      cellpadding: 'cellPadding',
      cellspacing: 'cellSpacing'
    }, Element._attributeTranslations.read.names),
    values: {
      checked: function(element, value) {
        element.checked = !!value;
      },

      style: function(element, value) {
        element.style.cssText = value ? value : '';
      }
    }
  };

  Element._attributeTranslations.has = {};

  $w('colSpan rowSpan vAlign dateTime accessKey tabIndex ' +
      'encType maxLength readOnly longDesc frameBorder').each(function(attr) {
    Element._attributeTranslations.write.names[attr.toLowerCase()] = attr;
    Element._attributeTranslations.has[attr.toLowerCase()] = attr;
  });

  (function(v) {
    Object.extend(v, {
      href:        v._getAttr,
      src:         v._getAttr,
      type:        v._getAttr,
      action:      v._getAttrNode,
      disabled:    v._flag,
      checked:     v._flag,
      readonly:    v._flag,
      multiple:    v._flag,
      onload:      v._getEv,
      onunload:    v._getEv,
      onclick:     v._getEv,
      ondblclick:  v._getEv,
      onmousedown: v._getEv,
      onmouseup:   v._getEv,
      onmouseover: v._getEv,
      onmousemove: v._getEv,
      onmouseout:  v._getEv,
      onfocus:     v._getEv,
      onblur:      v._getEv,
      onkeypress:  v._getEv,
      onkeydown:   v._getEv,
      onkeyup:     v._getEv,
      onsubmit:    v._getEv,
      onreset:     v._getEv,
      onselect:    v._getEv,
      onchange:    v._getEv
    });
  })(Element._attributeTranslations.read.values);

  if (Prototype.BrowserFeatures.ElementExtensions) {
    (function() {
      function _descendants(element) {
        var nodes = element.getElementsByTagName('*'), results = [];
        for (var i = 0, node; node = nodes[i]; i++)
          if (node.tagName !== "!") // Filter out comment nodes.
            results.push(node);
        return results;
      }

      Element.Methods.down = function(element, expression, index) {
        element = $(element);
        if (arguments.length == 1) return element.firstDescendant();
        return Object.isNumber(expression) ? _descendants(element)[expression] :
          Element.select(element, expression)[index || 0];
      }
    })();
  }

}

else if (Prototype.Browser.Gecko && /rv:1\.8\.0/.test(navigator.userAgent)) {
  Element.Methods.setOpacity = function(element, value) {
    element = $(element);
    element.style.opacity = (value == 1) ? 0.999999 :
      (value === '') ? '' : (value < 0.00001) ? 0 : value;
    return element;
  };
}

else if (Prototype.Browser.WebKit) {
  Element.Methods.setOpacity = function(element, value) {
    element = $(element);
    element.style.opacity = (value == 1 || value === '') ? '' :
      (value < 0.00001) ? 0 : value;

    if (value == 1)
      if(element.tagName.toUpperCase() == 'IMG' && element.width) {
        element.width++; element.width--;
      } else try {
        var n = document.createTextNode(' ');
        element.appendChild(n);
        element.removeChild(n);
      } catch (e) { }

    return element;
  };

  Element.Methods.cumulativeOffset = function(element) {
    var valueT = 0, valueL = 0;
    do {
      valueT += element.offsetTop  || 0;
      valueL += element.offsetLeft || 0;
      if (element.offsetParent == document.body)
        if (Element.getStyle(element, 'position') == 'absolute') break;

      element = element.offsetParent;
    } while (element);

    return Element._returnOffset(valueL, valueT);
  };
}

if ('outerHTML' in document.documentElement) {
  Element.Methods.replace = function(element, content) {
    element = $(element);

    if (content && content.toElement) content = content.toElement();
    if (Object.isElement(content)) {
      element.parentNode.replaceChild(content, element);
      return element;
    }

    content = Object.toHTML(content);
    var parent = element.parentNode, tagName = parent.tagName.toUpperCase();

    if (Element._insertionTranslations.tags[tagName]) {
      var nextSibling = element.next();
      var fragments = Element._getContentFromAnonymousElement(tagName, content.stripScripts());
      parent.removeChild(element);
      if (nextSibling)
        fragments.each(function(node) { parent.insertBefore(node, nextSibling) });
      else
        fragments.each(function(node) { parent.appendChild(node) });
    }
    else element.outerHTML = content.stripScripts();

    content.evalScripts.bind(content).defer();
    return element;
  };
}

Element._returnOffset = function(l, t) {
  var result = [l, t];
  result.left = l;
  result.top = t;
  return result;
};

Element._getContentFromAnonymousElement = function(tagName, html) {
  var div = new Element('div'), t = Element._insertionTranslations.tags[tagName];
  if (t) {
    div.innerHTML = t[0] + html + t[1];
    t[2].times(function() { div = div.firstChild });
  } else div.innerHTML = html;
  return $A(div.childNodes);
};

Element._insertionTranslations = {
  before: function(element, node) {
    element.parentNode.insertBefore(node, element);
  },
  top: function(element, node) {
    element.insertBefore(node, element.firstChild);
  },
  bottom: function(element, node) {
    element.appendChild(node);
  },
  after: function(element, node) {
    element.parentNode.insertBefore(node, element.nextSibling);
  },
  tags: {
    TABLE:  ['<table>',                '</table>',                   1],
    TBODY:  ['<table><tbody>',         '</tbody></table>',           2],
    TR:     ['<table><tbody><tr>',     '</tr></tbody></table>',      3],
    TD:     ['<table><tbody><tr><td>', '</td></tr></tbody></table>', 4],
    SELECT: ['<select>',               '</select>',                  1]
  }
};

(function() {
  var tags = Element._insertionTranslations.tags;
  Object.extend(tags, {
    THEAD: tags.TBODY,
    TFOOT: tags.TBODY,
    TH:    tags.TD
  });
})();

Element.Methods.Simulated = {
  hasAttribute: function(element, attribute) {
    attribute = Element._attributeTranslations.has[attribute] || attribute;
    var node = $(element).getAttributeNode(attribute);
    return !!(node && node.specified);
  }
};

Element.Methods.ByTag = { };

Object.extend(Element, Element.Methods);

(function(div) {

  if (!Prototype.BrowserFeatures.ElementExtensions && div['__proto__']) {
    window.HTMLElement = { };
    window.HTMLElement.prototype = div['__proto__'];
    Prototype.BrowserFeatures.ElementExtensions = true;
  }

  div = null;

})(document.createElement('div'))

Element.extend = (function() {

  function checkDeficiency(tagName) {
    if (typeof window.Element != 'undefined') {
      var proto = window.Element.prototype;
      if (proto) {
        var id = '_' + (Math.random()+'').slice(2);
        var el = document.createElement(tagName);
        proto[id] = 'x';
        var isBuggy = (el[id] !== 'x');
        delete proto[id];
        el = null;
        return isBuggy;
      }
    }
    return false;
  }

  function extendElementWith(element, methods) {
    for (var property in methods) {
      var value = methods[property];
      if (Object.isFunction(value) && !(property in element))
        element[property] = value.methodize();
    }
  }

  var HTMLOBJECTELEMENT_PROTOTYPE_BUGGY = checkDeficiency('object');
  var HTMLAPPLETELEMENT_PROTOTYPE_BUGGY = checkDeficiency('applet');

  if (Prototype.BrowserFeatures.SpecificElementExtensions) {
    if (HTMLOBJECTELEMENT_PROTOTYPE_BUGGY &&
        HTMLAPPLETELEMENT_PROTOTYPE_BUGGY) {
      return function(element) {
        if (element && typeof element._extendedByPrototype == 'undefined') {
          var t = element.tagName;
          if (t && (/^(?:object|applet|embed)$/i.test(t))) {
            extendElementWith(element, Element.Methods);
            extendElementWith(element, Element.Methods.Simulated);
            extendElementWith(element, Element.Methods.ByTag[t.toUpperCase()]);
          }
        }
        return element;
      }
    }
    return Prototype.K;
  }

  var Methods = { }, ByTag = Element.Methods.ByTag;

  var extend = Object.extend(function(element) {
    if (!element || typeof element._extendedByPrototype != 'undefined' ||
        element.nodeType != 1 || element == window) return element;

    var methods = Object.clone(Methods),
        tagName = element.tagName.toUpperCase();

    if (ByTag[tagName]) Object.extend(methods, ByTag[tagName]);

    extendElementWith(element, methods);

    element._extendedByPrototype = Prototype.emptyFunction;
    return element;

  }, {
    refresh: function() {
      if (!Prototype.BrowserFeatures.ElementExtensions) {
        Object.extend(Methods, Element.Methods);
        Object.extend(Methods, Element.Methods.Simulated);
      }
    }
  });

  extend.refresh();
  return extend;
})();

Element.hasAttribute = function(element, attribute) {
  if (element.hasAttribute) return element.hasAttribute(attribute);
  return Element.Methods.Simulated.hasAttribute(element, attribute);
};

Element.addMethods = function(methods) {
  var F = Prototype.BrowserFeatures, T = Element.Methods.ByTag;

  if (!methods) {
    Object.extend(Form, Form.Methods);
    Object.extend(Form.Element, Form.Element.Methods);
    Object.extend(Element.Methods.ByTag, {
      "FORM":     Object.clone(Form.Methods),
      "INPUT":    Object.clone(Form.Element.Methods),
      "SELECT":   Object.clone(Form.Element.Methods),
      "TEXTAREA": Object.clone(Form.Element.Methods)
    });
  }

  if (arguments.length == 2) {
    var tagName = methods;
    methods = arguments[1];
  }

  if (!tagName) Object.extend(Element.Methods, methods || { });
  else {
    if (Object.isArray(tagName)) tagName.each(extend);
    else extend(tagName);
  }

  function extend(tagName) {
    tagName = tagName.toUpperCase();
    if (!Element.Methods.ByTag[tagName])
      Element.Methods.ByTag[tagName] = { };
    Object.extend(Element.Methods.ByTag[tagName], methods);
  }

  function copy(methods, destination, onlyIfAbsent) {
    onlyIfAbsent = onlyIfAbsent || false;
    for (var property in methods) {
      var value = methods[property];
      if (!Object.isFunction(value)) continue;
      if (!onlyIfAbsent || !(property in destination))
        destination[property] = value.methodize();
    }
  }

  function findDOMClass(tagName) {
    var klass;
    var trans = {
      "OPTGROUP": "OptGroup", "TEXTAREA": "TextArea", "P": "Paragraph",
      "FIELDSET": "FieldSet", "UL": "UList", "OL": "OList", "DL": "DList",
      "DIR": "Directory", "H1": "Heading", "H2": "Heading", "H3": "Heading",
      "H4": "Heading", "H5": "Heading", "H6": "Heading", "Q": "Quote",
      "INS": "Mod", "DEL": "Mod", "A": "Anchor", "IMG": "Image", "CAPTION":
      "TableCaption", "COL": "TableCol", "COLGROUP": "TableCol", "THEAD":
      "TableSection", "TFOOT": "TableSection", "TBODY": "TableSection", "TR":
      "TableRow", "TH": "TableCell", "TD": "TableCell", "FRAMESET":
      "FrameSet", "IFRAME": "IFrame"
    };
    if (trans[tagName]) klass = 'HTML' + trans[tagName] + 'Element';
    if (window[klass]) return window[klass];
    klass = 'HTML' + tagName + 'Element';
    if (window[klass]) return window[klass];
    klass = 'HTML' + tagName.capitalize() + 'Element';
    if (window[klass]) return window[klass];

    var element = document.createElement(tagName);
    var proto = element['__proto__'] || element.constructor.prototype;
    element = null;
    return proto;
  }

  var elementPrototype = window.HTMLElement ? HTMLElement.prototype :
   Element.prototype;

  if (F.ElementExtensions) {
    copy(Element.Methods, elementPrototype);
    copy(Element.Methods.Simulated, elementPrototype, true);
  }

  if (F.SpecificElementExtensions) {
    for (var tag in Element.Methods.ByTag) {
      var klass = findDOMClass(tag);
      if (Object.isUndefined(klass)) continue;
      copy(T[tag], klass.prototype);
    }
  }

  Object.extend(Element, Element.Methods);
  delete Element.ByTag;

  if (Element.extend.refresh) Element.extend.refresh();
  Element.cache = { };
};


document.viewport = {

  getDimensions: function() {
    return { width: this.getWidth(), height: this.getHeight() };
  },

  getScrollOffsets: function() {
    return Element._returnOffset(
      window.pageXOffset || document.documentElement.scrollLeft || document.body.scrollLeft,
      window.pageYOffset || document.documentElement.scrollTop  || document.body.scrollTop);
  }
};

(function(viewport) {
  var B = Prototype.Browser, doc = document, element, property = {};

  function getRootElement() {
    if (B.WebKit && !doc.evaluate)
      return document;

    if (B.Opera && window.parseFloat(window.opera.version()) < 9.5)
      return document.body;

    return document.documentElement;
  }

  function define(D) {
    if (!element) element = getRootElement();

    property[D] = 'client' + D;

    viewport['get' + D] = function() { return element[property[D]] };
    return viewport['get' + D]();
  }

  viewport.getWidth  = define.curry('Width');

  viewport.getHeight = define.curry('Height');
})(document.viewport);


Element.Storage = {
  UID: 1
};

Element.addMethods({
  getStorage: function(element) {
    if (!(element = $(element))) return;

    var uid;
    if (element === window) {
      uid = 0;
    } else {
      if (typeof element._prototypeUID === "undefined")
        element._prototypeUID = [Element.Storage.UID++];
      uid = element._prototypeUID[0];
    }

    if (!Element.Storage[uid])
      Element.Storage[uid] = $H();

    return Element.Storage[uid];
  },

  store: function(element, key, value) {
    if (!(element = $(element))) return;

    if (arguments.length === 2) {
      Element.getStorage(element).update(key);
    } else {
      Element.getStorage(element).set(key, value);
    }

    return element;
  },

  retrieve: function(element, key, defaultValue) {
    if (!(element = $(element))) return;
    var hash = Element.getStorage(element), value = hash.get(key);

    if (Object.isUndefined(value)) {
      hash.set(key, defaultValue);
      value = defaultValue;
    }

    return value;
  },

  clone: function(element, deep) {
    if (!(element = $(element))) return;
    var clone = element.cloneNode(deep);
    clone._prototypeUID = void 0;
    if (deep) {
      var descendants = Element.select(clone, '*'),
          i = descendants.length;
      while (i--) {
        descendants[i]._prototypeUID = void 0;
      }
    }
    return Element.extend(clone);
  }
});
/* Portions of the Selector class are derived from Jack Slocum's DomQuery,
 * part of YUI-Ext version 0.40, distributed under the terms of an MIT-style
 * license.  Please see http://www.yui-ext.com/ for more information. */

var Selector = Class.create({
  initialize: function(expression) {
    this.expression = expression.strip();

    if (this.shouldUseSelectorsAPI()) {
      this.mode = 'selectorsAPI';
    } else if (this.shouldUseXPath()) {
      this.mode = 'xpath';
      this.compileXPathMatcher();
    } else {
      this.mode = "normal";
      this.compileMatcher();
    }

  },

  shouldUseXPath: (function() {

    var IS_DESCENDANT_SELECTOR_BUGGY = (function(){
      var isBuggy = false;
      if (document.evaluate && window.XPathResult) {
        var el = document.createElement('div');
        el.innerHTML = '<ul><li></li></ul><div><ul><li></li></ul></div>';

        var xpath = ".//*[local-name()='ul' or local-name()='UL']" +
          "//*[local-name()='li' or local-name()='LI']";

        var result = document.evaluate(xpath, el, null,
          XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);

        isBuggy = (result.snapshotLength !== 2);
        el = null;
      }
      return isBuggy;
    })();

    return function() {
      if (!Prototype.BrowserFeatures.XPath) return false;

      var e = this.expression;

      if (Prototype.Browser.WebKit &&
       (e.include("-of-type") || e.include(":empty")))
        return false;

      if ((/(\[[\w-]*?:|:checked)/).test(e))
        return false;

      if (IS_DESCENDANT_SELECTOR_BUGGY) return false;

      return true;
    }

  })(),

  shouldUseSelectorsAPI: function() {
    if (!Prototype.BrowserFeatures.SelectorsAPI) return false;

    if (Selector.CASE_INSENSITIVE_CLASS_NAMES) return false;

    if (!Selector._div) Selector._div = new Element('div');

    try {
      Selector._div.querySelector(this.expression);
    } catch(e) {
      return false;
    }

    return true;
  },

  compileMatcher: function() {
    var e = this.expression, ps = Selector.patterns, h = Selector.handlers,
        c = Selector.criteria, le, p, m, len = ps.length, name;

    if (Selector._cache[e]) {
      this.matcher = Selector._cache[e];
      return;
    }

    this.matcher = ["this.matcher = function(root) {",
                    "var r = root, h = Selector.handlers, c = false, n;"];

    while (e && le != e && (/\S/).test(e)) {
      le = e;
      for (var i = 0; i<len; i++) {
        p = ps[i].re;
        name = ps[i].name;
        if (m = e.match(p)) {
          this.matcher.push(Object.isFunction(c[name]) ? c[name](m) :
            new Template(c[name]).evaluate(m));
          e = e.replace(m[0], '');
          break;
        }
      }
    }

    this.matcher.push("return h.unique(n);\n}");
    eval(this.matcher.join('\n'));
    Selector._cache[this.expression] = this.matcher;
  },

  compileXPathMatcher: function() {
    var e = this.expression, ps = Selector.patterns,
        x = Selector.xpath, le, m, len = ps.length, name;

    if (Selector._cache[e]) {
      this.xpath = Selector._cache[e]; return;
    }

    this.matcher = ['.//*'];
    while (e && le != e && (/\S/).test(e)) {
      le = e;
      for (var i = 0; i<len; i++) {
        name = ps[i].name;
        if (m = e.match(ps[i].re)) {
          this.matcher.push(Object.isFunction(x[name]) ? x[name](m) :
            new Template(x[name]).evaluate(m));
          e = e.replace(m[0], '');
          break;
        }
      }
    }

    this.xpath = this.matcher.join('');
    Selector._cache[this.expression] = this.xpath;
  },

  findElements: function(root) {
    root = root || document;
    var e = this.expression, results;

    switch (this.mode) {
      case 'selectorsAPI':
        if (root !== document) {
          var oldId = root.id, id = $(root).identify();
          id = id.replace(/[\.:]/g, "\\$0");
          e = "#" + id + " " + e;
        }

        results = $A(root.querySelectorAll(e)).map(Element.extend);
        root.id = oldId;

        return results;
      case 'xpath':
        return document._getElementsByXPath(this.xpath, root);
      default:
       return this.matcher(root);
    }
  },

  match: function(element) {
    this.tokens = [];

    var e = this.expression, ps = Selector.patterns, as = Selector.assertions;
    var le, p, m, len = ps.length, name;

    while (e && le !== e && (/\S/).test(e)) {
      le = e;
      for (var i = 0; i<len; i++) {
        p = ps[i].re;
        name = ps[i].name;
        if (m = e.match(p)) {
          if (as[name]) {
            this.tokens.push([name, Object.clone(m)]);
            e = e.replace(m[0], '');
          } else {
            return this.findElements(document).include(element);
          }
        }
      }
    }

    var match = true, name, matches;
    for (var i = 0, token; token = this.tokens[i]; i++) {
      name = token[0], matches = token[1];
      if (!Selector.assertions[name](element, matches)) {
        match = false; break;
      }
    }

    return match;
  },

  toString: function() {
    return this.expression;
  },

  inspect: function() {
    return "#<Selector:" + this.expression.inspect() + ">";
  }
});

if (Prototype.BrowserFeatures.SelectorsAPI &&
 document.compatMode === 'BackCompat') {
  Selector.CASE_INSENSITIVE_CLASS_NAMES = (function(){
    var div = document.createElement('div'),
     span = document.createElement('span');

    div.id = "prototype_test_id";
    span.className = 'Test';
    div.appendChild(span);
    var isIgnored = (div.querySelector('#prototype_test_id .test') !== null);
    div = span = null;
    return isIgnored;
  })();
}

Object.extend(Selector, {
  _cache: { },

  xpath: {
    descendant:   "//*",
    child:        "/*",
    adjacent:     "/following-sibling::*[1]",
    laterSibling: '/following-sibling::*',
    tagName:      function(m) {
      if (m[1] == '*') return '';
      return "[local-name()='" + m[1].toLowerCase() +
             "' or local-name()='" + m[1].toUpperCase() + "']";
    },
    className:    "[contains(concat(' ', @class, ' '), ' #{1} ')]",
    id:           "[@id='#{1}']",
    attrPresence: function(m) {
      m[1] = m[1].toLowerCase();
      return new Template("[@#{1}]").evaluate(m);
    },
    attr: function(m) {
      m[1] = m[1].toLowerCase();
      m[3] = m[5] || m[6];
      return new Template(Selector.xpath.operators[m[2]]).evaluate(m);
    },
    pseudo: function(m) {
      var h = Selector.xpath.pseudos[m[1]];
      if (!h) return '';
      if (Object.isFunction(h)) return h(m);
      return new Template(Selector.xpath.pseudos[m[1]]).evaluate(m);
    },
    operators: {
      '=':  "[@#{1}='#{3}']",
      '!=': "[@#{1}!='#{3}']",
      '^=': "[starts-with(@#{1}, '#{3}')]",
      '$=': "[substring(@#{1}, (string-length(@#{1}) - string-length('#{3}') + 1))='#{3}']",
      '*=': "[contains(@#{1}, '#{3}')]",
      '~=': "[contains(concat(' ', @#{1}, ' '), ' #{3} ')]",
      '|=': "[contains(concat('-', @#{1}, '-'), '-#{3}-')]"
    },
    pseudos: {
      'first-child': '[not(preceding-sibling::*)]',
      'last-child':  '[not(following-sibling::*)]',
      'only-child':  '[not(preceding-sibling::* or following-sibling::*)]',
      'empty':       "[count(*) = 0 and (count(text()) = 0)]",
      'checked':     "[@checked]",
      'disabled':    "[(@disabled) and (@type!='hidden')]",
      'enabled':     "[not(@disabled) and (@type!='hidden')]",
      'not': function(m) {
        var e = m[6], p = Selector.patterns,
            x = Selector.xpath, le, v, len = p.length, name;

        var exclusion = [];
        while (e && le != e && (/\S/).test(e)) {
          le = e;
          for (var i = 0; i<len; i++) {
            name = p[i].name
            if (m = e.match(p[i].re)) {
              v = Object.isFunction(x[name]) ? x[name](m) : new Template(x[name]).evaluate(m);
              exclusion.push("(" + v.substring(1, v.length - 1) + ")");
              e = e.replace(m[0], '');
              break;
            }
          }
        }
        return "[not(" + exclusion.join(" and ") + ")]";
      },
      'nth-child':      function(m) {
        return Selector.xpath.pseudos.nth("(count(./preceding-sibling::*) + 1) ", m);
      },
      'nth-last-child': function(m) {
        return Selector.xpath.pseudos.nth("(count(./following-sibling::*) + 1) ", m);
      },
      'nth-of-type':    function(m) {
        return Selector.xpath.pseudos.nth("position() ", m);
      },
      'nth-last-of-type': function(m) {
        return Selector.xpath.pseudos.nth("(last() + 1 - position()) ", m);
      },
      'first-of-type':  function(m) {
        m[6] = "1"; return Selector.xpath.pseudos['nth-of-type'](m);
      },
      'last-of-type':   function(m) {
        m[6] = "1"; return Selector.xpath.pseudos['nth-last-of-type'](m);
      },
      'only-of-type':   function(m) {
        var p = Selector.xpath.pseudos; return p['first-of-type'](m) + p['last-of-type'](m);
      },
      nth: function(fragment, m) {
        var mm, formula = m[6], predicate;
        if (formula == 'even') formula = '2n+0';
        if (formula == 'odd')  formula = '2n+1';
        if (mm = formula.match(/^(\d+)$/)) // digit only
          return '[' + fragment + "= " + mm[1] + ']';
        if (mm = formula.match(/^(-?\d*)?n(([+-])(\d+))?/)) { // an+b
          if (mm[1] == "-") mm[1] = -1;
          var a = mm[1] ? Number(mm[1]) : 1;
          var b = mm[2] ? Number(mm[2]) : 0;
          predicate = "[((#{fragment} - #{b}) mod #{a} = 0) and " +
          "((#{fragment} - #{b}) div #{a} >= 0)]";
          return new Template(predicate).evaluate({
            fragment: fragment, a: a, b: b });
        }
      }
    }
  },

  criteria: {
    tagName:      'n = h.tagName(n, r, "#{1}", c);      c = false;',
    className:    'n = h.className(n, r, "#{1}", c);    c = false;',
    id:           'n = h.id(n, r, "#{1}", c);           c = false;',
    attrPresence: 'n = h.attrPresence(n, r, "#{1}", c); c = false;',
    attr: function(m) {
      m[3] = (m[5] || m[6]);
      return new Template('n = h.attr(n, r, "#{1}", "#{3}", "#{2}", c); c = false;').evaluate(m);
    },
    pseudo: function(m) {
      if (m[6]) m[6] = m[6].replace(/"/g, '\\"');
      return new Template('n = h.pseudo(n, "#{1}", "#{6}", r, c); c = false;').evaluate(m);
    },
    descendant:   'c = "descendant";',
    child:        'c = "child";',
    adjacent:     'c = "adjacent";',
    laterSibling: 'c = "laterSibling";'
  },

  patterns: [
    { name: 'laterSibling', re: /^\s*~\s*/ },
    { name: 'child',        re: /^\s*>\s*/ },
    { name: 'adjacent',     re: /^\s*\+\s*/ },
    { name: 'descendant',   re: /^\s/ },

    { name: 'tagName',      re: /^\s*(\*|[\w\-]+)(\b|$)?/ },
    { name: 'id',           re: /^#([\w\-\*]+)(\b|$)/ },
    { name: 'className',    re: /^\.([\w\-\*]+)(\b|$)/ },
    { name: 'pseudo',       re: /^:((first|last|nth|nth-last|only)(-child|-of-type)|empty|checked|(en|dis)abled|not)(\((.*?)\))?(\b|$|(?=\s|[:+~>]))/ },
    { name: 'attrPresence', re: /^\[((?:[\w-]+:)?[\w-]+)\]/ },
    { name: 'attr',         re: /\[((?:[\w-]*:)?[\w-]+)\s*(?:([!^$*~|]?=)\s*((['"])([^\4]*?)\4|([^'"][^\]]*?)))?\]/ }
  ],

  assertions: {
    tagName: function(element, matches) {
      return matches[1].toUpperCase() == element.tagName.toUpperCase();
    },

    className: function(element, matches) {
      return Element.hasClassName(element, matches[1]);
    },

    id: function(element, matches) {
      return element.id === matches[1];
    },

    attrPresence: function(element, matches) {
      return Element.hasAttribute(element, matches[1]);
    },

    attr: function(element, matches) {
      var nodeValue = Element.readAttribute(element, matches[1]);
      return nodeValue && Selector.operators[matches[2]](nodeValue, matches[5] || matches[6]);
    }
  },

  handlers: {
    concat: function(a, b) {
      for (var i = 0, node; node = b[i]; i++)
        a.push(node);
      return a;
    },

    mark: function(nodes) {
      var _true = Prototype.emptyFunction;
      for (var i = 0, node; node = nodes[i]; i++)
        node._countedByPrototype = _true;
      return nodes;
    },

    unmark: (function(){

      var PROPERTIES_ATTRIBUTES_MAP = (function(){
        var el = document.createElement('div'),
            isBuggy = false,
            propName = '_countedByPrototype',
            value = 'x'
        el[propName] = value;
        isBuggy = (el.getAttribute(propName) === value);
        el = null;
        return isBuggy;
      })();

      return PROPERTIES_ATTRIBUTES_MAP ?
        function(nodes) {
          for (var i = 0, node; node = nodes[i]; i++)
            node.removeAttribute('_countedByPrototype');
          return nodes;
        } :
        function(nodes) {
          for (var i = 0, node; node = nodes[i]; i++)
            node._countedByPrototype = void 0;
          return nodes;
        }
    })(),

    index: function(parentNode, reverse, ofType) {
      parentNode._countedByPrototype = Prototype.emptyFunction;
      if (reverse) {
        for (var nodes = parentNode.childNodes, i = nodes.length - 1, j = 1; i >= 0; i--) {
          var node = nodes[i];
          if (node.nodeType == 1 && (!ofType || node._countedByPrototype)) node.nodeIndex = j++;
        }
      } else {
        for (var i = 0, j = 1, nodes = parentNode.childNodes; node = nodes[i]; i++)
          if (node.nodeType == 1 && (!ofType || node._countedByPrototype)) node.nodeIndex = j++;
      }
    },

    unique: function(nodes) {
      if (nodes.length == 0) return nodes;
      var results = [], n;
      for (var i = 0, l = nodes.length; i < l; i++)
        if (typeof (n = nodes[i])._countedByPrototype == 'undefined') {
          n._countedByPrototype = Prototype.emptyFunction;
          results.push(Element.extend(n));
        }
      return Selector.handlers.unmark(results);
    },

    descendant: function(nodes) {
      var h = Selector.handlers;
      for (var i = 0, results = [], node; node = nodes[i]; i++)
        h.concat(results, node.getElementsByTagName('*'));
      return results;
    },

    child: function(nodes) {
      var h = Selector.handlers;
      for (var i = 0, results = [], node; node = nodes[i]; i++) {
        for (var j = 0, child; child = node.childNodes[j]; j++)
          if (child.nodeType == 1 && child.tagName != '!') results.push(child);
      }
      return results;
    },

    adjacent: function(nodes) {
      for (var i = 0, results = [], node; node = nodes[i]; i++) {
        var next = this.nextElementSibling(node);
        if (next) results.push(next);
      }
      return results;
    },

    laterSibling: function(nodes) {
      var h = Selector.handlers;
      for (var i = 0, results = [], node; node = nodes[i]; i++)
        h.concat(results, Element.nextSiblings(node));
      return results;
    },

    nextElementSibling: function(node) {
      while (node = node.nextSibling)
        if (node.nodeType == 1) return node;
      return null;
    },

    previousElementSibling: function(node) {
      while (node = node.previousSibling)
        if (node.nodeType == 1) return node;
      return null;
    },

    tagName: function(nodes, root, tagName, combinator) {
      var uTagName = tagName.toUpperCase();
      var results = [], h = Selector.handlers;
      if (nodes) {
        if (combinator) {
          if (combinator == "descendant") {
            for (var i = 0, node; node = nodes[i]; i++)
              h.concat(results, node.getElementsByTagName(tagName));
            return results;
          } else nodes = this[combinator](nodes);
          if (tagName == "*") return nodes;
        }
        for (var i = 0, node; node = nodes[i]; i++)
          if (node.tagName.toUpperCase() === uTagName) results.push(node);
        return results;
      } else return root.getElementsByTagName(tagName);
    },

    id: function(nodes, root, id, combinator) {
      var targetNode = $(id), h = Selector.handlers;

      if (root == document) {
        if (!targetNode) return [];
        if (!nodes) return [targetNode];
      } else {
        if (!root.sourceIndex || root.sourceIndex < 1) {
          var nodes = root.getElementsByTagName('*');
          for (var j = 0, node; node = nodes[j]; j++) {
            if (node.id === id) return [node];
          }
        }
      }

      if (nodes) {
        if (combinator) {
          if (combinator == 'child') {
            for (var i = 0, node; node = nodes[i]; i++)
              if (targetNode.parentNode == node) return [targetNode];
          } else if (combinator == 'descendant') {
            for (var i = 0, node; node = nodes[i]; i++)
              if (Element.descendantOf(targetNode, node)) return [targetNode];
          } else if (combinator == 'adjacent') {
            for (var i = 0, node; node = nodes[i]; i++)
              if (Selector.handlers.previousElementSibling(targetNode) == node)
                return [targetNode];
          } else nodes = h[combinator](nodes);
        }
        for (var i = 0, node; node = nodes[i]; i++)
          if (node == targetNode) return [targetNode];
        return [];
      }
      return (targetNode && Element.descendantOf(targetNode, root)) ? [targetNode] : [];
    },

    className: function(nodes, root, className, combinator) {
      if (nodes && combinator) nodes = this[combinator](nodes);
      return Selector.handlers.byClassName(nodes, root, className);
    },

    byClassName: function(nodes, root, className) {
      if (!nodes) nodes = Selector.handlers.descendant([root]);
      var needle = ' ' + className + ' ';
      for (var i = 0, results = [], node, nodeClassName; node = nodes[i]; i++) {
        nodeClassName = node.className;
        if (nodeClassName.length == 0) continue;
        if (nodeClassName == className || (' ' + nodeClassName + ' ').include(needle))
          results.push(node);
      }
      return results;
    },

    attrPresence: function(nodes, root, attr, combinator) {
      if (!nodes) nodes = root.getElementsByTagName("*");
      if (nodes && combinator) nodes = this[combinator](nodes);
      var results = [];
      for (var i = 0, node; node = nodes[i]; i++)
        if (Element.hasAttribute(node, attr)) results.push(node);
      return results;
    },

    attr: function(nodes, root, attr, value, operator, combinator) {
      if (!nodes) nodes = root.getElementsByTagName("*");
      if (nodes && combinator) nodes = this[combinator](nodes);
      var handler = Selector.operators[operator], results = [];
      for (var i = 0, node; node = nodes[i]; i++) {
        var nodeValue = Element.readAttribute(node, attr);
        if (nodeValue === null) continue;
        if (handler(nodeValue, value)) results.push(node);
      }
      return results;
    },

    pseudo: function(nodes, name, value, root, combinator) {
      if (nodes && combinator) nodes = this[combinator](nodes);
      if (!nodes) nodes = root.getElementsByTagName("*");
      return Selector.pseudos[name](nodes, value, root);
    }
  },

  pseudos: {
    'first-child': function(nodes, value, root) {
      for (var i = 0, results = [], node; node = nodes[i]; i++) {
        if (Selector.handlers.previousElementSibling(node)) continue;
          results.push(node);
      }
      return results;
    },
    'last-child': function(nodes, value, root) {
      for (var i = 0, results = [], node; node = nodes[i]; i++) {
        if (Selector.handlers.nextElementSibling(node)) continue;
          results.push(node);
      }
      return results;
    },
    'only-child': function(nodes, value, root) {
      var h = Selector.handlers;
      for (var i = 0, results = [], node; node = nodes[i]; i++)
        if (!h.previousElementSibling(node) && !h.nextElementSibling(node))
          results.push(node);
      return results;
    },
    'nth-child':        function(nodes, formula, root) {
      return Selector.pseudos.nth(nodes, formula, root);
    },
    'nth-last-child':   function(nodes, formula, root) {
      return Selector.pseudos.nth(nodes, formula, root, true);
    },
    'nth-of-type':      function(nodes, formula, root) {
      return Selector.pseudos.nth(nodes, formula, root, false, true);
    },
    'nth-last-of-type': function(nodes, formula, root) {
      return Selector.pseudos.nth(nodes, formula, root, true, true);
    },
    'first-of-type':    function(nodes, formula, root) {
      return Selector.pseudos.nth(nodes, "1", root, false, true);
    },
    'last-of-type':     function(nodes, formula, root) {
      return Selector.pseudos.nth(nodes, "1", root, true, true);
    },
    'only-of-type':     function(nodes, formula, root) {
      var p = Selector.pseudos;
      return p['last-of-type'](p['first-of-type'](nodes, formula, root), formula, root);
    },

    getIndices: function(a, b, total) {
      if (a == 0) return b > 0 ? [b] : [];
      return $R(1, total).inject([], function(memo, i) {
        if (0 == (i - b) % a && (i - b) / a >= 0) memo.push(i);
        return memo;
      });
    },

    nth: function(nodes, formula, root, reverse, ofType) {
      if (nodes.length == 0) return [];
      if (formula == 'even') formula = '2n+0';
      if (formula == 'odd')  formula = '2n+1';
      var h = Selector.handlers, results = [], indexed = [], m;
      h.mark(nodes);
      for (var i = 0, node; node = nodes[i]; i++) {
        if (!node.parentNode._countedByPrototype) {
          h.index(node.parentNode, reverse, ofType);
          indexed.push(node.parentNode);
        }
      }
      if (formula.match(/^\d+$/)) { // just a number
        formula = Number(formula);
        for (var i = 0, node; node = nodes[i]; i++)
          if (node.nodeIndex == formula) results.push(node);
      } else if (m = formula.match(/^(-?\d*)?n(([+-])(\d+))?/)) { // an+b
        if (m[1] == "-") m[1] = -1;
        var a = m[1] ? Number(m[1]) : 1;
        var b = m[2] ? Number(m[2]) : 0;
        var indices = Selector.pseudos.getIndices(a, b, nodes.length);
        for (var i = 0, node, l = indices.length; node = nodes[i]; i++) {
          for (var j = 0; j < l; j++)
            if (node.nodeIndex == indices[j]) results.push(node);
        }
      }
      h.unmark(nodes);
      h.unmark(indexed);
      return results;
    },

    'empty': function(nodes, value, root) {
      for (var i = 0, results = [], node; node = nodes[i]; i++) {
        if (node.tagName == '!' || node.firstChild) continue;
        results.push(node);
      }
      return results;
    },

    'not': function(nodes, selector, root) {
      var h = Selector.handlers, selectorType, m;
      var exclusions = new Selector(selector).findElements(root);
      h.mark(exclusions);
      for (var i = 0, results = [], node; node = nodes[i]; i++)
        if (!node._countedByPrototype) results.push(node);
      h.unmark(exclusions);
      return results;
    },

    'enabled': function(nodes, value, root) {
      for (var i = 0, results = [], node; node = nodes[i]; i++)
        if (!node.disabled && (!node.type || node.type !== 'hidden'))
          results.push(node);
      return results;
    },

    'disabled': function(nodes, value, root) {
      for (var i = 0, results = [], node; node = nodes[i]; i++)
        if (node.disabled) results.push(node);
      return results;
    },

    'checked': function(nodes, value, root) {
      for (var i = 0, results = [], node; node = nodes[i]; i++)
        if (node.checked) results.push(node);
      return results;
    }
  },

  operators: {
    '=':  function(nv, v) { return nv == v; },
    '!=': function(nv, v) { return nv != v; },
    '^=': function(nv, v) { return nv == v || nv && nv.startsWith(v); },
    '$=': function(nv, v) { return nv == v || nv && nv.endsWith(v); },
    '*=': function(nv, v) { return nv == v || nv && nv.include(v); },
    '~=': function(nv, v) { return (' ' + nv + ' ').include(' ' + v + ' '); },
    '|=': function(nv, v) { return ('-' + (nv || "").toUpperCase() +
     '-').include('-' + (v || "").toUpperCase() + '-'); }
  },

  split: function(expression) {
    var expressions = [];
    expression.scan(/(([\w#:.~>+()\s-]+|\*|\[.*?\])+)\s*(,|$)/, function(m) {
      expressions.push(m[1].strip());
    });
    return expressions;
  },

  matchElements: function(elements, expression) {
    var matches = $$(expression), h = Selector.handlers;
    h.mark(matches);
    for (var i = 0, results = [], element; element = elements[i]; i++)
      if (element._countedByPrototype) results.push(element);
    h.unmark(matches);
    return results;
  },

  findElement: function(elements, expression, index) {
    if (Object.isNumber(expression)) {
      index = expression; expression = false;
    }
    return Selector.matchElements(elements, expression || '*')[index || 0];
  },

  findChildElements: function(element, expressions) {
    expressions = Selector.split(expressions.join(','));
    var results = [], h = Selector.handlers;
    for (var i = 0, l = expressions.length, selector; i < l; i++) {
      selector = new Selector(expressions[i].strip());
      h.concat(results, selector.findElements(element));
    }
    return (l > 1) ? h.unique(results) : results;
  }
});

if (Prototype.Browser.IE) {
  Object.extend(Selector.handlers, {
    concat: function(a, b) {
      for (var i = 0, node; node = b[i]; i++)
        if (node.tagName !== "!") a.push(node);
      return a;
    }
  });
}

function $$() {
  return Selector.findChildElements(document, $A(arguments));
}

var Form = {
  reset: function(form) {
    form = $(form);
    form.reset();
    return form;
  },

  serializeElements: function(elements, options) {
    if (typeof options != 'object') options = { hash: !!options };
    else if (Object.isUndefined(options.hash)) options.hash = true;
    var key, value, submitted = false, submit = options.submit;

    var data = elements.inject({ }, function(result, element) {
      if (!element.disabled && element.name) {
        key = element.name; value = $(element).getValue();
        if (value != null && element.type != 'file' && (element.type != 'submit' || (!submitted &&
            submit !== false && (!submit || key == submit) && (submitted = true)))) {
          if (key in result) {
            if (!Object.isArray(result[key])) result[key] = [result[key]];
            result[key].push(value);
          }
          else result[key] = value;
        }
      }
      return result;
    });

    return options.hash ? data : Object.toQueryString(data);
  }
};

Form.Methods = {
  serialize: function(form, options) {
    return Form.serializeElements(Form.getElements(form), options);
  },

  getElements: function(form) {
    var elements = $(form).getElementsByTagName('*'),
        element,
        arr = [ ],
        serializers = Form.Element.Serializers;
    for (var i = 0; element = elements[i]; i++) {
      arr.push(element);
    }
    return arr.inject([], function(elements, child) {
      if (serializers[child.tagName.toLowerCase()])
        elements.push(Element.extend(child));
      return elements;
    })
  },

  getInputs: function(form, typeName, name) {
    form = $(form);
    var inputs = form.getElementsByTagName('input');

    if (!typeName && !name) return $A(inputs).map(Element.extend);

    for (var i = 0, matchingInputs = [], length = inputs.length; i < length; i++) {
      var input = inputs[i];
      if ((typeName && input.type != typeName) || (name && input.name != name))
        continue;
      matchingInputs.push(Element.extend(input));
    }

    return matchingInputs;
  },

  disable: function(form) {
    form = $(form);
    Form.getElements(form).invoke('disable');
    return form;
  },

  enable: function(form) {
    form = $(form);
    Form.getElements(form).invoke('enable');
    return form;
  },

  findFirstElement: function(form) {
    var elements = $(form).getElements().findAll(function(element) {
      return 'hidden' != element.type && !element.disabled;
    });
    var firstByIndex = elements.findAll(function(element) {
      return element.hasAttribute('tabIndex') && element.tabIndex >= 0;
    }).sortBy(function(element) { return element.tabIndex }).first();

    return firstByIndex ? firstByIndex : elements.find(function(element) {
      return /^(?:input|select|textarea)$/i.test(element.tagName);
    });
  },

  focusFirstElement: function(form) {
    form = $(form);
    form.findFirstElement().activate();
    return form;
  },

  request: function(form, options) {
    form = $(form), options = Object.clone(options || { });

    var params = options.parameters, action = form.readAttribute('action') || '';
    if (action.blank()) action = window.location.href;
    options.parameters = form.serialize(true);

    if (params) {
      if (Object.isString(params)) params = params.toQueryParams();
      Object.extend(options.parameters, params);
    }

    if (form.hasAttribute('method') && !options.method)
      options.method = form.method;

    return new Ajax.Request(action, options);
  }
};

/*--------------------------------------------------------------------------*/


Form.Element = {
  focus: function(element) {
    $(element).focus();
    return element;
  },

  select: function(element) {
    $(element).select();
    return element;
  }
};

Form.Element.Methods = {

  serialize: function(element) {
    element = $(element);
    if (!element.disabled && element.name) {
      var value = element.getValue();
      if (value != undefined) {
        var pair = { };
        pair[element.name] = value;
        return Object.toQueryString(pair);
      }
    }
    return '';
  },

  getValue: function(element) {
    element = $(element);
    var method = element.tagName.toLowerCase();
    return Form.Element.Serializers[method](element);
  },

  setValue: function(element, value) {
    element = $(element);
    var method = element.tagName.toLowerCase();
    Form.Element.Serializers[method](element, value);
    return element;
  },

  clear: function(element) {
    $(element).value = '';
    return element;
  },

  present: function(element) {
    return $(element).value != '';
  },

  activate: function(element) {
    element = $(element);
    try {
      element.focus();
      if (element.select && (element.tagName.toLowerCase() != 'input' ||
          !(/^(?:button|reset|submit)$/i.test(element.type))))
        element.select();
    } catch (e) { }
    return element;
  },

  disable: function(element) {
    element = $(element);
    element.disabled = true;
    return element;
  },

  enable: function(element) {
    element = $(element);
    element.disabled = false;
    return element;
  }
};

/*--------------------------------------------------------------------------*/

var Field = Form.Element;

var $F = Form.Element.Methods.getValue;

/*--------------------------------------------------------------------------*/

Form.Element.Serializers = {
  input: function(element, value) {
    switch (element.type.toLowerCase()) {
      case 'checkbox':
      case 'radio':
        return Form.Element.Serializers.inputSelector(element, value);
      default:
        return Form.Element.Serializers.textarea(element, value);
    }
  },

  inputSelector: function(element, value) {
    if (Object.isUndefined(value)) return element.checked ? element.value : null;
    else element.checked = !!value;
  },

  textarea: function(element, value) {
    if (Object.isUndefined(value)) return element.value;
    else element.value = value;
  },

  select: function(element, value) {
    if (Object.isUndefined(value))
      return this[element.type == 'select-one' ?
        'selectOne' : 'selectMany'](element);
    else {
      var opt, currentValue, single = !Object.isArray(value);
      for (var i = 0, length = element.length; i < length; i++) {
        opt = element.options[i];
        currentValue = this.optionValue(opt);
        if (single) {
          if (currentValue == value) {
            opt.selected = true;
            return;
          }
        }
        else opt.selected = value.include(currentValue);
      }
    }
  },

  selectOne: function(element) {
    var index = element.selectedIndex;
    return index >= 0 ? this.optionValue(element.options[index]) : null;
  },

  selectMany: function(element) {
    var values, length = element.length;
    if (!length) return null;

    for (var i = 0, values = []; i < length; i++) {
      var opt = element.options[i];
      if (opt.selected) values.push(this.optionValue(opt));
    }
    return values;
  },

  optionValue: function(opt) {
    return Element.extend(opt).hasAttribute('value') ? opt.value : opt.text;
  }
};

/*--------------------------------------------------------------------------*/


Abstract.TimedObserver = Class.create(PeriodicalExecuter, {
  initialize: function($super, element, frequency, callback) {
    $super(callback, frequency);
    this.element   = $(element);
    this.lastValue = this.getValue();
  },

  execute: function() {
    var value = this.getValue();
    if (Object.isString(this.lastValue) && Object.isString(value) ?
        this.lastValue != value : String(this.lastValue) != String(value)) {
      this.callback(this.element, value);
      this.lastValue = value;
    }
  }
});

Form.Element.Observer = Class.create(Abstract.TimedObserver, {
  getValue: function() {
    return Form.Element.getValue(this.element);
  }
});

Form.Observer = Class.create(Abstract.TimedObserver, {
  getValue: function() {
    return Form.serialize(this.element);
  }
});

/*--------------------------------------------------------------------------*/

Abstract.EventObserver = Class.create({
  initialize: function(element, callback) {
    this.element  = $(element);
    this.callback = callback;

    this.lastValue = this.getValue();
    if (this.element.tagName.toLowerCase() == 'form')
      this.registerFormCallbacks();
    else
      this.registerCallback(this.element);
  },

  onElementEvent: function() {
    var value = this.getValue();
    if (this.lastValue != value) {
      this.callback(this.element, value);
      this.lastValue = value;
    }
  },

  registerFormCallbacks: function() {
    Form.getElements(this.element).each(this.registerCallback, this);
  },

  registerCallback: function(element) {
    if (element.type) {
      switch (element.type.toLowerCase()) {
        case 'checkbox':
        case 'radio':
          Event.observe(element, 'click', this.onElementEvent.bind(this));
          break;
        default:
          Event.observe(element, 'change', this.onElementEvent.bind(this));
          break;
      }
    }
  }
});

Form.Element.EventObserver = Class.create(Abstract.EventObserver, {
  getValue: function() {
    return Form.Element.getValue(this.element);
  }
});

Form.EventObserver = Class.create(Abstract.EventObserver, {
  getValue: function() {
    return Form.serialize(this.element);
  }
});
(function() {

  var Event = {
    KEY_BACKSPACE: 8,
    KEY_TAB:       9,
    KEY_RETURN:   13,
    KEY_ESC:      27,
    KEY_LEFT:     37,
    KEY_UP:       38,
    KEY_RIGHT:    39,
    KEY_DOWN:     40,
    KEY_DELETE:   46,
    KEY_HOME:     36,
    KEY_END:      35,
    KEY_PAGEUP:   33,
    KEY_PAGEDOWN: 34,
    KEY_INSERT:   45,

    cache: {}
  };

  var docEl = document.documentElement;
  var MOUSEENTER_MOUSELEAVE_EVENTS_SUPPORTED = 'onmouseenter' in docEl
    && 'onmouseleave' in docEl;

  var _isButton;
  if (Prototype.Browser.IE) {
    var buttonMap = { 0: 1, 1: 4, 2: 2 };
    _isButton = function(event, code) {
      return event.button === buttonMap[code];
    };
  } else if (Prototype.Browser.WebKit) {
    _isButton = function(event, code) {
      switch (code) {
        case 0: return event.which == 1 && !event.metaKey;
        case 1: return event.which == 1 && event.metaKey;
        default: return false;
      }
    };
  } else {
    _isButton = function(event, code) {
      return event.which ? (event.which === code + 1) : (event.button === code);
    };
  }

  function isLeftClick(event)   { return _isButton(event, 0) }

  function isMiddleClick(event) { return _isButton(event, 1) }

  function isRightClick(event)  { return _isButton(event, 2) }

  function element(event) {
    event = Event.extend(event);

    var node = event.target, type = event.type,
     currentTarget = event.currentTarget;

    if (currentTarget && currentTarget.tagName) {
      if (type === 'load' || type === 'error' ||
        (type === 'click' && currentTarget.tagName.toLowerCase() === 'input'
          && currentTarget.type === 'radio'))
            node = currentTarget;
    }

    if (node.nodeType == Node.TEXT_NODE)
      node = node.parentNode;

    return Element.extend(node);
  }

  function findElement(event, expression) {
    var element = Event.element(event);
    if (!expression) return element;
    var elements = [element].concat(element.ancestors());
    return Selector.findElement(elements, expression, 0);
  }

  function pointer(event) {
    return { x: pointerX(event), y: pointerY(event) };
  }

  function pointerX(event) {
    var docElement = document.documentElement,
     body = document.body || { scrollLeft: 0 };

    return event.pageX || (event.clientX +
      (docElement.scrollLeft || body.scrollLeft) -
      (docElement.clientLeft || 0));
  }

  function pointerY(event) {
    var docElement = document.documentElement,
     body = document.body || { scrollTop: 0 };

    return  event.pageY || (event.clientY +
       (docElement.scrollTop || body.scrollTop) -
       (docElement.clientTop || 0));
  }


  function stop(event) {
    Event.extend(event);
    event.preventDefault();
    event.stopPropagation();

    event.stopped = true;
  }

  Event.Methods = {
    isLeftClick: isLeftClick,
    isMiddleClick: isMiddleClick,
    isRightClick: isRightClick,

    element: element,
    findElement: findElement,

    pointer: pointer,
    pointerX: pointerX,
    pointerY: pointerY,

    stop: stop
  };


  var methods = Object.keys(Event.Methods).inject({ }, function(m, name) {
    m[name] = Event.Methods[name].methodize();
    return m;
  });

  if (Prototype.Browser.IE) {
    function _relatedTarget(event) {
      var element;
      switch (event.type) {
        case 'mouseover': element = event.fromElement; break;
        case 'mouseout':  element = event.toElement;   break;
        default: return null;
      }
      return Element.extend(element);
    }

    Object.extend(methods, {
      stopPropagation: function() { this.cancelBubble = true },
      preventDefault:  function() { this.returnValue = false },
      inspect: function() { return '[object Event]' }
    });

    Event.extend = function(event, element) {
      if (!event) return false;
      if (event._extendedByPrototype) return event;

      event._extendedByPrototype = Prototype.emptyFunction;
      var pointer = Event.pointer(event);

      Object.extend(event, {
        target: event.srcElement || element,
        relatedTarget: _relatedTarget(event),
        pageX:  pointer.x,
        pageY:  pointer.y
      });

      return Object.extend(event, methods);
    };
  } else {
    Event.prototype = window.Event.prototype || document.createEvent('HTMLEvents').__proto__;
    Object.extend(Event.prototype, methods);
    Event.extend = Prototype.K;
  }

  function _createResponder(element, eventName, handler) {
    var registry = Element.retrieve(element, 'prototype_event_registry');

    if (Object.isUndefined(registry)) {
      CACHE.push(element);
      registry = Element.retrieve(element, 'prototype_event_registry', $H());
    }

    var respondersForEvent = registry.get(eventName);
    if (Object.isUndefined(respondersForEvent)) {
      respondersForEvent = [];
      registry.set(eventName, respondersForEvent);
    }

    if (respondersForEvent.pluck('handler').include(handler)) return false;

    var responder;
    if (eventName.include(":")) {
      responder = function(event) {
        if (Object.isUndefined(event.eventName))
          return false;

        if (event.eventName !== eventName)
          return false;

        Event.extend(event, element);
        handler.call(element, event);
      };
    } else {
      if (!MOUSEENTER_MOUSELEAVE_EVENTS_SUPPORTED &&
       (eventName === "mouseenter" || eventName === "mouseleave")) {
        if (eventName === "mouseenter" || eventName === "mouseleave") {
          responder = function(event) {
            Event.extend(event, element);

            var parent = event.relatedTarget;
            while (parent && parent !== element) {
              try { parent = parent.parentNode; }
              catch(e) { parent = element; }
            }

            if (parent === element) return;

            handler.call(element, event);
          };
        }
      } else {
        responder = function(event) {
          Event.extend(event, element);
          handler.call(element, event);
        };
      }
    }

    responder.handler = handler;
    respondersForEvent.push(responder);
    return responder;
  }

  function _destroyCache() {
    for (var i = 0, length = CACHE.length; i < length; i++) {
      Event.stopObserving(CACHE[i]);
      CACHE[i] = null;
    }
  }

  var CACHE = [];

  if (Prototype.Browser.IE)
    window.attachEvent('onunload', _destroyCache);

  if (Prototype.Browser.WebKit)
    window.addEventListener('unload', Prototype.emptyFunction, false);


  var _getDOMEventName = Prototype.K;

  if (!MOUSEENTER_MOUSELEAVE_EVENTS_SUPPORTED) {
    _getDOMEventName = function(eventName) {
      var translations = { mouseenter: "mouseover", mouseleave: "mouseout" };
      return eventName in translations ? translations[eventName] : eventName;
    };
  }

  function observe(element, eventName, handler) {
    element = $(element);

    var responder = _createResponder(element, eventName, handler);

    if (!responder) return element;

    if (eventName.include(':')) {
      if (element.addEventListener)
        element.addEventListener("dataavailable", responder, false);
      else {
        element.attachEvent("ondataavailable", responder);
        element.attachEvent("onfilterchange", responder);
      }
    } else {
      var actualEventName = _getDOMEventName(eventName);

      if (element.addEventListener)
        element.addEventListener(actualEventName, responder, false);
      else
        element.attachEvent("on" + actualEventName, responder);
    }

    return element;
  }

  function stopObserving(element, eventName, handler) {
    element = $(element);

    var registry = Element.retrieve(element, 'prototype_event_registry');

    if (Object.isUndefined(registry)) return element;

    if (eventName && !handler) {
      var responders = registry.get(eventName);

      if (Object.isUndefined(responders)) return element;

      responders.each( function(r) {
        Element.stopObserving(element, eventName, r.handler);
      });
      return element;
    } else if (!eventName) {
      registry.each( function(pair) {
        var eventName = pair.key, responders = pair.value;

        responders.each( function(r) {
          Element.stopObserving(element, eventName, r.handler);
        });
      });
      return element;
    }

    var responders = registry.get(eventName);

    if (!responders) return;

    var responder = responders.find( function(r) { return r.handler === handler; });
    if (!responder) return element;

    var actualEventName = _getDOMEventName(eventName);

    if (eventName.include(':')) {
      if (element.removeEventListener)
        element.removeEventListener("dataavailable", responder, false);
      else {
        element.detachEvent("ondataavailable", responder);
        element.detachEvent("onfilterchange",  responder);
      }
    } else {
      if (element.removeEventListener)
        element.removeEventListener(actualEventName, responder, false);
      else
        element.detachEvent('on' + actualEventName, responder);
    }

    registry.set(eventName, responders.without(responder));

    return element;
  }

  function fire(element, eventName, memo, bubble) {
    element = $(element);

    if (Object.isUndefined(bubble))
      bubble = true;

    if (element == document && document.createEvent && !element.dispatchEvent)
      element = document.documentElement;

    var event;
    if (document.createEvent) {
      event = document.createEvent('HTMLEvents');
      event.initEvent('dataavailable', true, true);
    } else {
      event = document.createEventObject();
      event.eventType = bubble ? 'ondataavailable' : 'onfilterchange';
    }

    event.eventName = eventName;
    event.memo = memo || { };

    if (document.createEvent)
      element.dispatchEvent(event);
    else
      element.fireEvent(event.eventType, event);

    return Event.extend(event);
  }


  Object.extend(Event, Event.Methods);

  Object.extend(Event, {
    fire:          fire,
    observe:       observe,
    stopObserving: stopObserving
  });

  Element.addMethods({
    fire:          fire,

    observe:       observe,

    stopObserving: stopObserving
  });

  Object.extend(document, {
    fire:          fire.methodize(),

    observe:       observe.methodize(),

    stopObserving: stopObserving.methodize(),

    loaded:        false
  });

  if (window.Event) Object.extend(window.Event, Event);
  else window.Event = Event;
})();

(function() {
  /* Support for the DOMContentLoaded event is based on work by Dan Webb,
     Matthias Miller, Dean Edwards, John Resig, and Diego Perini. */

  var timer;

  function fireContentLoadedEvent() {
    if (document.loaded) return;
    if (timer) window.clearTimeout(timer);
    document.loaded = true;
    document.fire('dom:loaded');
  }

  function checkReadyState() {
    if (document.readyState === 'complete') {
      document.stopObserving('readystatechange', checkReadyState);
      fireContentLoadedEvent();
    }
  }

  function pollDoScroll() {
    try { document.documentElement.doScroll('left'); }
    catch(e) {
      timer = pollDoScroll.defer();
      return;
    }
    fireContentLoadedEvent();
  }

  if (document.addEventListener) {
    document.addEventListener('DOMContentLoaded', fireContentLoadedEvent, false);
  } else {
    document.observe('readystatechange', checkReadyState);
    if (window == top)
      timer = pollDoScroll.defer();
  }

  Event.observe(window, 'load', fireContentLoadedEvent);
})();

Element.addMethods();

/*------------------------------- DEPRECATED -------------------------------*/

Hash.toQueryString = Object.toQueryString;

var Toggle = { display: Element.toggle };

Element.Methods.childOf = Element.Methods.descendantOf;

var Insertion = {
  Before: function(element, content) {
    return Element.insert(element, {before:content});
  },

  Top: function(element, content) {
    return Element.insert(element, {top:content});
  },

  Bottom: function(element, content) {
    return Element.insert(element, {bottom:content});
  },

  After: function(element, content) {
    return Element.insert(element, {after:content});
  }
};

var $continue = new Error('"throw $continue" is deprecated, use "return" instead');

var Position = {
  includeScrollOffsets: false,

  prepare: function() {
    this.deltaX =  window.pageXOffset
                || document.documentElement.scrollLeft
                || document.body.scrollLeft
                || 0;
    this.deltaY =  window.pageYOffset
                || document.documentElement.scrollTop
                || document.body.scrollTop
                || 0;
  },

  within: function(element, x, y) {
    if (this.includeScrollOffsets)
      return this.withinIncludingScrolloffsets(element, x, y);
    this.xcomp = x;
    this.ycomp = y;
    this.offset = Element.cumulativeOffset(element);

    return (y >= this.offset[1] &&
            y <  this.offset[1] + element.offsetHeight &&
            x >= this.offset[0] &&
            x <  this.offset[0] + element.offsetWidth);
  },

  withinIncludingScrolloffsets: function(element, x, y) {
    var offsetcache = Element.cumulativeScrollOffset(element);

    this.xcomp = x + offsetcache[0] - this.deltaX;
    this.ycomp = y + offsetcache[1] - this.deltaY;
    this.offset = Element.cumulativeOffset(element);

    return (this.ycomp >= this.offset[1] &&
            this.ycomp <  this.offset[1] + element.offsetHeight &&
            this.xcomp >= this.offset[0] &&
            this.xcomp <  this.offset[0] + element.offsetWidth);
  },

  overlap: function(mode, element) {
    if (!mode) return 0;
    if (mode == 'vertical')
      return ((this.offset[1] + element.offsetHeight) - this.ycomp) /
        element.offsetHeight;
    if (mode == 'horizontal')
      return ((this.offset[0] + element.offsetWidth) - this.xcomp) /
        element.offsetWidth;
  },


  cumulativeOffset: Element.Methods.cumulativeOffset,

  positionedOffset: Element.Methods.positionedOffset,

  absolutize: function(element) {
    Position.prepare();
    return Element.absolutize(element);
  },

  relativize: function(element) {
    Position.prepare();
    return Element.relativize(element);
  },

  realOffset: Element.Methods.cumulativeScrollOffset,

  offsetParent: Element.Methods.getOffsetParent,

  page: Element.Methods.viewportOffset,

  clone: function(source, target, options) {
    options = options || { };
    return Element.clonePosition(target, source, options);
  }
};

/*--------------------------------------------------------------------------*/

if (!document.getElementsByClassName) document.getElementsByClassName = function(instanceMethods){
  function iter(name) {
    return name.blank() ? null : "[contains(concat(' ', @class, ' '), ' " + name + " ')]";
  }

  instanceMethods.getElementsByClassName = Prototype.BrowserFeatures.XPath ?
  function(element, className) {
    className = className.toString().strip();
    var cond = /\s/.test(className) ? $w(className).map(iter).join('') : iter(className);
    return cond ? document._getElementsByXPath('.//*' + cond, element) : [];
  } : function(element, className) {
    className = className.toString().strip();
    var elements = [], classNames = (/\s/.test(className) ? $w(className) : null);
    if (!classNames && !className) return elements;

    var nodes = $(element).getElementsByTagName('*');
    className = ' ' + className + ' ';

    for (var i = 0, child, cn; child = nodes[i]; i++) {
      if (child.className && (cn = ' ' + child.className + ' ') && (cn.include(className) ||
          (classNames && classNames.all(function(name) {
            return !name.toString().blank() && cn.include(' ' + name + ' ');
          }))))
        elements.push(Element.extend(child));
    }
    return elements;
  };

  return function(className, parentElement) {
    return $(parentElement || document.body).getElementsByClassName(className);
  };
}(Element.Methods);

/*--------------------------------------------------------------------------*/

Element.ClassNames = Class.create();
Element.ClassNames.prototype = {
  initialize: function(element) {
    this.element = $(element);
  },

  _each: function(iterator) {
    this.element.className.split(/\s+/).select(function(name) {
      return name.length > 0;
    })._each(iterator);
  },

  set: function(className) {
    this.element.className = className;
  },

  add: function(classNameToAdd) {
    if (this.include(classNameToAdd)) return;
    this.set($A(this).concat(classNameToAdd).join(' '));
  },

  remove: function(classNameToRemove) {
    if (!this.include(classNameToRemove)) return;
    this.set($A(this).without(classNameToRemove).join(' '));
  },

  toString: function() {
    return $A(this).join(' ');
  }
};

Object.extend(Element.ClassNames.prototype, Enumerable);

/*--------------------------------------------------------------------------*/


var LowPro = {};
LowPro.Version = '0.5';
LowPro.CompatibleWithPrototype = '1.6.0.1';

//if (Prototype.Version != LowPro.CompatibleWithPrototype && console && console.warn)
//  console.warn("This version of Low Pro is tested with Prototype " + LowPro.CompatibleWithPrototype +
//                  " it may not work as expected with this version (" + Prototype.Version + ")");

if (!Element.addMethods)
  Element.addMethods = function(o) { Object.extend(Element.Methods, o) };

// Simple utility methods for working with the DOM
DOM = {};

// DOMBuilder for prototype
DOM.Builder = {
	tagFunc : function(tag) {
	  return function() {
	    var attrs, children;
	    if (arguments.length>0) {
	      if (arguments[0].nodeName ||
	        typeof arguments[0] == "string")
	        children = arguments;
	      else {
	        attrs = arguments[0];
	        children = Array.prototype.slice.call(arguments, 1);
	      };
	    }
	    return DOM.Builder.create(tag, attrs, children);
	  };
  },
	create : function(tag, attrs, children) {
		attrs = attrs || {}; children = children || []; tag = tag.toLowerCase();
		var el = new Element(tag, attrs);

		for (var i=0; i<children.length; i++) {
			if (typeof children[i] == 'string')
			  children[i] = document.createTextNode(children[i]);
			el.appendChild(children[i]);
		}
		return $(el);
	}
};

// Automatically create node builders as $tagName.
(function() {
	var els = ("canvas|p|div|span|strong|em|img|table|tr|td|th|thead|tbody|tfoot|pre|code|" +
				     "h1|h2|h3|h4|h5|h6|ul|ol|li|form|input|textarea|legend|fieldset|" +
				     "select|option|blockquote|cite|br|hr|dd|dl|dt|address|a|button|abbr|acronym|" +
				     "script|link|style|bdo|ins|del|object|param|col|colgroup|optgroup|caption|" +
				     "label|dfn|kbd|samp|var").split("|");
  var el, i=0;
	while (el = els[i++])
	  window['$' + el] = DOM.Builder.tagFunc(el);
})();

DOM.Builder.fromHTML = function(html) {
  var root;
  if (!(root = arguments.callee._root))
    root = arguments.callee._root = document.createElement('div');
  root.innerHTML = html;
  return root.childNodes[0];
};



// Wraps the 1.6 contentloaded event for backwards compatibility
//
// Usage:
//
// Event.onReady(callbackFunction);
Object.extend(Event, {
  onReady : function(f) {
    if (document.body) f();
    else document.observe('dom:loaded', f);
  }
});

// Based on event:Selectors by Justin Palmer
// http://encytemedia.com/event-selectors/
//
// Usage:
//
// Event.addBehavior({
//      "selector:event" : function(event) { /* event handler.  this refers to the element. */ },
//      "selector" : function() { /* runs function on dom ready.  this refers to the element. */ }
//      ...
// });
//
// Multiple calls will add to exisiting rules.  Event.addBehavior.reassignAfterAjax and
// Event.addBehavior.autoTrigger can be adjusted to needs.
Event.addBehavior = function(rules) {
  var ab = this.addBehavior;
  Object.extend(ab.rules, rules);

  if (!ab.responderApplied) {
    Ajax.Responders.register({
      onComplete : function() {
        if (Event.addBehavior.reassignAfterAjax)
          setTimeout(function() { ab.reload() }, 10);
      }
    });
    ab.responderApplied = true;
  }

  if (ab.autoTrigger) {
    this.onReady(ab.load.bind(ab, rules));
  }

};

Object.extend(Event.addBehavior, {
  rules : {}, cache : [],
  reassignAfterAjax : true,
  autoTrigger : true,

  load : function(rules) {
    for (var selector in rules) {
      var observer = rules[selector];
      var sels = selector.split(',');
      sels.each(function(sel) {
        var parts = sel.split(/:(?=[a-z]+$)/), css = parts[0], event = parts[1];
        $$(css).each(function(element) {
          if (event) {
            observer = Event.addBehavior._wrapObserver(observer);
            $(element).observe(event, observer);
            Event.addBehavior.cache.push([element, event, observer]);
          } else {
            if (!element.$$assigned || !element.$$assigned.include(observer)) {
              if (observer.attach) observer.attach(element);

              else observer.call($(element));
              element.$$assigned = element.$$assigned || [];
              element.$$assigned.push(observer);
            }
          }
        });
      });
    }
  },

  unload : function() {
    this.cache.each(function(c) {
      Event.stopObserving.apply(Event, c);
    });
    this.cache = [];
  },

  reload: function() {
    var ab = Event.addBehavior;
    ab.unload();
    ab.load(ab.rules);
  },

  _wrapObserver: function(observer) {
    return function(event) {
      if (observer.call(this, event) === false) event.stop();
    }
  }

});

Event.observe(window, 'unload', Event.addBehavior.unload.bind(Event.addBehavior));

// A silly Prototype style shortcut for the reckless
$$$ = Event.addBehavior.bind(Event);

// Behaviors can be bound to elements to provide an object orientated way of controlling elements
// and their behavior.  Use Behavior.create() to make a new behavior class then use attach() to
// glue it to an element.  Each element then gets it's own instance of the behavior and any
// methods called onxxx are bound to the relevent event.
//
// Usage:
//
// var MyBehavior = Behavior.create({
//   onmouseover : function() { this.element.addClassName('bong') }
// });
//
// Event.addBehavior({ 'a.rollover' : MyBehavior });
//
// If you need to pass additional values to initialize use:
//
// Event.addBehavior({ 'a.rollover' : MyBehavior(10, { thing : 15 }) })
//
// You can also use the attach() method.  If you specify extra arguments to attach they get passed to initialize.
//
// MyBehavior.attach(el, values, to, init);
//
// Finally, the rawest method is using the new constructor normally:
// var draggable = new Draggable(element, init, vals);
//
// Each behaviour has a collection of all its instances in Behavior.instances
//
var Behavior = {
  create: function() {
    var parent = null, properties = $A(arguments);
    if (Object.isFunction(properties[0]))
      parent = properties.shift();

      var behavior = function() {
        var behavior = arguments.callee;
        if (!this.initialize) {
          var args = $A(arguments);

          return function() {
            var initArgs = [this].concat(args);
            behavior.attach.apply(behavior, initArgs);
          };
        } else {
          var args = (arguments.length == 2 && arguments[1] instanceof Array) ?
                      arguments[1] : Array.prototype.slice.call(arguments, 1);

          this.element = $(arguments[0]);
          this.initialize.apply(this, args);
          behavior._bindEvents(this);
          behavior.instances.push(this);
        }
      };

    Object.extend(behavior, Class.Methods);
    Object.extend(behavior, Behavior.Methods);
    behavior.superclass = parent;
    behavior.subclasses = [];
    behavior.instances = [];

    if (parent) {
      var subclass = function() { };
      subclass.prototype = parent.prototype;
      behavior.prototype = new subclass;
      parent.subclasses.push(behavior);
    }

    for (var i = 0; i < properties.length; i++)
      behavior.addMethods(properties[i]);

    if (!behavior.prototype.initialize)
      behavior.prototype.initialize = Prototype.emptyFunction;

    behavior.prototype.constructor = behavior;

    return behavior;
  },
  Methods : {
    attach : function(element) {
      return new this(element, Array.prototype.slice.call(arguments, 1));
    },
    _bindEvents : function(bound) {
      for (var member in bound)
        if (member.match(/^on(.+)/) && typeof bound[member] == 'function')
          bound.element.observe(RegExp.$1, Event.addBehavior._wrapObserver(bound[member].bindAsEventListener(bound)));
    }
  }
};

Remote = Behavior.create({
  initialize: function(options) {
    if (this.element.nodeName == 'FORM') new Remote.Form(this.element, options);
    else new Remote.Link(this.element, options);
  }
});

Remote.Base = {
  initialize : function(options) {
    this.options = Object.extend({
      evaluateScripts : true
    }, options || {});
  },
  _makeRequest : function(options) {
    if (options.update) new Ajax.Updater(options.update, options.url, options);
    else new Ajax.Request(options.url, options);
    return false;
  }
}

Remote.Link = Behavior.create(Remote.Base, {
  onclick : function() {
    var options = Object.extend({ url : this.element.href, method : 'get' }, this.options);
    return this._makeRequest(options);
  }
});


Remote.Form = Behavior.create(Remote.Base, {
  onclick : function(e) {
    var sourceElement = e.element();

    if (['input', 'button'].include(sourceElement.nodeName.toLowerCase()) &&
        sourceElement.type == 'submit')
      this._submitButton = sourceElement;
  },
  onsubmit : function() {
    var options = Object.extend({
      url : this.element.action,
      method : this.element.method || 'get',
      parameters : this.element.serialize({ submit: this._submitButton.name })
    }, this.options);
    this._submitButton = null;
    return this._makeRequest(options);
  }
});

Observed = Behavior.create({
  initialize : function(callback, options) {
    this.callback = callback.bind(this);
    this.options = options || {};
    this.observer = (this.element.nodeName == 'FORM') ? this._observeForm() : this._observeField();
  },
  stop: function() {
    this.observer.stop();
  },
  _observeForm: function() {
    return (this.options.frequency) ? new Form.Observer(this.element, this.options.frequency, this.callback) :
                                      new Form.EventObserver(this.element, this.callback);
  },
  _observeField: function() {
    return (this.options.frequency) ? new Form.Element.Observer(this.element, this.options.frequency, this.callback) :
                                      new Form.Element.EventObserver(this.element, this.callback);
  }
});
Remote.FormWithIndicator = Behavior.create({
  initialize: function(options) {
    this.options = Object.extend({
      evaluateScripts : true
    }, options || {});
    var indicator = $img({
      src: '/images/indicator_16.gif',
      style: 'display:none;clear:both;'
    });
    this.element.down('.button').insert({ after: indicator});
  },
  onclick: function(e) {
    var sourceElement = Event.element(e);
    if (sourceElement.nodeName.toLowerCase() == 'input' &&
    sourceElement.type == 'submit'){
      this._submitButton = sourceElement;
      sourceElement.hide();
      sourceElement.next('img').show();
    }
  },
  onsubmit: function() {
    var options = Object.extend({
      url : this.element.action,
      method : this.element.method,
      parameters : Form.serialize(this.element)
    }, this.options);
    this._submitButton = null;
    return this._makeRequest(options);
  },
  _makeRequest: function(options) {
    if (options.update) new Ajax.Updater(options.update, options.url, options);
    else new Ajax.Request(options.url, options);
    return false;
  }
});
Remote.LinkWithIndicator = Behavior.create({
  initialize: function(options) {
    this.options = Object.extend({
      evaluateScripts : true
    }, options || {});
    var indicator = $img({
      src: '/images/indicator_16.gif',
      style: 'display:none;clear:both;'
    });
    this.element.insert({ after: indicator});
  },
  onclick: function() {
    this.element.hide();
    this.element.next('img').show();
    var options = Object.extend({ url : this.element.href, method : 'get' }, this.options);
    return this._makeRequest(options);
  },
  _makeRequest: function(options) {
    if (options.update) new Ajax.Updater(options.update, options.url, options);
    else new Ajax.Request(options.url, options);
    return false;
  }
});


// Copyright (c) 2005-2008 Thomas Fuchs (http://script.aculo.us, http://mir.aculo.us)
// Contributors:
//  Justin Palmer (http://encytemedia.com/)
//  Mark Pilgrim (http://diveintomark.org/)
//  Martin Bialasinki
// 
// script.aculo.us is freely distributable under the terms of an MIT-style license.
// For details, see the script.aculo.us web site: http://script.aculo.us/ 

// converts rgb() and #xxx to #xxxxxx format,  
// returns self (or first argument) if not convertable  
String.prototype.parseColor = function() {  
  var color = '#';
  if (this.slice(0,4) == 'rgb(') {  
    var cols = this.slice(4,this.length-1).split(',');  
    var i=0; do { color += parseInt(cols[i]).toColorPart() } while (++i<3);  
  } else {  
    if (this.slice(0,1) == '#') {  
      if (this.length==4) for(var i=1;i<4;i++) color += (this.charAt(i) + this.charAt(i)).toLowerCase();  
      if (this.length==7) color = this.toLowerCase();  
    }  
  }  
  return (color.length==7 ? color : (arguments[0] || this));  
};

/*--------------------------------------------------------------------------*/

Element.collectTextNodes = function(element) {  
  return $A($(element).childNodes).collect( function(node) {
    return (node.nodeType==3 ? node.nodeValue : 
      (node.hasChildNodes() ? Element.collectTextNodes(node) : ''));
  }).flatten().join('');
};

Element.collectTextNodesIgnoreClass = function(element, className) {  
  return $A($(element).childNodes).collect( function(node) {
    return (node.nodeType==3 ? node.nodeValue : 
      ((node.hasChildNodes() && !Element.hasClassName(node,className)) ? 
        Element.collectTextNodesIgnoreClass(node, className) : ''));
  }).flatten().join('');
};

Element.setContentZoom = function(element, percent) {
  element = $(element);  
  element.setStyle({fontSize: (percent/100) + 'em'});   
  if (Prototype.Browser.WebKit) window.scrollBy(0,0);
  return element;
};

Element.getInlineOpacity = function(element){
  return $(element).style.opacity || '';
};

Element.forceRerendering = function(element) {
  try {
    element = $(element);
    var n = document.createTextNode(' ');
    element.appendChild(n);
    element.removeChild(n);
  } catch(e) { }
};

/*--------------------------------------------------------------------------*/

var Effect = {
  _elementDoesNotExistError: {
    name: 'ElementDoesNotExistError',
    message: 'The specified DOM element does not exist, but is required for this effect to operate'
  },
  Transitions: {
    linear: Prototype.K,
    sinoidal: function(pos) {
      return (-Math.cos(pos*Math.PI)/2) + 0.5;
    },
    reverse: function(pos) {
      return 1-pos;
    },
    flicker: function(pos) {
      var pos = ((-Math.cos(pos*Math.PI)/4) + 0.75) + Math.random()/4;
      return pos > 1 ? 1 : pos;
    },
    wobble: function(pos) {
      return (-Math.cos(pos*Math.PI*(9*pos))/2) + 0.5;
    },
    pulse: function(pos, pulses) { 
      pulses = pulses || 5; 
      return (
        ((pos % (1/pulses)) * pulses).round() == 0 ? 
              ((pos * pulses * 2) - (pos * pulses * 2).floor()) : 
          1 - ((pos * pulses * 2) - (pos * pulses * 2).floor())
        );
    },
    spring: function(pos) { 
      return 1 - (Math.cos(pos * 4.5 * Math.PI) * Math.exp(-pos * 6)); 
    },
    none: function(pos) {
      return 0;
    },
    full: function(pos) {
      return 1;
    }
  },
  DefaultOptions: {
    duration:   1.0,   // seconds
    fps:        100,   // 100= assume 66fps max.
    sync:       false, // true for combining
    from:       0.0,
    to:         1.0,
    delay:      0.0,
    queue:      'parallel'
  },
  tagifyText: function(element) {
    var tagifyStyle = 'position:relative';
    if (Prototype.Browser.IE) tagifyStyle += ';zoom:1';
    
    element = $(element);
    $A(element.childNodes).each( function(child) {
      if (child.nodeType==3) {
        child.nodeValue.toArray().each( function(character) {
          element.insertBefore(
            new Element('span', {style: tagifyStyle}).update(
              character == ' ' ? String.fromCharCode(160) : character), 
              child);
        });
        Element.remove(child);
      }
    });
  },
  multiple: function(element, effect) {
    var elements;
    if (((typeof element == 'object') || 
        Object.isFunction(element)) && 
       (element.length))
      elements = element;
    else
      elements = $(element).childNodes;
      
    var options = Object.extend({
      speed: 0.1,
      delay: 0.0
    }, arguments[2] || { });
    var masterDelay = options.delay;

    $A(elements).each( function(element, index) {
      new effect(element, Object.extend(options, { delay: index * options.speed + masterDelay }));
    });
  },
  PAIRS: {
    'slide':  ['SlideDown','SlideUp'],
    'blind':  ['BlindDown','BlindUp'],
    'appear': ['Appear','Fade']
  },
  toggle: function(element, effect) {
    element = $(element);
    effect = (effect || 'appear').toLowerCase();
    var options = Object.extend({
      queue: { position:'end', scope:(element.id || 'global'), limit: 1 }
    }, arguments[2] || { });
    Effect[element.visible() ? 
      Effect.PAIRS[effect][1] : Effect.PAIRS[effect][0]](element, options);
  }
};

Effect.DefaultOptions.transition = Effect.Transitions.sinoidal;

/* ------------- core effects ------------- */

Effect.ScopedQueue = Class.create(Enumerable, {
  initialize: function() {
    this.effects  = [];
    this.interval = null;    
  },
  _each: function(iterator) {
    this.effects._each(iterator);
  },
  add: function(effect) {
    var timestamp = new Date().getTime();
    
    var position = Object.isString(effect.options.queue) ? 
      effect.options.queue : effect.options.queue.position;
    
    switch(position) {
      case 'front':
        // move unstarted effects after this effect  
        this.effects.findAll(function(e){ return e.state=='idle' }).each( function(e) {
            e.startOn  += effect.finishOn;
            e.finishOn += effect.finishOn;
          });
        break;
      case 'with-last':
        timestamp = this.effects.pluck('startOn').max() || timestamp;
        break;
      case 'end':
        // start effect after last queued effect has finished
        timestamp = this.effects.pluck('finishOn').max() || timestamp;
        break;
    }
    
    effect.startOn  += timestamp;
    effect.finishOn += timestamp;

    if (!effect.options.queue.limit || (this.effects.length < effect.options.queue.limit))
      this.effects.push(effect);
    
    if (!this.interval)
      this.interval = setInterval(this.loop.bind(this), 15);
  },
  remove: function(effect) {
    this.effects = this.effects.reject(function(e) { return e==effect });
    if (this.effects.length == 0) {
      clearInterval(this.interval);
      this.interval = null;
    }
  },
  loop: function() {
    var timePos = new Date().getTime();
    for(var i=0, len=this.effects.length;i<len;i++) 
      this.effects[i] && this.effects[i].loop(timePos);
  }
});

Effect.Queues = {
  instances: $H(),
  get: function(queueName) {
    if (!Object.isString(queueName)) return queueName;
    
    return this.instances.get(queueName) ||
      this.instances.set(queueName, new Effect.ScopedQueue());
  }
};
Effect.Queue = Effect.Queues.get('global');

Effect.Base = Class.create({
  position: null,
  start: function(options) {
    function codeForEvent(options,eventName){
      return (
        (options[eventName+'Internal'] ? 'this.options.'+eventName+'Internal(this);' : '') +
        (options[eventName] ? 'this.options.'+eventName+'(this);' : '')
      );
    }
    if (options && options.transition === false) options.transition = Effect.Transitions.linear;
    this.options      = Object.extend(Object.extend({ },Effect.DefaultOptions), options || { });
    this.currentFrame = 0;
    this.state        = 'idle';
    this.startOn      = this.options.delay*1000;
    this.finishOn     = this.startOn+(this.options.duration*1000);
    this.fromToDelta  = this.options.to-this.options.from;
    this.totalTime    = this.finishOn-this.startOn;
    this.totalFrames  = this.options.fps*this.options.duration;
    
    eval('this.render = function(pos){ '+
      'if (this.state=="idle"){this.state="running";'+
      codeForEvent(this.options,'beforeSetup')+
      (this.setup ? 'this.setup();':'')+ 
      codeForEvent(this.options,'afterSetup')+
      '};if (this.state=="running"){'+
      'pos=this.options.transition(pos)*'+this.fromToDelta+'+'+this.options.from+';'+
      'this.position=pos;'+
      codeForEvent(this.options,'beforeUpdate')+
      (this.update ? 'this.update(pos);':'')+
      codeForEvent(this.options,'afterUpdate')+
      '}}');
    
    this.event('beforeStart');
    if (!this.options.sync)
      Effect.Queues.get(Object.isString(this.options.queue) ? 
        'global' : this.options.queue.scope).add(this);
  },
  loop: function(timePos) {
    if (timePos >= this.startOn) {
      if (timePos >= this.finishOn) {
        this.render(1.0);
        this.cancel();
        this.event('beforeFinish');
        if (this.finish) this.finish(); 
        this.event('afterFinish');
        return;  
      }
      var pos   = (timePos - this.startOn) / this.totalTime,
          frame = (pos * this.totalFrames).round();
      if (frame > this.currentFrame) {
        this.render(pos);
        this.currentFrame = frame;
      }
    }
  },
  cancel: function() {
    if (!this.options.sync)
      Effect.Queues.get(Object.isString(this.options.queue) ? 
        'global' : this.options.queue.scope).remove(this);
    this.state = 'finished';
  },
  event: function(eventName) {
    if (this.options[eventName + 'Internal']) this.options[eventName + 'Internal'](this);
    if (this.options[eventName]) this.options[eventName](this);
  },
  inspect: function() {
    var data = $H();
    for(property in this)
      if (!Object.isFunction(this[property])) data.set(property, this[property]);
    return '#<Effect:' + data.inspect() + ',options:' + $H(this.options).inspect() + '>';
  }
});

Effect.Parallel = Class.create(Effect.Base, {
  initialize: function(effects) {
    this.effects = effects || [];
    this.start(arguments[1]);
  },
  update: function(position) {
    this.effects.invoke('render', position);
  },
  finish: function(position) {
    this.effects.each( function(effect) {
      effect.render(1.0);
      effect.cancel();
      effect.event('beforeFinish');
      if (effect.finish) effect.finish(position);
      effect.event('afterFinish');
    });
  }
});

Effect.Tween = Class.create(Effect.Base, {
  initialize: function(object, from, to) {
    object = Object.isString(object) ? $(object) : object;
    var args = $A(arguments), method = args.last(), 
      options = args.length == 5 ? args[3] : null;
    this.method = Object.isFunction(method) ? method.bind(object) :
      Object.isFunction(object[method]) ? object[method].bind(object) : 
      function(value) { object[method] = value };
    this.start(Object.extend({ from: from, to: to }, options || { }));
  },
  update: function(position) {
    this.method(position);
  }
});

Effect.Event = Class.create(Effect.Base, {
  initialize: function() {
    this.start(Object.extend({ duration: 0 }, arguments[0] || { }));
  },
  update: Prototype.emptyFunction
});

Effect.Opacity = Class.create(Effect.Base, {
  initialize: function(element) {
    this.element = $(element);
    if (!this.element) throw(Effect._elementDoesNotExistError);
    // make this work on IE on elements without 'layout'
    if (Prototype.Browser.IE && (!this.element.currentStyle.hasLayout))
      this.element.setStyle({zoom: 1});
    var options = Object.extend({
      from: this.element.getOpacity() || 0.0,
      to:   1.0
    }, arguments[1] || { });
    this.start(options);
  },
  update: function(position) {
    this.element.setOpacity(position);
  }
});

Effect.Move = Class.create(Effect.Base, {
  initialize: function(element) {
    this.element = $(element);
    if (!this.element) throw(Effect._elementDoesNotExistError);
    var options = Object.extend({
      x:    0,
      y:    0,
      mode: 'relative'
    }, arguments[1] || { });
    this.start(options);
  },
  setup: function() {
    this.element.makePositioned();
    this.originalLeft = parseFloat(this.element.getStyle('left') || '0');
    this.originalTop  = parseFloat(this.element.getStyle('top')  || '0');
    if (this.options.mode == 'absolute') {
      this.options.x = this.options.x - this.originalLeft;
      this.options.y = this.options.y - this.originalTop;
    }
  },
  update: function(position) {
    this.element.setStyle({
      left: (this.options.x  * position + this.originalLeft).round() + 'px',
      top:  (this.options.y  * position + this.originalTop).round()  + 'px'
    });
  }
});

// for backwards compatibility
Effect.MoveBy = function(element, toTop, toLeft) {
  return new Effect.Move(element, 
    Object.extend({ x: toLeft, y: toTop }, arguments[3] || { }));
};

Effect.Scale = Class.create(Effect.Base, {
  initialize: function(element, percent) {
    this.element = $(element);
    if (!this.element) throw(Effect._elementDoesNotExistError);
    var options = Object.extend({
      scaleX: true,
      scaleY: true,
      scaleContent: true,
      scaleFromCenter: false,
      scaleMode: 'box',        // 'box' or 'contents' or { } with provided values
      scaleFrom: 100.0,
      scaleTo:   percent
    }, arguments[2] || { });
    this.start(options);
  },
  setup: function() {
    this.restoreAfterFinish = this.options.restoreAfterFinish || false;
    this.elementPositioning = this.element.getStyle('position');
    
    this.originalStyle = { };
    ['top','left','width','height','fontSize'].each( function(k) {
      this.originalStyle[k] = this.element.style[k];
    }.bind(this));
      
    this.originalTop  = this.element.offsetTop;
    this.originalLeft = this.element.offsetLeft;
    
    var fontSize = this.element.getStyle('font-size') || '100%';
    ['em','px','%','pt'].each( function(fontSizeType) {
      if (fontSize.indexOf(fontSizeType)>0) {
        this.fontSize     = parseFloat(fontSize);
        this.fontSizeType = fontSizeType;
      }
    }.bind(this));
    
    this.factor = (this.options.scaleTo - this.options.scaleFrom)/100;
    
    this.dims = null;
    if (this.options.scaleMode=='box')
      this.dims = [this.element.offsetHeight, this.element.offsetWidth];
    if (/^content/.test(this.options.scaleMode))
      this.dims = [this.element.scrollHeight, this.element.scrollWidth];
    if (!this.dims)
      this.dims = [this.options.scaleMode.originalHeight,
                   this.options.scaleMode.originalWidth];
  },
  update: function(position) {
    var currentScale = (this.options.scaleFrom/100.0) + (this.factor * position);
    if (this.options.scaleContent && this.fontSize)
      this.element.setStyle({fontSize: this.fontSize * currentScale + this.fontSizeType });
    this.setDimensions(this.dims[0] * currentScale, this.dims[1] * currentScale);
  },
  finish: function(position) {
    if (this.restoreAfterFinish) this.element.setStyle(this.originalStyle);
  },
  setDimensions: function(height, width) {
    var d = { };
    if (this.options.scaleX) d.width = width.round() + 'px';
    if (this.options.scaleY) d.height = height.round() + 'px';
    if (this.options.scaleFromCenter) {
      var topd  = (height - this.dims[0])/2;
      var leftd = (width  - this.dims[1])/2;
      if (this.elementPositioning == 'absolute') {
        if (this.options.scaleY) d.top = this.originalTop-topd + 'px';
        if (this.options.scaleX) d.left = this.originalLeft-leftd + 'px';
      } else {
        if (this.options.scaleY) d.top = -topd + 'px';
        if (this.options.scaleX) d.left = -leftd + 'px';
      }
    }
    this.element.setStyle(d);
  }
});

Effect.Highlight = Class.create(Effect.Base, {
  initialize: function(element) {
    this.element = $(element);
    if (!this.element) throw(Effect._elementDoesNotExistError);
    var options = Object.extend({ startcolor: '#ffff99' }, arguments[1] || { });
    this.start(options);
  },
  setup: function() {
    // Prevent executing on elements not in the layout flow
    if (this.element.getStyle('display')=='none') { this.cancel(); return; }
    // Disable background image during the effect
    this.oldStyle = { };
    if (!this.options.keepBackgroundImage) {
      this.oldStyle.backgroundImage = this.element.getStyle('background-image');
      this.element.setStyle({backgroundImage: 'none'});
    }
    if (!this.options.endcolor)
      this.options.endcolor = this.element.getStyle('background-color').parseColor('#ffffff');
    if (!this.options.restorecolor)
      this.options.restorecolor = this.element.getStyle('background-color');
    // init color calculations
    this._base  = $R(0,2).map(function(i){ return parseInt(this.options.startcolor.slice(i*2+1,i*2+3),16) }.bind(this));
    this._delta = $R(0,2).map(function(i){ return parseInt(this.options.endcolor.slice(i*2+1,i*2+3),16)-this._base[i] }.bind(this));
  },
  update: function(position) {
    this.element.setStyle({backgroundColor: $R(0,2).inject('#',function(m,v,i){
      return m+((this._base[i]+(this._delta[i]*position)).round().toColorPart()); }.bind(this)) });
  },
  finish: function() {
    this.element.setStyle(Object.extend(this.oldStyle, {
      backgroundColor: this.options.restorecolor
    }));
  }
});

Effect.ScrollTo = function(element) {
  var options = arguments[1] || { },
    scrollOffsets = document.viewport.getScrollOffsets(),
    elementOffsets = $(element).cumulativeOffset(),
    max = (window.height || document.body.scrollHeight) - document.viewport.getHeight();  

  if (options.offset) elementOffsets[1] += options.offset;

  return new Effect.Tween(null,
    scrollOffsets.top,
    elementOffsets[1] > max ? max : elementOffsets[1],
    options,
    function(p){ scrollTo(scrollOffsets.left, p.round()) }
  );
};

/* ------------- combination effects ------------- */

Effect.Fade = function(element) {
  element = $(element);
  var oldOpacity = element.getInlineOpacity();
  var options = Object.extend({
    from: element.getOpacity() || 1.0,
    to:   0.0,
    afterFinishInternal: function(effect) { 
      if (effect.options.to!=0) return;
      effect.element.hide().setStyle({opacity: oldOpacity}); 
    }
  }, arguments[1] || { });
  return new Effect.Opacity(element,options);
};

Effect.Appear = function(element) {
  element = $(element);
  var options = Object.extend({
  from: (element.getStyle('display') == 'none' ? 0.0 : element.getOpacity() || 0.0),
  to:   1.0,
  // force Safari to render floated elements properly
  afterFinishInternal: function(effect) {
    effect.element.forceRerendering();
  },
  beforeSetup: function(effect) {
    effect.element.setOpacity(effect.options.from).show(); 
  }}, arguments[1] || { });
  return new Effect.Opacity(element,options);
};

Effect.Puff = function(element) {
  element = $(element);
  var oldStyle = { 
    opacity: element.getInlineOpacity(), 
    position: element.getStyle('position'),
    top:  element.style.top,
    left: element.style.left,
    width: element.style.width,
    height: element.style.height
  };
  return new Effect.Parallel(
   [ new Effect.Scale(element, 200, 
      { sync: true, scaleFromCenter: true, scaleContent: true, restoreAfterFinish: true }), 
     new Effect.Opacity(element, { sync: true, to: 0.0 } ) ], 
     Object.extend({ duration: 1.0, 
      beforeSetupInternal: function(effect) {
        Position.absolutize(effect.effects[0].element)
      },
      afterFinishInternal: function(effect) {
         effect.effects[0].element.hide().setStyle(oldStyle); }
     }, arguments[1] || { })
   );
};

Effect.BlindUp = function(element) {
  element = $(element);
  element.makeClipping();
  return new Effect.Scale(element, 0,
    Object.extend({ scaleContent: false, 
      scaleX: false, 
      restoreAfterFinish: true,
      afterFinishInternal: function(effect) {
        effect.element.hide().undoClipping();
      } 
    }, arguments[1] || { })
  );
};

Effect.BlindDown = function(element) {
  element = $(element);
  var elementDimensions = element.getDimensions();
  return new Effect.Scale(element, 100, Object.extend({ 
    scaleContent: false, 
    scaleX: false,
    scaleFrom: 0,
    scaleMode: {originalHeight: elementDimensions.height, originalWidth: elementDimensions.width},
    restoreAfterFinish: true,
    afterSetup: function(effect) {
      effect.element.makeClipping().setStyle({height: '0px'}).show(); 
    },  
    afterFinishInternal: function(effect) {
      effect.element.undoClipping();
    }
  }, arguments[1] || { }));
};

Effect.SwitchOff = function(element) {
  element = $(element);
  var oldOpacity = element.getInlineOpacity();
  return new Effect.Appear(element, Object.extend({
    duration: 0.4,
    from: 0,
    transition: Effect.Transitions.flicker,
    afterFinishInternal: function(effect) {
      new Effect.Scale(effect.element, 1, { 
        duration: 0.3, scaleFromCenter: true,
        scaleX: false, scaleContent: false, restoreAfterFinish: true,
        beforeSetup: function(effect) { 
          effect.element.makePositioned().makeClipping();
        },
        afterFinishInternal: function(effect) {
          effect.element.hide().undoClipping().undoPositioned().setStyle({opacity: oldOpacity});
        }
      })
    }
  }, arguments[1] || { }));
};

Effect.DropOut = function(element) {
  element = $(element);
  var oldStyle = {
    top: element.getStyle('top'),
    left: element.getStyle('left'),
    opacity: element.getInlineOpacity() };
  return new Effect.Parallel(
    [ new Effect.Move(element, {x: 0, y: 100, sync: true }), 
      new Effect.Opacity(element, { sync: true, to: 0.0 }) ],
    Object.extend(
      { duration: 0.5,
        beforeSetup: function(effect) {
          effect.effects[0].element.makePositioned(); 
        },
        afterFinishInternal: function(effect) {
          effect.effects[0].element.hide().undoPositioned().setStyle(oldStyle);
        } 
      }, arguments[1] || { }));
};

Effect.Shake = function(element) {
  element = $(element);
  var options = Object.extend({
    distance: 20,
    duration: 0.5
  }, arguments[1] || {});
  var distance = parseFloat(options.distance);
  var split = parseFloat(options.duration) / 10.0;
  var oldStyle = {
    top: element.getStyle('top'),
    left: element.getStyle('left') };
    return new Effect.Move(element,
      { x:  distance, y: 0, duration: split, afterFinishInternal: function(effect) {
    new Effect.Move(effect.element,
      { x: -distance*2, y: 0, duration: split*2,  afterFinishInternal: function(effect) {
    new Effect.Move(effect.element,
      { x:  distance*2, y: 0, duration: split*2,  afterFinishInternal: function(effect) {
    new Effect.Move(effect.element,
      { x: -distance*2, y: 0, duration: split*2,  afterFinishInternal: function(effect) {
    new Effect.Move(effect.element,
      { x:  distance*2, y: 0, duration: split*2,  afterFinishInternal: function(effect) {
    new Effect.Move(effect.element,
      { x: -distance, y: 0, duration: split, afterFinishInternal: function(effect) {
        effect.element.undoPositioned().setStyle(oldStyle);
  }}) }}) }}) }}) }}) }});
};

Effect.SlideDown = function(element) {
  element = $(element).cleanWhitespace();
  // SlideDown need to have the content of the element wrapped in a container element with fixed height!
  var oldInnerBottom = element.down().getStyle('bottom');
  var elementDimensions = element.getDimensions();
  return new Effect.Scale(element, 100, Object.extend({ 
    scaleContent: false, 
    scaleX: false, 
    scaleFrom: window.opera ? 0 : 1,
    scaleMode: {originalHeight: elementDimensions.height, originalWidth: elementDimensions.width},
    restoreAfterFinish: true,
    afterSetup: function(effect) {
      effect.element.makePositioned();
      effect.element.down().makePositioned();
      if (window.opera) effect.element.setStyle({top: ''});
      effect.element.makeClipping().setStyle({height: '0px'}).show(); 
    },
    afterUpdateInternal: function(effect) {
      effect.element.down().setStyle({bottom:
        (effect.dims[0] - effect.element.clientHeight) + 'px' }); 
    },
    afterFinishInternal: function(effect) {
      effect.element.undoClipping().undoPositioned();
      effect.element.down().undoPositioned().setStyle({bottom: oldInnerBottom}); }
    }, arguments[1] || { })
  );
};

Effect.SlideUp = function(element) {
  element = $(element).cleanWhitespace();
  var oldInnerBottom = element.down().getStyle('bottom');
  var elementDimensions = element.getDimensions();
  return new Effect.Scale(element, window.opera ? 0 : 1,
   Object.extend({ scaleContent: false, 
    scaleX: false, 
    scaleMode: 'box',
    scaleFrom: 100,
    scaleMode: {originalHeight: elementDimensions.height, originalWidth: elementDimensions.width},
    restoreAfterFinish: true,
    afterSetup: function(effect) {
      effect.element.makePositioned();
      effect.element.down().makePositioned();
      if (window.opera) effect.element.setStyle({top: ''});
      effect.element.makeClipping().show();
    },  
    afterUpdateInternal: function(effect) {
      effect.element.down().setStyle({bottom:
        (effect.dims[0] - effect.element.clientHeight) + 'px' });
    },
    afterFinishInternal: function(effect) {
      effect.element.hide().undoClipping().undoPositioned();
      effect.element.down().undoPositioned().setStyle({bottom: oldInnerBottom});
    }
   }, arguments[1] || { })
  );
};

// Bug in opera makes the TD containing this element expand for a instance after finish 
Effect.Squish = function(element) {
  return new Effect.Scale(element, window.opera ? 1 : 0, Object.extend({ 
    restoreAfterFinish: true,
    beforeSetup: function(effect) {
      effect.element.makeClipping(); 
    },  
    afterFinishInternal: function(effect) {
      effect.element.hide().undoClipping(); 
    }
  }, arguments[1] || {}));
};

Effect.Grow = function(element) {
  element = $(element);
  var options = Object.extend({
    direction: 'center',
    moveTransition: Effect.Transitions.sinoidal,
    scaleTransition: Effect.Transitions.sinoidal,
    opacityTransition: Effect.Transitions.full
  }, arguments[1] || { });
  var oldStyle = {
    top: element.style.top,
    left: element.style.left,
    height: element.style.height,
    width: element.style.width,
    opacity: element.getInlineOpacity() };

  var dims = element.getDimensions();    
  var initialMoveX, initialMoveY;
  var moveX, moveY;
  
  switch (options.direction) {
    case 'top-left':
      initialMoveX = initialMoveY = moveX = moveY = 0; 
      break;
    case 'top-right':
      initialMoveX = dims.width;
      initialMoveY = moveY = 0;
      moveX = -dims.width;
      break;
    case 'bottom-left':
      initialMoveX = moveX = 0;
      initialMoveY = dims.height;
      moveY = -dims.height;
      break;
    case 'bottom-right':
      initialMoveX = dims.width;
      initialMoveY = dims.height;
      moveX = -dims.width;
      moveY = -dims.height;
      break;
    case 'center':
      initialMoveX = dims.width / 2;
      initialMoveY = dims.height / 2;
      moveX = -dims.width / 2;
      moveY = -dims.height / 2;
      break;
  }
  
  return new Effect.Move(element, {
    x: initialMoveX,
    y: initialMoveY,
    duration: 0.01, 
    beforeSetup: function(effect) {
      effect.element.hide().makeClipping().makePositioned();
    },
    afterFinishInternal: function(effect) {
      new Effect.Parallel(
        [ new Effect.Opacity(effect.element, { sync: true, to: 1.0, from: 0.0, transition: options.opacityTransition }),
          new Effect.Move(effect.element, { x: moveX, y: moveY, sync: true, transition: options.moveTransition }),
          new Effect.Scale(effect.element, 100, {
            scaleMode: { originalHeight: dims.height, originalWidth: dims.width }, 
            sync: true, scaleFrom: window.opera ? 1 : 0, transition: options.scaleTransition, restoreAfterFinish: true})
        ], Object.extend({
             beforeSetup: function(effect) {
               effect.effects[0].element.setStyle({height: '0px'}).show(); 
             },
             afterFinishInternal: function(effect) {
               effect.effects[0].element.undoClipping().undoPositioned().setStyle(oldStyle); 
             }
           }, options)
      )
    }
  });
};

Effect.Shrink = function(element) {
  element = $(element);
  var options = Object.extend({
    direction: 'center',
    moveTransition: Effect.Transitions.sinoidal,
    scaleTransition: Effect.Transitions.sinoidal,
    opacityTransition: Effect.Transitions.none
  }, arguments[1] || { });
  var oldStyle = {
    top: element.style.top,
    left: element.style.left,
    height: element.style.height,
    width: element.style.width,
    opacity: element.getInlineOpacity() };

  var dims = element.getDimensions();
  var moveX, moveY;
  
  switch (options.direction) {
    case 'top-left':
      moveX = moveY = 0;
      break;
    case 'top-right':
      moveX = dims.width;
      moveY = 0;
      break;
    case 'bottom-left':
      moveX = 0;
      moveY = dims.height;
      break;
    case 'bottom-right':
      moveX = dims.width;
      moveY = dims.height;
      break;
    case 'center':  
      moveX = dims.width / 2;
      moveY = dims.height / 2;
      break;
  }
  
  return new Effect.Parallel(
    [ new Effect.Opacity(element, { sync: true, to: 0.0, from: 1.0, transition: options.opacityTransition }),
      new Effect.Scale(element, window.opera ? 1 : 0, { sync: true, transition: options.scaleTransition, restoreAfterFinish: true}),
      new Effect.Move(element, { x: moveX, y: moveY, sync: true, transition: options.moveTransition })
    ], Object.extend({            
         beforeStartInternal: function(effect) {
           effect.effects[0].element.makePositioned().makeClipping(); 
         },
         afterFinishInternal: function(effect) {
           effect.effects[0].element.hide().undoClipping().undoPositioned().setStyle(oldStyle); }
       }, options)
  );
};

Effect.Pulsate = function(element) {
  element = $(element);
  var options    = arguments[1] || { };
  var oldOpacity = element.getInlineOpacity();
  var transition = options.transition || Effect.Transitions.sinoidal;
  var reverser   = function(pos){ return transition(1-Effect.Transitions.pulse(pos, options.pulses)) };
  reverser.bind(transition);
  return new Effect.Opacity(element, 
    Object.extend(Object.extend({  duration: 2.0, from: 0,
      afterFinishInternal: function(effect) { effect.element.setStyle({opacity: oldOpacity}); }
    }, options), {transition: reverser}));
};

Effect.Fold = function(element) {
  element = $(element);
  var oldStyle = {
    top: element.style.top,
    left: element.style.left,
    width: element.style.width,
    height: element.style.height };
  element.makeClipping();
  return new Effect.Scale(element, 5, Object.extend({   
    scaleContent: false,
    scaleX: false,
    afterFinishInternal: function(effect) {
    new Effect.Scale(element, 1, { 
      scaleContent: false, 
      scaleY: false,
      afterFinishInternal: function(effect) {
        effect.element.hide().undoClipping().setStyle(oldStyle);
      } });
  }}, arguments[1] || { }));
};

Effect.Morph = Class.create(Effect.Base, {
  initialize: function(element) {
    this.element = $(element);
    if (!this.element) throw(Effect._elementDoesNotExistError);
    var options = Object.extend({
      style: { }
    }, arguments[1] || { });
    
    if (!Object.isString(options.style)) this.style = $H(options.style);
    else {
      if (options.style.include(':'))
        this.style = options.style.parseStyle();
      else {
        this.element.addClassName(options.style);
        this.style = $H(this.element.getStyles());
        this.element.removeClassName(options.style);
        var css = this.element.getStyles();
        this.style = this.style.reject(function(style) {
          return style.value == css[style.key];
        });
        options.afterFinishInternal = function(effect) {
          effect.element.addClassName(effect.options.style);
          effect.transforms.each(function(transform) {
            effect.element.style[transform.style] = '';
          });
        }
      }
    }
    this.start(options);
  },
  
  setup: function(){
    function parseColor(color){
      if (!color || ['rgba(0, 0, 0, 0)','transparent'].include(color)) color = '#ffffff';
      color = color.parseColor();
      return $R(0,2).map(function(i){
        return parseInt( color.slice(i*2+1,i*2+3), 16 ) 
      });
    }
    this.transforms = this.style.map(function(pair){
      var property = pair[0], value = pair[1], unit = null;

      if (value.parseColor('#zzzzzz') != '#zzzzzz') {
        value = value.parseColor();
        unit  = 'color';
      } else if (property == 'opacity') {
        value = parseFloat(value);
        if (Prototype.Browser.IE && (!this.element.currentStyle.hasLayout))
          this.element.setStyle({zoom: 1});
      } else if (Element.CSS_LENGTH.test(value)) {
          var components = value.match(/^([\+\-]?[0-9\.]+)(.*)$/);
          value = parseFloat(components[1]);
          unit = (components.length == 3) ? components[2] : null;
      }

      var originalValue = this.element.getStyle(property);
      return { 
        style: property.camelize(), 
        originalValue: unit=='color' ? parseColor(originalValue) : parseFloat(originalValue || 0), 
        targetValue: unit=='color' ? parseColor(value) : value,
        unit: unit
      };
    }.bind(this)).reject(function(transform){
      return (
        (transform.originalValue == transform.targetValue) ||
        (
          transform.unit != 'color' &&
          (isNaN(transform.originalValue) || isNaN(transform.targetValue))
        )
      )
    });
  },
  update: function(position) {
    var style = { }, transform, i = this.transforms.length;
    while(i--)
      style[(transform = this.transforms[i]).style] = 
        transform.unit=='color' ? '#'+
          (Math.round(transform.originalValue[0]+
            (transform.targetValue[0]-transform.originalValue[0])*position)).toColorPart() +
          (Math.round(transform.originalValue[1]+
            (transform.targetValue[1]-transform.originalValue[1])*position)).toColorPart() +
          (Math.round(transform.originalValue[2]+
            (transform.targetValue[2]-transform.originalValue[2])*position)).toColorPart() :
        (transform.originalValue +
          (transform.targetValue - transform.originalValue) * position).toFixed(3) + 
            (transform.unit === null ? '' : transform.unit);
    this.element.setStyle(style, true);
  }
});

Effect.Transform = Class.create({
  initialize: function(tracks){
    this.tracks  = [];
    this.options = arguments[1] || { };
    this.addTracks(tracks);
  },
  addTracks: function(tracks){
    tracks.each(function(track){
      track = $H(track);
      var data = track.values().first();
      this.tracks.push($H({
        ids:     track.keys().first(),
        effect:  Effect.Morph,
        options: { style: data }
      }));
    }.bind(this));
    return this;
  },
  play: function(){
    return new Effect.Parallel(
      this.tracks.map(function(track){
        var ids = track.get('ids'), effect = track.get('effect'), options = track.get('options');
        var elements = [$(ids) || $$(ids)].flatten();
        return elements.map(function(e){ return new effect(e, Object.extend({ sync:true }, options)) });
      }).flatten(),
      this.options
    );
  }
});

Element.CSS_PROPERTIES = $w(
  'backgroundColor backgroundPosition borderBottomColor borderBottomStyle ' + 
  'borderBottomWidth borderLeftColor borderLeftStyle borderLeftWidth ' +
  'borderRightColor borderRightStyle borderRightWidth borderSpacing ' +
  'borderTopColor borderTopStyle borderTopWidth bottom clip color ' +
  'fontSize fontWeight height left letterSpacing lineHeight ' +
  'marginBottom marginLeft marginRight marginTop markerOffset maxHeight '+
  'maxWidth minHeight minWidth opacity outlineColor outlineOffset ' +
  'outlineWidth paddingBottom paddingLeft paddingRight paddingTop ' +
  'right textIndent top width wordSpacing zIndex');
  
Element.CSS_LENGTH = /^(([\+\-]?[0-9\.]+)(em|ex|px|in|cm|mm|pt|pc|\%))|0$/;

String.__parseStyleElement = document.createElement('div');
String.prototype.parseStyle = function(){
  var style, styleRules = $H();
  if (Prototype.Browser.WebKit)
    style = new Element('div',{style:this}).style;
  else {
    String.__parseStyleElement.innerHTML = '<div style="' + this + '"></div>';
    style = String.__parseStyleElement.childNodes[0].style;
  }
  
  Element.CSS_PROPERTIES.each(function(property){
    if (style[property]) styleRules.set(property, style[property]); 
  });
  
  if (Prototype.Browser.IE && this.include('opacity'))
    styleRules.set('opacity', this.match(/opacity:\s*((?:0|1)?(?:\.\d*)?)/)[1]);

  return styleRules;
};

if (document.defaultView && document.defaultView.getComputedStyle) {
  Element.getStyles = function(element) {
    var css = document.defaultView.getComputedStyle($(element), null);
    return Element.CSS_PROPERTIES.inject({ }, function(styles, property) {
      styles[property] = css[property];
      return styles;
    });
  };
} else {
  Element.getStyles = function(element) {
    element = $(element);
    var css = element.currentStyle, styles;
    styles = Element.CSS_PROPERTIES.inject({ }, function(hash, property) {
      hash.set(property, css[property]);
      return hash;
    });
    if (!styles.opacity) styles.set('opacity', element.getOpacity());
    return styles;
  };
};

Effect.Methods = {
  morph: function(element, style) {
    element = $(element);
    new Effect.Morph(element, Object.extend({ style: style }, arguments[2] || { }));
    return element;
  },
  visualEffect: function(element, effect, options) {
    element = $(element)
    var s = effect.dasherize().camelize(), klass = s.charAt(0).toUpperCase() + s.substring(1);
    new Effect[klass](element, options);
    return element;
  },
  highlight: function(element, options) {
    element = $(element);
    new Effect.Highlight(element, options);
    return element;
  }
};

$w('fade appear grow shrink fold blindUp blindDown slideUp slideDown '+
  'pulsate shake puff squish switchOff dropOut').each(
  function(effect) { 
    Effect.Methods[effect] = function(element, options){
      element = $(element);
      Effect[effect.charAt(0).toUpperCase() + effect.substring(1)](element, options);
      return element;
    }
  }
);

$w('getInlineOpacity forceRerendering setContentZoom collectTextNodes collectTextNodesIgnoreClass getStyles').each( 
  function(f) { Effect.Methods[f] = Element[f]; }
);

Element.addMethods(Effect.Methods);


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
