RESTit is a prototype and is not under active development.

---

# RESTit

*REST Interface Tool* is a tool for interacting with [pure REST APIs](http://bitworking.org/news/Hi_REST__Lo_REST_and_Everything_in_between_REST) designed by RESTpi.


# Philosophy

> Science is what you know, philosophy is what you don’t know. *Bertrand Russell*


# Principles

* Runtime requirement: 1 (and only 1) URI
* Optionally configurable
  * associate method, content-type, accept into operations
  * associate operations into resources
  * associate relations with resources
* Bookmarking
  * create, get, remove
  * import, export
* Easy access to resources
  * by URI (optionally type)
  * by bookmark
  * by relationships
* Uniform interaction (with configurable operations):
  * generic: options, head
  * list resource: create, list
  * item resource: read, update, replace, remove
  * other configurable operations
* Simplify relations by fixed prefix
* Simplify media-types by fixed prefix and syntax
* Simplify statusCodes
* Tabbed-like interaction (perform multiple requests inline)
* Fluent Interface (or language's most natural interface)


# Usage

> Example, whether it be good or bad, has a powerful influence. *George Washington*

Have a look at [the API test of starbucks.apiary.io](test/20121115.coffee), or below

```coffeescript
# simple setup
RESTit = require 'restit'
re$ = (new RESTit()).re$

# setup
myConfig =
  mediaTypePrefix: 'application/vnd.examples.'
  mediaTypeSyntax: 'json'
  resourceNames:
    car:
      acceptedMediaTypes: [
        'car'
        'car-race'
      ]
      providedMediaTypes: ['car']
      patchMediaTypes: ['car-patch']
      operations:
        read:
          providedMediaTypes: ['car']
        race:
          acceptMediaTypes: ['car-race']
          providedMediaTypes: ['car']
    person:
      providedMediaTypes: ['person']
      operations: {
        read:
          providedMediaTypes: ['person']
    root:
      providedMediaTypes: ['root']
      operations:
        read:
          providedMediaTypes: ['root']
  relRoot: 'https://example.com/rels'
  rel2resourceType:
    'https://example.com/rels/car': 'car'
    'https://example.com/rels/owner': 'person'
re$ = (new RESTit(myConfig)).re$


# fun
re$('root', 'https://example.com').read().callback (err, resp) ->
  throw err  if err
  console.log resp[prop]  for prop in [
    'status'
    'headers'
    'body'
  ]
```


# License

[Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0)
