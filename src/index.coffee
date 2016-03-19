propertyManager = require 'property-manager/ability'
path            = require('path.js/lib/path').path
isObject        = require 'util-ex/lib/is/type/object'
isFunction      = require 'util-ex/lib/is/type/function'
isBoolean       = require 'util-ex/lib/is/type/boolean'
isArray         = require 'util-ex/lib/is/type/array'
isBuffer        = require 'util-ex/lib/is/type/buffer'
isString        = require 'util-ex/lib/is/type/string'
cloneObject     = require 'util-ex/lib/clone-object'
defineProperty  = require 'util-ex/lib/defineProperty'
stream          = require 'stream'
attributes      = require './attributes'
Stream          = stream.Stream
PassThrough     = stream.PassThrough
streamify       = require './streamifier'
setImmediate    = setImmediate || process.nextTick

isStream        = (aStream)->aStream instanceof Stream

module.exports = class AbstractFile
  gfs = null

  propertyManager AbstractFile, name:'advance', nonExported1stChar:'_'

  AbstractFile.defineProperties AbstractFile, attributes

  setFS = (value)->
    gfs = value
    if value
      path.cwd = value.cwd if isFunction value.cwd
      gfs.path = value.path || path
    return

  defineProperty @, 'fs', undefined,
    get: -> gfs
    set: setFS

  defineProperty @::, 'fs', undefined,
    get: -> gfs
    set: setFS

  constructor: (aPath, aOptions, done)->
    if isObject aPath
      aOptions = aPath
      aPath = undefined
    aOptions?={}
    aOptions.path = aPath if aPath
    @initialize aOptions
    if aOptions.load
      throw new TypeError('path must be exist') unless @path?
      if isFunction(done)
        @load(aOptions, done)
      else
        @loadSync(aOptions)
  orgIsSame = @::isSame
  isSame: (obj)->orgIsSame.call @, obj, ['contents', 'history']
  isStream: -> isStream @contents
  isBuffer: -> isBuffer @contents
  isText: -> !!@encoding
  isDirectory: ->
    if @hasOwnProperty('stat') and @stat and isFunction(@stat.isDirectory)
      result = @stat.isDirectory()
    result
  replaceExt: (aExtName)->path.replaceExt @path, aExtName
  toString: -> @path
  _inspect: -> '"'+@relative+'"'
  inspect: -> '<'+ @constructor.name + ' ' + @_inspect() + '>'
  getOptions: (aOptions)->
    result = @mergeTo(aOptions, ['contents','history'])
    result.cwd = @cwd
    result.base = @base
    result.path = @path
    result
  updatePath: (value)->
    if isString(value) and value isnt @_orgPath
      @_orgPath = value
    if @_orgPath
      cwd = @cwd
      cwd = path.resolve '.' unless cwd
      @_path = value = gfs.path.resolve cwd, @base, @_orgPath
      len = @history.length
      @history.push value if !len or value isnt @history[len-1]


  loaded: (aOptions)->
    aOptions ?= @
    @hasOwnProperty('_contents') and @_contents? and @validate(aOptions, false)

  load: (aOptions, done)->
    if isFunction aOptions
      done = aOptions
      aOptions = null
    aOptions = @getOptions(aOptions)
    checkValid = aOptions.validate isnt false
    loaded = @loaded(aOptions)
    unless @stat?
      @_loadStat aOptions, (err, stat)=>
        @stat = stat
        if !err and checkValid
          try @validate() catch err
        return done.call(@, err) if err
        if aOptions.read and stat? and !loaded
          @_loadContent aOptions, (err, result)=>
            unless err
              if aOptions.encoding or aOptions.text
                vEncoding = aOptions.encoding
                vEncoding ?= 'utf8'
                @encoding = vEncoding
              else
                @encoding = undefined
              @_contents = result
              @skipSize = aOptions.skipSize if @skipSize isnt aOptions.skipSize
            done.call @, err, result
        else
          done.call @, null, @contents
        return
    else if aOptions.read and !loaded
      if checkValid
        try @validate() catch err
      if err
        done(err)
      else
        @loadContent(aOptions, done)
    else
      done(null, @contents)
    @
  loadSync: (aOptions)->
    if isFunction(@_loadStatSync)
      aOptions = @getOptions(aOptions)
      checkValid = aOptions.validate isnt false
      @stat = @_loadStatSync(aOptions) unless @stat?
      @validate() if checkValid
      if aOptions.read and @stat? and !@loaded(aOptions)
        if isFunction(@_loadContentSync)
          @skipSize = aOptions.skipSize if @skipSize isnt aOptions.skipSize
          if aOptions.encoding or aOptions.text
            vEncoding = aOptions.encoding
            vEncoding ?= 'utf8'
            @encoding = vEncoding
          else
            @encoding = undefined
          @_contents = @_loadContentSync(aOptions)
        else
          ### !pragma coverage-skip-next ###
          throw new TypeError '_loadContentSync not implemented'
      else
        @contents
    else
      ### !pragma coverage-skip-next ###
      throw new TypeError '_loadStatSync not implemented'

  _loadStat: (aOptions, done)->
    if @_loadStatSync
      setImmediate =>
        try
          stat = @_loadStatSync(aOptions)
          done(null, stat)
        catch e
          done(e)
        return
    else
      ### !pragma coverage-skip-next ###
      done(new TypeError '_loadStat Async not implemented')
    @

  _loadContent: (aOptions, done)->
    if @_loadContentSync
      setImmediate =>
        try
          result = @_loadContentSync(aOptions)
          done(null, result)
        catch e
          done(e)
        return
    else
      ### !pragma coverage-skip-next ###
      done(new TypeError '_loadContent Async not implemented')
    @

  loadStat: (aOptions, done)->
    if isFunction aOptions
      done = aOptions
      aOptions = null
    aOptions = @getOptions(aOptions)
    @_loadStat aOptions, (err, stat)=>
      @stat = stat unless err or aOptions.overwrite is false
      done(err, stat)
    @
  loadStatSync: (aOptions)->
    aOptions = @getOptions(aOptions)
    if @_loadStatSync
      result = @_loadStatSync aOptions
      @stat = result if aOptions.overwrite isnt false
    else
      ### !pragma coverage-skip-next ###
      throw new TypeError '_loadStatSync not implemented'
    result

  loadContent: (aOptions, done)->
    if isFunction aOptions
      done = aOptions
      aOptions = null
    aOptions = @getOptions(aOptions)
    aOptions.read = true
    if !aOptions.reload and @loaded(aOptions)
      result = @_contents
      if aOptions.overwrite isnt false
        @skipSize = aOptions.skipSize if @skipSize isnt aOptions.skipSize
      done(null, result)
    else
      @_loadContent aOptions, (err, result)=>
        unless err or aOptions.overwrite is false
          if aOptions.encoding or aOptions.text
            vEncoding = aOptions.encoding
            vEncoding ?= 'utf8'
            @encoding = vEncoding
          else
            @encoding = undefined
          @_contents = result
          @skipSize = aOptions.skipSize if @skipSize isnt aOptions.skipSize
        done(err, result)
        return
    @

  loadContentSync: (aOptions)->
    if isFunction(@_loadContentSync)
      aOptions = @getOptions aOptions
      aOptions.read = true
      if !aOptions.reload and @loaded(aOptions)
        result = @contents
      else
        result = @_loadContentSync aOptions
      if aOptions.overwrite isnt false
        if aOptions.encoding or aOptions.text
          vEncoding = aOptions.encoding
          vEncoding ?= 'utf8'
          @encoding = vEncoding
        else
          @encoding = undefined
        @skipSize = aOptions.skipSize if @skipSize isnt aOptions.skipSize
        @_contents = result
    else
      ### !pragma coverage-skip-next ###
      throw new TypeError 'loadContentSync not implemented'
    result

  _validate: (aOptions)-> aOptions.hasOwnProperty('stat') and aOptions.stat?
  validate: (aOptions, raiseError)->
    if isBoolean aOptions
      raiseError = aOptions
      aOptions = null
    raiseError ?= true
    aOptions = @getOptions(aOptions)
    result = @_validate aOptions
    if aOptions.read and result and @contents
      result = @isStream() == !(aOptions.buffer isnt false)
    if raiseError and not result
      throw new TypeError @name+': invalid path '+aOptions.path
    result
  isValid: (aOptions)->
    @validate(aOptions, false)

  getContentSync: (aOptions)->
    aOptions = {} unless isObject aOptions
    aOptions.buffer = true
    aOptions.overwrite = false unless aOptions.overwrite?
    if aOptions.skipSize?
      vSkipSize = aOptions.skipSize
      aOptions.skipSize = undefined
    result = @loadContentSync(aOptions)
    if result
      if aOptions.text and !isString result
        vEncoding = aOptions.encoding if aOptions.encoding
        result = result.toString(vEncoding)
      vSkipSize ?= aOptions.skipSize
      if vSkipSize > 0 and isFunction result.slice
        result = result.slice(vSkipSize)
    result

  getContent: (aOptions, done)->
    if isFunction aOptions
      done = aOptions
    aOptions = {} unless isObject aOptions
    aOptions.buffer = true
    aOptions.overwrite = false unless aOptions.overwrite?
    if aOptions.skipSize?
      vSkipSize = aOptions.skipSize
      aOptions.skipSize = undefined
    @loadContent aOptions, (err, result)->
      if result
        if aOptions.text and !isString result
          vEncoding = aOptions.encoding if aOptions.encoding
          result = result.toString(vEncoding)
        vSkipSize ?= aOptions.skipSize
        if vSkipSize > 0 and isFunction result.slice
          result = result.slice(vSkipSize)
      done(err, result)

  pipe: (aStream, options)->
    options ?= {}
    options.end ?= true
    if @hasOwnProperty('contents')
      if @isStream()
        @contents.pipe(aStream, options)
      else if @isBuffer() or @isText()
        if options.end
          aStream.end(@contents)
        else
          aStream.write(@contents)
      else if isArray @contents
        streamify(@contents).pipe(aStream, options)
      else if options.end # isNull
        aStream.end()
    else if options.end # isUndefined
      aStream.end()
    return aStream

  setContents: (value)->@_contents = value