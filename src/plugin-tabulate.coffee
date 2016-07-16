



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


###


┌───┬───┐
│   │   │
╞═══╪═══╡
│   │   │
├───┼───┤
│   │   │
└───┴───┘

  l   c   r     l   c   r
t ┌───┬───┐   t ╭───┬───╮
  │   │   │     │   │   │
m ├───┼───┤   m ├───┼───┤
  │   │   │     │   │   │
b └───┴───┘   b ╰───┴───╯

lt    ┌             ╭
ct    ┬             ┬
rt    ┐             ╮
lm    ├             ├
cm    ┼             ┼
rm    ┤             ┤
lb    └             ╰
cb    ┴             ┴
rb    ┘             ╯
hc    │             │
vc    ─             ─

settings =
  default:
    width:          <number>  ::                                              // 20
    alignment:      <text>    :: 'left' | 'right' | 'center' | 'justify'      // 'left'

  widths:         [ <number> | '*' ]
  alignments:     [ <text> ]
  titles:         [ <text> ]
  keys:           [ <text> | <number> ]

  width:          <number>  ::                                                // 108
  ellipsis:       <text>                                                      // '…'
  pad:            <number> | <text>                                           // ''


###


#-----------------------------------------------------------------------------------------------------------
@$show_table = ( settings ) ->
  throw new Error "not implemented"

#-----------------------------------------------------------------------------------------------------------
_new_state = ( settings ) ->
  S = {}
  ### TAINT better to use formal schema here? ###
  unless CND.is_subset ( keys = Object.keys settings ), keys_toplevel
    throw new Error "### MEH 1 ### #{rpr keys}"
  if settings[ 'default' ]?
    if CND.is_subset ( keys = Object.keys settings[ 'default' ] ), keys_default
      throw new Error "### MEH 2 ### #{rpr keys}"
  #.........................................................................................................
  if settings[ 'widths'      ]? then throw new Error "'widths' not yet supported"
  if settings[ 'alignments'  ]? then throw new Error "'alignments' not yet supported"
  #.........................................................................................................
  S.widths            = settings[ 'widths'      ] ? []
  S.alignments        = settings[ 'alignments'  ] ? []
  S.titles            = settings[ 'titles'      ] ? null
  S.keys              = settings[ 'keys'        ] ? null
  S.width             = settings[ 'width'       ] ? 108
  S.ellipsis          = settings[ 'ellipsis'    ] ? '…'
  S.pad               = settings[ 'pad'         ] ? ''
  #.........................................................................................................
  S.default           = {}
  S.default.width     = settings[ 'default' ]?[ 'width'     ] ? 20
  S.default.alignment = settings[ 'default' ]?[ 'alignment' ] ? 'left'
  #.........................................................................................................
  return S

#-----------------------------------------------------------------------------------------------------------
keys_toplevel = [ 'default', 'widths', 'alignments', 'titles', 'keys', 'width', 'ellipsis', 'pad', ]
keys_default  = [ 'width', 'alignment', ]

#-----------------------------------------------------------------------------------------------------------
@$tabulate = ( settings = {} ) ->
  debug '7233', _new_state settings
  settings     ?= {}
  S             = {}
  #.........................................................................................................
  unless CND.is_subset ( keys = Object.keys settings ), @$tabulate._keys
    expected  = ( rpr x for x in @$tabulate._keys                    ).join ', '
    got       = ( rpr x for x in keys when x not in @$tabulate._keys ).join ', '
    throw new Error "expected #{expected}, got #{got}"
  #.........................................................................................................
  S.width     = settings[ 'width'     ]  ? 20
  S.spacing   = settings[ 'spacing'   ]  ? 'wide'
  S.columns   = settings[ 'columns'   ]  ? null
  #.........................................................................................................
  switch S.spacing
    when 'wide'
      S._left     =  '│ '
      S._mid      = ' │ '
      S._right    = ' │'
    when 'tight'
      S._left     = '│'
      S._mid      = '│'
      S._right    = '│'
    else throw new Error "expected 'tight' or 'wide', got #{rpr S.spacing} "
  #.........................................................................................................
  S._slice    = null
  S._titles   = null
  #.........................................................................................................
  switch type = CND.type_of S.columns
    when 'null'
      null
    when 'number'
      S._slice  = S.columns
      S.columns = null
    else throw new Error "type #{type} not implemented for settings 'columns'"
  #.........................................................................................................
  S.widths  = null
  S.keys    = null
  S.titles  = null
  pipeline  = []
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
@$tabulate._keys = [ 'spacing', 'width', 'columns', ]

#-----------------------------------------------------------------------------------------------------------
$as_event = ( S ) -> $ ( data, send ) -> send [ 'data', data, ]

#-----------------------------------------------------------------------------------------------------------
as_text = ( x ) -> if ( CND.isa_text x ) then x else rpr x

#-----------------------------------------------------------------------------------------------------------
$read_parameters = ( S ) ->
  return D.$on_first ( event, send ) ->
    [ mark, data, ] = event
    send event
    return unless mark is 'data'
    send [ 'table', '', ]
    #...................................................................................................
    unless S.keys?
      switch type_of_data = CND.type_of data
        when 'list'
          S.keys    = ( idx for _, idx in data )
        when 'pod'
          S.keys    = ( key for key of data )
          S.titles ?= S.keys
        else
          return send.error new Error "expected a list or a POD, got a #{type_of_data}"
      if S._slice?
        S.keys.length   = S._slice
    #...................................................................................................
    unless widths?
      widths = ( S.width for key in S.keys )
    #...................................................................................................
    if S.titles?
      S.titles.length = S._slice if S._slice?
      send [ 'table', as_row S, S.titles ]
    #...................................................................................................
    send [ 'table', '│──────────────────────│──────────────────────│',  ]

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
    send [ 'table', '│──────────────────────│──────────────────────│',  ]
    send [ 'table', '',                                                 ]

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

