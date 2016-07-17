



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
#...........................................................................................................
D                         = require './main'
{ $, $async, }            = D
{ to_width }              = require 'to-width'



#-----------------------------------------------------------------------------------------------------------
@$tabulate = ( settings = {} ) ->
  S = _new_state settings
  debug '4404', S
  #.........................................................................................................
  pipeline = [
    $as_event           S
    $read_parameters    S
    $as_row             S
    $finalize           S
    $cleanup            S
    ]
  #.........................................................................................................
  return @new_stream { pipeline, }

#-----------------------------------------------------------------------------------------------------------
@$show_table = ( settings ) ->
  throw new Error "not implemented"

#-----------------------------------------------------------------------------------------------------------
_new_state = ( settings ) ->
  S = {}
  ### TAINT better to use formal schema here? ###
  #.........................................................................................................
  unless CND.is_subset ( keys = Object.keys settings ), keys_toplevel
    throw new Error "### MEH 1 ### #{rpr keys}"
  #.........................................................................................................
  if settings[ 'default' ]?
    if CND.is_subset ( keys = Object.keys settings[ 'default' ] ), keys_default
      throw new Error "### MEH 2 ### #{rpr keys}"
  #.........................................................................................................
  if settings[ 'widths'      ]? then throw new Error "'widths' not yet supported"
  if settings[ 'alignments'  ]? then throw new Error "'alignments' not yet supported"
  #.........................................................................................................
  S.width             = settings[ 'width'       ] ? 12
  S.alignment         = settings[ 'alignment'   ] ? 'left'
  ###
  process.stdout.columns
  ###
  S.fit               = settings[ 'fit'         ] ? null
  S.ellipsis          = settings[ 'ellipsis'    ] ? '…'
  S.pad               = settings[ 'pad'         ] ? ''
  S.overflow          = settings[ 'overflow'    ] ? 'show'
  #.........................................................................................................
  S.widths            = settings[ 'widths'      ] ? []
  S.alignments        = settings[ 'alignments'  ] ? []
  S.headings          = settings[ 'headings'    ] ? yes
  S.keys              = settings[ 'keys'        ] ? null
  #.........................................................................................................
  unless S.alignment in values_alignment
    throw new Error "### MEH 3 ### #{rpr S.alignment}"
  #.........................................................................................................
  unless S.overflow in values_overflow
    throw new Error "### MEH 4 ### #{rpr S.overflow}"
  #.........................................................................................................
  if S.fit?
    throw new Error "setting `fit` not yet implemented"
  #.........................................................................................................
  ### TAINT check widths are non-zero integers ###
  ### TAINT check values in headings, widths, keys (?) ###
  #.........................................................................................................
  return S

###
  #.........................................................................................................
  unless CND.is_subset ( keys = Object.keys settings ), @$tabulate._keys
    expected  = ( rpr x for x in @$tabulate._keys                    ).join ', '
    got       = ( rpr x for x in keys when x not in @$tabulate._keys ).join ', '
    throw new Error "expected #{expected}, got #{got}"

  switch S.spacing
    when 'wide'
      S._left     =  '│ '
      S._mid      = ' │ '
      S._right    = ' │'
    when 'tight'
      S._left     = '│'
      S._mid      = '│'
      S._right    = '│'

###

#-----------------------------------------------------------------------------------------------------------
keys_toplevel     = [ 'default', 'widths', 'alignments', 'headings', 'keys', 'width', 'ellipsis', 'pad', ]
keys_default      = [ 'width', 'alignment', ]
values_overflow   = [ 'show',  'hide', ]
values_alignment  = [ 'left',  'right', 'center', 'justify', ]

#-----------------------------------------------------------------------------------------------------------
$as_event = ( S ) -> $ ( data, send ) -> send [ 'data', data, ]
as_text   = ( x ) -> if ( CND.isa_text x ) then x else rpr x

#-----------------------------------------------------------------------------------------------------------
$read_parameters = ( S ) ->
  return D.$on_first ( event, send ) ->
    [ mark, data, ] = event
    send event
    return unless mark is 'data'
    # send [ 'table', '', ]
    #...................................................................................................
    unless S.keys?
      if      CND.isa_list data then S.keys = ( idx for _, idx in data )
      else if CND.isa_pod data  then S.keys = ( key for key of data )
      else return send.error new Error "expected a list or a POD, got a #{CND.type_of data}"
    S.headings = S.keys if S.headings is true
    #...................................................................................................
    if S.widths? then S.widths[ idx ] ?= S.width for idx in [ 0 ... S.widths.length ]
    else              S.widths = ( S.width for key in S.keys )
    #...................................................................................................
    unless S.headings in [ null, false, ]
      send [ 'table', as_row S, S.headings ]
    #...................................................................................................
    # send [ 'table', '│──────────────────────│──────────────────────│',  ]

#-----------------------------------------------------------------------------------------------------------
as_row = ( S, data, keys = null ) =>
  R = []
  if keys?
    for key, idx in keys
      R.push to_width ( as_text data[ key ] ), S.widths?[ idx ] ? S.width
  else
    for idx in [ 0 ... data.length ]
      R.push to_width ( as_text data[ idx ] ), S.widths?[ idx ] ? S.width
  #.......................................................................................................
  return S._left + ( R.join S._mid ) + S._right

#-----------------------------------------------------------------------------------------------------------
$as_row = ( S ) ->
  return $ ( event, send ) ->
    [ mark, data, ] = event
    return send [ 'table', as_row S, data, S.keys ] if mark is 'data'
    send event

#-----------------------------------------------------------------------------------------------------------
$finalize = ( S ) ->
  return D.$on_stop ( send ) ->
    # send [ 'table', '│──────────────────────│──────────────────────│',  ]
    # send [ 'table', '',                                                 ]

#-----------------------------------------------------------------------------------------------------------
$cleanup = ( S ) ->
  return $ ( event, send ) ->
    [ mark, data, ] = event
    send data if mark is 'table'
    return null


############################################################################################################
do ( self = @ ) ->
  D = require './main'
  for name, value of self
    D[ name ] = value

