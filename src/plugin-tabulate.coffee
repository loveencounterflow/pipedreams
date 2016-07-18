



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
  validate_keys "settings", "one or more out of", ( Object.keys settings ), keys_toplevel
  #.........................................................................................................
  S.width             =       settings[ 'width'       ] ? 12
  S.alignment         =       settings[ 'alignment'   ] ? 'left'
  ###
  process.stdout.columns
  ###
  S.fit               =       settings[ 'fit'         ] ? null
  S.ellipsis          =       settings[ 'ellipsis'    ] ? '…'
  S.pad               =       settings[ 'pad'         ] ? ' '
  S.overflow          =       settings[ 'overflow'    ] ? 'show'
  S.alignment         =       settings[ 'alignment'   ] ? 'left'
  #.........................................................................................................
  S.widths            = copy  settings[ 'widths'      ] ? []
  S.alignments        =       settings[ 'alignments'  ] ? []
  S.headings          =       settings[ 'headings'    ] ? yes
  S.keys              =       settings[ 'keys'        ] ? null
  S.box               = copy  settings[ 'box'         ] ? copy boxes[ 'plain' ]
  #.........................................................................................................
  S.pad               = ( ' '.repeat S.pad ) if CND.isa_number S.pad
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
  validate_keys "alignment", "one of", [ S.alignment, ], values_alignment
  validate_keys "overflow",  "one of", [ S.overflow,  ], values_overflow
  #.........................................................................................................
  if S.overflow isnt 'show' then throw new Error "setting 'overflow' not yet supported"
  if S.fit?                 then throw new Error "setting 'fit' not yet supported"
  #.........................................................................................................
  ### TAINT check widths etc. are non-zero integers ###
  ### TAINT check values in headings, widths, keys (?) ###
  #.........................................................................................................
  return S

#-----------------------------------------------------------------------------------------------------------
validate_keys = ( title, arity, got, expected ) ->
  return if CND.is_subset got, expected
  got       = ( ( rpr x ) for x in got when x not in expected ).join ', '
  expected  = ( ( rpr x ) for x in expected                   ).join ', '
  throw new Error """
    #{title}:
    expected #{arity} #{expected},
    got #{got}"""

#-----------------------------------------------------------------------------------------------------------
keys_toplevel     = [
  'alignment'
  'alignments'
  'box'
  'default'
  'ellipsis'
  'fit'
  'headings'
  'keys'
  'overflow'
  'pad'
  'width'
  'widths'
  ]
values_overflow   = [ 'show',  'hide', ]
values_alignment  = [ 'left',  'right', 'center', ]

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
    if S.widths?      then  S.widths[ idx ]      ?= S.width for idx in [ 0 ... S.keys.length ]
    else                    S.widths              = ( S.width for key in S.keys )
    #...................................................................................................
    if S.alignments?  then  S.alignments[ idx ]  ?= S.alignment for idx in [ 0 ... S.keys.length ]
    else                    S.alignments          = ( S.alignment for key in S.keys )
    #...................................................................................................
    return send event

#-----------------------------------------------------------------------------------------------------------
as_row = ( S, data, keys = null ) =>
  R = []
  if keys? then keys_and_idxs = ( [ key, idx, ] for key, idx in keys                  )
  else          keys_and_idxs = ( [ idx, idx, ] for      idx in [ 0 ... data.length ] )
  for [ key, idx, ] in keys_and_idxs
    text      = as_text data[ key ]
    width     = S.widths[ idx ]
    align     = S.alignments[ idx ]
    ellipsis  = S.ellipsis
    R.push to_width text, width, { align, ellipsis, }
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
      send event
      send [ 'table', get_divider S, 'bottom', ]
  #.........................................................................................................
  return D.new_stream pipeline: [ $top(), $mid(), $bottom(), ]

#-----------------------------------------------------------------------------------------------------------
$cleanup = ( S ) ->
  return $ ( event, send ) ->
    [ mark, data, ] = event
    send data if mark is 'table'
    return null

#-----------------------------------------------------------------------------------------------------------
boxes =
  plain:
    lt:   '┌'
    ct:   '┬'
    rt:   '┐'
    lm:   '├'
    cm:   '┼'
    rm:   '┤'
    lb:   '└'
    cb:   '┴'
    rb:   '┘'
    vs:   '│'
    hs:   '─'
  round:
    lt:   '╭'
    ct:   '┬'
    rt:   '╮'
    lm:   '├'
    cm:   '┼'
    rm:   '┤'
    lb:   '╰'
    cb:   '┴'
    rb:   '╯'
    vs:   '│'
    hs:   '─'


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

