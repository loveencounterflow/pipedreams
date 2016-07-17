



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
{ to_width, width_of, }   = require 'to-width'



#-----------------------------------------------------------------------------------------------------------
@$tabulate = ( settings = {} ) ->
  urge '4404', settings
  S = _new_state settings
  #.........................................................................................................
  pipeline = [
    $as_event           S
    $set_widths_etc     S
    $dividers           S
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
  # if settings[ 'widths'      ]? then throw new Error "'widths' not yet supported"
  if settings[ 'alignments'  ]? then throw new Error "'alignments' not yet supported"
  #.........................................................................................................
  S.width             =       settings[ 'width'       ] ? 12
  S.alignment         =       settings[ 'alignment'   ] ? 'left'
  ###
  process.stdout.columns
  ###
  S.fit               =       settings[ 'fit'         ] ? null
  S.ellipsis          =       settings[ 'ellipsis'    ] ? '…'
  S.pad               =       settings[ 'pad'         ] ? ''
  S.overflow          =       settings[ 'overflow'    ] ? 'show'
  #.........................................................................................................
  S.widths            = copy  settings[ 'widths'      ] ? []
  S.alignments        =       settings[ 'alignments'  ] ? []
  S.headings          =       settings[ 'headings'    ] ? yes
  S.keys              =       settings[ 'keys'        ] ? null
  S.box               = copy  settings[ 'box'         ] ? copy boxes[ 'plain' ]
  #.........................................................................................................
  S.box               = box_style = boxes[ S.box ] if CND.isa_text S.box
  throw new Error "unknown box style #{rpr box_style}" unless S.box?
  #.........................................................................................................
  S.box.left          =         S.box.vs + S.pad
  S.box.center        = S.pad + S.box.vs + S.pad
  S.box.right         = S.pad + S.box.vs
  S.box.left_width    = width_of S.box.left
  S.box.center_width  = width_of S.box.center
  S.box.right_width   = width_of S.box.right
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
###

#-----------------------------------------------------------------------------------------------------------
keys_toplevel     = [ 'default', 'widths', 'alignments', 'headings', 'keys', 'width', 'ellipsis', 'pad', ]
keys_default      = [ 'width', 'alignment', ]
values_overflow   = [ 'show',  'hide', ]
values_alignment  = [ 'left',  'right', 'center', 'justify', ]

#-----------------------------------------------------------------------------------------------------------
$set_widths_etc = ( S ) ->
  return D.$on_first ( event, send ) ->
    [ mark, data, ] = event
    return send event unless mark is 'data'
    #...................................................................................................
    unless S.keys?
      if      CND.isa_list data then S.keys = ( idx for _, idx in data )
      else if CND.isa_pod data  then S.keys = ( key for key of data )
      else return send.error new Error "expected a list or a POD, got a #{CND.type_of data}"
    S.headings = S.keys if S.headings is true
    #...................................................................................................
    if S.widths? then S.widths[ idx ]  ?= S.width for idx in [ 0 ... S.keys.length ]
    else              S.widths          = ( S.width for key in S.keys )
    #...................................................................................................
    return null

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
  return S.box.left + ( R.join S.box.center ) + S.box.right

#-----------------------------------------------------------------------------------------------------------
$as_row = ( S ) ->
  return $ ( event, send ) ->
    [ mark, data, ] = event
    row             = as_row S, data, S.keys
    return send [ 'table', row, ] if mark is 'data'
    send event

#-----------------------------------------------------------------------------------------------------------
get_divider = ( S, position ) ->
  switch position
    when 'top'
      left    = S.box.lt
      center  = S.box.ct
      right   = S.box.rt
    when 'heading'
      left    = S.box.lm
      center  = S.box.cm
      right   = S.box.rm
    when 'mid'
      left    = S.box.lm
      center  = S.box.cm
      right   = S.box.rm
    when 'bottom'
      left    = S.box.lb
      center  = S.box.cb
      right   = S.box.rb
    else throw new Error "unknown position #{rpr position}"
  #.........................................................................................................
  last_idx  = S.widths.length - 1
  R         = []
  #.........................................................................................................
  ### TAINT simplified calculation; assumes single-width glyphs and symmetric padding etc. ###
  for width, idx in S.widths
    column = []
    if idx is 0
      column.push left
      count = ( S.box.left_width - 1 )           + width + ( ( S.box.center_width - 1 ) / 2 )
    else if idx is last_idx
      column.push center
      count = ( ( S.box.center_width - 1 ) / 2 ) + width + ( S.box.right_width - 1 )
    else
      column.push center
      count = ( ( S.box.center_width - 1 ) / 2 ) + width + ( ( S.box.center_width - 1 ) / 2 )
    column.push S.box.hs.repeat count
    column.push right if idx is last_idx
    R.push column.join ''
  #.........................................................................................................
  return R.join ''

#-----------------------------------------------------------------------------------------------------------
$dividers = ( S ) ->
  #.........................................................................................................
  $top = ->
    return D.$on_first ( event, send ) ->
      send [ 'table', get_divider S, 'top', ]
      #.....................................................................................................
      unless S.headings in [ null, false, ]
        send [ 'table', as_row S, S.headings ]
        send [ 'table', get_divider S, 'heading', ]
      #.....................................................................................................
      send event
  #.........................................................................................................
  $mid = -> $ ( event ) ->
  #.........................................................................................................
  $bottom = ->
    return D.$on_last ( event, send ) ->
      debug '7141', event
      send event
      send [ 'table', get_divider S, 'bottom', ]
  #.........................................................................................................
  return D.new_stream pipeline: [ $top(), $mid(), $bottom(), ]

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

#-----------------------------------------------------------------------------------------------------------
boxes =
  plain:
    lt:   '┌'           #  ╭
    ct:   '┬'           #  ┬
    rt:   '┐'           #  ╮
    lm:   '├'           #  ├
    cm:   '┼'           #  ┼
    rm:   '┤'           #  ┤
    lb:   '└'           #  ╰
    cb:   '┴'           #  ┴
    rb:   '┘'           #  ╯
    vs:   '│'           #  │
    hs:   '─'           #  ─


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
$as_event = ( S ) -> $ ( data, send ) -> send [ 'data', data, ]
as_text   = ( x ) -> if ( CND.isa_text x ) then x else rpr x
copy      = ( x ) ->
  return Object.assign [], x if CND.isa_list x
  return Object.assign {}, x if CND.isa_pod  x
  return x



############################################################################################################
do ( self = @ ) ->
  D = require './main'
  for name, value of self
    D[ name ] = value

