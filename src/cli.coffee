`#!/usr/bin/env node
`

{
  discover
  reinstall_all
  save
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
  .option '-q --silent',  'suppress child processes output'
  .option '-s --save',    'resolve URLs to sha and save it to package file'
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
dry_guardian : Object -> -> undefined

Terminate the script if options.dry is truthy.
###
dry_guardian = (options) -> () ->
  return unless options.dry

  console.log 'Finished dry run.'
  console.log ''
  process.exit 0

cli
  .command 'install [packages...]'
  .description 'install git dependencies'
  .action (packages, command) ->
    options = command.parent.opts()
    console.log {options, packages}

    if packages.length is 0
      packages = discover options.package

      # TODO: Curry print_list properly
      (print_list "Installing packages from #{options.package}", options) packages

    else
      (print_list "Installing following packages", options) packages

    Promise
      .resolve packages
      .then tap dry_guardian options
      .then reinstall_all options
      .then tap print_list "Following packages has been installed", options
      .then (report) ->
        return if not options.save

        if options.verbose then console.log "Updating #{options.package}"
        save options.package, report

      .catch (error) ->
        console.error error
        process.exit 5

cli.parse process.argv
