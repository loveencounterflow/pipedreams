


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
  ###

  A stream transform to help in reading files with data in
  [Tab-Separated Values (TSV)](http://www.iana.org/assignments/media-types/text/tab-separated-values)
  format. It accepts a stream of buffers or text, splits it into
  lines, and splits each line into fields (using the tab character, U+0009). In the process
  it can also skip empty and blank lines, omit comments, and name fields.

  + `comments` defines how to recognize a comment. If it is a string, lines and individual fields that start
    with the specified text are left out of the results. It is also possible to use a RegEx or a custom
    function to recognize comments.

  + When `empty` is set to `false`, empty lines (and lines that contain nothing but empty fields) are
    left in the stream.

  * If `settings[ 'names' ]` is set to `'inline'`, field names are gleaned from the first non-discarded line
    of input; if it is a list of `n` elements, it defines labels for the first `n` columns of data. Columns
    with no defined name will be labelled as `'field-0'`, `'field-5'` and so on, depending on the zero-based
    index of the respective column. Where naming of fields is used, each TSV data line will be turned into a
    JS object with the appropriately named members, such as `{ name: 'John', age: 32, 'field-2': 'lawyer', }`;
    where no naming is used, lists of values are sent into the stream, such as `[ 'John', 32, 'lawyer', ]`.

  Observe that `$split_tsv` has been (experimentally) factored out into a plugin of sorts; to use it, be sure
  to `require 'pipedreams/lib/plugin-split-tsv'` after your `D = require 'pipedreams'` statement. This import
  has no interesting return value, but will provide `D.$split_tsv` for you to use.

  ###
  ### TAINT temporary clause ###
  if settings?
    throw new Error "setting 'first' deprecated" if settings[ 'first' ]?
    throw new Error "setting 'trim' deprecated" if settings[ 'trim' ]?
    throw new Error "setting 'splitter' not yet supported" if settings[ 'splitter' ]?
  # splitter        =       settings?[ 'splitter'   ] ? '\t'
  splitter          =       '\t'
  skip_empty_lines  = not ( settings?[ 'empty'      ] ? no )
  use_names         =       settings?[ 'names'      ] ? null
  comment_pattern   =       settings?[ 'comments'   ] ? '#'
  skip_comments     = not ( comment_pattern is no )
  comment_pattern   = null if comment_pattern is no
  #.........................................................................................................
  $trim = => @$ ( line, send ) => send @$split_tsv._trim line
  #.........................................................................................................
  ### TAINT may want to specify empty lines, fields ###
  unless skip_empty_lines in [ true, false, ]
    throw new Error "### MEH 1 ###"
  #.........................................................................................................
  switch type = CND.type_of comment_pattern
    when 'null', 'undefined'  then comments =  no; is_comment = ( text ) -> no
    # when yes                  then comments = yes; is_comment = ( text ) -> text.startsWith comment_pattern
    when 'text'               then comments = yes; is_comment = ( text ) -> text.startsWith comment_pattern
    when 'regex'              then comments = yes; is_comment = ( text ) -> comment_pattern.test text
    when 'function'           then comments = yes; is_comment = ( text ) -> not not comment_pattern text
    else throw new Error "expected `null`, a text, a RegEx or a function for 'comment', got a #{type}"
  #.........................................................................................................
  if skip_comments
    #.......................................................................................................
    $skip_line_comments = => @$ ( line, send ) =>
      send line unless is_comment line
    #.......................................................................................................
    $skip_field_comments = => @$ ( fields, send ) =>
      for field, idx in fields
        # urge '7765', idx, ( rpr field ), is_comment field
        continue unless is_comment field
        fields.length = idx
        break
      send fields unless skip_empty_lines and fields.length is 0
  #.........................................................................................................
  if skip_empty_lines
    $skip_empty_lines = => @$ ( line, send ) => send line if line.length > 0
    $skip_empty_lines = @_rpr 'skip-empty-lines', 'skip-empty-lines', null, $skip_empty_lines
    $skip_empty_fields = => @$ ( fields, send ) =>
      for field in fields
        continue if field.length is 0
        send fields
        break
      return null
    $skip_empty_fields = @_rpr 'skip-empty-fields', 'skip-empty-fields', null, $skip_empty_fields
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
  # unless ( type_of_splitter = CND.type_of splitter ) in [ 'text', 'regex', 'function', ]
  #   throw new Error "### MEH 3 ###"
  $split_line = =>
    return @$ ( line, send ) =>
      send line.split splitter
  #.........................................................................................................
  pipeline = []
  pipeline.push @$split()
  pipeline.push $trim()
  pipeline.push $skip_empty_lines()     if skip_empty_lines
  pipeline.push $skip_line_comments()   if skip_comments
  pipeline.push $split_line()
  pipeline.push $skip_field_comments()  if skip_comments
  pipeline.push $skip_empty_fields()    if skip_empty_lines
  pipeline.push $name_fields()          if use_names
  # pipeline.push @$ ( data ) => debug '3', JSON.stringify data if data?
  #.........................................................................................................
  return @_rpr "split-tsv", "split-tsv", null, @new_stream { pipeline, }

#-----------------------------------------------------------------------------------------------------------
@$split_tsv._trim = ( line ) =>
  R = line
  R = R.replace @$split_tsv._ends_pattern, ''
  R = R.replace @$split_tsv._mid_pattern,  '\t'
  return R

#-----------------------------------------------------------------------------------------------------------
@$split_tsv._ends_pattern = ///
    (?: ^ [\x20\f\n\r\v​\u00a0\u1680​\u180e\u2000-\u200a​\u2028\u2029\u202f\u205f​\u3000\ufeff]+   )
    |
    (?:   [\x20\f\n\r\v​\u00a0\u1680​\u180e\u2000-\u200a​\u2028\u2029\u202f\u205f​\u3000\ufeff]+ $ )
    ///g

#-----------------------------------------------------------------------------------------------------------
@$split_tsv._mid_pattern = ///
    [\x20\f\n\r\v​\u00a0\u1680​\u180e\u2000-\u200a​\u2028\u2029\u202f\u205f​\u3000\ufeff]*
    \t
    [\x20\f\n\r\v​\u00a0\u1680​\u180e\u2000-\u200a​\u2028\u2029\u202f\u205f​\u3000\ufeff]*
    ///g

#-----------------------------------------------------------------------------------------------------------
do ( self = @ ) ->
  D = require './main'
  for name, value of self
    D[ name ] = value











