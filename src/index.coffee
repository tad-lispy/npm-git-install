cp          = require 'child_process'
cs          = require 'cross-spawn'
temp        = require 'temp'
fs          = require 'fs'
{ resolve } = require 'path'

{
  cwd
  chdir
}         = process

# Helpful promises
exec = (cmd, options) -> new Promise (resolve, reject) ->
  [ cmd, args... ] = cmd.split ' '
  child = cs cmd, args, options
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
        if verbose then console.log "executing `#{cmd}` in `#{tmp}`"

        exec cmd, { cwd: tmp, stdio }

      .then () ->
        # Gather some metadata that can be displayed and saved later
        cmd = "git show --format=format:%h --no-patch"
        if verbose then console.log "executing `#{cmd}` in `#{tmp}`"

        sha = cp
          .execSync cmd, { cwd: tmp }
          .toString "utf-8"
          .trim()

        if verbose then console.log "reading package name from #{tmp}/package.json"


        {
          name
        }   = require "#{tmp}/package.json"

        return {
          name
          url
          sha
        }

      .then (metadata) ->
        cmd = "npm install #{tmp}"
        if verbose then console.log "executing #{cmd}"

        exec cmd, { stdio }

        return metadata

  return if pkg then curried pkg else curried

discover = (package_json = '../package.json') ->
  package_json = resolve package_json
  delete require.cache[package_json]
  { gitDependencies } = require package_json
  ( url for name, url of gitDependencies)

save = (file = '../package.json', report) ->
  file = resolve file
  delete require.cache[file]
  pkg = require file
  pkg.gitDependencies ?= {}
  for { name, url, sha } in report
    do (name, url, sha) -> pkg.gitDependencies[name] = "#{url}##{sha}"

  fs.writeFileSync file, JSON.stringify pkg, null, 2

###

As seen on http://pouchdb.com/2015/05/18/we-have-a-problem-with-promises.html

###

reinstall_all = (options = {}, packages) ->

  curried = (packages) ->
    factories = packages.map (url) ->
      [ whole, url, revision ] = url.match ///
        ^
        (.+?)         # url
        (?:\#(.+))?   # revision
        $
      ///
      revision ?= 'master'

      return (memo) ->
        Promise
          .resolve reinstall options, { url, revision }
          .then (metadata) ->
            memo.concat metadata

    sequence = Promise.resolve []
    for factory in factories
      sequence = sequence.then factory

    return sequence

  return if packages then curried packages else curried


module.exports = {
  discover
  reinstall
  reinstall_all
  save
}
