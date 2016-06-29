


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TRANSFORM-SPLIT-TSV'
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
@$split_tsv = ( settings ) ->
  ### A fairly complex stream transform to help in reading files with data in
  [Tab-Separated Values (TSV)](http://www.iana.org/assignments/media-types/text/tab-separated-values)
  format.

  * `comments` defines how to recognize a comment. If it is a string, lines (or fields, when `first:
    'split'` has been specified) that start with the specified text are left out of the results.
    It is also possible to use a RegEx or a custom function to recognize comments.

  * `trim`: `false` for no trimming, `true` for trimming both ends of each line (with `first: 'trim'`)
    or each field (with `first: 'split'`).

  * `first`: either `'trim'` or `'split'`. No effect with `trim: false`; otherwise, indicates whether
    first the line is trimmed (which means that leading and trailing tabs are also removed), or whether
    we should first split into lines, and then trim each field individually. The `first: 'trim'` method—the
    default—is faster, but it may conflate empty fields if there are any. The `first: 'split'` method
    will first split each line using the `splitter` setting, and then trim all the fields individually.
    This has the side-effect that comments (as field values on their own, not when tacked unto a non-comment
    value) are reliably recognized and sorted out (when `comments` is set to a sensible value).

  * `splitter` defines one or more characters to split each line into fields.

  * When `empty` is set to `false`, empty lines (and lines that contain nothing but empty fields) are
    left in the stream.
  ###
  first           =       settings?[ 'first'      ] ? 'trim' # or 'split'
  trim            =       settings?[ 'trim'       ] ? yes
  splitter        =       settings?[ 'splitter'   ] ? '\t'
  skip_empty      = not ( settings?[ 'empty'      ] ? no )
  comment_pattern =       settings?[ 'comments'   ] ? '#'
  use_names       =       settings?[ 'names'      ] ? null
  #.........................................................................................................
  unless first in [ 'trim', 'split', ]
    throw new Error "### MEH ###"
  #.........................................................................................................
  ### TAINT may want to allow custom function to do trimming ###
  switch trim
    when yes
      if first is 'trim'
        $trim = => @$ ( line, send ) =>
          send line.trim()
      else
        $trim = => @$ ( fields, send ) =>
          fields[ idx ] = field.trim() for field, idx in fields
          send fields
    when no then null
    else throw new Error "### MEH ###"
  #.........................................................................................................
  ### TAINT may want to specify empty lines, fields ###
  unless skip_empty in [ true, false, ]
    throw new Error "### MEH ###"
  #.........................................................................................................
  switch type = CND.type_of comment_pattern
    when 'null', 'undefined'  then comments =  no; is_comment = ( text ) -> no
    when 'text'               then comments = yes; is_comment = ( text ) -> text.startsWith comment_pattern
    when 'regex'              then comments = yes; is_comment = ( text ) -> comment_pattern.test text
    when 'function'           then comments = yes; is_comment = ( text ) -> not not comment_pattern text
    else throw new Error "### MEH ###"
  #.........................................................................................................
  if first is 'trim'
    $skip_comments = => @$ ( line, send ) =>
      send line unless is_comment line
  else
    $skip_comments = => @$ ( fields, send ) =>
      for field, idx in fields
        # urge '7765', idx, ( rpr field ), is_comment field
        continue unless is_comment field
        fields.length = idx
        break
      send fields unless skip_empty and fields.length is 0
  #.........................................................................................................
  if skip_empty
    $skip_empty_lines = => @$ ( line, send ) => send line if line.length > 0
    if first is 'split'
      $skip_empty_fields = => @$ ( fields, send ) =>
        for field in fields
          continue if field.length is 0
          send fields
          break
        return null
  #.........................................................................................................
  use_names = null if use_names is no
  if use_names?
    names = null
    #.......................................................................................................
    if CND.isa_list use_names
      names = use_names
      $name_fields = =>
        return @$ ( fields, send ) =>
          send name_fields fields
    #.......................................................................................................
    else if use_names in [ 'inline', yes, ]
      $name_fields = =>
        is_first  = yes
        return @$ ( fields, send ) =>
          return send name_fields fields unless is_first
          is_first  = no
          names     = fields
    #.......................................................................................................
    else
      throw new Error "expected setting names to be true, false, 'inline', or a list; got #{rpr use_names}"
    #.......................................................................................................
    use_names   = yes
    name_fields = ( fields ) =>
      R = {}
      for field, idx in fields
        R[ names[ idx ] ? "field-#{idx}" ] = field
      return R
  #.........................................................................................................
  unless ( type_of_splitter = CND.type_of splitter ) in [ 'text', 'regex', 'function', ]
    throw new Error "### MEH ###"
  throw new Error "splitter as function no yet implemented" if type_of_splitter is 'function'
  $split_line = =>
    return @$ ( line, send ) =>
      send line.split splitter
  #.........................................................................................................
  pipeline = []
  pipeline.push @$split()
  pipeline.push $trim()               if first is 'trim'
  pipeline.push $skip_empty_lines()   if skip_empty
  pipeline.push $skip_comments()      if first is 'trim' and comments
  pipeline.push $split_line()
  pipeline.push $trim()               if first is 'split'
  pipeline.push $skip_comments()      if first is 'split' and comments
  pipeline.push $skip_empty_fields()  if first is 'split' and skip_empty
  pipeline.push $name_fields()        if use_names
  # pipeline.push @$ ( data ) => debug '3', JSON.stringify data if data?
  #.........................................................................................................
  return @_new_stream$wrap 'split-tsv', @new_stream { pipeline, }


############################################################################################################
module.exports = @$split_tsv.bind require './main'









