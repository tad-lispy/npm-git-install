{
  discover
  reinstall_all
}         = require '.'
cli       = require 'commander'
path      = require 'path'

cli
  .version '0.0.0' # TODO: Read from package.json
  .description """
    A utility to properly install npm git dependencies.
  """
  .arguments '<file>'
  .option '-s --silent',  'do not print to stdio'
  .option '-a --all',     'reinstall all git dependencies and devDependencies'
  .option '-d --dry',     'just print what packages would be installed'
  .option '-v --verbose', 'be verbose'
  .parse process.argv

{
  silent
  verbose
  all
  dry
  args: [ file ]
} = cli

complain = (rant) ->
  console.error rant
  process.exit 1

# All the possible complaints
if not file?          then do cli.help
if silent and verbose then complain "Silent or verbose? Please make your mind."
if silent             then complain "Silence is golden, but it's not implemented yet. Sorry."
if all                then complain "I'd love to do it all, but it's not implemented yet. Sorry."

file = path.resolve file
if verbose then console.log "Reading dependencies from #{file}"

tap = (fn) -> (value) ->
  fn value
  return value

Promise
  .resolve discover 'package.json'
  .then (packages) ->
    if dry or verbose then console.log packages.join '\n'
    if dry then process.exit 0
    return packages
  .then reinstall_all
  .catch (error) ->
    console.error error
    throw error
