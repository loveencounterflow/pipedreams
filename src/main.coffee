

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS2'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
### https://github.com/rvagg/through2 ###
through2                  = require 'through2'
#...........................................................................................................
DS                        = require './densort'
@new_densort              = DS.new_densort.bind DS
#...........................................................................................................
### https://github.com/dominictarr/event-stream ###
@ES                       = require 'event-stream'
#...........................................................................................................
### https://github.com/dominictarr/sort-stream ###
@$sort                    = require 'sort-stream'


#===========================================================================================================
# GENERIC METHODS
#-----------------------------------------------------------------------------------------------------------
# @create_readstream            = HELPERS.create_readstream             .bind HELPERS
# @create_readstream_from_text  = HELPERS.create_readstream_from_text   .bind HELPERS
# @pimp_readstream              = HELPERS.pimp_readstream               .bind HELPERS
# @merge                        = @ES.merge                              .bind @ES
@$split                       = @ES.split                              .bind @ES
# @$chain                       = @ES.pipeline                           .bind @ES
# @through                      = @ES.through                            .bind @ES
# @duplex                       = @ES.duplex                             .bind @ES
# @as_readable                  = @ES.readable                           .bind @ES
# @read_list                    = @ES.readArray                          .bind @ES


#===========================================================================================================
# REMIT
#-----------------------------------------------------------------------------------------------------------
@remit = ( method ) ->
  send      = null
  cache     = null
  on_end    = null
  #.........................................................................................................
  get_send = ( self ) ->
    R             = (  data ) -> self.emit 'data',  data # if data?
    R.error       = ( error ) -> self.emit 'error', error
    R.end         =           -> self.emit 'end'
    R.pause       =           -> self.pause()
    R.resume      =           -> self.resume()
    R.read        =           -> self.read()
    R[ '%self' ]  = self
    return R
  #.........................................................................................................
  switch arity = method.length
    #.......................................................................................................
    when 2
      #.....................................................................................................
      on_data = ( data ) ->
        # debug '©3w9', send
        send = get_send @ unless send?
        method data, send
    #.......................................................................................................
    when 3
      cache = []
      #.....................................................................................................
      on_data = ( data ) ->
        # debug '©3w9', send, data
        if cache.length is 0
          cache[ 0 ] = data
          return
        send = get_send @ unless send?
        [ cache[ 0 ], data, ] = [ data, cache[ 0 ], ]
        method data, send, null
      #.....................................................................................................
      on_end = ->
        send  = get_send @ unless send?
        end   = => @emit 'end'
        if cache.length is 0
          data = null
        else
          data = cache[ 0 ]
          cache.length = 0
        method data, send, end
    #.......................................................................................................
    else
      throw new Error "expected a method with an arity of 2 or 3, got one with an arity of #{arity}"
  #.........................................................................................................
  return @ES.through on_data, on_end

#-----------------------------------------------------------------------------------------------------------
$ = @remit.bind @

#===========================================================================================================
# OMITTING VALUES
#-----------------------------------------------------------------------------------------------------------
@$skip_first = ( n = 1 ) ->
  count = 0
  return $ ( data, send ) ->
    count += +1
    send data if count > n


#===========================================================================================================
# SPECIALIZED STREAMS
#-----------------------------------------------------------------------------------------------------------
@create_throughstream = ( P... ) ->
  R = through2.obj P...
  R.setMaxListeners 0
  return R



#===========================================================================================================
# SORT AND SHUFFLE
#-----------------------------------------------------------------------------------------------------------
@$densort = ( key = 1, first_idx = 0, report_handler = null ) ->
  ds        = @new_densort key, first_idx, report_handler
  has_ended = no
  #.........................................................................................................
  send_data = ( send, data ) =>
  #.........................................................................................................
  signal_end = ( send ) =>
    send.end() unless has_ended
    has_ended = yes
  #.........................................................................................................
  return $ ( input_data, send, end ) =>
    #.......................................................................................................
    if input_data?
      ds input_data, ( error, output_data ) =>
        return send.error error if error?
        send output_data
    #.......................................................................................................
    if end?
      ds null, ( error, output_data ) =>
        return send.error error if error?
        if output_data? then  send output_data
        else                  signal_end send

#-----------------------------------------------------------------------------------------------------------
# @$shuffle =



#===========================================================================================================
# AGGREGATION & DISSEMINATION
#-----------------------------------------------------------------------------------------------------------
### TAINT all these functions should have an optional callback (that does not take an error and
should not be named 'handler'); with no callback, the aggregated data will be sent downstream; with a
callback, the orighinal data will be sent downstream, and the aggregate is the sole argument for the callback on
end-of-stream. ###
@$count = ( handler = null ) ->
  count = 0
  return $ ( data, send, end ) =>
    count += 1 if data?
    send data if handler?
    if end?
      if handler?
        handler count
      else
        send count
      end()

#-----------------------------------------------------------------------------------------------------------
@$collect = ( collector = null ) ->
  collector ?= []
  return $ ( event, send, end ) =>
    if event?
      collector.push event
    if end?
      send collector
      end()

#-----------------------------------------------------------------------------------------------------------
@$spread = ( settings ) ->
  indexed   = settings?[ 'indexed'  ] ? no
  end       = settings?[ 'end'      ] ? no
  return $ ( event, send ) =>
    unless type = ( CND.type_of event ) is 'list'
      return send.error new Error "expected a list, got a #{rpr type}"
    for value, idx in event
      send if indexed then [ idx, value, ] else value
    send null if end


#===========================================================================================================
# FILTERING
#-----------------------------------------------------------------------------------------------------------
@$filter = ( select ) ->
  return $ ( event, send ) =>
    send event if select event


#===========================================================================================================
# REPORTING
#-----------------------------------------------------------------------------------------------------------
@$show = ( badge = null ) ->
  my_show = CND.get_logger 'info', badge ? '*'
  return $ ( record, send ) =>
    my_show rpr record
    send record


#===========================================================================================================
# EXPERIMENTAL: STREAM LINKING
#-----------------------------------------------------------------------------------------------------------
@$continue = ( stream ) ->
  return $ ( data, send, end ) =>
    stream.write data
    if end?
      stream.end()
      end()








