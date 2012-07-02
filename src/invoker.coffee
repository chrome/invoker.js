class Invoker

  @settings:
    async: false
    defaultPriority: 10

  testEventName = (tested, target) ->
    !!getRegExp(tested).exec(target) or !!getRegExp(target).exec(tested)

  getRegExp = (event) ->
    events = event.replace(/[-[\]{}()+.\\^$|#]/g, "\\$&").replace(/\?/g, '.').replace(/\*/g, '(.*?)').split(/[\s,;]+/)
    new RegExp("(^#{events.join('$|^')}$)")

  @publish: (event, options...) ->
    return false unless @subscribers?

    toExecute = []
    async = @settings.async

    for topic of @subscribers
      if testEventName(event, topic)
        for subscriber in @subscribers[topic]
          toExecute.push subscriber
          async = async and subscriber.priority == @settings.defaultPriority

    unless async
      toExecute.sort(
        (a, b) ->
          a.priority > b.priority
      )

    for subscriber in toExecute
      if subscriber.context
        if async
          setTimeout(
            ->
              subscriber.callback.call(subscriber.context, options...)
            1
          )
        else
          subscriber.callback.call(subscriber.context, options...)
      else
        if async
          setTimeout(
            ->
              subscriber.callback(options...)
            1
          )
        else
          subscriber.callback(options...)



  @subscribe: (event, context, callback, priority = @settings.defaultPriority) ->
    if arguments.length == 3 and typeof(callback) == 'number'
      [priority, callback, context] = [callback, context, undefined]
    if arguments.length == 2
      [callback, context] = [context, undefined]

    @subscribers ?= {}

    events = event.split(/[\s,;]+/)

    for event in events
      @subscribers[event] ?= []
      @subscribers[event].push({callback, context, priority})


  @unsubscribe: (event, context, callback) ->
    return false unless @subscribers?

    if arguments.length == 2 and typeof(context) == 'function'
      [callback, context] = [context, undefined]

    deleted = 0
    for topic of @subscribers
      if testEventName(event, topic)
        if callback? or context?
          index = 0
          while index < @subscribers[topic].length
            if (callback? and not context?  and callback == @subscribers[topic][index].callback) or
               (context?  and not callback? and context  == @subscribers[topic][index].context ) or
               (callback? and     context?  and context  == @subscribers[topic][index].context and callback == @subscribers[topic][index].callback)
              @subscribers[topic].splice(index, 1)
            else
              index++
        else
          delete @subscribers[topic]
    deleted > 0

if window?
  window.Invoker = Invoker
else
  module.exports = Invoker