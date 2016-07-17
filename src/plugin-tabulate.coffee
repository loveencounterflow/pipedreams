



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

  width:          <number>  ::                                                // 12
  alignment:      <text>    :: 'left' | 'right' | 'center' | 'justify'        // 'left'
  fit:            <number> | <null> ::                                        // null
  ellipsis:       <text>                                                      // '…'
  pad:            <number> | <text>                                           // ''
  overflow:       <text> :: 'hide' | 'show'                                   // 'show'


  widths:         <number>
  alignments:     [ <text> ]
  headings:       [ <text> ]
  keys:           [ <text> | <number> ]

**Formatting modes**: When width is given and a number, relative mode is used; otherwise, absolute mode.

In absolute mode, the width of a column in terms of character cells is either given by a column-specific
setting in `settings[ 'widths' ]` or by the fallback value in `settings[ 'width' ]`. The resulting table
will take up as many character cells as needed for each column, plus the ones needed for padding and
borders.

In relative mode, an attempt is made to keep the overall width of the table—including paddings and
borders—to the number of character cells given in `settings[ 'fit' ]`. Columns widths given in `settings[
'widths' ]` are interpreted as proportional to their sum; columns may stretch or shrink to meet the desired
table width. Since a minimum width of two character cells must be assumed and there is no way to fit
arbitrarily many columns into a finite table width, overflow may occur. When `settings[ 'overflow' ]` is set
to `'show'`, then overlong lines may occur; if it is set to `'hide'`, overlong lines are truncated so that
line wrap is avoided on terminals.

**Keys, Column Headings, and Data Types**: PipeDreams `$tabulate` accepts data items from the stream and
reformats them into a tabular format (or prints that table as a convenience shortcut). The table may or
may not have headings; the incoming data items must either be lists of values or JS objects with key/value
pairs (a.k.a. properties or attributes). The question is:

**Q 1)** In what order is data be mapped to columns?
**Q 2)** From which attributes of the streamed data do table contents come?
**Q 3)** If headings are used, where do they come from?

**A 1)** If the data events are lists, then columns will appear in the same order as in those events,
naturally. With PODs (plain old dictionaries, a.k.a. JS objects), the matter is a bit more complicated: most
JS engines used to iterate over object keys in insertion order (which is good), but V8 started a trend to
treat keys that look like list indexes (such as `'3'` or `'756') and sort them first in numerical order.
Whatever be the case, when the first data event comes down the stream and it is a POD, `$tabulate` will walk
over its keys and save them for all subsequent rows. Thus, in the absence of other settings, the first data
event determines how many columns from what attributes in which order are put into to the table. But see the
next point.

**A 2)** Point 1, above, explains the default behavior of `$tabulate` when no explicit setting is given. You
can, however, specify your preferred selection and order of columns with the setting `keys`; when given,
this should be a list of the keys used to access the values of each streamed data event; for example, if
your data events look like `[ 'file', 'emerald.jpg', '~/downloads', '-rw-r-----', 109418, '2016-03-21
17:57', ]`, you can specify `.pipe $tabulate keys: [ 2, 1, 4, ]` to display only folder, filename and size
in the table.

**A 3)** By default, `$tabulate` will display column headings in the first row of the table; this can be
switched off with the setting `headings: false`. With the default setting or `true`, headings will be the
keys used to access the data fields as discussed in point 2, above. When `headings` is a list, the list
items become column headings; if that list has less items than the table has columns, the reamining headers
are left blank; the same goes for intermittent elements that are set to `null`.




###


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

