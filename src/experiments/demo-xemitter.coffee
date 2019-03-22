
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/EXPERIMENTS/XEMITTER'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
#...........................................................................................................
PD                        = require '../..'
jr                        = JSON.stringify
defer                     = setImmediate
{ $
  $async }                = PD
XE                        = PD.XE.new_scope()
other_XE                  = PD.XE.new_scope()

# { emit
#   delegate
#   delegate_strict
#   listen_to_all
#   listen_to
#   contract }              = PD.XE

#-----------------------------------------------------------------------------------------------------------
### Used to make plausible context-binding did work: ###
@some_method = ->

#-----------------------------------------------------------------------------------------------------------
### Define a listener for all events; when being called, `this` will be set to the first argument (in this
case `@`, which here represents the module). Observe you cannot use fat-arrow functions here: ###
XE.listen_to_all @, ( key, event ) ->
  whisper 'µ28823-1', key, event, ( k for k of @ )
  return "listener #1"

#-----------------------------------------------------------------------------------------------------------
### Same as above, but the method context is here implicitly defined by the fat-arrow syntax: ###
XE.listen_to_all ( key, event ) =>
  whisper 'µ28823-2', key, event, ( k for k of @ )
  return "listener #2"

#-----------------------------------------------------------------------------------------------------------
### Listen to datoms with key `'^something': ###
XE.listen_to '~something', ( d ) =>
  whisper 'µ28823-3', d
  return "listener #3"

#-----------------------------------------------------------------------------------------------------------
### Define a listener for several event types (a.k.a. 'keys', 'channels')... ###
computation_listener = ( d ) =>
  urge "a computation has been requested: #{CND.white d.key}: #{CND.lime jr d.value}"
  return "listener #4"

#-----------------------------------------------------------------------------------------------------------
### ...and bind it to two kinds of events: ###
XE.listen_to '^plus-sync',  computation_listener
XE.listen_to '^plus-async', computation_listener
# XE.listen_to_once '^plus-async', ( d ) -> debug '37733', d

#-----------------------------------------------------------------------------------------------------------
### Register a 'contractor' (a.k.a. 'result producer') for `^plus-sync` events: ###
XE.contract '^plus-sync', ( d ) =>
  return d.value.a + d.value.b

#-----------------------------------------------------------------------------------------------------------
### Register a 'contractor' (a.k.a. 'result producer') for `^plus-async` events; observe that asynchronous
contractors should return a promise: ###
XE.contract '^plus-async', ( d ) =>
  return new Promise ( resolve, reject ) =>
    defer => resolve d.value.a + d.value.b

#-----------------------------------------------------------------------------------------------------------
### Make sure it's ok to yield `null`: ###
XE.contract '^always-null', ( d ) => null

# #-----------------------------------------------------------------------------------------------------------
# XE.contract_once '^multiply', ( d ) => debug '26672', d; d.value.a * d.value.b

#-----------------------------------------------------------------------------------------------------------
other_XE.listen_to_all ( key, d ) =>
  urge "other_XE received #{jr d}"


############################################################################################################
do =>
  ### Emit a few events to see what happens: ###
  XE.emit 'foo', { value: 42, }
  XE.emit PD.new_system_event 'something', 42

  ### You *must* use `await` to collect any or all results from an event, *even when the contractor is
  synchronous*. The return value for emit is a list of all the values produced by all listeners to an event;
  in case there is a contractor for an event, the contractor's result is wrapped in a `~XEMITTER-preferred`
  datom: ###

  info 'µ28823-4', await XE.emit PD.new_event '^plus-sync', { a: 42, b: 108, }
  # -> [ 'listener #4', { key: '~xemitter-preferred', value: 150 }, 'listener #1', 'listener #2' ]

  info 'µ28823-5', await XE.emit PD.new_event '^plus-async', { a: 42, b: 108, }
  # -> [ 'listener #4', { key: '~xemitter-preferred', value: 150 }, 'listener #1', 'listener #2' ]

  ### When using `delegate()` instead of `emit()`, the preferred value (a.k.a. '*the* event result')
  will be picked out of the list and unwrapped for you: ###
  info 'µ28823-6', await XE.delegate PD.new_event '^plus-sync',  { a: 42, b: 108, }
  info 'µ28823-6', await XE.delegate PD.new_event '^plus-async', { a: 42, b: 108, }
  info 'µ28823-6', await XE.delegate PD.new_event '^always-null'
  # -> 150

  ### When delegating an event without a listener, an error will be thrown: ###
  try
    info 'µ28823-7', await XE.delegate PD.new_event '^unknown-event', 'some value'
  catch error
    warn 'µ28823-8', error.message
    # -> Error: µ83733 no results for '^unknown-event'

  # info 'µ28823-9', await XE.delegate PD.new_event '^multiply', { a: 3, b: 4, }
  # try
  #   info 'µ28823-10', await XE.delegate PD.new_event '^multiply', { a: 3, b: 4, }
  # catch error
  #   warn error.message
  #   # -> Error: µ83733 no results for '^unknown-event'

  ### Emitting on `other_XE` must not send events to main `XE`: ###
  debug 'µ76767', await other_XE.emit PD.new_event '^event-on-other-xe', 111





