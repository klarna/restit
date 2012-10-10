{_, should, nock} = require './utils'

describe 'ResHTTP', () ->
  request = require 'request'
  ResHTTP = require '../src/ResHTTP'
  AcceptHeader = require 'otw/like/HTTP/AcceptHeader'
  ContentTypeHeader = require 'otw/like/HTTP/ContentTypeHeader'
  LinkHeader = require 'otw/like/HTTP/LinkHeader'
  example =
    URI: 'http://example.com/'
    body: {test:true}
    body2: {test:true,parsed:true}

  it 'should perform a basic HTTP request correctly', (done) ->
    nock(example.URI).post('/', example.body).reply 200, example.body, {
      'Content-Type': 'application/json; charset=utf-8'
      'Link': '<http://example.com/>;rel=self'
    }

    r = new ResHTTP
      URI: example.URI
      requestLib: (options, callback) ->
        options.headers.accept.should.equal 'application/json;charset=utf-8'
        options.headers['content-type'].should.equal 'application/json'
        request.call request, options, callback

    r.request {
      method: 'POST'
      body: JSON.stringify example.body
      headers:
        'accept': new AcceptHeader 'application/json; charset=utf-8'
        'content-type': new ContentTypeHeader 'application/json'
    }, (err, resp) ->
      resp.headers['content-type'].should.be.an.instanceOf ContentTypeHeader
      resp.headers['content-type'].tokens.should.eql [{mediaType:'application/json',type:'application',subtype:'json',syntax:'json',charset:'utf-8'}]

      resp.headers['link'].should.be.an.instanceOf LinkHeader
      resp.headers['link'].tokens.should.eql [{href:example.URI,rel:'self'}]

      resp.body.should.equal JSON.stringify example.body
      should.not.exist resp.representation
      done()


  it 'should call response body parsers', (done) ->
    nock(example.URI).post('/', example.body2).reply 204

    r = new ResHTTP
      URI: example.URI
      RESTit:
        syntaxParsers:
          json: (body) -> _.JSON.parse body
        semanticParsers:
          'application/json': (body) -> 'test'
        syntaxRenderers:
          json: (representation) -> _.JSON.stringify representation
        semanticRenderers:
          'application/json': (representation) -> example.body2
      requestLib: (options, callback) ->
        options.body.should.equal JSON.stringify example.body2
        options.representation.should.eql example.body2
        request.call request, options, callback

    r.request {
      method: 'POST'
      representation: example.body
      headers:
        'content-type': 'application/json'
    }, (err, resp) ->
      resp.statusCode.should.equal 204
      done()


  it 'should switch to safe methods (POST tunneling)', (done) ->
    nock(example.URI).post('/').reply 204

    r = new ResHTTP
      URI: example.URI
      requestLib: (options, callback) ->
        options.method.should.equal 'POST'
        options.headers['x-http-method-override'].should.equal 'PATCH'
        request.call request, options, callback
      safeMethods: true

    r.request {
      method: 'PATCH'
    }, (err, resp) ->
      resp.statusCode.should.equal 204
      done()
