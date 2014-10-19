

############################################################################################################
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'PIPEDREAMS2'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
urge                      = TRM.get_logger 'urge',      badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
### https://github.com/rvagg/through2 ###
through2                  = require 'through2'
#...........................................................................................................
# # BAP                       = require 'coffeenode-bitsnpieces'
# # TYPES                     = require 'coffeenode-types'
# # TEXT                      = require 'coffeenode-text'


#===========================================================================================================
# REMIT
#-----------------------------------------------------------------------------------------------------------
@remit = ( method ) ->
  send      = null
  on_end    = null
  #.........................................................................................................
  unless 2 <= ( arity = method.length ) <= 3
    throw new Error "expected a method with an arity of 2 or 3, got one with an arity of #{arity}"
  #.........................................................................................................
  get_send = ( self, encoding, done ) ->
    # R           = (  data ) -> self.push data; done()
    P2_send_method          = (  data ) -> done new Error "Pipedreams v2 API changed; use `send.one` or `send.done`"
    P2_send_method.one      = (  data ) -> self.push data
    P2_send_method.done     = (  data ) -> self.push data if data?; done()
    # P2_send_method.one      = (  data ) -> whisper 'one',  rpr data; self.push data
    # P2_send_method.done     = (  data ) -> whisper 'done', rpr data; self.push data if data?; done()
    P2_send_method.error    = ( error ) -> done error
    P2_send_method.pause    =           -> self.pause()
    P2_send_method.resume   =           -> self.resume()
    ### TAINT it's presently not quite clear whether using the advisory `@emit 'end'` or else the
      prescriptive `@end()` is the better way to tell the stream we've finished; until i find out,
      we add one more method, `send.finish()` that uses `@end` instead of emitting an event. ###
    P2_send_method.end      =           -> self.emit 'end'
    P2_send_method.finish   =           -> self.end()
    P2_send_method.encoding = encoding
    return P2_send_method
  #.....................................................................................................
  on_data = ( data, encoding, done ) ->
    send = get_send @, encoding, done unless send?
    method data, send, null
  #.........................................................................................................
  if arity is 3
    on_end = ( done ) ->
      send = get_send @, null, done
      method null, null, send.end
  #.........................................................................................................
  ### TAINT no way to use byte / text streaming? necessary? ###
  stream_options = { objectMode: true, allowHalfOpen: false, highWaterMark: 10, }
  stream_options = { objectMode: true, highWaterMark: 10, }
  stream_options = {}
  return through2.obj stream_options, on_data, on_end


#===========================================================================================================
# SPECIALIZED STREAMS
#-----------------------------------------------------------------------------------------------------------
@create_throughstream = ->
  R = through2.obj()
  R.setMaxListeners 0
  return R


#===========================================================================================================
# COUNTING
#-----------------------------------------------------------------------------------------------------------
@$count = ( label, handler = null ) ->
  count = 0
  return @remit ( data, send, end ) =>
    count += 1 if data?
    unless end?
      send.done data
    else
      if handler?
        handler null, count
      else
        info "encountered #{count} #{label}"
      end()


#===========================================================================================================
# REPORTING
#-----------------------------------------------------------------------------------------------------------
@$show = ( badge = null ) ->
  if badge? then  show = TRM.get_logger 'info', badge
  else            show = info
  return @remit ( record, send ) =>
    # show ( rpr record ), send.encoding
    show rpr record
    send.done record


#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@$sink = ->
  ### TAINT not sure whether this is needed, but i found cases where pipelines without an all-accepting
    last member wouldn't run properly. Try `.pipe P2.$sink()` in cases where pipelines stop transporting
    data early. This method may be a temporary fix. ###
  return ( require 'fs' ).createWriteStream '/dev/null'







