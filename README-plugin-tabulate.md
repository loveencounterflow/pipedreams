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



