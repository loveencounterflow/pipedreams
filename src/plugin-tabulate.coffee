



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/PLUGIN-TABULATE'
# log                       = CND.get_logger 'plain',     badge
# info                      = CND.get_logger 'info',      badge
# whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
# echo                      = CND.echo.bind CND


#-----------------------------------------------------------------------------------------------------------
@$show_table = ( settings ) ->
  throw new Error "not implemented"

#-----------------------------------------------------------------------------------------------------------
@$tabulate = ( settings ) ->
  { to_width }  = require 'to-width'
  settings     ?= {}
  #.........................................................................................................
  unless CND.is_subset ( keys = Object.keys settings ), @$tabulate._keys
    expected  = ( rpr x for x in @$tabulate._keys                    ).join ', '
    got       = ( rpr x for x in keys when x not in @$tabulate._keys ).join ', '
    throw new Error "expected #{expected}, got #{got}"
  #.........................................................................................................
  settings[ 'width'     ]  ?= 20
  settings[ 'spacing'   ]  ?= 'wide'
  settings[ 'columns'   ]  ?= null
  #.........................................................................................................
  switch settings[ 'spacing' ]
    when 'wide'
      settings[ '_left'   ] =  '│ '
      settings[ '_mid'    ] = ' │ '
      settings[ '_right'  ] = ' │'
    when 'tight'
      settings[ '_left'   ] = '│'
      settings[ '_mid'    ] = '│'
      settings[ '_right'  ] = '│'
    else throw new Error "expected 'tight' or 'wide', got #{rpr settings[ 'spacing' ]} "
  #.........................................................................................................
  settings[ '_slice'  ] = null
  settings[ '_titles' ] = null
  #.........................................................................................................
  switch type = CND.type_of settings[ 'columns' ]
    when 'null'
      null
    when 'number'
      settings[ '_slice' ]  = settings[ 'columns' ]
      settings[ 'columns' ] = null
    else throw new Error "type #{type} not implemented for settings 'columns'"
  #.........................................................................................................
  widths    = null
  keys      = null
  titles    = null
  as_text   = ( x ) => if ( CND.isa_text x ) then x else rpr x
  pipeline  = []
  is_first  = yes
  #.........................................................................................................
  as_row = ( data, keys = null ) =>
    R = []
    if keys?
      for key, idx in keys
        R.push to_width ( as_text data[ key ] ), widths?[ idx ] ? settings[ 'width' ]
    else
      for idx in [ 0 ... data.length ]
        R.push to_width ( as_text data[ idx ] ), widths?[ idx ] ? settings[ 'width' ]
    R = R.join settings[ '_mid' ]
    #.......................................................................................................
    return settings[ '_left' ] + R + settings[ '_right' ]
  #.........................................................................................................
  $as_event = => @$ ( data, send ) =>
    # debug '4456', rpr data
    send [ 'data', data, ]
  #.........................................................................................................
  $read_parameters = => @$on_first ( event, send ) =>
    [ mark, data, ] = event
    send event
    return unless mark is 'data'
    send [ 'table', '', ]
    #...................................................................................................
    unless keys?
      switch type_of_data = CND.type_of data
        when 'list'
          keys    = ( idx for _, idx in data )
        when 'pod'
          keys    = ( key for key of data )
          titles ?= keys
        else
          return send.error new Error "expected a list or a POD, got a #{type_of_data}"
      if settings[ '_slice' ]?
        keys.length = settings[ '_slice' ]
    #...................................................................................................
    unless widths?
      widths = ( settings[ 'width' ] for key in keys )
    #...................................................................................................
    if titles?
      send [ 'table', as_row titles ]
    #...................................................................................................
    send [ 'table', '│──────────────────────│──────────────────────│',  ]
  #.........................................................................................................
  $as_row = => @$ ( event, send ) =>
    [ mark, data, ] = event
    return send [ 'table', as_row data, keys ] if mark is 'data'
    send event
  #.........................................................................................................
  $finalize = => @$on_stop ( send ) =>
    send [ 'table', '│──────────────────────│──────────────────────│',  ]
    send [ 'table', '',                                                 ]
  #.........................................................................................................
  $cleanup = => @$ ( event, send ) =>
    [ mark, data, ] = event
    send data if mark is 'table'
    return null
  #.........................................................................................................
  pipeline = [
    $as_event()
    $read_parameters()
    $as_row()
    $finalize()
    $cleanup()
    ]
  #.........................................................................................................
  return @new_stream { pipeline, }


#-----------------------------------------------------------------------------------------------------------
@$tabulate._keys = [ 'spacing', 'width', 'columns', ]


############################################################################################################
do ( self = @ ) ->
  D = require './main'
  for name, value of self
    D[ name ] = value
