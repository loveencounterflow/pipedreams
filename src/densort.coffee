


############################################################################################################
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'PIPEDREAMS2/densort'
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
# ### https://github.com/rvagg/through2 ###
# through2                  = require 'through2'
# #...........................................................................................................
# BNP                       = require 'coffeenode-bitsnpieces'
TYPES                     = require 'coffeenode-types'



#-----------------------------------------------------------------------------------------------------------
@new_densort = ( getter = 1, first_idx = 0, report_handler = null ) ->
  ### Given up to three arguments—a `getter`, a `first_idx`, and a `report_handler`—return a function
  `densort = ( element, handler ) ->` that in turn accepts a series of indexed elements and a callback
  function which it will be called once for each element and in the order of the element indices.

  The `densort` function should be called one for each element; each element should be an object or
  primitive value. In case `getter` is not callable, then indices will be retrieved as `element[ getter ]`
  (`getter` defaulting to `1`, because i often send 'event' lists similar to `[ type, idx, payload... ]` down
  the stream); in case `getter` is a function, indices will be retrieved as `getter element`. When the series
  of elements has ended, `densort` should be called once more with a `null` value to signal this.

  The `handler` argument to `densort` should be a NodeJS-style callback function, i.e. it should accept
  two arguments, `error` and `element`; it is sort of symmetric to `densort` as it will be called once
  as `handler null, element` for each element and once as `handler null, null` to signal exhaustion of the
  series.


  ###
  #.........................................................................................................
  getter_is_function  = TYPES.isa_function getter
  buffer              = []
  buffer_size         = 0             # Amount of buffered items
  previous_idx        = first_idx - 1 # Index of most recently sent item
  smallest_idx        = Infinity      # Index of first item in buffer
  min_legal_idx       = 0             # 'Backlog' of the range of indexes that have already been sent out
  max_buffer_size     = 0
  element_count       = 0
  sent_count          = 0
  #.........................................................................................................
  if report_handler is true
    report_handler = ( [ event_count, max_buffer_size, ] ) ->
      percentage = (     max_buffer_size / event_count * 100  ).toFixed 2
      efficiency = ( 1 - max_buffer_size / event_count        ).toFixed 2
      info """\nPipeDreams DenSort:
        of #{event_count} elements, up to #{max_buffer_size} (#{percentage}%) had to be buffered;
        efficiency: #{efficiency}"""
  #.........................................................................................................
  buffer_element = ( idx, element, handler ) =>
    return handler new Error "duplicate index #{rpr idx}" if buffer[ idx ]?
    smallest_idx  = Math.min smallest_idx, idx
    # debug '<---', smallest_idx
    buffer[ idx ] = element
    buffer_size  += +1
    return null
  #.........................................................................................................
  send_buffered_elements = ( handler ) =>
    ### Refuse to send anything unless all elements with smaller indexes have already been sent: ###
    return if sent_count < ( smallest_idx - first_idx )
    loop
      ### Terminate loop in case nothing is in the buffer or we have reached an empty position: ###
      if buffer_size < 1 or not ( element = buffer[ smallest_idx ] )?
        # smallest_idx    = Infinity if buffer_size < 1
        min_legal_idx   = Math.max min_legal_idx, smallest_idx
        break
      #.....................................................................................................
      ### Remove element to be sent from buffer (making it a sparse list in most cases), adjust sentinels and
      send element: ###
      delete buffer[ smallest_idx ]
      previous_idx    = smallest_idx
      max_buffer_size = Math.max max_buffer_size, buffer_size
      smallest_idx   += +1
      buffer_size    += -1
      sent_count     += +1
      min_legal_idx   = Math.max min_legal_idx, smallest_idx
      handler null, element
  #.........................................................................................................
  return ( element, handler ) =>
    #.......................................................................................................
    if element?
      element_count += +1
      idx            = if getter_is_function then getter element else element[ getter ]
      return handler new Error "index too small: #{rpr idx}" if idx < first_idx
      return handler new Error "duplicate index: #{rpr idx}" if idx < min_legal_idx
      #.....................................................................................................
      if buffer_size is 0 and idx is previous_idx + 1
        previous_idx    = idx
        min_legal_idx   = idx + 1
        sent_count     += +1
        smallest_idx    = Infinity if buffer_size < 1
        handler null, element
      #.....................................................................................................
      else
        buffer_element idx, element, handler
        send_buffered_elements handler
    #.......................................................................................................
    else
      send_buffered_elements handler
      return handler new Error "detected missing elements" if buffer_size > 0
      report_handler [ element_count, max_buffer_size, ] if report_handler?
      handler null, null



