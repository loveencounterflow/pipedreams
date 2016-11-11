#-----------------------------------------------------------------------------------------------------------
@_$experimental_wrap_async = ( method, settings ) ->
  finished    = no
  open_count  = 0
  main_end    = null
  filter      = settings?[ 'filter'   ] ? -> yes
  fallback    = settings?[ 'fallback' ] ? null
  unpack      = settings?[ 'unpack'   ] ? yes
  #.........................................................................................................
  return @$async ( data, send, end ) =>
    main_end = end if end?
    #.......................................................................................................
    if data?
      #.....................................................................................................
      if filter data
        open_count += +1
        method data, ( error, Z... ) =>
          #.................................................................................................
          if unpack
            Z   = Z[ 0 ]
            Z  ?= fallback
            return send.error new Error "expected a value, got a #{CND.type_of Z}" unless Z?
          #.................................................................................................
          send Z
          send.done()
          open_count += -1
          #.................................................................................................
          if main_end?
            if ( open_count is 0 ) and ( not finished )
              finished = yes
              main_end()
      else
        send data
        send.done()
    #.......................................................................................................
    if main_end?
      if ( open_count is 0 ) and ( not finished )
        finished = yes
        main_end()
    #.......................................................................................................
    return null

#-----------------------------------------------------------------------------------------------------------
@$spawn = ( command_template, settings ) ->
  finished    = no
  data_idx    = null
  open_count  = null
  output      = @new_stream()
  #.........................................................................................................
  throw new Error "### MEH 1 ###" unless CND.isa_list command_template
  throw new Error "### MEH 2 ###" unless command_template.length > 0
  #.........................................................................................................
  for part, part_idx in command_template
    switch type = CND.type_of part
      when 'text'
        throw new Error "### MEH 3 ###" unless part.length > 0
      when 'null'
        data_idx = part_idx
      else
        throw new Error "### MEH 4 ###"
  #.........................................................................................................
  $preprocess = => @$ ( data, send ) =>
    command             = Object.assign [], command_template
    command[ data_idx ] = data if data_idx?
    send command
  #.........................................................................................................
  pipeline = []
  pipeline.push $preprocess()
  pipeline.push @_$experimental_wrap_async @_plugin_spawn_spawn { output, }
  pipeline.push output
  pipeline.push @$show 'PLUGIN-SPAWN'
  #.........................................................................................................
  return @new_stream { pipeline, }

  ###
    throw error if finished
    finished = yes
    return handler null, fallback unless fallback is undefined
    handler error
  ###

#-----------------------------------------------------------------------------------------------------------
@_plugin_spawn_spawn = ( command, settings, handler ) ->
  ### TAINT improve error handling (see below)

  commands may communicate errors via

  * return code != 0
  * message on stderr
  * error event

  Additionally, some commands may output purely informative content to stderr without implying an error
  condition. The interpretation of such outputs should be done according to a command-specific settings.

  ###
  ### TAINT `cwd` should be a matter of (optional) configuration ###
  ### TAINT assuming UTF-8 encoded text stream from shell command ###
  #.........................................................................................................
  switch arity = arguments.length
    when 2
      handler   = settings
      settings  = null
    when 3
      null
    else return handler new Error "expected 2 or 3 arguments, got #{arity}"
  #.........................................................................................................
  output            = settings?[ 'output' ]
  throw new Error "need output stream, got none" unless output?
  #.........................................................................................................
  [ command
    parameters... ] = command
  cwd               = process.cwd()
  cp_settings       = { cwd, }
  cp                = CP.spawn command, parameters, cp_settings
  #.........................................................................................................
  cp.stdout
    .pipe @$split()
    .pipe @$ ( line, send ) => send [ 'stdout', line, ]
    .pipe output
  #.........................................................................................................
  cp.stderr
    .pipe @$split()
    .pipe @$ ( line, send ) => send [ 'stderr', line, ]
    .pipe output
  #.........................................................................................................
  cp.on 'error', ( error ) => D.send output, [ 'error', error, ]
  cp.on 'close', ( code  ) => D.send output, [ 'code',  code,  ]
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
_test_error = ( { code, stdout, stderr, error, } ) ->
  return yes if code?   and code isnt 0
  return yes if stderr? and stderr.length > 0
  return yes if error?
  return no

#-----------------------------------------------------------------------------------------------------------
_XXX_log  = ( P... ) -> help '77761', P...
_XXX_dump = ( P... ) -> urge '77761', P...

