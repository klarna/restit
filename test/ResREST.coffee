{_, should, nock} = require './utils'

describe 'ResREST', () ->
  request = require 'request'
  ResREST = require '../src/ResREST'
  example =
    URI: 'http://example.com/'
    body:
      test:true
      links: [
        {rel:'self',href:'http://example.com'},
        {rel:'alternate',href:'https://example.com'}
      ]

  it 'should extract links correctly from the Link header and the payload', (done) ->
    nock(example.URI).get('/').reply 200, example.body, {
      'Link': "<#{example.URI}>;rel=self"
    }

    r = new ResREST
      URI: example.URI
      requestLib: request

    r.request {
      method: 'GET'
    }, (err, resp, body) ->
      r.getLinks().should.eql [{href:example.URI,rel:'self'}]
      done()
