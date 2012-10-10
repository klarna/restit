{_, should, nock} = require './utils'

describe 'Repr', () ->
  request = require 'request'
  Repr = require '../src/Repr'
  example =
    test: true
    sub:
      test: true
    arr: [
      1
      2
      3
    ]


  it 'should get', () ->
    r = new Repr()
    r.get('/').should.eql {}
    r.get('').should.eql {}
    r.get().should.eql {}

    r = new Repr(example)
    r.get('/test').should.equal true
    r.get('/sub/test').should.equal true
    r.get('/arr/1').should.equal 2

    r = new Repr(example)
    r.get('.test').should.equal true
    r.get('.sub.test').should.equal true
    r.get('.arr[1]').should.equal 2

  it 'should set', () ->
    r = new Repr(example)
    r.set('/sub/test', false)
    r.get('/sub/test').should.equal false

    r = new Repr(example)
    r.set('.sub.test', false)
    r.get('.sub.test').should.equal false


  it 'should set(create) with JSON reference', () ->
      r = new Repr(example)
      r.set('.sub.sub.test', false, true)
      r.get('.sub.sub.test').should.equal false


  it 'should patch', () ->
      r = new Repr(example, true)
      r.set('.sub.sub.test', false, true)
      r.patch.get('.sub.sub.test').should.equal false
