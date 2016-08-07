`#!/usr/bin/env node
`

{
  discover
  reinstall_all
  shrinkwrap
}           = require '.'
cli         = require 'commander'
path        = require 'path'
fs          = require 'fs'
cwd         = process.cwd()

# Command line options
# See below for sub-commands definitions
cli
  .version '0.0.0' # TODO: Read from package.json
  .description """
    A utility to properly install npm git dependencies.
  """
  .option '-s --silent',  'suppress child processes output'
  .option '-w, --git_shrinkwrap <path>', 'Optional git shrinkwrap file location'
  .option '-c --package <path>', 'Optional package.json file location [package.json]', "package.json"
  .option '-v --verbose', 'be verbose'
  .option '-d --dry',     'just print what packages would be installed'

# Helper functions
# Most of the work with promises

###
tap : Function -> Identity

Executes a function on a value and returns value, ignoring whatever the function returns. Useful for debugging or performing other side effects.
###
tap = (fn) -> (value) ->
  fn value
  return value

###
conf_file_error : String -> undefined

Helper method to output an error when package files are not found
###
conf_file_error = (file) ->
  console.error "package file '#{file}' not found."
  process.exit 1


###
print_list : String -> Object -> [String] -> undefined

Prints formated list of strings with title. Useful for printing list of discovered packages.
###
print_list = (title = "List", options = {}) -> (list) ->
  return unless options.dry or options.verbose
  console.log "#{title}:"
  for item in list
    console.log "  #{item}"
  console.log ''

###
validate_paths : Object -> undefined

Prints formated list of strings with title. Useful for printing list of discovered packages.
###
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

###
dry_guardian : Object -> _ -> undefined

Terminate the script if options.dry is truthy.
###
dry_guardian = (options) -> () ->
  return unless options.dry

  console.log 'Finished dry run.'
  console.log ''
  process.exit 0

cli
  .command 'install'
  .description 'install git dependencies'
  .action (command) ->
    options = command.parent.opts()
    if options.verbose or options.dry
      console.log "Installing packages from #{options.package}"

    validate_paths options

    Promise
      .resolve discover options.package
      .then tap print_list "Discovered packages", options
      .then tap dry_guardian options
      .then reinstall_all options
      .catch (error) ->
        console.error

cli
  .command 'shrinkwrap'
  .description 'bump all git dependencies to latest remote and generate a git-shrinkwrap.json file'
  .action((options) ->
    options = command.parent.opts()
    if options.verbose or options.dry
      console.log "Generating shrinkwrap file for #{options.package} in #{options.git_shrinkwrap}"

    Promise
      .resolve validate_paths options
      .then discover options.package
      .then tap print_list "Discovered packages", options
      .then tap dry_guardian options
      .then shrinkwrap options
      .catch (error) ->
        console.error
  )

cli.parse process.argv
