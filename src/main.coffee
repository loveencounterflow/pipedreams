

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
#...........................................................................................................
PIPEDREAMS                = @


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
  return @ES.through on_data, on_end

# #-----------------------------------------------------------------------------------------------------------
# @remit = ( method ) ->
#   send      = null
#   cache     = null
#   on_end    = null
#   #.........................................................................................................
#   get_send = ( self ) ->
#     R             = (  data ) -> self.emit 'data',  data # if data?
#     R.error       = ( error ) -> self.emit 'error', error
#     R.end         =           -> self.emit 'end'
#     R.pause       =           -> self.pause()
#     R.resume      =           -> self.resume()
#     R.read        =           -> self.read()
#     R[ '%self' ]  = self
#     return R
#   #.........................................................................................................
#   switch arity = method.length
#     #.......................................................................................................
#     when 2
#       #.....................................................................................................
#       on_data = ( data ) ->
#         # debug '©3w9', send
#         send = get_send @ unless send?
#         method data, send
#     #.......................................................................................................
#     when 3
#       cache = []
#       #.....................................................................................................
#       on_data = ( data ) ->
#         # debug '©3w9', send, data
#         if cache.length is 0
#           cache[ 0 ] = data
#           return
#         send = get_send @ unless send?
#         [ cache[ 0 ], data, ] = [ data, cache[ 0 ], ]
#         method data, send, null
#       #.....................................................................................................
#       on_end = ->
#         send  = get_send @ unless send?
#         end   = => @emit 'end'
#         if cache.length is 0
#           data = null
#         else
#           data = cache[ 0 ]
#           cache.length = 0
#         method data, send, end
#     #.......................................................................................................
#     else
#       throw new Error "expected a method with an arity of 2 or 3, got one with an arity of #{arity}"
#   #.........................................................................................................
#   return @ES.through on_data, on_end

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
  return @ES.through on_data, on_end

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
# EXPERIMENTAL: STREAM LINKING
#-----------------------------------------------------------------------------------------------------------
@$continue = ( stream ) ->
  return $ ( data, send, end ) =>
    stream.write data
    if end?
      stream.end()
      end()



#===========================================================================================================
# HYPHENATION
#-----------------------------------------------------------------------------------------------------------
@new_hyphenator = ( hyphenation = null, min_length = 4 ) ->
  ### https://github.com/bramstein/hypher ###
  Hypher        = require 'hypher'
  hyphenation  ?= require 'hyphenation.en-us'
  HYPHER        = new Hypher hyphenation
  return HYPHER.hyphenateText.bind HYPHER

#-----------------------------------------------------------------------------------------------------------
@$hyphenate = ( hyphenation = null, min_length = 4 ) ->
  hyphenate = @new_hyphenator hyphenation, min_length
  return $ ( text, send ) => send hyphenate text, min_length


#===========================================================================================================
# EXPERIMENTAL: STREAM LINKING
#-----------------------------------------------------------------------------------------------------------
@HTML = {}

#-----------------------------------------------------------------------------------------------------------
@HTML._new_parser = ( settings, stream ) ->
  ### NB.: Will not send empty text nodes; will not join ('normalize') adjacent text nodes. ###
  lone_tags = """area base br col command embed hr img input keygen link meta param
    source track wbr""".split /\s+/
  #.........................................................................................................
  handlers =
    #.......................................................................................................
    onopentag:  ( name, attributes )  ->
      if name in lone_tags
        if name is 'wbr'
          throw new Error "illegal <wbr> tag with attributes" if ( Object.keys attributes ).length > 0
          ### as per https://developer.mozilla.org/en/docs/Web/HTML/Element/wbr ###
          stream.write [ 'text', '\u200b' ]
        else
          stream.write [ 'lone-tag', name, attributes, ]
      else
        stream.write [ 'open-tag', name, attributes, ]
    #.......................................................................................................
    onclosetag: ( name ) ->
      unless name in lone_tags
        stream.write [ 'close-tag', name, ]
    #.......................................................................................................
    ontext: ( text ) ->
      stream.write [ 'text', text, ]
    #.......................................................................................................
    onend: ->
      stream.write [ 'end', ]; stream.end()
    #.......................................................................................................
    onerror: ( error ) ->
      throw error
  #.........................................................................................................
  Htmlparser = ( require 'htmlparser2' ).Parser
  return new Htmlparser handlers, settings

#-----------------------------------------------------------------------------------------------------------
@HTML.$parse = ->
  settings    = decodeEntities: yes
  stream      = PIPEDREAMS.create_throughstream()
  html_parser = @_new_parser settings, stream
  _send       = null
  #.........................................................................................................
  stream.on 'data', ( data ) -> _send data
  stream.on 'end',           -> _send.end()
  #.........................................................................................................
  return $ ( source, send, end ) =>
    _send = send
    if source?
      html_parser.write source
    if end?
      html_parser.end()

#-----------------------------------------------------------------------------------------------------------
@HTML.$collect_closing_tags = ->
  ### Keeps trace of all opened tags and adds a list to each event that speels out the names of tags to be
  closed at that point; that list anticipates all the `close-tag` events that are due to arrive later in the
  stream. ###
  pending_tag_buffer = []
  #.........................................................................................................
  return $ ( event, send ) ->
    # debug '©LTGTp', event
    [ type, tail..., ] = event
    if type is 'open-tag'
      pending_tag_buffer.unshift tail[ 0 ][ 0 ]
    else if type is 'close-tag'
      pending_tag_buffer.shift()
    unless type is 'end'
      event.push pending_tag_buffer[ .. ]
    send event

#-----------------------------------------------------------------------------------------------------------
@HTML.$collect_texts = ->
  text_buffer = []
  _send       = null
  #.........................................................................................................
  send_buffer = ->
    if text_buffer.length > 0
      _send [ 'text', text_buffer.join '', ]
      text_buffer.length = 0
  #.........................................................................................................
  return $ ( event, send ) ->
    _send               = send
    [ type, tail..., ]  = event
    if type is 'text'
      text_buffer.push tail[ 0 ]
    else
      send_buffer()
      send event

#-----------------------------------------------------------------------------------------------------------
@HTML.$collect_empty_tags = ->
  ### Detects situations where an openening tag is directly followed by a closing tag, such as in `foo
  <span class='x'></span> bar`, and turns such occurrances into single `empty-tag` events to simplifiy
  further processing. ###
  last_event = null
  #.........................................................................................................
  return $ ( event, send ) ->
    [ type, tail..., ] = event
    if type is 'open-tag'
      send last_event if last_event?
      last_event = event
      return
    if type is 'close-tag' and last_event?
      send [ 'empty-tag', last_event[ 1 .. ]..., ]
      last_event = null
      return
    if last_event?
      send last_event
      last_event = null
    send event



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
  emit    = ->
    if ( data = buffer[ idx ] ) isnt undefined
      buffer[ idx ] = undefined
      idx   += +1
      count += -1
      _send data
    #.......................................................................................................
    if has_ended and count < 1
      clearInterval timer
      buffer = _send = timer = null # necessary?
      _send.end()
    #.......................................................................................................
    return null
  #.........................................................................................................
  start   = ->
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








