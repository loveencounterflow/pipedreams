


############################################################################################################
TRM                       = require 'coffeenode-trm'
rpr                       = TRM.rpr.bind TRM
badge                     = 'TEST'
log                       = TRM.get_logger 'plain',     badge
info                      = TRM.get_logger 'info',      badge
whisper                   = TRM.get_logger 'whisper',   badge
alert                     = TRM.get_logger 'alert',     badge
debug                     = TRM.get_logger 'debug',     badge
warn                      = TRM.get_logger 'warn',      badge
help                      = TRM.get_logger 'help',      badge
urge                      = TRM.get_logger 'urge',      badge
echo                      = TRM.echo.bind TRM
#...........................................................................................................
BNP                       = require 'coffeenode-bitsnpieces'

#-----------------------------------------------------------------------------------------------------------
module.exports = run = ( x ) ->
  T             = {}
  test_count    = 0
  check_count   = 0
  pass_count    = 0
  fail_count    = 0
  failures      = {}

  #---------------------------------------------------------------------------------------------------------
  T.eq = ( P... ) ->
    ### Tests whether all arguments are pairwise and deeply equal. Uses CoffeeNode Bits'n'Pieces' `equal`
    for testing as (1) Node's `assert` distinguishes—unnecessarily—between shallow and deep equality, and,
    worse, [`assert.equal` and `assert.deepEqual` are broken](https://github.com/joyent/node/issues/7161),
    as they use JavaScript's broken `==` equality operator instead of `===`. ###
    check_count += 1
    if BNP.equals P...
      pass_count       += 1
    else
      fail_count       += 1
      error             = new Error "not equal: #{rpr P}"
      error[ 'caller' ] = TEST.get_caller_description 1
      throw error

  #---------------------------------------------------------------------------------------------------------
  T.rsvp = ( callback ) ->
    debug '©phhjN', BNP.get_caller_locators delta
    return ( error, P... ) =>
      ### TAINT need better error handling ###
      throw error if error?
      return callback P...

  #---------------------------------------------------------------------------------------------------------
  T.ok = ( result ) ->
    ### Tests whether `result` is strictly `true` (not only true-ish). ###
    unless result is true
      throw new Error "expected true, got #{rpr result}"

  #---------------------------------------------------------------------------------------------------------
  T.fail = ( message ) ->
    debug '©9HhEC', BNP.get_caller_locators delta
    throw new Error message

  #---------------------------------------------------------------------------------------------------------
  for name, test of x
    test = test.bind x
    test_count += 1
    #.......................................................................................................
    switch arity = test.length
      #.....................................................................................................
      when 1
        try
          test T
        catch error
          ### NB `entry[ 'name' ]` should normally match `entry[ 'caller' ][ 'name' ]` ###
          caller      = error[ 'caller'  ]
          entry       =
            'name':     name
            'message':  error[ 'message' ]
            'caller':   caller
          fail_count += 1 unless caller?
          target      = failures[ name ]?= []
          target.push [ entry, ]
      #.....................................................................................................
      when 2
        ### TAINT need ASYNC or similar to manage callbacks in concert with synhronous code ###
        test T, ( error ) =>
          throw error if error?
      #.....................................................................................................
      else
        throw new Error "expected test with 1 or 2 arguments, got one with #{arity}"

  #---------------------------------------------------------------------------------------------------------
  info 'test_count:   ',   test_count
  info 'check_count:  ',   check_count
  info 'pass_count:   ',   pass_count
  info 'fail_count:   ',   fail_count
  info 'failures:     ',   failures

#-----------------------------------------------------------------------------------------------------------
@get_caller_description = ( delta = 1 ) ->
  locator = ( BNP.get_caller_locators delta + 1 )[ 0 ]
  return BNP.caller_description_from_locator locator

#-----------------------------------------------------------------------------------------------------------
TEST = @



