

'use strict'


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/TESTS/SELECT'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
test                      = require 'guy-test'
jr                        = JSON.stringify
#...........................................................................................................
types                     = require '../_types'
{ isa
  validate
  type_of }               = types
#...........................................................................................................
PD                        = require '../..'
{ $, $async, }            = PD


#-----------------------------------------------------------------------------------------------------------
@[ "select ignores values other than PODs" ] = ( T, done ) ->
  groupers =
    odd_even: ( ( x ) -> if isa.odd x then 'odd' else 'even' )
    vowel_consonant: ( ( x ) -> if x[ 0 ] in 'aeiou' then 'vowel' else 'consonant' )
  probes_and_matchers = [
    [[[1,2,3,4,5],'odd_even'],[{"key":"^group","name":"odd","value":[1]},{"key":"^group","name":"even","value":[2]},{"key":"^group","name":"odd","value":[3]},{"key":"^group","name":"even","value":[4]},{"key":"^group","name":"odd","value":[5]}],null]
    [[[2,3,4,5],'odd_even'],[{"key":"^group","name":"even","value":[2]},{"key":"^group","name":"odd","value":[3]},{"key":"^group","name":"even","value":[4]},{"key":"^group","name":"odd","value":[5]}],null]
    [[[1,3,2,4,6,5,8,10],"odd_even"],[{"key":"^group","name":"odd","value":[1,3]},{"key":"^group","name":"even","value":[2,4,6]},{"key":"^group","name":"odd","value":[5]},{"key":"^group","name":"even","value":[8,10]}],null]
    [[["all","odd","things","are","unequal"],"vowel_consonant"],[{"key":"^group","name":"vowel","value":["all","odd"]},{"key":"^group","name":"consonant","value":["things"]},{"key":"^group","name":"vowel","value":["are","unequal"]}],null]
    ]
  #.........................................................................................................
  for [ probe, matcher, error, ] in probes_and_matchers
    await T.perform probe, matcher, error, -> return new Promise ( resolve, reject ) ->
      [ values
        grouper ] = probe
      grouper     = groupers[ grouper ]
      source      = PD.new_value_source values
      collector   = []
      pipeline    = []
      pipeline.push source
      pipeline.push PD.$group_by grouper
      pipeline.push PD.$collect { collector, }
      # pipeline.push PD.$show()
      pipeline.push PD.$drain ->
        resolve collector
      PD.pull pipeline...
  done()
  return null





############################################################################################################
unless module.parent?
  test @
  # test @[ "selector keypatterns" ]
  # test @[ "select 2" ]


