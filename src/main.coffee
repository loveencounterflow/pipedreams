

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
### https://github.com/dominictarr/event-stream ###
ES                        = require 'event-stream'
#...........................................................................................................
### https://github.com/dominictarr/sort-stream ###
@$sort                    = require 'sort-stream'
#...........................................................................................................
@new_densort              = ( DS = require './densort' ).new_densort.bind DS
PIPEDREAMS                = @
LODASH                    = CND.LODASH
@HOTMETAL                 = require 'hotmetal'



#===========================================================================================================
# GENERIC METHODS
#-----------------------------------------------------------------------------------------------------------
# @create_readstream            = HELPERS.create_readstream             .bind HELPERS
# @create_readstream_from_text  = HELPERS.create_readstream_from_text   .bind HELPERS
# @pimp_readstream              = HELPERS.pimp_readstream               .bind HELPERS
# @merge                        = ES.merge                              .bind ES
@$split                       = ES.split                              .bind ES
# @$chain                       = ES.pipeline                           .bind ES
# @through                      = ES.through                            .bind ES
# @duplex                       = ES.duplex                             .bind ES
# @as_readable                  = ES.readable                           .bind ES
# @read_list                    = ES.readArray                          .bind ES


#===========================================================================================================
# REMIT
#-----------------------------------------------------------------------------------------------------------
@remit = ( method ) ->
  send      = null
  on_end    = null
  #.........................................................................................................
  get_send = ( self ) ->
    R             = (  data ) -> self.emit 'data',  data # if data?
    R.error       = ( error ) -> self.emit 'error', error
    R.end         =           -> self.emit 'end'
    R.pause       =           -> self.pause()
    R.resume      =           -> self.resume()
    R.read        =           -> self.read()
    # R[ '%self' ]  = self
    R.stream      = self
    return R
  #.....................................................................................................
  on_data = ( data ) ->
    send = get_send @ unless send?
    method data, send
  #.........................................................................................................
  switch arity = method.length
    when 2
      null
    #.......................................................................................................
    when 3
      on_end = ->
        send  = get_send @ unless send?
        end   = => @emit 'end'
        method undefined, send, end
    #.......................................................................................................
    else
      throw new Error "expected a method with an arity of 2 or 3, got one with an arity of #{arity}"
  #.........................................................................................................
  return ES.through on_data, on_end

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
# SUB-STREAMS
#-----------------------------------------------------------------------------------------------------------
@$sub = ( sub_transformer ) ->
  #.........................................................................................................
  _send   = null
  _end    = null
  cache   = undefined
  #.........................................................................................................
  source        = @create_throughstream()
  sink          = @create_throughstream()
  state         = {}
  source.ended  = false
  sub_transformer source, sink, state
  #.........................................................................................................
  sink.on   'data', ( data )  => _send data
  sink.on   'end',            => _send.end()
  #.........................................................................................................
  return $ ( data, send, end ) =>
    if data?
      _send = send
      if cache is undefined
        cache = data
      else
        source.write cache
        cache = data
    if end?
      source.ended = true
      source.write cache unless cache is undefined


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
@$aggregate = ( aggregator, on_end = null ) ->
  Z = null
  return $ ( data, send, end ) =>
    if data?
      Z = aggregator data
      send data if on_end?
    if end?
      if on_end? then on_end Z
      else            send   Z
      end()

#-----------------------------------------------------------------------------------------------------------
@$count = ( on_end = null ) ->
  count = 0
  return @$aggregate ( -> count += +1 ), on_end

#-----------------------------------------------------------------------------------------------------------
@$collect = ( on_end = null ) ->
  collector = []
  aggregator = ( data ) ->
    collector.push data
    return collector
  return @$aggregate aggregator, on_end

#-----------------------------------------------------------------------------------------------------------
@$spread = ( settings ) ->
  indexed   = settings?[ 'indexed'  ] ? no
  end       = settings?[ 'end'      ] ? no
  return $ ( data, send ) =>
    unless type = ( CND.type_of data ) is 'list'
      return send.error new Error "expected a list, got a #{rpr type}"
    for value, idx in data
      send if indexed then [ idx, value, ] else value
    send null if end


#===========================================================================================================
# STREAM START & END DETECTION
#-----------------------------------------------------------------------------------------------------------
@$signal_end = ( signal = @eos ) ->
  ### Given an optional `signal` (which defaults to `null`), return a stream transformer that emits
  `signal` as last value in the stream. Observe that whatever value you choose for `signal`, that value
  should be gracefully handled by any transformers that follow in the pipe. ###
  on_data = null
  on_end  = ->
    @emit 'data', signal
    @emit 'end'
  return ES.through on_data, on_end

#-----------------------------------------------------------------------------------------------------------
@$on_end = ( method ) ->
  return $ ( data, send, end ) ->
    send data if data?
    if end?
      method send, end

#-----------------------------------------------------------------------------------------------------------
@$on_start = ( method ) ->
  is_first = yes
  return $ ( data, send ) ->
    method send if is_first
    is_first = no
    send data


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
# EXPERIMENTAL: STREAM LINKING, CONCATENATING
#-----------------------------------------------------------------------------------------------------------
@$continue = ( stream ) ->
  return $ ( data, send, end ) =>
    stream.write data
    if end?
      stream.end()
      end()


#-----------------------------------------------------------------------------------------------------------
@$link = ( transforms... ) ->
  return @create_throughstream() if transforms.length is 0
  source  = sink = @create_throughstream()
  sink    = sink.pipe transform for transform in LODASH.flatten transforms
  _send   = null
  sink.on 'data', ( data ) => _send data
  return $ ( data, send ) =>
    _send = send
    source.write data


#===========================================================================================================
# HYPHENATION
#-----------------------------------------------------------------------------------------------------------
@$hyphenate = ( hyphenation = null, min_length = 4 ) ->
  hyphenate = @HOTMETAL.new_hyphenate hyphenation, min_length
  return $ ( text, send ) => send hyphenate text, min_length


#===========================================================================================================
# UNICODE LINE BREAKING
#-----------------------------------------------------------------------------------------------------------
@$break_lines = ( settings ) ->
  #.........................................................................................................
  return $ ( text, send ) =>
    send @HOTMETAL.break_lines text, settings


#===========================================================================================================
# TYPOGRAPHIC ENHANCEMENTS
#-----------------------------------------------------------------------------------------------------------
@TYPO = {}

#-----------------------------------------------------------------------------------------------------------
@TYPO.$quotes = ->
  return $ ( text, send ) => send PIPEDREAMS.HOTMETAL.TYPO.quotes text

#-----------------------------------------------------------------------------------------------------------
@TYPO.$dashes = ->
  return $ ( text, send ) => send PIPEDREAMS.HOTMETAL.TYPO.dashes text


#===========================================================================================================
# MARKDOWN
#-----------------------------------------------------------------------------------------------------------
@MD = {}

#-----------------------------------------------------------------------------------------------------------
@MD.$as_html = ->
  parser = PIPEDREAMS.HOTMETAL.MD.new_parser()
  #.........................................................................................................
  return $ ( md, send ) =>
    send PIPEDREAMS.HOTMETAL.MD.as_html md, parser


#===========================================================================================================
# HTML
#-----------------------------------------------------------------------------------------------------------
@HTML = {}

#---------------------------------------------------------------------------------------------------------
@HTML.$parse = ( disperse = yes, hyphenation = yes ) ->
  return $ ( html, send ) =>
    send PIPEDREAMS.HOTMETAL.HTML.parse html, disperse, hyphenation

#-----------------------------------------------------------------------------------------------------------
@HTML.$slice_toplevel_tags = ->
  return $ ( me, send ) =>
    PIPEDREAMS.HOTMETAL.slice_toplevel_tags me, ( error, slice ) =>
      return send.error error if error?
      send slice

#-----------------------------------------------------------------------------------------------------------
@HTML.$unwrap = ( silent = no) ->
  return $ ( me, send ) =>
    send PIPEDREAMS.HOTMETAL.unwrap me, silent



#===========================================================================================================
# THROUGHPUT LIMITING
#-----------------------------------------------------------------------------------------------------------
@$throttle_bytes = ( bytes_per_second ) ->
  Throttle = require 'throttle'
  return new Throttle bytes_per_second

#-----------------------------------------------------------------------------------------------------------
@$throttle_items = ( items_per_second ) ->
  buffer    = []
  count     = 0
  idx       = 0
  _send     = null
  timer     = null
  has_ended = no
  #.........................................................................................................
  emit = ->
    if ( data = buffer[ idx ] ) isnt undefined
      buffer[ idx ] = undefined
      idx   += +1
      count += -1
      _send data
    #.......................................................................................................
    if has_ended and count < 1
      clearInterval timer
      _send.end()
      buffer = _send = timer = null # necessary?
    #.......................................................................................................
    return null
  #.........................................................................................................
  start = ->
    timer = setInterval emit, 1 / items_per_second * 1000
  #---------------------------------------------------------------------------------------------------------
  return $ ( data, send, end ) =>
    if data?
      unless _send?
        _send = send
        start()
      buffer.push data
      count += +1
    #.......................................................................................................
    if end?
      has_ended = yes







