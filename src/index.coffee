cp          = require 'child_process'
temp        = require 'temp'
jsonfile    = require 'jsonfile'
fs          = require 'fs'
{ resolve } = require 'path'

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

discover = (package_json = '../package.json') ->
  package_json = resolve package_json
  delete require.cache[package_json]
  { gitDependencies } = require package_json
  ( url for name, url of gitDependencies)

sha_for = (name_to_find, shrinkwrap_file = '../git-shrinkwrap.json') ->
  shrinkwrap_file = resolve shrinkwrap_file
  delete require.cache[shrinkwrap_file]
  { dependencies } = require shrinkwrap_file
  for name, url of dependencies
    return url if name = name_to_find

###

As seen on http://pouchdb.com/2015/05/18/we-have-a-problem-with-promises.html

###

reinstall_all = (packages, options = {}) ->

  curried = (packages) ->
    factories = packages.map (url) ->
      [ whole, url, revision] = url.match /^(.+?)(?:#(.+))?$/
      revision ?= 'master'
      name = url.split(':').pop().replace(/\.git$/, "")

      try
        file_stat = fs.statSync(options.git_shrinkwrap)
        if !file_stat || !file_stat.isFile()
          options.git_shrinkwrap = ''
      catch
        options.git_shrinkwrap = ''

      if options.git_shrinkwrap
        sha = sha_for name, options.git_shrinkwrap
        revision = sha if sha

      return -> reinstall options, { url, revision }

    sequence = do Promise.resolve
    for factory in factories
      sequence = sequence.then factory

    return sequence

  return if packages then curried packages else curried

shrinkwrap = (packages, options = {}) ->
  shrinkwrap_json =
    dependencies: {}

  for pkg in packages
    [ whole, git_at_github, name, branch] = pkg.match /^(.+?):(.+?)(?:\.git)(?:#(.+))?$/
    ref = "refs/heads/#{branch}"
    ref = 'HEAD' if !branch || branch == 'master'

    cmd = "git ls-remote #{git_at_github}:#{name}.git #{ref} | head -1 | cut -f 1"
    if options.verbose then console.log "Getting latest sha of #{whole}"

    sha = cp.execSync(cmd, encoding: 'utf8').trim()
    if !sha
      throw "Couldn't fetch latest commit for #{whole}"

    shrinkwrap_json.dependencies[name] = sha

  console.log "Writing shrinkwrap to #{options.git_shrinkwrap}"
  if options.verbose then console.log shrinkwrap_json
  jsonfile.writeFileSync(options.git_shrinkwrap, shrinkwrap_json, { spaces: 2 })

module.exports = {
  discover
  reinstall
  reinstall_all
  shrinkwrap
}
