
#===========================================================================================================
# SELECT
#-----------------------------------------------------------------------------------------------------------
@$select = ( selector, tracks = null ) ->
  receiver    = @new_stream()
  sender      = @new_stream()
  drop        = @$drop()
  pass        = @$pass()
  pass.pipe sender
  my_streams  = {}
  #.........................................................................................................
  if tracks?
    ( Object.keys tracks ).forEach ( key ) =>
      stream            = tracks[ key ]
      my_streams[ key ] = sub_input = @new_stream()
      sub_input
        .pipe stream
        .pipe sender
  #.........................................................................................................
  receiver
    .pipe @$ ( raw_data, send, end ) =>
      #.....................................................................................................
      if raw_data?
        #...................................................................................................
        keys        = null
        data        = null
        selection   = selector raw_data
        throw new Error "expected value for selection, got #{rpr selection}" unless selection?
        #...................................................................................................
        { key
          data }    = selection
        throw new Error "expected value for key, got #{rpr key}" unless key?
        data       ?= raw_data
        keys        = if ( CND.isa_list key ) then key else [ key, ]
        #...................................................................................................
        for key in keys
          if @isa_stream key
            target_stream = key
          else if ( CND.type_of key ) is 'symbol'
            switch key
              when @σ_pass then target_stream = pass
              when @σ_drop then target_stream = drop
              else throw new Error "expected symbol for 'pass' or 'drop', got #{rpr key}"
          else
            target_stream = my_streams[ key ]
            throw new Error "not a valid key: #{rpr key}" unless target_stream?
          @send target_stream, data
      #.....................................................................................................
      if end?
        if tracks?
          ( Object.keys tracks ).forEach ( key ) => @end my_streams[ key ]
        @end drop
        @end pass
        end()
  #.........................................................................................................
  # return @new_stream duplex: [ receiver, sender, ]
  return @_duplex$duplexer2 receiver, sender

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $select (1)" ] = ( T, done ) ->
  #.........................................................................................................
  say_it_in_english = $ ( n, send ) ->
    if n?
      switch n
        when 1 then send 'one'
        when 2 then send 'two'
        when 3 then send 'three'
        else send 'many'
    return null
  #.........................................................................................................
  say_it_in_french = $ ( n, send ) ->
    switch n
      when 1 then send 'un'
      when 2 then send 'deux'
      when 3 then send 'troix'
      else send 'beaucoup'
    return null
  #.........................................................................................................
  say_it_in_german = $ ( n, send ) ->
    switch n
      when 1 then send 'eins'
      when 2 then send 'zwei'
      when 3 then send 'drei'
      else send 'viele'
    return null
  #.........................................................................................................
  draw_a_separator = $ ( ignore, send ) ->
    send '—————'
    return null
  #.........................................................................................................
  dispatch = ( event ) ->
    return key: Symbol.for 'drop'  if event is 'drop this one'
    return key: Symbol.for 'pass'  if event is 'pass this one'
    return key: 'SEP'              if event is '---'
    [ languages, number, ] = event
    if languages is '*'   then languages = [ 'EN', 'FR', 'DE', ]
    else                       languages = ( language.toUpperCase() for language in languages.split ',' )
    return key: languages, data: number
  #.........................................................................................................
  tracks =
    EN:   say_it_in_english
    FR:   say_it_in_french
    DE:   say_it_in_german
    SEP:  draw_a_separator
  #.........................................................................................................
  probes = [
    [ 'fr', 1, ]
    [ 'fr', 2, ]
    [ 'fr', 3, ]
    [ 'fr', 4, ]
    'pass this one'
    '---'
    [ 'en,fr',  1, ]
    '---'
    'drop this one'
    [ '*',  1, ]
    '---'
    [ 'en', 2, ]
    '---'
    [ 'de', 3, ]
    [ 'de', 4, ]
    ]
  #.........................................................................................................
  matchers = [
    "un"
    "deux"
    "troix"
    "beaucoup"
    "pass this one"
    "—————"
    "one"
    "un"
    "—————"
    "one"
    "un"
    "eins"
    "—————"
    "two"
    "—————"
    "drei"
    "viele"
    ]
  #.........................................................................................................
  my_input = D.new_stream()
  my_input
    .pipe D.$select dispatch, tracks
    # .pipe $ ( data ) => urge JSON.stringify data
    .pipe D.$collect()
    .pipe $ ( results ) =>
      T.eq results.length, matchers.length
      T.eq results[ idx ], matcher for matcher, idx in matchers
    .pipe $ 'finish', done
  #.........................................................................................................
  # D.send  my_input, events[ 0 ] for n in [ 1 ... 1e3 ]
  D.send  my_input, probe for probe in probes
  D.end   my_input
  #.........................................................................................................
  return null

#-----------------------------------------------------------------------------------------------------------
@[ "(v4) $select (2)" ] = ( T, done ) ->
  #.........................................................................................................
  say_it_in_english = $ ( n, send, end ) ->
    if n?
      switch n
        when 1 then send 'one'
        when 2 then send 'two'
        when 3 then send 'three'
        else send 'many'
    if end?
      send "guess we're done here"
      end()
    return null
  #.........................................................................................................
  say_it_in_french = $ ( n, send ) ->
    switch n
      when 1 then send 'un'
      when 2 then send 'deux'
      when 3 then send 'troix'
      else send 'beaucoup'
    return null
  #.........................................................................................................
  say_it_in_german = $ ( n, send ) ->
    switch n
      when 1 then send 'eins'
      when 2 then send 'zwei'
      when 3 then send 'drei'
      else send 'viele'
    return null
  #.........................................................................................................
  draw_a_separator = $ ( ignore, send ) ->
    send '—————'
    return null
  #.........................................................................................................
  bridgehead  = D.$pass()
  drop        = D.$drop()
  #.........................................................................................................
  dispatch_drop_and_pass_events = ( event ) ->
    return key: drop       if event is 'drop this one'
    return key: bridgehead if event is 'dont process this one'
    return key: Symbol.for 'pass'
  #.........................................................................................................
  dispatch_draw_line_events = ( event ) ->
    return key: Symbol.for 'pass' unless event is '---'
    return key: 'SEP'
  #.........................................................................................................
  dispatch_language_events = ( event ) ->
    return key: bridgehead unless CND.isa_list event
    [ languages, number, ] = event
    return key: [ 'EN', 'FR', 'DE', ], data: number if  languages is '*'
    languages = ( language.toUpperCase() for language in languages.split ',' )
    return key: languages, data: number
  #.........................................................................................................
  draw_line_track =
    SEP:  draw_a_separator
  #.........................................................................................................
  language_track =
    EN:   say_it_in_english
    FR:   say_it_in_french
    DE:   say_it_in_german
  #.........................................................................................................
  probes = [
    [ 'fr', 1, ]
    [ 'fr', 2, ]
    [ 'fr', 3, ]
    [ 'fr', 4, ]
    'dont process this one'
    '---'
    [ 'en,fr',  1, ]
    '---'
    'drop this one'
    [ '*',  1, ]
    '---'
    [ 'en', 2, ]
    '---'
    [ 'de', 3, ]
    [ 'de', 4, ]
    ]
  #.........................................................................................................
  matchers = [
    "un"
    "deux"
    "troix"
    "beaucoup"
    "dont process this one"
    "—————"
    "one"
    "un"
    "—————"
    "one"
    "un"
    "eins"
    "—————"
    "two"
    "—————"
    "drei"
    "viele"
    "guess we're done here"
    ]
  #.........................................................................................................
  my_input = D.new_stream()
  my_input
    .pipe D.$select dispatch_drop_and_pass_events
    .pipe D.$select dispatch_draw_line_events,    draw_line_track
    .pipe D.$select dispatch_language_events,     language_track
    .pipe bridgehead
    # .pipe $ ( data ) => urge JSON.stringify data
    .pipe D.$collect()
    .pipe $ ( results ) =>
      T.eq results.length, matchers.length
      T.eq results[ idx ], matcher for matcher, idx in matchers
    .pipe $ 'finish', done
  #.........................................................................................................
  # D.send  my_input, events[ 0 ] for n in [ 1 ... 1e3 ]
  D.send  my_input, probe for probe in probes
  D.end   my_input
  #.........................................................................................................
  return null

