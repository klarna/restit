{_, should, nock} = require './utils'

describe 'RESTit', () ->
  request = require 'request'
  RESTit = require '../src/RESTit'
  ResREST = require '../src/ResREST'
  ContentTypeHeader = require 'otw/like/HTTP/ContentTypeHeader'
  LinkHeader = require 'otw/like/HTTP/LinkHeader'
  example =
    URI: 'http://example.com/'
    body:
      test:true
      links: [
        {rel:'self',href:'http://example.com/'},
        {rel:'alternate',href:'https://example.com/'}
      ]
    config:
      resourceNames:
        testResource:
          operations: [
            {name: 'read'}
          ]
      rel2resourceName: {}
      errorMediaTypes: {}
      requestLib: request


  it 'should get operations', () ->
    r = new RESTit example.config

    operation = r.getOperation 'testResource', 'read'
    operation.should.eql {
      name: 'read'
      method: 'GET'
    }

  it 'should get resources by types', () ->
  it 'should get resources by URI and type', () ->
  it 'should have a working fluent interface', () ->

  it 'should perform a basic HTTP request correctly', (done) ->
    nock(example.URI).get('/').reply 200, example.body, {
      'Content-Type': 'application/json; charset=utf-8'
      'Link': "<#{example.URI}>;rel=self"
    }
    re$ = RESTit(example.config).re$

    re$(example.URI, 'testResource').read().callback (err, resp) ->
      resp = resp[0]
      resp.headers['content-type'].should.be.an.instanceOf ContentTypeHeader
      resp.headers['content-type'].tokens.should.eql [{mediaType:'application/json',type:'application',subtype:'json',syntax:'json',charset:'utf-8'}]

      resp.headers['link'].should.be.an.instanceOf LinkHeader
      resp.headers['link'].tokens.should.eql [{href:example.URI,rel:'self'}]

      resp.body.should.equal JSON.stringify example.body
      resp.representation.should.be.an 'object'

      @get(0).should.not.equal resp
      @get(0).should.be.an.instanceOf ResREST
      done()
