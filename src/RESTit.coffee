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
  'otw/like/NodeJS/url'
  'request'
  './_'
  './ResREST'
  './FluentREST'
  './Repr'
], (
  Url
  request
  _
  ResREST
  FluentREST
  Repr
) ->
  "use strict"

  class RESTit
    self = @
    _resources: undefined
    config: undefined

    ####

    constructor: (config = {}) ->
      return new RESTit(config)  unless @ instanceof RESTit

      # Shortcuts
      _.configOption.call @, configOption  for configOption in [
        'resourceNames'
        'mediaTypePrefix'
        'mediaTypeSyntax'
        'relRoot'
        'rel2resourceName'
        'errorMediaTypes'
        'bookmarks'
        'syntaxParsers'
        'semanticParsers'
        'syntaxRenderers'
        'semanticRenderers'
        'linkParser'
        'requestLib'
        'requestOptions'
        'ResREST'
        'FluentREST'
        'Repr'
      ]

      defaultMediaType = config.defaultMediaType or 'application/json'
      defaultConfig =
        # blueprint
        resourceNames:
          _generic:
            operations: [{
              name: 'options'
              method: 'OPTIONS'
            }, {
              name: 'head'
              method: 'HEAD'
              providedMediaTypes: [defaultMediaType]
            }, {
              name: 'send'
              method: 'POST'
              acceptedMediaTypes: [defaultMediaType]
              providedMediaTypes: [defaultMediaType]
            }, {
              name: 'list'
              method: 'GET'
              providedMediaTypes: [defaultMediaType]
            }, {
              name: 'read'
              method: 'GET'
              providedMediaTypes: [defaultMediaType]
            }, {
              name: 'update'
              method: 'PATCH'
              patchMediaTypes: [defaultMediaType]
              providedMediaTypes: [defaultMediaType]
            }, {
              name: 'replace'
              method: 'PUT'
              acceptedMediaTypes: [defaultMediaType]
              providedMediaTypes: [defaultMediaType]
            }, {
              name: 'remove'
              method: 'DELETE'
            }]
        relRoot: ''
        mediaTypePrefix: ''
        mediaTypeSyntax: ''
        rel2resourceName: {}
        errorMediaTypes: {}
        bookmarks: {}
        syntaxParsers:
          json: (body) ->
            _.JSON.parse body
        semanticParsers: {}
        syntaxRenderers:
          json: (representation) ->
            _.JSON.stringify representation
        semanticRenderers: {}
        linkParsers: [
          'default'
        ]
        requestLib: undefined
        requestOptions:
          method: undefined
          uri: undefined
          qs: undefined
          headers: []
          body: undefined
          followRedirect: false
          followAllRedirects: false
          maxRedirects: 0
          strictSSL: true
          timeout: 10000
        ResREST: undefined
        FluentREST: undefined
        Repr: undefined

      @config = _.merge defaultConfig, config
      @config.requestLib or= request
      @config.ResREST or= ResREST
      @config.FluentREST or= FluentREST
      @config.Repr or= Repr
      @_resources = {}
      @re$ = @_makeRe$()

    ####

    bookmarkURI: (bookmark, URI, resourceName) ->
      @bookmarks[bookmark] = [URI, resourceName]


    getBookmark: (bookmark) ->
      @bookmarks[bookmark]


    removeBookmark: (bookmark) ->
      delete @bookmarks[bookmark]

    ####

    getResource: (URI, type, orCreate = true) ->
      throw new Error 'A resource needs a URI'  unless URI
      URI = Url.format URI  unless _.type(URI) is 'string'
      # FIXME maybe?
      # TODO the URI should maybe be normalized first (remove fragment for instance)
      resource = @_resources[URI]
      return resource  if resource

      return  unless orCreate

      type ?= '_generic'
      resource = new @ResREST {
        type: type
        config: @resourceNames[type] or {}
        URI: URI
        RESTit: @
      }
      @cacheResource resource
      resource


    cacheResource: (resource) ->
      URI = resource.URI
      URI = Url.format URI  unless _.type(URI) is 'string'
      # FIXME maybe?
      # TODO the URI should maybe be normalized first (remove fragment for instance)
      @_resources[URI] = resource
      resource


    maybeExtensionRel: (rel) ->
      return rel  unless @relRoot
      return rel  if @rel2resourceName?[rel] or rel.indexOf(@relRoot) is 0
      extensionRel = @relRoot + '/' + rel
      return extensionRel  if @rel2resourceName?[extensionRel]
      rel


    getresourceNamesByRel: (rels) ->
      resourceNames = []
      return resourceNames  unless @rel2resourceName

      rels = rels.split ' '
      for rel in rels
        rel = @maybeExtensionRel rel
        resourceName = @rel2resourceName[rel]
        continue  unless resourceName
        resourceNames.push resourceName
      resourceNames = _.uniq resourceNames
      resourceNames

    ####

    _getResourceFromSelector: (selector) ->
      [resOrBookmarkOrURI, resourceName] = selector

      # ResREST
      return resOrBookmarkOrURI  if resOrBookmarkOrURI instanceof @ResREST

      # Bookmark
      bookmark = @getBookmark resOrBookmarkOrURI
      return @getResource bookmark[0], bookmark[1]  if bookmark

      # URI, type
      return @getResource resOrBookmarkOrURI, resourceName


    _makeRe$: () ->
      # FIXME?
      # NB. Must return a bound function,
      # otherwise doing re$ = (new RESTit()).re$ will be unbound and fail
      (selector...) =>
        resource = @_getResourceFromSelector selector
        fluent = new @FluentREST {}, @
        if resource
          fluent = fluent.pushStack [resource]
        fluent


    re$: undefined

    ####

    getOperation: (resourceName, name) ->
      resource = @resourceNames[resourceName]  if resourceName
      unless resourceName is '_generic'
        genericOperation = @getOperation '_generic', name
        return genericOperation  unless resource

      switch _.type(name)
        when 'string'
          # refineOrderPrepurchase-v1
          [name, version] = name.split '-'
          name = name.replace /([a-z])([A-Z])/, '$1-$2'
          [name, subname] = name.split '-'
        when 'array'
          [name, subname, version] = name

      version = "v#{version}"  if _.type(version) is 'number'
      operations = []
      # Match on name and subname, maybe version
      for operation in (resource.operations or [])
        continue  unless operation.name is name
        continue  unless not subname or operation.subname is subname
        operations.push operation
        break  if version? and operation.version is version
      _.sortBy operations, (operation) -> operation.version
      operation = _.last operations
      # Return latest version
      if operation
        operation.method ?= genericOperation.method
        return operation
      # Return generic version
      return genericOperation  if resourceName isnt '_generic'
      # Return abstract version
      {
        name: name
        subname: subname
        version: version
        method: 'POST' # FIXME GET?
        providedMediaTypes: ['*/*']
      }
