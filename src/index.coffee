cp          = require 'child_process'
temp        = require 'temp'
{ resolve } = require 'path'
{ Clone }   = require 'nodegit'

{
  cwd
  chdir
}         = process

# Helpful promises
exec = (cmd, options) -> new Promise (resolve, reject) ->
  console.log "executing #{cmd}"
  [ cmd, args... ] = cmd.split ' '
  child = cp.spawn cmd, args, options
  child.on 'close', (code) ->
    if code is 0 then resolve code
    else reject code

mktmp = (prefix) -> new Promise (resolve, reject) ->
  temp.mkdir prefix, (error, path) ->
    if error then return reject error
    resolve path


reinstall = ({url, revision}) ->
  tmp = null
  temp.track()

  mktmp 'npm-git-'
    .then (path) ->
      tmp = path
      console.log "Cloning '#{url}' into #{tmp}"
      # TODO: Handle Git authentication (at least ssh keys)
      Clone url, tmp, checkoutBranch: revision
    .then -> exec 'npm install', cwd: tmp, stdio: 'inherit'
    .then -> exec "npm install #{tmp}"

discover = (path = '../package.json') ->
  path = resolve path
  delete require.cache[path]
  { gitDependencies } = require path
  ( url for name, url of gitDependencies)

###

As seen on http://pouchdb.com/2015/05/18/we-have-a-problem-with-promises.html

###

reinstall_all = (packages) ->
  factories = packages.map (url) ->
    [ whole, url, revision] = url.match /^(.+)(?:#(.+))?$/
    revision ?= 'master'
    return -> reinstall { url, revision }

  sequence = do Promise.resolve
  for factory in factories
    sequence = sequence.then factory

  return sequence

module.exports = {
  discover
  reinstall
  reinstall_all
}
