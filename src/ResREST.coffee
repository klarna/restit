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
  'otw/like/HTTP/getLinksFromHeaders'
  'otw/like/JSON/getLinksFromJSON'
  'otw/like/NodeJS/url'
  './_'
  './ResHTTP'
], (
  getLinksFromHeaders
  getLinksFromJSON
  Url
  _
  ResHTTP
) ->
  "use strict"

  class ResREST extends ResHTTP
    self = @
    sup = self.__super__
    config: undefined
    links: undefined

    ####

    constructor: (config) ->
      return new ResREST(config)  unless @ instanceof ResREST

      # Shortcuts
      _.configOption.call @, configOption  for configOption in [
        'type'
      ]

      defaultConfig =
        type: '_generic'
      config = _.merge defaultConfig, config
      super config
      @links = []

    ####

    _findLinksInRepresentation: (representation) ->
      result = []
      return result  unless representation
      for linkParser in @RESTit.config.linkParsers
        if _.type(linkParser) is 'function'
          links = linkParser representation
        else
          links = getLinksFromJSON representation.data, linkParser
        links or= []
        result = result.concat links
      result


    _addResponseLinks: (resp) ->
      links = []
      if resp.headers?['link']
        links = getLinksFromHeaders resp.headers['link']
      if resp.representation
        links = links.concat @_findLinksInRepresentation resp.representation
      links = _.uniq links, false, (link) -> JSON.stringify link

      # Resolve relative links
      # FIXME request has a !isUrl test
      link.href = Url.resolve resp.request.uri.href, link.href  for link in links

      resp.links = links


    _onPreCallback: (err, resp) ->
      super
      @_addResponseLinks resp  if resp
      @links = resp.links  unless err or not resp?.links

    ####

    _maybeRel: (linkParams) ->
      return linkParams  unless _.type(linkParams) is 'string'
      rel = linkParams
      {
        rel: @RESTit.maybeExtensionRel rel
      }


    getLinks: (linkParams) ->
      linkParams = @_maybeRel linkParams
      links = []
      for link in @links
        skip = false
        for paramName, paramValue of linkParams
          unless link[paramName] and link[paramName] is paramValue
            skip = true
            break
        links.push link  unless skip
      links


    getresourceNamesByRel: (rels) ->
      resourceNames = @RESTit.getresourceNamesByRel rels
      rels = rels.split ' '
      for rel in rels
        rel = @config.outboundRels[rel]
        continue  unless rel
        resourceNames.concat @RESTit.getresourceNamesByRel rel
      resourceNames = _.uniq resourceNames
      resourceNames


    getLinkedResources: (linkParams) ->
      links = @getLinks linkParams
      resources = []
      for link in links
        types = @getresourceNamesByRel link.rel
        # FIXME should probably throw when types.length > 1
        resources.push @RESTit.getResource link.href, types[0]
      resources


    follow: (linkParams) ->
      linkParams = @_maybeRel linkParams
      resources = []
      links = @getLinks linkParams
      # throw Error("Unknown link that matches: #{linkParams}")  unless links.length
      for link in links
        resourceName = @getresourceNamesByRel link.rel
        continue  unless resourceName
        resources.push @RESTit.re$ link.href, resourceName
      resources
