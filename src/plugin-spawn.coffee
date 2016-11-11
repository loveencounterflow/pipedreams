




############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/PLUGIN-SPAWN'
# log                       = CND.get_logger 'plain',     badge
# info                      = CND.get_logger 'info',      badge
# whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
# echo                      = CND.echo.bind CND
#...........................................................................................................
# FS                        = require 'fs'
# PATH                      = require 'path'
# OS                        = require 'os'
CP                        = require 'child_process'
#...........................................................................................................
# D                         = require '..'
# { $, $async, }            = D
# { step, }                 = require 'coffeenode-suspend'

#-----------------------------------------------------------------------------------------------------------
@_new_stream_from_pattern_and_path = ( pattern_and_path, hints, settings ) ->
  unless ( type = CND.type_of pattern_and_path ) is 'pod'
    throw new Error "expected a POD, got a #{type}"
  unless CND.is_subset ( keys = Object.keys pattern_and_path ), [ 'pattern', 'path', ]
    throw new Error "expected a POD, with keys 'pattern' and 'path', got one with #{keys}"
  if hints?
    throw new Error "hints not implemented, got #{rpr hints}"
  if settings?
    throw new Error "settings not implemented, got #{rpr settings}"
  #.........................................................................................................
  R                     = @new_stream()
  cwd                   = process.cwd()
  { pattern, path, }    = pattern_and_path
  pattern_txt           = pattern[ 'source' ]
  ignore_case           = pattern[ 'ignoreCase' ]
  debug '77698', pattern_and_path
  debug '77698', ignore_case
  cp_settings           = { cwd, }
  command               = 'grep'
  #.........................................................................................................
  parameters            = []
  parameters.push         '--extended-regexp'
  parameters.push         '-e'
  parameters.push         pattern_txt
  parameters.push         '--ignore-case' if ignore_case
  parameters.push         path
  #.........................................................................................................
  debug '12034', "#{command} #{parameters.join ' '}"
  cp                    = CP.spawn command, parameters, cp_settings
  #.........................................................................................................
  stdout_finished       = no
  stderr_finished       = no
  has_ended             = no
  error_lines           = []
  errors                = []
  codes                 = []
  #.........................................................................................................
  finish = =>
    ### "Normally the exit status is 0 if a line is selected, 1 if no lines were selected, and 2 if an error
    occurred." ###
    return if has_ended
    if errors.length is 0 and error_lines.length is 0
      return unless stdout_finished and stderr_finished and codes[ 0 ] in [ 0, 1, ]
      @end R
      has_ended = yes
      return
    if errors.length > 0
      has_ended = yes
      R.emit 'error', errors[ 0 ]
    else if error_lines.length > 0
      has_ended = yes
      R.emit 'error', new Error error_lines.join '\n'
    else if codes[ 0 ] is 2
      has_ended = yes
      R.emit 'error', new Error "grep exited with error code #{codes[ 0 ]}"
  #.........................................................................................................
  cp.stdout
    .pipe @$split()
    .pipe @$ ( line ) => @send R, line
    .pipe @$ 'finish', =>
      stdout_finished = yes
      finish()
  #.........................................................................................................
  cp.stderr
    .pipe @$split()
    .pipe @$ ( line ) => error_lines.push line
    .pipe @$ 'finish', =>
      stderr_finished = yes
      finish()
  #.........................................................................................................
  cp.on 'error', ( error ) =>
    errors.push error
    finish()
  #.........................................................................................................
  cp.on 'close', ( code  ) =>
    codes.push code
    finish()
  #.........................................................................................................
  return R


############################################################################################################
do ( self = @ ) ->
  D = require './main'
  for name, value of self
    D[ name ] = value














