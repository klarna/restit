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
  'otw/like/Fluent/AsyncFluentInterface'
  './_'
], (
  AsyncFluentInterface
  _
) ->
  class FluentREST extends AsyncFluentInterface
    self = @
    sup = self.__super__
    _chainableActions: [
      'jumpTo'
      'returnTo'
      'getLinks'
      'follow'
      'followLocation'
      'go'
    ]

    ####

    constructor: (context = {}, RESTit) ->
      super context
      throw new Error 'RESTit configuration is missing'  unless RESTit
      @RESTit = RESTit

      @[alias] = _.bind @go, @, alias  for alias in [
        'options'
        'head'
        'create'
        'list'
        'read'
        'update'
        'replace'
        'remove'
      ]


    _sibling: (newInstance) ->
      newInstance ?= new @constructor undefined, @RESTit
      super newInstance
      newInstance.RESTit = @RESTit
      newInstance

    ####

    jumpTo: (URI, name, callback) ->
      {next, err, resp} = callback
      return next err  if err
      resource = @RESTit.getResource URI, name
      return resource  unless @_isAsync()
      return next new Error "Resource #{URI} (#{name}) was not found"  unless resource
      return next null, @pushStack [resource]


    returnTo: (bookmark, callback) ->
      {next, err, resp} = callback
      return next err  if err
      resource = @RESTit.getBookmark bookmark
      return resource  unless @_isAsync()
      return next new Error "Bookmark #{bookmark} was not found"  unless resource
      return next null, @pushStack [resource]

    ####

    _syncGetLinks: (linkParams) ->
      links = []
      for resource in @
        links = links.concat resource.getLinks linkParams
      links


    getLinks: (linkParams, callback) ->
      {next, err, resp} = callback
      return next err  if err
      links = @_syncGetLinks linkParams
      return next null, links


    _syncGetLinkedResources: (linkParams) ->
      links = []
      for resource in @
        links = links.concat resource.getLinkedResources linkParams
      links


    # TODO click?, goTo?
    follow: (linkParams, callback) ->
      {next, err, resp} = callback
      return next err  if err
      resources = @_syncGetLinkedResources linkParams
      return next new Error "No link with #{linkParams} was found"  unless resources.length
      return next null, @pushStack resources


    followLocation: (callback) ->
      {next, err, resp} = callback
      return next err  if err
      resources = []
      for r, index in resp
        return next new Error "No Location header was found"  unless r.headers?.location
        types = @[index].getresourceNamesByRel 'item'
        # FIXME should probably throw when types.length > 1
        resources.push @RESTit.getResource r.headers.location, types[0]
      return next null, @pushStack resources

    ####

    go: (operationName, options, callback) ->
      {next, err, resp} = callback
      return next err  if err
      iterator = (next, elem) ->
        elem.go operationName, options, (err, resp, body) ->
          next err, resp
      _.eachAsync @, next, iterator
