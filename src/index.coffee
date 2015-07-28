propertyManager = require 'property-manager/ability'
path            = require('path.js/lib/path').path
isObject        = require 'util-ex/lib/is/type/object'
isFunction      = require 'util-ex/lib/is/type/function'
isBoolean       = require 'util-ex/lib/is/type/boolean'
isArray         = require 'util-ex/lib/is/type/array'
isBuffer        = require 'util-ex/lib/is/type/buffer'
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
      gfs.path = path
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
  isDirectory: -> @stat? and isFunction(@stat.isDirectory) and @stat.isDirectory()
  toString: -> @path
  _inspect: -> '"'+@relative+'"'
  inspect: -> '<'+ @constructor.name + ' ' + @_inspect() + '>'
  getOptions: (aOptions)->
    result = @mergeTo(aOptions, ['contents','history'])
    result.path = @path
    result.base = @base
    result.cwd = @cwd
    result

  load: (aOptions, done)->
    if isFunction aOptions
      done = aOptions
      aOptions = null
    aOptions = @getOptions(aOptions)
    checkValid = aOptions.validate isnt false
    loaded = @contents? and @validate(aOptions, false)
    unless @stat?
      @_loadStat aOptions, (err, stat)=>
        @stat = stat
        if !err and checkValid
          try @validate() catch err
        return done.call(@, err) if err
        if aOptions.read and stat? and !loaded
          @_loadContent aOptions, (err, result)=>
            @contents = result unless err
            done.call @, err, result
        else
          done.call @, null, @contents
        return
    else if aOptions.read and !loaded
      if checkValid
        try
          @validate()
        catch e
          done(e)
          return @
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
      if aOptions.read and @stat? and !(@contents? and @validate(aOptions, false))
        if isFunction(@_loadContentSync)
          @contents = @_loadContentSync(aOptions)
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
    @_loadContent aOptions, (err, result)=>
      @contents = result unless err or aOptions.overwrite is false
      done(err, result)
    @

  loadContentSync: (aOptions)->
    if isFunction(@_loadContentSync)
      aOptions = @getOptions aOptions
      result = @_loadContentSync aOptions
      @contents = result if aOptions.overwrite isnt false
    else
      ### !pragma coverage-skip-next ###
      throw new TypeError 'loadContentSync not implemented'
    result

  _validate: (aOptions)->
    aOptions.stat?
  validate: (aOptions, raiseError)->
    if isBoolean aOptions
      raiseError = aOptions
      aOptions = null
    raiseError ?= true
    aOptions = @getOptions(aOptions)
    result = @_validate aOptions
    if aOptions.read and result and @contents
      result = @isStream() and !aOptions.buffer
    if raiseError and not result
      throw new TypeError @name+': invalid path '+aOptions.path
    result
  isValid: (aOptions)->
    @validate(aOptions, false)

  getContentSync: (aOptions)->
    aOptions = {} unless isObject aOptions
    aOptions.buffer = true
    aOptions.overwrite = false
    result = @loadContentSync(aOptions)
    if aOptions.skipSize and isBuffer result
      result = result.slice(aOptions.skipSize)
    result

  getContent: (aOptions, done)->
    if isFunction aOptions
      done = aOptions
    aOptions = {} unless isObject aOptions
    aOptions.buffer = true
    aOptions.overwrite = false
    @loadContent aOptions, (err, result)->
      if aOptions.skipSize and isBuffer result
        result = result.slice(aOptions.skipSize)
      done(err, result)

  pipe: (aStream, options)->
    options ?= {}
    options.end ?= true

    if @isStream()
      return @contents.pipe(aStream, options)

    if @isBuffer()
      if options.end
        aStream.end(@contents)
      else
        aStream.write(@contents)
      return aStream

    if isArray @contents
      return streamify(@contents).pipe(aStream, options)

    # isNull
    if options.end
      aStream.end()

    return aStream
