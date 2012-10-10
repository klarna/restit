# Copyright 2013 Klarna AB
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

define = require('amdefine')(module)  if typeof define isnt 'function'

define [
  'http-status-codes-json'
  'otw/like/HTTP/ContentTypeHeader'
  'otw/like/HTTP/AcceptHeader'
  'otw/like/HTTP/LinkHeader'
  'otw/like/NodeJS/url'
  'request'
  './_'
], (
  StatusCodes
  ContentTypeHeader
  AcceptHeader
  LinkHeader
  Url
  request
  _
) ->
  "use strict"

  StatusMessages = _.invert _.map StatusCodes, (value, key) -> value.toLowerCase()

  class ResHTTP
    self = @
    config: undefined

    ####

    constructor: (config) ->
      return new ResHTTP(config)  unless @ instanceof ResHTTP

      # Shortcuts
      _.configOption.call @, configOption  for configOption in [
        'outboundRels'
        'operations'
        'type'
        'URI'
        'RESTit'
        'requestOptions'
        'safeMethods'
      ]

      defaultConfig =
        acceptedMediaTypes: []
        providedMediaTypes: []
        patchMediaTypes: []
        outboundRels: {}
        operations: []
        type: '_generic'
        URI: undefined
        RESTit: undefined
        requestOptions:
          method: undefined
          uri: undefined
          qs: undefined
          headers: []
          body: undefined
          representation: undefined
          followRedirect: undefined
          followAllRedirects: undefined
          maxRedirects: undefined
          strictSSL: undefined
          timeout: undefined
        safeMethods: undefined
      @config = _.merge defaultConfig, config
      @URI = Url.parse @URI  if _.type(@URI) is 'string'

    ####

    _renderAcceptHeader: (options) ->
      return  unless options.headers.accept
      header = options.headers.accept
      unless @RESTit and @RESTit.mediaTypePrefix
        options.headers.accept = header.toString()
        return
      header = new AcceptHeader header
      for token in header.tokens
        unless /[a-z]+\//.test token.mediaType
          token.mediaType = @RESTit.mediaTypePrefix + token.mediaType
          if @RESTit.mediaTypeSyntax
            token.mediaType += '+' + @RESTit.mediaTypeSyntax
      options.headers.accept = header.toString()


    _renderContentTypeHeader: (options) ->
      return  unless options.headers['content-type']
      header = options.headers['content-type']
      unless @RESTit and @RESTit.mediaTypePrefix
        options.headers['content-type'] = header.toString()
        return
      header = new ContentTypeHeader header
      token = header.token
      unless /[a-z]+\//.test token.mediaType
        token.mediaType = @RESTit.mediaTypePrefix + token.mediaType
        if @RESTit.mediaTypeSyntax
          token.mediaType += '+' + @RESTit.mediaTypeSyntax
      options.headers['content-type'] = header.toString()


    _renderBody: (options) ->
      return  unless options.headers?['content-type']
      return  unless _.type(options.body) is 'undefined'
      return  unless _.type(options.representation) isnt 'undefined'

      contentType = options.headers['content-type']
      unless contentType instanceof ContentTypeHeader
        contentType = new ContentTypeHeader contentType

      body = options.representation

      mediaType = contentType.token.mediaType
      if mediaType and @RESTit?.semanticRenderers?[mediaType]
        body = @RESTit.semanticRenderers[mediaType] body
      else if @RESTit?.Repr and body instanceof @RESTit.Repr
        body = body.get()

      syntax = contentType.token.syntax
      if syntax and @RESTit?.syntaxRenderers?[syntax]
        body = @RESTit.syntaxRenderers[syntax] body

      throw new Error('Could not render the representation!')  if _.type(body) isnt 'string'
      options.body = body


    _onPreCallbackParseStatusCode: (resp) ->
      type = resp.statusType = parseInt resp.statusCode / 100

      resp.isInfo = type is 1
      resp.isOK = type is 2
      resp.isRedirect = type is 3
      resp.isClientError = type is 4
      resp.isServerError = type is 5
      resp.isUnknown = type not in [1..5]

      resp.is = (codeOrMessage) =>
        code = StatusMessages[codeOrMessage.toLowerCase()]  if _.type(codeOrMessage) is 'string'
        code or= codeOrMessage
        resp.statusCode is code


    _onPreCallbackParseHeadersAllow: (resp) ->
      return  unless resp.headers?.allow

      allows = resp.headers.allow.toUpperCase()
      allows = allows.split /[, ]+/

      resp["can#{allow}"] = true  for allow in allows

      resp.can = (methodOrOperation) -> methodOrOperation in allows


    _onPreCallbackParseHeadersLocation: (resp) ->
      return  unless resp.headers?.location
      # Resolve relative links
      resp.headers.location = Url.resolve resp.request.uri.href, resp.headers.location


    _onPreCallbackParseHeaders: (resp) ->
      return  unless resp.headers

      if resp.headers?['content-type']
        resp.headers['content-type'] = new ContentTypeHeader resp.headers['content-type']
      if resp.headers?.link
        resp.headers.link = new LinkHeader resp.headers.link

      @_onPreCallbackParseHeadersAllow resp  if resp.request.method is 'OPTIONS'
      @_onPreCallbackParseHeadersLocation resp


    _onPreCallbackParseBody: (resp) ->
      return  unless _.type(resp.body) isnt 'undefined' and resp.headers['content-type']
      contentType = resp.headers['content-type']

      representation = resp.body

      syntax = contentType.token.syntax
      if syntax and @RESTit?.syntaxParsers?[syntax]
        representation = @RESTit.syntaxParsers[syntax] representation
      mediaType = contentType.token.mediaType
      if mediaType and @RESTit?.semanticParsers?[mediaType]
        representation = @RESTit.semanticParsers[mediaType] representation

      return  if representation is resp.body

      representation = new @RESTit.Repr(representation, true)  if @RESTit?.Repr  and _.isPlainObject representation
      resp.representation = representation


    _onPreCallback: (err, resp) ->
      return  unless resp
      @_onPreCallbackParseStatusCode resp
      @_onPreCallbackParseHeaders resp
      @_onPreCallbackParseBody resp


    _onCallback: (callbackFun, options) ->
      (err, resp) =>
        # resp =
        #   request: undefined
        #   client: undefined
        #   statusCode: undefined
        #   statusType: undefined
        #   isInfo: undefined
        #   isOK: undefined
        #   isRedirect: undefined
        #   isClientError: undefined
        #   isServerError: undefined
        #   isUnknown: undefined
        #   is: undefined
        #   headers: undefined
        #   body: undefined
        #   repr: undefined

        # resp.options = options  if response
        @_onPreCallback err, resp

        # FIXME decide what more to do on error
        return callbackFun err, resp  if err

        # FIXME decide what more to do with the body
        callbackFun err, resp


    # Make a HTTP request
    request: (options = {}, callback) ->
      options = _.merge {
        uri: Url.format @URI
        headers:
          accept: @providedMediaTypes
      }, (@RESTit?.requestOptions or {}), @requestOptions, options

      #FIXME merge options.uri.query with options.query ?

      #FIXME break this into parse=fix=expand and normalize=toString
      @_renderBody options
      @_renderAcceptHeader options  if options.headers.accept
      @_renderContentTypeHeader options  if options.headers['content-type']

      # Deal with safeMethods
      safeMethods = ['OPTIONS', 'HEAD', 'GET', 'POST']
      safeMethods = @safeMethods  if _.type(@safeMethods) is 'array'
      if @safeMethods and options.method not in safeMethods
          options.headers['x-http-method-override'] = options.method
          options.method = 'POST'

      request2 = @requestLib or @RESTit?.requestLib or request
      request2 options, @_onCallback callback, options


    go: (operationName, options = {}, callback) ->
      operation = @RESTit.getOperation @type, operationName
      options = _.merge options, {
        method: operation.method
        headers: {}
      }

      if operation.providedMediaTypes
        options.headers.accept = _.last operation.providedMediaTypes

      if options.method is 'PATCH' and operation.patchMediaTypes
        options.headers['content-type'] = _.last operation.patchMediaTypes
      else if operation.acceptedMediaTypes
        options.headers['content-type'] = _.last operation.acceptedMediaTypes

      @request options, callback


    bookmarkAs: (bookmarkName) ->
      return  unless @RESTit
      @RESTit.bookmarkURI bookmarkName, @URI, @type
