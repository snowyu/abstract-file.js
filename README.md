## abstract-file [![npm](https://img.shields.io/npm/v/abstract-file.svg)](https://npmjs.org/package/abstract-file)

[![Build Status](https://img.shields.io/travis/snowyu/abstract-file.js/master.svg)](http://travis-ci.org/snowyu/abstract-file.js)
[![Code Climate](https://codeclimate.com/github/snowyu/abstract-file.js/badges/gpa.svg)](https://codeclimate.com/github/snowyu/abstract-file.js)
[![Test Coverage](https://codeclimate.com/github/snowyu/abstract-file.js/badges/coverage.svg)](https://codeclimate.com/github/snowyu/abstract-file.js/coverage)
[![downloads](https://img.shields.io/npm/dm/abstract-file.svg)](https://npmjs.org/package/abstract-file)
[![license](https://img.shields.io/npm/l/abstract-file.svg)](https://npmjs.org/package/abstract-file)

It can be used on any virtual file system, and stream supports. Inspired by [vinyl][vinyl].
Try to keep compatibility with [vinyl][vinyl].

[vinyl]:https://github.com/wearefractal/vinyl

+ abstract file information class
+ abstract file operation ability
  + abstract load supports
    * load read:true, buffer:true
    * load stat
    * load content

## Usage

the File and Folder load implementation is in the [custom-file](https://github.com/snowyu/custom-file.js) package


## API

### Properties

* `path` *(File|String)*: the file path. it will be internally stored as absolute path always.
  * It will get path string from the object's `path` attribute if it's an file object.
* `cwd` *(String)*: the current working directroy.
* `base` *(String)*: the base directory. used to calc the relative path.
  the default is `cwd` if it's empty.
* `history` *(ArrayOf String)*: the history of the path changes.
* `stat` *(Stat)*: the file stats object. the `isDirectory()` method be used.
* `contents` *(Buffer|ArrayOf(File)|Stream)*: the contents of the file.
  * It's the array of `File`/`Folder` object or a read-dir-stream if the file is a folder.
* `skipSize` *(Integer)*: the skipped length from beginning of contents. used by `getContent()`.
  only for buffer.
* `relative` *(String)*: readonly. the relative path from `path` to `base`.
* `dirname` *(String)*: readonly. the dirname of the `path`.
* `basename` *(String)*: readonly. the basename of the `path`.


### Methods

* `constructor([aPath, ]aOptions[, done])`
  * `aPath` *(String)*: the file path. it will be stored as absolute path always.
  * `aOptions` *(Object)*:
    * `path` *(String)*: the same as the `aPath` argument.
    * `cwd` *(String)*: the current working directroy.
    * `base` *(String)*: the base directory. used to calc the relative path.
      the default is `cwd` if it's empty.
    * `load` *(Boolean)*: whether load file data(stat and contents). defaults to false
    * `read` *(Boolean)*: whether load file contents. defaults to false. only for `load` is true.
    * `buffer` *(Boolean)*: whether load file contents as buffer or stream, defaults to false.
       only available for `load` and `read` both are true.
  * `done` *(Function)*: the callback function only available for `load` is true.
    * the `loadSync` will be used if no `done` function.
* `load(aOptions, done)`: Asynchronous load file stat and content.
    * `read` *(Boolean)*: whether load file contents. defaults to false.
    * `buffer` *(Boolean)*: whether load file contents as buffer or stream, defaults to false.
       only available for `read` is true.
  * `done` *Function(err, content)*: the callback function. the `content` only available when `read` is true
* `loadSync(aOptions)`: Synchronous load file stat and content.
    * `read` *(Boolean)*: whether load file contents. defaults to false.
    * `buffer` *(Boolean)*: whether load file contents as buffer or stream, defaults to false.
       only available for `read` is true.
    * return contents only available when `read` is true
* `loadContent(aOptions, done)`: Asynchronous load file contents.
    * `buffer` *(Boolean)*: whether load file contents as buffer or stream, defaults to false.
  * `done` *Function(err, content)*: the callback function.
* `loadContentSync(aOptions)`: Synchronous load file contents.
    * `buffer` *(Boolean)*: whether load file contents as buffer or stream, defaults to false.
    * return contents
* `getContent(aOptions, done)`: Asynchronous get the file contents buffer, skipSize used.
  only available for File(not for folder)
  * `done` *Function(err, content)*: the callback function.
* `getContentSync(aOptions)`: Synchronous get the file contents buffer, skipSize used.
  only available for File(not for folder)
* `loadStat(aOptions, done)`: Asynchronous load file stats.
  * `done` *Function(err, stat)*: the callback function.
* `loadStatSync(aOptions)`: Synchronous load file stats.
    * return stat
* `pipe(stream[, options])`: pipe it to the stream.
  * `stream` *(Writable Stream)*: The destination stream for writing data.
  * `options` *(Object)*: Pipe options
    * `end` *(Boolean)*: End the writer when the reader ends. Default = true
* `validate(aFile, raiseError=true)`: the aFile object whether is valid.
* `isDirectory()`: whether is directory.
* `isBuffer()`: whether contents is buffer.
* `isStream()`: whether contents is stream.

these methods should be overrides:

* _validate(aFile): the aFile object whether is valid.
* _loadContentSync(aFile)
* _loadStatSync(aFile)
* _loadContent(aFile, done): optional
* _loadStat(aFile, done): optional
* _inspect()

## License

MIT

