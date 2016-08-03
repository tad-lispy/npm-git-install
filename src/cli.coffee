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
  .option '-w, --git-shrinkwrap <path>', 'Optional git shrinkwrap file location [git-shrinkwrap.json]' # NOTE: No default value for shrinkwrap here. See apply_shrinkwrap helper.
  .option '-c, --package <path>', 'Optional package.json file location [package.json]', "package.json"
  .option '-v --verbose', 'be verbose'
  .option '-d --dry',     'just print what packages would be installed'

# Helper functions
# Most of the work with promises

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

###
read_shrinkwrap : Object -> String -> Object

Attempts to read shrinkwrapped dependencies from file. If optioms.hard is truthy and file does not exist then terminates the script.
###
read_shrinkwrap = (options, file) ->
  location = path.resolve cwd, file
  console.log options

  try
    { dependencies } = require location
    return dependencies
  catch error
    switch
      when options.hard and error.code is "MODULE_NOT_FOUND"
        ###
        If git-shrinkwrap option was explicitly provided (signified by options.hard) and file doesn't exists, then terminate abnormally:
        ###
        console.error "No such file: #{location}"
        process.exit 2
      when error.code is "MODULE_NOT_FOUND"
        ###
        If git-shrinkwrap option was not provided (i.e. options.hard is falsy), then lack of git-shrinkwrap.json file is an expected error.

        In this case just return an empty map, as if no pacakge was shrinkwrapped - which is exactly the case.
        ###
        if options.verbose
          console.log "Shrinkwrap file not found. That's ok. Proceeding.",

        return {}

      else
        ###
        Rethrow any other (unexpected) error
        ###
        throw error

###
apply_shrinkwrap : Object -> Object -> [Object] -> [Object]

TODO: apply_shrinkwrap should actually go to the API
###
apply_shrinkwrap = (options, shrinkwrap) -> (packages) ->
  file = options["gitShrinkwrap"] ? "git-shrinkwrap.json"

  if options.verbose
    console.log "Applying shrinkwrap from #{file}"

  options = Object.assign {}, options,
    hard: options["gitShrinkwrap"]?

  shrinkwrap = read_shrinkwrap options, file



  console.log {dependencies}

cli
  .command 'install'
  .description 'install git dependencies'
  .action (command) ->
    options = command.parent.opts()
    if options.verbose or options.dry
      console.log "Installing packages from #{options.package}"

    shrinkwrap =

    Promise
      .resolve discover options.package
      .then tap print_list "Discovered packages", options
      # TODO: .then apply_shrinkwrap options # TODO: Implement
      .then tap dry_guardian options
      .then reinstall_all options
      .then (revisions) ->
      .catch (error) ->
        console.error



# run_shrinkwrap = (options) ->
#   try
#     opts = options.parent
#     validate_paths opts
#     packages = discover opts.package
#     print packages, opts
#     dry_guardian opts
#     shrinkwrap packages, opts
#   catch error
#     console.error error
#     process.exit 1
#
cli
  .command 'shrinkwrap'
  .description 'bump all git dependencies to latest and generate a git-shrinkwrap.json file'
  .action (command) ->
    options = command.parent.opts()

    if options.verbose or options.dry
      console.log "Preparing shrinkwrap of packages from #{options.package}"

    Promise
      .resolve discover options.package
      .then tap print "Discovered packa"

cli.parse process.argv
