{_, should, nock} = require './utils'

describe.skip '20121115', () ->
  request = require 'request'
  RESTit = require '../src/RESTit'


  it 'should GET root', (done) ->
    re$ = RESTit().re$

    re$('http://starbucks.apiary.io')
    .read()
    .callback (err, resp) ->
      return done err  if err
      resp[0].statusType.should.equal 2
      done()


  it 'should GET order history', (done) ->
    re$ = RESTit().re$

    re$('http://starbucks.apiary.io')
    .read()
    .follow('/rels/orders') # .follow('orders')
    .read()
    .callback (err, resp) ->
      return done err  if err
      resp[0].statusType.should.equal 2
      done()


  it 'should show OPTIONS for orders', (done) ->
    re$ = RESTit().re$

    re$('http://starbucks.apiary.io')
    .read()
    .follow('/rels/orders')
    .options()
    .callback (err, resp) ->
      return done err  if err
      resp[0].statusType.should.equal 2
      resp[0].canPOST.should.equal true
      should.not.equal resp[0].canDELETE, true # undefined
      done()


  it 'should POST(create) the order and then PATCH(update) the order', (done) ->
    re$ = RESTit().re$

    re$('http://starbucks.apiary.io')
    .read()
    .follow('/rels/orders')
    .create({representation:{drink:'espresso'}})
    .followLocation()
    .read()
    .callback (err, resp) ->
      return done err  if err
      resp[0].statusType.should.equal 2
      @[0].bookmarkAs 'myOrder'
      changeMyMind()

    changeMyMind = () ->
      re$('myOrder')
      .update({representation:{ammend_drink:'with cream'}})
      .callback (err, resp) ->
        return done err  if err
        return done()
        resp[0].representation.get('.drink').should.equal 'espresso con panna'
        resp[0].statusType.should.equal 2
        done()

    ###

    smuggleOrder = () ->
      re$('myOrder')
      .go('smuggle', {representation:{drink:'latte'}})
      .callback (err, resp) ->
        return done err  if err
        resp[0].representation.get('.drink').should.equal 'latte'
        resp[0].statusType.should.equal 2
        done()

    ###

  it 'should GET the order', (done) ->
    re$ = RESTit().re$

    re$('http://starbucks.apiary.io')
    .read()
    .follow('/rels/orders')
    .read()
    .follow({rel:'item',index:1})
    .read()
    .callback (err, resp) ->
      return done err  if err
      resp[0].statusType.should.equal 2
      done()
