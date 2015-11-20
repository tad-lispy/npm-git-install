`#!/usr/bin/env node
`

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
  .option '-s --silent',  'suppress child processes output'
  .option '-v --verbose', 'be verbose'
  .option '-a --all',     'reinstall all git dependencies and devDependencies'
  .option '-d --dry',     'just print what packages would be installed'
  .parse process.argv

{
  silent
  verbose
  all
  dry
  args: [ file ]
} = cli

file ?= 'package.json'

if all
  # TODO: Implement messy, but compatible discovery
  console.error "I'd love to do it all, but it's not implemented yet. Sorry."
  process.exit 1

file = path.resolve file
if verbose then console.log "Reading dependencies from #{file}"

tap = (fn) -> (value) ->
  fn value
  return value

print = (packages) ->
  if dry or verbose then console.log packages.join '\n'

dry_guardian = ->
  if dry then process.exit 0

Promise
  .resolve discover 'package.json'
  .then tap print
  .then tap dry_guardian
  .then reinstall_all {silent, verbose}
  .catch (error) ->
    console.error error
    throw error
