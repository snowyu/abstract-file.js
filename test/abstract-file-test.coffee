chai            = require 'chai'
sinon           = require 'sinon'
sinonChai       = require 'sinon-chai'
should          = chai.should()
expect          = chai.expect
assert          = chai.assert
chai.use(sinonChai)

fs              = require 'fs'
fs.cwd          = process.cwd
inherits        = require 'inherits-ex/lib/inherits'
extend          = require 'util-ex/lib/_extend'
File            = require '../src'
#console.log Object.getOwnPropertyDescriptor File, 'fs'
File.fs = fs

setImmediate    = setImmediate || process.nextTick

describe 'AbstractFile', ->
  describe '.constructor', ->
  it 'should create an file object', ->
    result = new File cwd: '/path/dff', path: 'path'
    result.should.have.property 'path', '/path/dff/path'
    result.should.have.ownProperty 'history'
    result.history.should.be.deep.equal ['/path/dff/path']
  it 'should assign the options via the order of defined properties', ->
    result = new File path: 'path', base: 'hhah', cwd: '/path/dff'
    result.should.have.property 'path', '/path/dff/hhah/path'
    result.should.have.ownProperty 'history'
    result.history.should.be.deep.equal ['/path/dff/hhah/path']
