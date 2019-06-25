

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TESTS/SELECT'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
jr                        = JSON.stringify
#...........................................................................................................
PD                        = require '../..'
PATH                      = require 'path'
FS                        = require 'fs'
#...........................................................................................................
types                     = require '../_types'
{ isa
  validate
  type_of }               = types
randomize                 = require 'randomatic'




#-----------------------------------------------------------------------------------------------------------
generate_key_or_selector = ( type ) ->
  validate.true type in [ 'key', 'selector', ]
  use_prefix    = false
  #.........................................................................................................
  if type is 'key'
    use_sigil     = true
    use_suffix    = true
    use_tag       = false
    sigil_length  = 1
  else
    use_sigil     = true
    use_suffix    = true
    use_tag       = false
    sigil_length  = 1
  #.........................................................................................................
  prefix_length = CND.random_integer 1, 15
  suffix_length = CND.random_integer 3, 10
  #.........................................................................................................
  sigil         = if use_sigil  then ( randomize '?', sigil_length, { chars: '^<>~[]', }  ) else ''
  prefix        = if use_prefix then ( ( randomize 'a', prefix_length ) + ':'             ) else ''
  suffix        = if use_suffix then (   randomize 'a', suffix_length                     ) else ''
  tag           = if use_tag    then '#stamped'                                             else ''
  return sigil + prefix + suffix + tag

#-----------------------------------------------------------------------------------------------------------
generate_keys_and_selectors = ->
  path  = PATH.join __dirname, '../../src/tests/data-for-select-benchmark.coffee'
  lines = []
  n     = 1500
  lines.push '@datoms = ['
  for _ in [ 1 .. n ]
    key = generate_key_or_selector 'key'
    d   = PD.new_datom key
    lines.push '  ' + ( jr d )
  lines.push '  ]'
  lines.push '@selectors = ['
  for _ in [ 1 .. n ]
    selector  = generate_key_or_selector 'selector'
    lines.push '  ' + ( jr selector )
  lines.push '  ]'
  FS.writeFileSync path, ( lines.join '\n' ) + '\n'
  return null



############################################################################################################
unless module.parent?
  generate_keys_and_selectors()
  # test @
  # test @[ "selector keypatterns" ]
  # test @[ "select 2" ]

