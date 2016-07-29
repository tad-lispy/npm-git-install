`#!/usr/bin/env node
`

{
  discover
  reinstall_all
  shrinkwrap
}         = require '.'
cli       = require 'commander'
path      = require 'path'
fs        = require 'fs'

cli
  .version '0.0.0' # TODO: Read from package.json
  .description """
    A utility to properly install npm git dependencies.
  """
  .option '-s --silent',  'suppress child processes output'
  .option '-w, --git_shrinkwrap <path>', 'Optional git shrinkwrap file location'
  .option '-c, --package <path>', 'Optional git shrinkwrap file location'
  .option '-v --verbose', 'be verbose'
  #.option '-a --all',     'reinstall all git dependencies and devDependencies'
  .option '-d --dry',     'just print what packages would be installed'

conf_file_error = (file) ->
  console.error "package file '#{file}' not found."
  process.exit 1

validate_paths = (options) ->
  options.package ?= 'package.json'
  options.package = path.resolve options.package

  options.git_shrinkwrap ?= 'git-shrinkwrap.json'
  options.git_shrinkwrap = path.resolve options.git_shrinkwrap

  try
    file_stat = fs.statSync(options.package)
    if !file_stat || !file_stat.isFile()
      conf_file_error options.package

    if options.verbose
      console.log "Reading dependencies from #{options.package}"
  catch
    conf_file_error options.package

  try
    shrinkwrap_stat = fs.statSync(options.git_shrinkwrap)
    if !shrinkwrap_stat || !shrinkwrap_stat.isFile()
      options.git_shrinkwrap = ''

    if options.verbose && options.git_shrinkwrap
      console.log "Using shrinkwrap from #{options.git_shrinkwrap}"
  catch
    options.git_shrinkwrap = ''

print = (packages, options) ->
  return unless options.dry or options.verbose
  console.log 'Detected packages:'
  console.log ' ' + packages.join '\n'
  console.log ''

dry_guardian = (options) ->
  return unless options.dry

  console.log 'Finished dry run.'
  console.log ''
  process.exit 0

cli
  .command 'shrinkwrap'
  .description 'bump all git dependencies to latest and generate a git-shrinkwrap.json file'
  .action((options) ->
    try
      opts = options.parent
      validate_paths opts
      packages = discover opts.package
      print packages, opts
      dry_guardian opts
      shrinkwrap packages, opts
    catch error
      console.error error
      process.exit 1
  )

cli
  .command 'install'
  .description 'install git dependencies'
  .action((options) ->

    try
      opts = options.parent
      validate_paths opts
      packages = discover opts.package
      print packages, opts
      dry_guardian opts
      reinstall_all packages, opts
    catch error
      console.error error
      process.exit 1
  )

cli
  .command '*'
  .action((cmd, options) ->
    console.error 'Invalid command'
    process.exit 1
  )

cli.parse process.argv
