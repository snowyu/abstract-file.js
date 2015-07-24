inherits  = require 'inherits-ex/lib/inherits'
Readable  = require('readable-stream').Readable
isArray   = Array.isArray

module.exports = class StreamArray
  inherits StreamArray, Readable

  constructor: (list) ->
    return new StreamArray list unless @ instanceof StreamArray
    ### !pragma coverage-skip-next ###
    if !isArray(list)
      throw new TypeError('First argument must be an Array')
    Readable.call this, objectMode: true
    @_i = 0
    @_l = list.length
    @_list = list
    return

  _read: (size) ->
    @push if @_i < @_l then @_list[@_i++] else null
    return
