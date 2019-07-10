
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'PIPEDREAMS/MAIN'
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
info                      = CND.get_logger 'info',      badge
urge                      = CND.get_logger 'urge',      badge
help                      = CND.get_logger 'help',      badge
whisper                   = CND.get_logger 'whisper',   badge
echo                      = CND.echo.bind CND
#...........................................................................................................
{ jr, }                   = CND
# override_sym              = Symbol.for 'override'
#...........................................................................................................
types                     = require './_types'
{ isa
  validate
  type_of }               = types
{ Pipestreams, }          = require 'pipestreams'

#-----------------------------------------------------------------------------------------------------------
class Pipedreams extends Pipestreams
  # @extend   object_with_class_properties
  @include require 'pipestreams'
  @include require './add_position'
  @include require './datoms'
  @include require './group-by'
  @include require './overrides'
  @include require './select'
  @include require './transforms'
  # @include require './xemitter'
  #---------------------------------------------------------------------------------------------------------
  constructor: ( @settings = null ) ->
    super()
    # @specs    = {}
    # @isa      = Multimix.get_keymethod_proxy @, isa
    # # @validate = Multimix.get_keymethod_proxy @, validate
    # declarations.declare_types.apply @

############################################################################################################
module.exports  = L = new Pipedreams()
L.Pipedreams    = Pipedreams



