# ENV
module.exports = _ = require 'otw/like/lodash'
module.exports.JSON = JSON = require 'json3'

# FUNS
module.exports.renderJSON = (obj) ->
  JSON.stringify obj, null, 4


module.exports.uniqObjects = (arr) ->
  _.map(_.uniq(_.collect(arr, (x) ->
    JSON.stringify(x)
  )), (x) ->
    JSON.parse(x)
  )


module.exports.yyyymmddhhmmss = () ->
  padding = (value) ->
    if value.length > 1 then value else '0' + value[0]
  d = new Date()
  yyyy = d.getFullYear().toString()
  mm = (d.getMonth()+1).toString() # getMonth() is zero-based
  dd = d.getDate().toString()
  hh = d.getHours().toString()
  mi = d.getMinutes().toString()
  ss = d.getSeconds().toString()
  yyyy + padding(mm) + padding(dd) + '-' + padding(hh) + padding(mi) + padding(ss)


module.exports.regexEscape = (text) ->
  text.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\,\\\^\$\|\#\s]/g, '\\$&'

module.exports._ = _
