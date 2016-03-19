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
    get: -> @_cwd || @fs.path.resolve '.'
    set: (value)->
      @_cwd = value
      @updatePath()
      return
  base:
    type: 'String'
    get: ->
      if @_base
        #TODO: should I use a _orgBase to speedup this?
        result = @fs.path.resolve @cwd, @_base
      else
        result = @cwd
      result
    set: (value)->
      @_base = value
      @updatePath()
  path:
    type: 'String'
    get: ->@_path
    set: (value)->
      if isObject(value) and isString(value.path)
        value = value.path
      if isString(value)
        @updatePath value
      return
  name:
    type: 'String'
  _cwd:
    type: 'String'
    assigned: false
    exported: false
  _base:
    type: 'String'
    assigned: false
    exported: false
  _orgPath:
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
      path = @fs.path
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
        @fs.path.dirname @path
  basename:
    assigned: false
    exported: false
    get: -> @fs.path.basename @path
  extname:
    assigned: false
    exported: false
    get: -> @fs.path.extname @path
