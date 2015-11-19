cp          = require 'child_process'
temp        = require 'temp'
{ resolve } = require 'path'
{ Clone }   = require 'nodegit'
pkg         = require '../package.json'

{
  cwd
  chdir
}         = process

# Helpful promises
exec = (args...) -> new Promise (resolve, reject) ->
  console.log "executing #{args[0]}"
  cp.exec args..., (error, out, err) ->
    if error then return reject error
    do resolve

mktmp = (prefix) -> new Promise (resolve, reject) ->
  temp.mkdir prefix, (error, path) ->
    if error then return reject error
    resolve path


reinstall = (url) ->
  tmp = null
  temp.track()

  mktmp 'npm-git-'
    .then (path) ->
      tmp = path
      console.log "Cloning '#{url}' into #{tmp}"
      Clone url, tmp
    .then -> exec 'npm install', cwd: tmp
    .then -> exec "npm install #{tmp}"

reinstall "https://github.com/lzrski/data-object.git"
