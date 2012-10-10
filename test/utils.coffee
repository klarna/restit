chai = require 'chai'
chai.Assertion.includeStack = true

exports.should = chai.should()
exports.nock = require 'nock'
exports._ = require '../src/_'

console.jog = (arg) ->
  console.log JSON.stringify arg
