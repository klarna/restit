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
  'otw/like/JSON/pointer'
  './_'
], (
  JSONpointer
  _
) ->
  "use strict"

  class Repr
    self = @
    sup = self.__super__
    data: undefined
    patch: undefined

    ####

    constructor: (data = {}, patch = false) ->
      return new Repr(data)  unless @ instanceof Repr
      @data = data
      @patch = new Repr()  if patch

    ####

    get: (pointer) ->
      JSONpointer.get @data, pointer


    has: (pointer) ->
      JSONpointer.has @data, pointer


    set: (pointer, value) ->
      return @patch.set pointer, value  if @patch
      JSONpointer.set @data, pointer, value, true


    applyPatch: () ->
      return  unless @patch
      _.merge @data, @patch.data
      @patch.data = {}


    remove: (pointer) ->
      JSONpointer.remove @data, pointer


    toString: () ->
      patchString = ''
      patchString = '\n----' + @patch.toString()  if @patch
      JSON.stringify(@data) + patchString
