(function() {
  var Invoker,
    __slice = [].slice;

  Invoker = (function() {
    var getRegExp, testEventName;

    function Invoker() {}

    Invoker.STOP = '7Jxmz}a&nst4@Y';

    Invoker.settings = {
      async: false,
      defaultPriority: 10,
      breakOnError: true
    };

    testEventName = function(tested, target) {
      return !!getRegExp(tested).exec(target) || !!getRegExp(target).exec(tested);
    };

    getRegExp = function(event) {
      var events;
      events = event.replace(/[-[\]{}()+.\\^$|#]/g, "\\$&").replace(/\?/g, '.').replace(/\*/g, '(.*?)').split(/[\s,;]+/);
      return new RegExp("(^" + (events.join('$|^')) + "$)");
    };

    Invoker.publish = function() {
      var async, callbackResult, event, options, subscriber, toExecute, topic, _i, _j, _len, _len1, _ref, _ref1, _ref2, _results;
      event = arguments[0], options = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (this.subscribers == null) {
        return false;
      }
      toExecute = [];
      async = this.settings.async;
      for (topic in this.subscribers) {
        if (testEventName(event, topic)) {
          _ref = this.subscribers[topic];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            subscriber = _ref[_i];
            toExecute.push(subscriber);
            async = async && subscriber.priority === this.settings.defaultPriority;
          }
        }
      }
      if (!async) {
        toExecute.sort(function(a, b) {
          return a.priority > b.priority;
        });
      }
      _results = [];
      for (_j = 0, _len1 = toExecute.length; _j < _len1; _j++) {
        subscriber = toExecute[_j];
        if (async) {
          _results.push(setTimeout(function() {
            var _ref1;
            return (_ref1 = subscriber.callback).call.apply(_ref1, [subscriber.context].concat(__slice.call(options)));
          }, 1));
        } else {
          if (this.settings.breakOnError) {
            callbackResult = (_ref1 = subscriber.callback).call.apply(_ref1, [subscriber.context].concat(__slice.call(options)));
          } else {
            try {
              callbackResult = (_ref2 = subscriber.callback).call.apply(_ref2, [subscriber.context].concat(__slice.call(options)));
            } catch (e) {
              setTimeout(function() {
                throw e;
              }, 1);
            }
          }
          if (callbackResult === this.STOP) {
            break;
          } else {
            _results.push(void 0);
          }
        }
      }
      return _results;
    };

    Invoker.subscribe = function(event, context, callback, priority) {
      var events, _base, _i, _len, _ref, _ref1, _ref2, _ref3, _results;
      if (priority == null) {
        priority = this.settings.defaultPriority;
      }
      if (arguments.length === 3 && typeof callback === 'number') {
        _ref = [callback, context, void 0], priority = _ref[0], callback = _ref[1], context = _ref[2];
      }
      if (arguments.length === 2) {
        _ref1 = [context, void 0], callback = _ref1[0], context = _ref1[1];
      }
      if ((_ref2 = this.subscribers) == null) {
        this.subscribers = {};
      }
      events = event.split(/[\s,;]+/);
      _results = [];
      for (_i = 0, _len = events.length; _i < _len; _i++) {
        event = events[_i];
        if ((_ref3 = (_base = this.subscribers)[event]) == null) {
          _base[event] = [];
        }
        _results.push(this.subscribers[event].push({
          callback: callback,
          context: context,
          priority: priority
        }));
      }
      return _results;
    };

    Invoker.unsubscribe = function(event, context, callback) {
      var deleted, index, topic, _ref;
      if (this.subscribers == null) {
        return false;
      }
      if (arguments.length === 2 && typeof context === 'function') {
        _ref = [context, void 0], callback = _ref[0], context = _ref[1];
      }
      deleted = 0;
      for (topic in this.subscribers) {
        if (testEventName(event, topic)) {
          if ((callback != null) || (context != null)) {
            index = 0;
            while (index < this.subscribers[topic].length) {
              if (((callback != null) && !(context != null) && callback === this.subscribers[topic][index].callback) || ((context != null) && !(callback != null) && context === this.subscribers[topic][index].context) || ((callback != null) && (context != null) && context === this.subscribers[topic][index].context && callback === this.subscribers[topic][index].callback)) {
                this.subscribers[topic].splice(index, 1);
              } else {
                index++;
              }
            }
          } else {
            delete this.subscribers[topic];
          }
        }
      }
      return deleted > 0;
    };

    return Invoker;

  })();

  if (typeof window !== "undefined" && window !== null) {
    window.Invoker = Invoker;
  } else {
    module.exports = Invoker;
  }

}).call(this);
