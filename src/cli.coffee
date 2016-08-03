`#!/usr/bin/env node
`

{
  discover
  reinstall_all
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
  .command 'install'
  .description 'install git dependencies'
  .action (command) ->
    options = command.parent.opts()
    if options.verbose or options.dry
      console.log "Installing packages from #{options.package}"

    Promise
      .resolve discover options.package
      .then tap print_list "Discovered packages", options
      .then tap dry_guardian options
      .then reinstall_all options
      .catch (error) ->
        console.error

cli.parse process.argv
