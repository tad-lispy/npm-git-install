cp          = require 'child_process'
temp        = require 'temp'
{ resolve } = require 'path'
NodeGit     = require 'nodegit'

{
  cwd
  chdir
}         = process

# Helpful promises
exec = (cmd, options) -> new Promise (resolve, reject) ->
  [ cmd, args... ] = cmd.split ' '
  child = cp.spawn cmd, args, options
  child.on 'close', (code) ->
    if code is 0 then resolve code
    else reject code

mktmp = (prefix) -> new Promise (resolve, reject) ->
  temp.mkdir prefix, (error, path) ->
    if error then return reject error
    resolve path


reinstall = (options = {}, pkg) ->
  {
    silent
    verbose
  } = options

  curried = ({ url, revision }) ->
    do temp.track

    tmp = null
    stdio = [
      'pipe'
      if silent then 'pipe' else process.stdout
      process.stderr
    ]

    mktmp 'npm-git-'
      .then (path) ->
        tmp = path
        cmd = "git clone #{url} #{tmp}"
        if verbose then console.log "Cloning '#{url}' into #{tmp}"

        exec cmd, { stdio }

      .then ->
        cmd = "git checkout #{revision}"

        if verbose then console.log "Checking out #{revision}"

        exec cmd, { cwd: tmp, stdio }

      .then ->
        cmd = 'npm install'
        if verbose then console.log "executing #{cmd}"

        exec cmd, { cwd: tmp, stdio }

      .then ->
        cmd = "npm install #{tmp}"
        if verbose then console.log "executing #{cmd}"

        exec cmd, { stdio }

  return if pkg then curried pkg else curried

discover = (path = '../package.json') ->
  path = resolve path
  delete require.cache[path]
  { gitDependencies } = require path
  ( url for name, url of gitDependencies)

###

As seen on http://pouchdb.com/2015/05/18/we-have-a-problem-with-promises.html

###

reinstall_all = (options = {}, packages) ->
  curried = (packages) ->
    factories = packages.map (url) ->
      [ whole, url, revision] = url.match /^(.+?)(?:#(.+))?$/
      revision ?= 'master'
      return -> reinstall options, { url, revision }

    sequence = do Promise.resolve
    for factory in factories
      sequence = sequence.then factory

    return sequence

  return if packages then curried packages else curried

module.exports = {
  discover
  reinstall
  reinstall_all
}
