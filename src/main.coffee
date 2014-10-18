

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
# # BAP                       = require 'coffeenode-bitsnpieces'
# # TYPES                     = require 'coffeenode-types'
# # TEXT                      = require 'coffeenode-text'


#-----------------------------------------------------------------------------------------------------------
@remit = ( method ) ->
  send      = null
  cache     = null
  on_end    = null
  #.........................................................................................................
  get_send = ( self, encoding, done ) ->
    # R           = (  data ) -> self.push data; done()
    R           = (  data ) -> done new Error "Pipedreams v2 API changed; use `send.one` or `send.done`"
    R.one       = (  data ) -> self.push data
    R.done      = (  data ) -> self.push data if data?; done()
    R.error     = ( error ) -> done error
    ### TAINT it's presently not quite clear whether using the advisory `@emit 'end'` or else the
      prescriptive `@end()` is the better way to tell the stream we've finished; until i find out,
      we add one more method, `send.finish()` that uses `@end` instead of emitting an event. ###
    R.end       =           -> self.emit 'end'
    R.finish    =           -> self.end()
    R.encoding  = encoding
    return R
  #.........................................................................................................
  switch arity = method.length
    #.......................................................................................................
    when 2
      #.....................................................................................................
      on_data = ( data, encoding, done ) ->
        # debug '©3w9', send
        send = get_send @, encoding, done unless send?
        method data, send
    #.......................................................................................................
    when 3
      cache = []
      #.....................................................................................................
      on_data = ( data, encoding, done ) ->
        if cache.length is 0
          cache[ 0 ] = data
          return done()
        [ cache[ 0 ], data, ] = [ data, cache[ 0 ], ]
        #...................................................................................................
        send = get_send @, encoding, done
        method data, send, null
      #.....................................................................................................
      on_end = ( done ) ->
        if cache.length is 0
          data = null
        else
          data = cache[ 0 ]
          cache.length = 0
        #...................................................................................................
        send = get_send @, null, done
        method data, send, send.end
    #.......................................................................................................
    else
      throw new Error "expected a method with an arity of 2 or 3, got one with an arity of #{arity}"
  #.........................................................................................................
  ### TAINT no way to use byte / text streaming? necessary? ###
  return through2.obj on_data, on_end




