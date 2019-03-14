
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/XEMITTER'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
#...........................................................................................................
### https://github.com/sindresorhus/emittery ###
Emittery                  = require 'emittery'


#-----------------------------------------------------------------------------------------------------------
@_emitter         = new Emittery()
@_has_contractors = {}

#-----------------------------------------------------------------------------------------------------------
@_mark_as_primary = ( x ) -> { '~isa': 'XEMITTER/preferred', value: x, }
@_filter_primary  = ( x ) -> CND.isa x, 'XEMITTER/preferred'
@_get_primary     = ( values ) -> ( values.filter @_filter_primary )[ 0 ]?.value ? null

#-----------------------------------------------------------------------------------------------------------
@_get_ccl = ( channel, self, listener ) ->
  switch arity = arguments.length
    when 2 then [ channel, self, listener, ] = [ channel, null, self,       ]
    when 3 then [ channel, self, listener, ] = [ channel, self,  listener,  ]
    else throw new Error "expected 2 or 3 arguments, got #{arity}"
  unless ( CND.isa_text channel ) and ( channel.length > 0 )
    throw new Error "expected a non-empty text for channel, got #{rpr channel}"
  return [ channel, self, listener, ]

#-----------------------------------------------------------------------------------------------------------
@_get_cl = ( self, listener ) ->
  switch arity = arguments.length
    when 1 then [ self, listener, ] = [ null, self,       ]
    when 2 then [ self, listener, ] = [ self,  listener,  ]
    else throw new Error "expected 1 or 2 arguments, got #{arity}"
  return [ self, listener, ]

#-----------------------------------------------------------------------------------------------------------
@contract = ( channel, self, listener ) ->
  [ channel, self, listener, ] = @_get_ccl arguments...
  if @_has_contractors[ channel ]
    throw new Error "channel #{rpr channel} already has a primary listener"
  @_has_contractors[ channel ] = yes
  @_emitter.on channel, ( data ) =>
    return @_mark_as_primary await listener.call self, data
  return listener

#-----------------------------------------------------------------------------------------------------------
@listen_to = ( channel, self, listener ) ->
  [ channel, self, listener, ] = @_get_ccl arguments...
  @_emitter.on channel, ( data ) -> await listener.call self, data
  return listener

#-----------------------------------------------------------------------------------------------------------
@listen_to_all = ( self, listener ) ->
  [ self, listener, ] = @_get_cl arguments...
  @_emitter.onAny ( channel, data ) -> await listener.call self, channel, data
  return listener

#-----------------------------------------------------------------------------------------------------------
@emit             = ( channel, data ) ->                                await @_emitter.emit channel, data
@delegate         = ( channel, data ) ->                  @_get_primary await @_emitter.emit channel, data


############################################################################################################
for name, value of L = @
  ### TAINT poor man's 'callable' detection ###
  continue unless CND.isa_function value.bind
  L[ name ] = value.bind L
