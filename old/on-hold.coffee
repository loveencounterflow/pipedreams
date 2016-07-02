
###

This module contains candidate PipeDreams methods that have been put on hold
because they are of dubious value, do not fall clearly within the scope of the
PipeDreams library, or have implementation issues yet to be solved.

In order to opt-in and use these methods (as far as the're usable at all),
use `require 'pipdreams/lib/on-hold'`.

###


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
# ### https://github.com/rvagg/through2 ###
# through2                  = require 'through2'
### https://github.com/maxogden/mississippi ###
MSP                       = require 'mississippi'
#...........................................................................................................
### http://stringjs.com ###
# stringfoo                 = require 'string'
#...........................................................................................................
### https://github.com/mcollina/split2 ###
# split2                    = require 'split2'
#...........................................................................................................
### https://github.com/mziccard/node-timsort ###
# timsort                   = require 'timsort'

############################################################################################################
f = ->
  #-----------------------------------------------------------------------------------------------------------
  @new_file_readstream = ( P... ) -> ( require 'fs' ).createReadStream P...

  #-----------------------------------------------------------------------------------------------------------
  @new_file_readlinestream = ( P... ) ->
    return @new_stream pipeline: [
      ( @new_file_readstream P... )
      ( @$split()                 )
      ]

  #-----------------------------------------------------------------------------------------------------------
  @new_sink = ->
    return @new_stream pipeline: [
      # ( @$as_text()                                             )
      ( @$bridge ( require 'fs' ).createWriteStream '/dev/null' )
      ]

  #-----------------------------------------------------------------------------------------------------------
  @new_file_writestream = -> throw new Error "new_file_writestream not implemented"


  #-----------------------------------------------------------------------------------------------------------
  @$observe = ( method ) ->
    ### Call `method` for each piece of data; when `method` has returned with whatever result, send data on.
    ###
    # return @$filter ( data ) -> method data; return true
    throw new Error "`$observe ( data ) ->` replaced by `$ ( data ) ->`"
    switch arity = method.length
      when 1
        return @$ ( data ) => method data
      when 2
        return @$ ( data, send, end ) =>
          if data?
            method data, false
            send data
          if end?
            method null, true
            end()
    throw new Error "expected method with arity 1 or 2, got one with arity #{arity}"

  #===========================================================================================================
  # SPECIALIZED STREAMS
  #-----------------------------------------------------------------------------------------------------------
  @spawn_and_read = ( P... ) ->
    ### from https://github.com/alessioalex/spawn-to-readstream:

    Make child process spawn behave like a read stream (buffer the error, don't emit end if error emitted).

    ```js
    var toReadStream = require('spawn-to-readstream'),
        spawn        = require('child_process').spawn;

    toReadStream(spawn('ls', ['-lah'])).on('error', function(err) {
      throw err;
    }).on('end', function() {
      console.log('~~~ DONE ~~~');
    }).on('data', function(data) {
      console.log('ls data :::', data.toString());
    });
    ```
    ###
    readstream_from_spawn     = require 'spawn-to-readstream'
    spawn                     = ( require 'child_process' ).spawn
    return readstream_from_spawn spawn P...

  #-----------------------------------------------------------------------------------------------------------
  @spawn_and_read_lines = ( P... ) ->
    last_line = null
    R         = @new_stream()
    input     = @spawn_and_read P...
    #.........................................................................................................
    input
      .pipe @$split()
      .pipe @$ ( line, send, end ) =>
        #.....................................................................................................
        if line?
          R.write last_line if last_line?
          last_line = line
        #.....................................................................................................
        if end?
          R.write last_line if last_line? and last_line.length > 0
          R.end()
          end()
    #.........................................................................................................
    return R

#-----------------------------------------------------------------------------------------------------------
@$bridge_A = ( stream ) ->
  ### Make it so that the pipeline may be continued even below a writable but not readable stream.
  Conceivably, this method could have be named `tunnel` as well. Something to get you across, you get the
  meaning. ###
  throw new Error "expected a single argument, got #{arity}"        unless ( arity = arguments.length ) is 1
  throw new Error "expected a stream, got a #{CND.type_of stream}"  unless @isa_stream stream
  throw new Error "expected a writable stream"                      if not stream.writable
  # throw new Error "expected a writable, non-readable stream"        if     stream.readable
  # W = ( require 'fs' ).createWriteStream path_1
  Z = @new_stream()
  A = @$ ( data, send, end ) =>
      if data?
        stream.write data
        Z.write data
      if end?
        stream.end()
        Z.end()
        end()
  return MSP.duplex A, Z, { objectMode: yes, }



############################################################################################################
f.apply require './main'

