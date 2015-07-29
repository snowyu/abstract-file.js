chai            = require 'chai'
sinon           = require 'sinon'
sinonChai       = require 'sinon-chai'
should          = chai.should()
expect          = chai.expect
assert          = chai.assert
chai.use(sinonChai)

Stream          = require('stream').Stream
through2        = require 'through2'
fs              = require 'fs'
fs.cwd          = process.cwd
inherits        = require 'inherits-ex/lib/inherits'
extend          = require 'util-ex/lib/_extend'
isString        = require 'util-ex/lib/is/type/string'
File            = require '../src'
FakeFile        = require './fake-file'
isStream        = (aStream)->aStream instanceof Stream
File.fs = fs
path = null
setImmediate    = setImmediate || process.nextTick

describe 'AbstractFile', ->
  it 'should set file-system via AbstractFile.fs', ->
    File.fs.should.be.equal fs
  it 'should set file-system via AbstractFile::fs', ->
    File.fs = null
    should.not.exist File::fs
    File::fs = fs
    File.fs.should.be.equal fs
    File::fs.should.be.equal fs
    path = File.fs.path
  describe '.constructor', ->
    it 'should create an file object', ->
      result = new File cwd: '/path/dff', path: 'path'
      result.should.have.property 'path', '/path/dff/path'
      result.toString().should.be.equal '/path/dff/path'
      result.inspect().should.be.equal '<AbstractFile "path">'
      result.isValid().should.be.false
      result.should.have.ownProperty 'history'
      result.history.should.be.deep.equal ['/path/dff/path']
    it 'should assign the options via the order of defined properties', ->
      result = new File path: 'path', base: 'hhah', cwd: '/path/dff'
      result.should.have.property 'path', '/path/dff/hhah/path'
      result.should.have.ownProperty 'history'
      result.history.should.be.deep.equal ['/path/dff/hhah/path']
    it 'should create a file object', ->
      result = new FakeFile path: path:'readme'
      result.should.have.property 'path', path.join fs.cwd(),'readme'
    it 'should create and load stat', ->
      result = new FakeFile 'path', base: 'hhah', cwd: '/path/dff', load:true
      result.should.have.property 'path', '/path/dff/hhah/path'
      should.exist result.stat
    it 'should create and load contents', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true
      result.should.have.property 'path', '/path/dff/hhah/path'
      should.exist result.stat
      should.exist result.contents
      result.contents.should.be.instanceof Stream
    it 'should create and load stat async', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, (err)->
          should.exist @stat
          done(err)
    it 'should create and load contents async', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true, (err, contents)->
          should.exist contents
          contents.should.be.instanceof Stream
          done(err)
    it 'should create and load contents buffer', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true, buffer:true
      result.should.have.property 'path', '/path/dff/hhah/path'
      should.exist result.stat
      should.exist result.contents
      result.contents.should.be.instanceof Buffer
    it 'should create and load contents buffer async', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true, buffer:true,
        (err, contents)->
          should.exist contents
          contents.should.be.instanceof Buffer
          done(err)
  describe '#relative', ->
    it 'should get relative path', ->
      result = new File path: '/path/dff/xie', base: 'hhah', cwd: '/path/dff'
      result.relative.should.be.equal '../xie'
  describe '#dirname', ->
    it 'should get dirname', ->
      result = new File path: '/path/dff/xie', base: 'hhah', cwd: '/path/dff'
      result.dirname.should.be.equal '/path/dff'
  describe '#basename', ->
    it 'should get basename', ->
      result = new File path: '/path/dff/xie.md', base: 'hhah', cwd: '/path/dff'
      result.basename.should.be.equal 'xie.md'
  describe '#extname', ->
    it 'should get extname', ->
      result = new File path: '/path/dff/xie.md', base: 'hhah', cwd: '/path/dff'
      result.extname.should.be.equal '.md'
  describe '#replaceExt', ->
    it 'should repalce the extname', ->
      result = new File path: '/path/dff/xie.md', base: 'hhah', cwd: '/path/dff'
      result.replaceExt('.coffee').should.be.equal '/path/dff/xie.coffee'
  describe '#load', ->
    it 'should load stat', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff'
      result.load (err, contents)->
        should.not.exist contents
        should.exist result.stat
        result.isDirectory().should.be.false
        done(err)
    it 'should reload content', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true
      result.load read:true, buffer:true, (err, contents)->
        should.exist contents
        contents.should.be.instanceof Buffer
        result.contents.should.be.equal contents
        result.isDirectory().should.be.false
        done(err)
  describe '#loadSync', ->
    it 'should reload content', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true
      should.throw result.validate.bind(result, read:true,buffer:true)
      contents = result.loadSync read:true, buffer:true
      should.exist contents
      contents.should.be.instanceof Buffer
      result.contents.should.be.equal contents
  describe '#loadContent', ->
    it 'should load content', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff'
      result.loadContent (err, contents)->
        should.exist contents
        contents.should.be.instanceof Stream
        done(err)
    it 'should load text content', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff'
      result.loadContent buffer:true, text: true, (err, contents)->
        should.exist contents
        contents.should.be.equal result.path
        done(err)
    it 'should load content after stat', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true
      result.loadContent (err, contents)->
        should.exist contents
        contents.should.be.instanceof Stream
        result.validate(false).should.be.true
        done(err)
    it 'should load content buffer', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff'
      result.loadContent buffer:true, (err, contents)->
        should.exist contents
        contents.should.be.instanceof Buffer
        done(err)
    it 'should load content buffer after stat', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true
      result.loadContent buffer:true, (err, contents)->
        should.exist contents
        contents.should.be.instanceof Buffer
        done(err)
    it 'should reload content', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff'
      result.loadContent (err, contents)->
        should.exist contents
        contents.should.be.instanceof Stream
        result.loadContent buffer:true, (err, contents)->
          should.exist contents
          contents.should.be.instanceof Buffer
          done(err)
  describe '#loadContentSync', ->
    it 'should load content', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff'
      contents = result.loadContentSync()
      should.exist contents
      contents.should.be.instanceof Stream
      result.isBuffer().should.be.false
    it 'should load text content', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff'
      contents = result.loadContentSync buffer:true, text:true
      should.exist contents
      contents.should.be.equal result.path
      result.isBuffer().should.be.false
      result.isText().should.be.true
    it 'should load content after stat', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true
      contents = result.loadContentSync()
      should.exist contents
      contents.should.be.instanceof Stream
    it 'should load content buffer', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff'
      contents = result.loadContentSync buffer:true
      should.exist contents
      contents.should.be.instanceof Buffer
      result.isBuffer().should.be.true
    it 'should load content buffer after stat', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true
      contents = result.loadContentSync(buffer:true)
      should.exist contents
      contents.should.be.instanceof Buffer
    it 'should reload content', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true
      contents = result.loadContentSync()
      should.exist contents
      contents.should.be.instanceof Stream
      contents = result.loadContentSync(buffer:true)
      should.exist contents
      contents.should.be.instanceof Buffer
  describe '#loadStat', ->
    it 'should load stat', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff',
      result.loadStat (err, stat)->
        should.exist stat
        done(err)
    it 'should load stat with empty options', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff',
      result.loadStat {}, (err, stat)->
        should.exist stat
        done(err)
  describe '#loadStatSync', ->
    it 'should load stat', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff',
      stat = result.loadStatSync(dir:true)
      should.exist stat
      result.isDirectory().should.be.true
  describe '#getContent', ->
    it 'should getContent', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff',
      result.getContent (err, contents)->
        should.exist contents
        contents.should.be.instanceof Buffer
        done(err)
    it 'should getContent as text', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff',
      result.getContent text:true, (err, contents)->
        should.exist contents
        contents.should.be.equal result.path
        done(err)
    it 'should getContent with skipSize', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff',
      result.getContent skipSize:1, (err, contents)->
        should.exist contents
        contents.should.be.instanceof Buffer
        s = contents.toString()
        s.should.be.equal result.path.substr(1)
        done(err)
    it 'should getContent after stream', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true
      result.getContent skipSize:1, (err, contents)->
        should.exist contents
        contents.should.be.instanceof Buffer
        s = contents.toString()
        s.should.be.equal result.path.substr(1)
        done(err)
  describe '#getContentSync', ->
    it 'should getContent', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff',
      contents = result.getContentSync()
      should.exist contents
      contents.should.be.instanceof Buffer
    it 'should getContent as text', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff',
      contents = result.getContentSync text:true
      should.exist contents
      contents.should.be.equal result.path
    it 'should getContent as text with skipSize', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff',
      contents = result.getContentSync(skipSize:1, text:true)
      should.exist contents
      contents.should.be.equal result.path.substr(1)
    it 'should getContent with skipSize', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff',
      contents = result.getContentSync(skipSize:1)
      should.exist contents
      contents.should.be.instanceof Buffer
      s = contents.toString()
      s.should.be.equal result.path.substr(1)
    it 'should getContent after stream', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true
      contents = result.getContentSync(skipSize:1)
      should.exist contents
      contents.should.be.instanceof Buffer
      s = contents.toString()
      s.should.be.equal result.path.substr(1)
  describe '#pipe', ->
    it 'should pipe a stream', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true
      all = ''
      stream = through2 (dat, enc, cb)->
        cb(null, dat)
        return
      result.pipe stream
      .on 'end', ->
        all.should.be.equal result.path
        done()
      .on 'error', (err)->
        done(err)
      .on 'data', (data)->
        all += data.toString()

    it 'should pipe a buffer', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true,buffer:true
      all = ''
      stream = through2 (dat, enc, cb)->
        cb(null, dat)
        return
      result.pipe stream
      .on 'end', ->
        all.should.be.equal result.path
        done()
      .on 'error', (err)->
        done(err)
      .on 'data', (data)->
        all += data.toString()
    it 'should pipe a buffer', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true,buffer:true
      all = ''
      stream = through2 (dat, enc, cb)->
        cb(null, dat)
        return
      result.pipe stream
      .on 'end', ->
        all.should.be.equal result.path
        done()
      .on 'error', (err)->
        done(err)
      .on 'data', (data)->
        all += data.toString()

    it 'should pipe a text', (done)->
      result = new FakeFile 'path',
        base: 'hhah',cwd: '/path/dff',load:true,read:true,buffer:true,text:true
      all = ''
      should.exist result.contents
      isString(result.contents).should.be.true
      stream = through2.obj (dat, enc, cb)->
        cb(null, dat)
        return
      result.pipe stream
      .on 'end', ->
        all.should.be.deep.equal result.path
        done()
      .on 'error', (err)->
        done(err)
      .on 'data', (data)->
        all += data
    it 'should pipe an null', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff'
      all = []
      should.not.exist result.contents
      stream = through2 (dat, enc, cb)->
        cb(null, dat)
        return
      result.pipe stream
      .on 'end', ->
        all.should.have.length 0
        done()
      .on 'error', (err)->
        done(err)
      .on 'data', (data)->
        all.push data
  describe '#clone', ->
    it 'should clone file object with stream', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true
      obj = result.clone()
      should.exist obj.contents
      obj.contents.should.be.instanceof Stream
      obj.contents.should.not.equal result.contents
      obj.isSame(result).should.be.true
    it 'should clone dir object with stream', ->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true,dir:true
      obj = result.clone()
      should.exist obj.contents
      obj.contents.should.be.instanceof Stream
      obj.contents.should.not.equal result.contents
      obj.isSame(result).should.be.true
    it 'should pipe clone file object with stream', (done)->
      result = new FakeFile 'path',
        base: 'hhah', cwd: '/path/dff', load:true, read:true, highWaterMark:5
      result.contents._readableState.should.have.property 'highWaterMark', 5
      obj = result.clone()
      data=''
      obj.contents._readableState.should.have.property 'highWaterMark', 5
      obj.contents
      .on 'error', (err)->done(err)
      .on 'data', (dat)->data += dat.toString()
      .on 'end', ->
        data.should.be.equal result.path
        data = ''
        result.contents
        .on 'error', (err)->done(err)
        .on 'data', (dat)->data += dat.toString()
        .on 'end', ->
          data.should.be.equal result.path
          done()
