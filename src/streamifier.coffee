isArray   = require 'util-ex/lib/is/type/array'
isBuffer  = require 'util-ex/lib/is/type/buffer'
isString  = require 'util-ex/lib/is/type/string'
inherits  = require 'inherits-ex/lib/inherits'
Readable  = require('readable-stream').Readable

module.exports = class Streamifier
  inherits Streamifier, Readable

  constructor: (object, options) ->
    return new Streamifier(object, options) unless @ instanceof Streamifier

    options ?= {}
    unless isBuffer(object) or isString(object)
      options.objectMode = true
    Readable.call this, options
    object = [object] unless isArray object
    @_i = 0
    @_l = object.length
    @_list = object
    return

  _read: (size) ->
    @push if @_i < @_l then @_list[@_i++] else null
    return
