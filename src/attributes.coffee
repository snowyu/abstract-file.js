path            = require('path.js/lib/path').path
isObject        = require 'util-ex/lib/is/type/object'
isArray         = require 'util-ex/lib/is/type/array'
isString        = require 'util-ex/lib/is/type/string'
isBuffer        = require 'util-ex/lib/is/type/buffer'
cloneObject     = require 'util-ex/lib/clone-object'
stream          = require 'stream'
Stream          = stream.Stream
PassThrough     = stream.PassThrough
isStream        = (aStream)->aStream instanceof Stream

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
  _contents:
    assigned: false
  encoding:
    type: 'String'
  contents:
    assign: (value, dest, src, name)->
      if isStream value
        src = dest unless src.loadContentSync
        opts =
          buffer: false
          overwrite:false
          highWaterMark: value._readableState.highWaterMark
        value = src.loadContentSync opts
      value
    set: (value)-> @setContents(value)
    get: ->
      result = @_contents if @hasOwnProperty '_contents'
      if result and @encoding and isBuffer result
        result = result.toString(@encoding)
      result
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
    get: ->
      if @isDirectory()
        @path
      else
        path.dirname @path
  basename:
    assigned: false
    exported: false
    get: -> path.basename @path
  extname:
    assigned: false
    exported: false
    get: -> path.extname @path
