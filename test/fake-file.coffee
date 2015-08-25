sinon           = require 'sinon'
inherits        = require 'inherits-ex/lib/inherits'
Stream          = require('stream').Readable
streamifier     = require '../src/streamifier'
AbstractFile    = require '../src/'

module.exports = class FakeFile
  inherits FakeFile, AbstractFile

  constructor: -> super
  @reset: ->
    FakeFile::_loadContent.reset()
    FakeFile::_loadContentSync.reset()
    FakeFile::_loadStat.reset()
    FakeFile::_loadStatSync.reset()
    FakeFile::_validate.reset()
  # _loadContent: sinon.spy (aOptions, done)->
  #   if aOptions.buffer
  #     result = new Buffer(aOptions.path)
  #   else
  #     result = new Stream
  #   done(aOptions.error, result)
  _loadContentSync: sinon.spy (aOptions)->
    if aOptions.buffer isnt false
      if aOptions.dir
        [1,2]
      else
        new Buffer(aOptions.path)
    else
      streamifier(aOptions.path, aOptions)

  # _loadStat: sinon.spy (aFile, done)->
  #   result =
  #     path: aFile.path
  #     dir: !!aFile.dir
  #     isDirectory: -> @dir
  #   done(aFile.error, result)
  _loadStatSync: sinon.spy (aFile)->
    result =
      path: aFile.path
      dir: !!aFile.dir
      isDirectory: -> @dir
