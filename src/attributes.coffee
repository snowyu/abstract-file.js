path            = require('path.js/lib/path').path
isObject        = require 'util-ex/lib/is/type/object'
isArray         = require 'util-ex/lib/is/type/array'
isString        = require 'util-ex/lib/is/type/string'
isBuffer        = require 'util-ex/lib/is/type/buffer'
cloneObject     = require 'util-ex/lib/clone-object'
stream          = require 'stream'
Stream          = stream.Stream
PassThrough     = stream.PassThrough

PATH_SEP        = path.sep

module.exports =
  cwd:
    value: ''
    type: 'String'
  base:
    type: 'String'
    get: ->@_base || @cwd
    set: (value)->@_base = path.resolve @cwd, value
  path:
    type: 'String'
    get: ->@_path
    set: (value)->
      if isObject(value) and isString(value.path)
        value = value.path
      if isString(value)
        @cwd = path.resolve '.' unless @cwd
        @_path = value = path.resolve @cwd, @base, value
        len = @history.length
        @history.push value if !len or value isnt @history[len-1]
  name:
    type: 'String'
  _base:
    type: 'String'
    assigned: false
    exported: false
  _path:
    type: 'String'
    assigned: false
    exported: false
  history:
    value: []
    type: 'Array'
    exported: false
    assign: (value)-> if isArray(value) then value.slice() else []
  stat: null
  contents:
    assign: (value, dest, src, name)->
      if value instanceof Stream
        t = value.pipe(new PassThrough())
        src.contents = value.pipe(new PassThrough())
        value = t
      value
  # the skipped length from beginning of contents.
  # this could get the contents quickly later.
  skipSize:
    type: 'Number'
  relative:
    assigned: false
    exported: false
    get: ->
      if @base isnt @path
        path.relative @base, @path
      else
        '.'
  dirname:
    assigned: false
    exported: false
    get: -> path.dirname @path
  basename:
    assigned: false
    exported: false
    get: -> path.basename @path
