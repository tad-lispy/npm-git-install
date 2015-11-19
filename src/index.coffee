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


reinstall = ({url, branch}) ->
  tmp = null
  temp.track()

  mktmp 'npm-git-'
    .then (path) ->
      tmp = path
      console.log "Cloning '#{url}' into #{tmp}"
      Clone url, tmp, checkoutBranch: branch
    .then -> exec 'npm install', cwd: tmp, stdio: 'inherit'
    .then -> exec "npm install #{tmp}"

# Different formats of NPM GIT urls
name = /[\w\-\_\.]+/.source # Host, user or repo name

regexps = [
  # lzrski/data-object#0.2.0
  pattern : ///
    ^
    (#{name}) # 1. User
    \/
    (#{name}) # 2. Repo
    (?:
      \#(.+)  # 3. Revision
    )?
    $
  ///
  method  : (match) ->
    url     : "https://github.com/#{match[1]}/#{match[2]}.git"
    branch  : match[3] or 'master'
,
  # github:lzrski/data-object#0.2.0
  pattern : ///
    ^
    github:
    (#{name}) # 1. User
    \/
    (#{name}) # 2. Repo
    (?:
      \#(.+)  # 3. Revision
    )?
    $
  ///
  method  : (match) ->
    url     : "https://github.com/#{match[1]}/#{match[2]}.git"
    branch  : match[3] or 'master'
,
  # git+ssh://git@github.com:lzrski/data-object.git#2.0'
  pattern : ///
    ^
    git\+ssh:\/\/
    git@
    (#{name})       # 1. Host
    :
    (#{name})       # 2. User
    \/
    (#{name})       # 3. Repo
    \.git
    \/?
    (?:
      \#(.+)        # 4. Revision
    )?
    $
  ///
  method  : (match) ->
    url     : "git@#{match[1]}:#{match[2]}/#{match[3]}.git"
    branch  : match[4] or 'master'

  ###
  TODO:
    git://github.com/user/project.git#commit-ish
    git+ssh://user@hostname:project.git#commit-ish
    git+ssh://user@hostname/project.git#commit-ish        - Really?
    git+http://user@hostname/project/blah.git#commit-ish
    git+https://user@hostname/project/blah.git#commit-ish
  ###
]

pkg = require '../package.json'
packages = ({name, url} for name, url of Object.assign {},
  pkg.devDependencies or {},
  pkg.dependencies    or {})

factories = packages
  .map ({ url }) ->
    for { pattern, method } in regexps when match = url.match pattern
      return method match

    return null

  .filter Boolean

  .map (pkg) ->
    console.log "Building #{pkg.url} factory"
    ->
      console.log "Runnint #{pkg.url} factory"
      reinstall pkg # This is not a typo - it's a factory

console.dir factories
# As seen on http://pouchdb.com/2015/05/18/we-have-a-problem-with-promises.html
sequence = do Promise.resolve
for factory in factories
  sequence = sequence.then factory

sequence.catch (error) ->
  console.error error
