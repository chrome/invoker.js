Invoker   = require('../src/invoker.coffee')

chai      = require('chai')
sinon     = require('sinon')
sinonChai = require('sinon-chai')

chai.should()
chai.use(sinonChai)


describe 'Invoker', ->

  beforeEach (done) ->
    Invoker.subscribers = {}
    done()

  describe 'subscribe', ->

    it 'should be defined', ->
      Invoker.subscribe.should.exist


    it 'should accept topic name with callback', ->
      (-> Invoker.subscribe('topic', sinon.spy())).should.not.throw()


    it 'should subscribe multiple topics at once', ->
      spy = sinon.spy()

      Invoker.subscribe('topic1 topic2', spy)

      Invoker.publish('topic1')
      Invoker.publish('topic2')

      spy.should.be.calledTwice


    it 'should subscribe by wildcards ("*")', ->
      spy = sinon.spy()

      Invoker.subscribe('topic*', spy)

      Invoker.publish('topic')
      Invoker.publish('topic123')
      Invoker.publish('topicabc')
      Invoker.publish('top')

      spy.should.have.been.calledThrice


    it 'should subscribe by wildcards ("?")', ->
      spy = sinon.spy()

      Invoker.subscribe('topic?', spy)

      Invoker.publish('topic')
      Invoker.publish('topic1')
      Invoker.publish('topic2')
      Invoker.publish('topic11')

      spy.should.have.been.calledTwice


  describe 'publish', ->

    it 'should be defined', ->
      Invoker.publish.should.exist


    it 'should run callback', ->
      spy = sinon.spy()
      Invoker.subscribe('topic', spy)
      Invoker.publish('topic')

      spy.should.be.calledOnce


    it 'should run callback twice', ->
      spy = sinon.spy()
      Invoker.subscribe('topic', spy)
      Invoker.publish('topic')
      Invoker.publish('topic')

      spy.should.be.calledTwice


    it 'should run callback with arguments', ->
      spy = sinon.spy()
      Invoker.subscribe('topic', spy)
      Invoker.publish('topic', 1, 2, 3)

      spy.should.be.calledWith(1, 2, 3)


    it 'should run callback with context', ->
      spy = sinon.spy()

      class SubTest
      subTest = new SubTest()

      Invoker.subscribe('topic', subTest, spy)
      Invoker.publish('topic')

      spy.should.be.calledOn(subTest)


    it 'should run multiple callbacks', ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()

      Invoker.subscribe('topic', spy1)
      Invoker.subscribe('topic', spy2)

      Invoker.publish('topic')

      spy1.should.be.calledOnce
      spy2.should.be.calledOnce


    it 'should run multiple callbacks on different contexts', ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()
      class SubTest1
      class SubTest2
      subTest1 = new SubTest1()
      subTest2 = new SubTest2()

      Invoker.subscribe('topic', subTest1, spy1)
      Invoker.subscribe('topic', subTest2, spy2)

      Invoker.publish('topic')

      spy1.should.be.calledOn(subTest1)
      spy2.should.be.calledOn(subTest2)


    it 'should run callbacks assigned only to publiched topic', ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()

      Invoker.subscribe('topic1', spy1)
      Invoker.subscribe('topic2', spy2)

      Invoker.publish('topic1')

      spy1.should.be.calledOnce
      spy2.should.not.be.called


    it 'should run callbacks by wildcards ("*")', ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()
      spy3 = sinon.spy()

      Invoker.subscribe('ns1:topic1', spy1)
      Invoker.subscribe('ns1:topic2', spy2)
      Invoker.subscribe('ns2:topic3', spy3)

      Invoker.publish('ns1:*')

      spy1.should.be.calledOnce
      spy2.should.be.calledOnce
      spy3.should.not.be.called


    it 'should run callbacks by wildcards ("?")', ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()
      spy3 = sinon.spy()

      Invoker.subscribe('ns1:topic1', spy1)
      Invoker.subscribe('ns1:topic2', spy2)
      Invoker.subscribe('ns1:topic10', spy3)

      Invoker.publish('ns1:topic?')

      spy1.should.be.calledOnce
      spy2.should.be.calledOnce
      spy3.should.not.be.called


    it 'should run callbacks by priority order', ->
      a = ''
      spy1 = -> a += '1'
      spy2 = -> a += '2'
      spy3 = -> a += '3'

      Invoker.subscribe('topic', spy1, 3)
      Invoker.subscribe('topic', spy2, 1)
      Invoker.subscribe('topic', spy3, 2)

      Invoker.publish('topic')

      a.should.be.equal '231'

    it 'should break callbacks execution if callback returns Invoker.STOP', ->
      a = ''
      spy1 = -> a += '1'
      spy2 = -> a += '2'
      spy3 = ->
        a += '3'
        Invoker.STOP
      spy4 = -> a += '4'

      Invoker.subscribe('topic', spy1, 1)
      Invoker.subscribe('topic', spy2, 2)
      Invoker.subscribe('topic', spy3, 3)
      Invoker.subscribe('topic', spy4, 4)

      Invoker.publish('topic')

      a.should.be.equal '123'


    it 'should break callbacks execution if callback raise exception', ->
      a = ''
      spy1 = -> a += '1'
      spy2 = -> a += '2'
      spy3 = -> notExistedFunction()
      spy4 = -> a += '3'

      Invoker.subscribe('topic', spy1, 1)
      Invoker.subscribe('topic', spy2, 2)
      Invoker.subscribe('topic', spy3, 3)
      Invoker.subscribe('topic', spy4, 4)

      (-> Invoker.publish('topic')).should.throw()
      a.should.be.equal '12'



  describe 'unsubscribe', ->

    it 'should be defined', ->
      Invoker.unsubscribe.should.exist


    it 'should unsubscribe by topic', ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()
      spy3 = sinon.spy()

      Invoker.subscribe('topic1', spy1)
      Invoker.subscribe('topic1', spy2)
      Invoker.subscribe('topic2', spy3)

      Invoker.unsubscribe('topic1')

      Invoker.publish('topic1')
      Invoker.publish('topic2')

      spy1.should.not.be.called
      spy2.should.not.be.called
      spy3.should.be.calledOnce


    it 'should unsubscribe by topic and callback', ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()

      Invoker.subscribe('topic', spy1)
      Invoker.subscribe('topic', spy2)

      Invoker.unsubscribe('topic', spy1)

      Invoker.publish('topic')

      spy1.should.not.be.called
      spy2.should.be.calledOnce


    it 'should unsubscribe by topic and context', ->
      spy = sinon.spy()

      context1 = new (class Context1)
      context2 = new (class Context2)

      Invoker.subscribe('topic', context1, spy)
      Invoker.subscribe('topic', context2, spy)

      Invoker.unsubscribe('topic', context1)

      Invoker.publish('topic')

      spy.should.not.be.calledOn(context1)
      spy.should.be.calledOn(context2)


    it 'should unsubscribe by topic, context and callback', ->
      spy1 = sinon.spy()
      spy2 = sinon.spy()

      context1 = new (class Context1)
      context2 = new (class Context2)

      Invoker.subscribe('topic', context1, spy1)
      Invoker.subscribe('topic', context1, spy2)
      Invoker.subscribe('topic', context2, spy1)
      Invoker.subscribe('topic', context2, spy2)

      Invoker.unsubscribe('topic', context1, spy2)
      Invoker.unsubscribe('topic', context2, spy1)

      Invoker.publish('topic')

      spy1.should.be.calledOn(context1)
      spy2.should.not.be.calledOn(context1)

      spy1.should.not.be.calledOn(context2)
      spy2.should.be.calledOn(context2)
