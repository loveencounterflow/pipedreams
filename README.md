<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [PipeDreams](#pipedreams)
- [Stream and Transform Construction](#stream-and-transform-construction)
  - [remit()](#remit)
  - [create_throughstream()](#create_throughstream)
  - [Error Handling](#error-handling)
  - ['Retroactive' Sub-Streams: $sub()](#retroactive-sub-streams-sub)
  - [$link()](#link)
  - [$continue()](#continue)
  - [Creating 'Fittings' (Higher-Order Streams)](#creating-fittings-higher-order-streams)
    - [Motivation](#motivation)
    - [Usage](#usage)
      - [**`@create_fitting_from_pipeline = ( transforms, settings ) ->`**](#@create_fitting_from_pipeline---transforms-settings---)
      - [**`@create_fitting_from_readwritestreams = ( readstream, writestream, settings ) ->`**](#@create_fitting_from_readwritestreams---readstream-writestream-settings---)
    - [Example](#example)
- [Aggregation](#aggregation)
  - [$aggregate = ( aggregator, on_end = null ) ->](#aggregate---aggregator-on_end--null---)
  - [$collect(), $count()](#collect-count)
- [Strings](#strings)
  - [$split()](#split)
- [Sorting](#sorting)
- ['Dense' Sorting](#dense-sorting)
  - [new_densort()](#new_densort)
  - [$densort()](#densort)
  - [$sort()](#sort)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



- [PipeDreams](#pipedreams)
- [Stream and Transform Construction](#stream-and-transform-construction)
	- [remit()](#remit)
	- [create_throughstream()](#create_throughstream)
	- [Error Handling](#error-handling)
	- ['Retroactive' Sub-Streams: $sub()](#'retroactive'-sub-streams-$sub)
	- [$link()](#$link)
	- [$continue()](#$continue)
	- [Creating 'Fittings' (Higher-Order Streams)](#creating-'fittings'-higher-order-streams)
		- [Motivation](#motivation)
		- [Usage](#usage)
			- [**`@create_fitting_from_pipeline = ( transforms, settings ) ->`**](#@create_fitting_from_pipeline-=--transforms-settings--->)
			- [**`@create_fitting_from_readwritestreams = ( readstream, writestream, settings ) ->`**](#@create_fitting_from_readwritestreams-=--readstream-writestream-settings--->)
		- [Example](#example)
- [Aggregation](#aggregation)
	- [$aggregate = ( aggregator, on_end = null ) ->](#$aggregate-=--aggregator-on_end-=-null--->)
	- [$collect(), $count()](#$collect-$count)
- [Strings](#strings)
	- [$split()](#$split)
- [Sorting](#sorting)
- ['Dense' Sorting](#'dense'-sorting)
	- [new_densort()](#new_densort)
	- [$densort()](#$densort)
	- [$sort()](#$sort)

> **Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*


# PipeDreams

![stability-experimental-red](https://img.shields.io/badge/stability-experimental-red.svg)
![npm-0.2.5-yellowgreen](https://img.shields.io/badge/npm-0.2.5-yellowgreen.svg)
![motivation-字面明快排字機-yellow](https://img.shields.io/badge/motivation-字面明快排字機-yellow.svg)

Common operations for piped NodeJS streams.

`npm install --save pipedreams2`

**Caveat** Below examples are all written in CoffeeScript.


<!-- =================================================================================================== -->
# Stream and Transform Construction

## remit()
## create_throughstream()

`D2.create_throughstream` is an exact copy of [`event-streams`' `through()` method] (which in turn is implemented
with [`through`](https://github.com/dominictarr/through)); however, the `write()` method of the
returned stream will work in an asynchronous fashion when passed some data *and* a callback.

Here's an example for using an asynchronous `write` in concert with ES6
generators / `yield`, taking advantage of the simplified handling offered by
[`coffeenode-suspend`](https://github.com/loveencounterflow/coffeenode-suspend):

```coffee
suspend = require 'coffeenode-suspend'
step    = suspend.step

f = ->
  step ( resume ) =>
    input = D.create_throughstream()
    input
      .pipe HOLLERITH.$write db
      .pipe D.$on_end =>
        urge "test data written"
        handler()
    for idx in [ 0 .. 100 ]
      probe = "entry-#{idx}"
      yield input.write probe, resume
    input.end()
```

The general advantage of asynchronous writes is that the JavaScript event loop
gets an opportunity to process steps further down the line; in this example, you
could imagine millions of records being sent into the pipeline. Without
asynchronicity, that data would have to be buffered somewhere before `end` is
called on the `input` stream. With asynchronicity, the processing steps are
called after each single item.

## Error Handling

Handling errors that occur in NodeJS streams can be tough. The best solution
known to me is to use domains. Here's an example from the
[Hollerith](https://github.com/loveencounterflow/hollerith2) tests:

```coffee
@[ "invalid key not accepted (2)" ] = ( T, done ) ->
  domain  = ( require 'domain' ).create();
  domain.on 'error', ( error ) ->
    T.eq error[ 'message' ], "invalid SPO key, must be of length 3: [ 'foo' ]"
    done()
  domain.run ->
    input   = D.create_throughstream()
    input.pipe HOLLERITH.$write db
    input.write [ 'foo', ]
```

> thx to http://stackoverflow.com/a/22389498/256361, http://grokbase.com/t/gg/nodejs/12bwd4zm4x/should-stream-pipe-forward-errors#20121129e2ve6sah3cwqgbsc2noefyrsba
> for this suggestion.

To simplify the above, you may want to use PipeDreams' `run` method:

```coffee
@run = ( method, handler ) ->
  domain  = ( require 'domain' ).create()
  domain.on 'error', ( error ) -> handler error
  domain.run -> method()
  return domain
```

`run` expects a method to execute and a handler that will be called in case an error
should have occurred. Another example from Hollerith tests:

```coffee
@[ "catching errors (3)" ] = ( T, done ) ->
  #.........................................................................................................
  D.run ->
    input   = D.create_throughstream()
    input
      .pipe HOLLERITH.$write db
      .pipe D.$on_end -> setImmediate done
    input.write [ 'foo', 'bar', 'baz', 'gnu', ]
    input.end()
  , ( error ) ->
    T.eq error[ 'message' ], "invalid SPO key, must be of length 3: [ 'foo', 'bar', 'baz', 'gnu' ]"
    done()
```

Notes:

* Nothing keeps you from calling `run` with arbitrary, non-streamy code as it is
  a fully generic method.
* As for the style of the above example one could frown upon
  the use of two consecutive anonymous functions; then again, it really *looks* like

  ```coffee
  try
    f()
  catch error
    boo()
  ```

## 'Retroactive' Sub-Streams: $sub()

The PipeDreams `$sub` method allows to formulate pipes which 'talk back', as it were, to upstream
transformers. This can be handy when a given transformer performs single steps of an iterative optimization
process; with `$sub`, it becomes possible to re-submit a less-than-perfect value from a downstream
tranformer. Let's have a look at a simple example; we start with a stream of numbers, and our goal is to
'reduce' each number to a value closer to `1` than a given quality margin `epsilon` allows. We implement
that by an 'optimizer' transform which takes the square root of each number and passes it on. The result
will always be closer to 1 (if input was > 0), but not necessarily good enough. We verify for that in
the next step: if the recevied number differs from 1 by more than allowed by `epsilon`, it is re-written
into the source stream to be 'optimized' again; otherwise, it is send on as usual:

```coffee
sub_demo = ->
  input   = D2.create_throughstream()
  epsilon = 0.1
  #.........................................................................................................
  input
    # .pipe this # imagine any number of piping steps here
    # .pipe that
    #.......................................................................................................
    # Let's start the substream:
    .pipe D2.$sub ( source, sink ) ->
      source
        #...................................................................................................
        # Optimizer: take the square root of each number:
        .pipe $ ( n, send ) ->
          send Math.sqrt n
        #...................................................................................................
        # Quality Control: if distance to target value 1 to great, re-insert into the sub-stream source;
        # if OK, then pass on downstream
        .pipe $ ( n, send ) ->
          whisper n
          if ( Math.abs n - 1 ) > epsilon then  source.write n # value sent 'up'
          else                                  send n         # value sent 'down'
        #...................................................................................................
        # Don't forget to pipe to the sink:
        .pipe sink
    #.......................................................................................................
    # The substream is finished here, let's show the results:
    .pipe D2.$show()
  #.........................................................................................................
  for n in [ 3, 4, 1e6, 0.1, ]
    input.write n
```

And here is the output of the above:

```
(1.7320508075688772)
(1.3160740129524924)
(1.147202690439877)
(1.0710754830729146)
*  ▶  1.0710754830729146
(2)
(1.4142135623730951)
(1.189207115002721)
(1.0905077326652577)
*  ▶  1.0905077326652577
(1000)
(31.622776601683793)
(5.623413251903491)
(2.3713737056616555)
(1.539926526059492)
(1.2409377607517196)
(1.1139738599948024)
(1.055449600878603)
*  ▶  1.055449600878603
(0.31622776601683794)
(0.5623413251903491)
(0.7498942093324559)
(0.8659643233600653)
(0.930572040929699)
*  ▶  0.930572040929699
```

**Important Caveat** Because sub-streams are intended to be used in cases where re-sending of values to
upstream consumers is needed, the `source` stream will *not* receive an end event, as that would preclude
re-sending of data for the last element in the stream (you can't write to a stream that has ended). Instead,
a special attribute, `source.ended`, is set to `true` when the last data item comes down the stream.
Based on the knowledge of what you're doing and at what point in time you are through with sending more
data, you can check for that condition and say, for example, `if source.ended then source.end()`.

Be aware that some stream transformers (e.g. transformers that sort the entire stream) rely on the `end`
event in the stream to be issued; such transformers must not be in the stream above the point where you
explicitly call `source.end()`.


## $link()

`$link` accepts any number of stream transforms, either as single arguments or as list arguments; it returns
a stream transform that represents the pipeline of the individual transforms. When called with no arguments
or an empty list, it simply returns `$create_throughstream()` (i.e. a neutral stream transform). `$link`
allows to parametrize pipelines; as a side effect, it allows to omit the ever-repeating `.pipe` from
source code. For example, instead of writing

```coffee
input
  .pipe @_$break_lines()
  .pipe @_$disperse_texts()
  .pipe assemble_buffer()
  .pipe build_line()
  .pipe test test_line
  .pipe D.$collect ( collector ) -> urge collector
  .pipe D.$count ( count ) -> urge count
  .pipe D.$show()
```

you can now write

```coffee
input.pipe D.$link [
  @_$break_lines()
  @_$disperse_texts()
  assemble_buffer()
  build_line()
  test test_line
  D.$collect ( collector ) -> urge collector
  D.$count ( count ) -> urge count
  D.$show()
  ]
```


## $continue()


## Creating 'Fittings' (Higher-Order Streams)


### Motivation

Building stream pipelines often happens by concatenating (as far as the
resulting stream is concerned) anonymous stream transforms with chanins of
`.pipe()` calls, and often this approach is appropriate and sufficient.
Figuratively, a pipeline of stream transforms is like an assembly line for
data, with one end for input of raw data and one end for output of processed
data. Often, all that matters is that the resulting complex transformation is
defined in neat steps (so it remains easy to maintain) and wrapped up in
method with a snazzy name. Such methods are conventionally called
`create_xxx_stream` and do in fact return a NodeJS stream instance.

Especially as transforms grow more complex, however, we often want to adapt
existing pipelines to varied new uses, keep tabs on what's going on at
intermediate points, re-inject data at specific points, or deal with meta data
that may only become avaible at some time during processing. Such needs might
be dealt with, for example, by way of extending the return value of our
`create_xxxstream` method, but that has two disadvantages: for one thing, we'd
end up modifying objects that are supposed to have a certain shape  and you
could never know whether one of the new attributes wouldn't mess with one of
the stream-handling methods. The second disadvantage is that just tacking
named values onto an object that was created with a whole other intended use
tends to become semantically messy.

From these considerations, it becomes clear that the solution is to not return
a stream object, but rather an 'umbrella object' that has the pertinent
streams and other data attached to it. This is exactly what
`PIPEDREAMS.create_fitting_from_pipeline` and
`PIPEDREAMS.create_fitting_from_readwritestreams` do, and, in fact, that is
already pretty much all they do, as a look into the source readily shows:

```coffee
@create_fitting_from_pipeline = ( pipeline, settings ) ->
  unless ( type = CND.type_of pipeline ) is 'list'
    throw new Error "expected a list for pipeline, got a #{type}"
  confluence  = @combine pipeline...
  input       = settings?[ 'input'  ] ? @create_throughstream()
  output      = settings?[ 'output' ] ? @create_throughstream()
  input
    .pipe confluence
    .pipe output
  R =
    '~isa':       'PIPEDREAMS/fitting'
    input:        input
    output:       output
    inputs:       if settings[ 'inputs'  ]? then LODASH.clone settings[ 'inputs'  ] else {}
    outputs:      if settings[ 'outputs' ]? then LODASH.clone settings[ 'outputs' ] else {}
  return R
```

The only—but important—added value of the two methods is that they (1) turn an
array of stream transforms into a pipeline using `PIPEDREAMS.combine` (in the
case of `create_fitting_from_pipeline`) or `EVENTSTREAM.duplex` (in the case
of `create_fitting_from_readwritestreams`), that they (2) suggest to call the
stream's two ends `input` and `output`, and that they (3) suggest to keep all
other points of in- and output under `inputs` and `outputs`.


### Usage

#### **`@create_fitting_from_pipeline = ( transforms, settings ) ->`**

Given a pipeline (in the form of a list of `transforms`) and an optional `settings` object,
derive input, transformation and output from these givens and return a `PIPEDREAMS/fitting` object with
the following entries:

+ `input`: the reading side of the pipeline; this will be `settings[ 'input' ]` where present, or else
  a newly created throughstream;
+ `output`: the writing side of the pipeline; either `settings[ 'output' ]` or a new stream;
+ `inputs`: a copy of `settings[ 'inputs' ]` or a blank object;
+ `outputs`: a copy of `settings[ 'outputs' ]` or a blank object.

The `inputs` and `outputs` members of the fitting are a mere convenience, a
convention meant to aid in mainting consistent APIs. The consumer of
`create_fitting_from_pipeline` is responsible to populate these entries in a
meaningful way.

#### **`@create_fitting_from_readwritestreams = ( readstream, writestream, settings ) ->`**

Same as `create_fitting_from_pipeline`, but accepts a `readstream` and a `writestream` (and an
optional `settings` object). `readstream` should somehow be connected to `writestream`, and the pair
should be suitable arguments to the [EventsStream `duplex`
method](https://github.com/dominictarr/event-stream#duplex-writestream-readstream).


### Example

As a simple demonstration how to use `create_fitting_from_pipeline`, here's a
function that defines three transforms to perform addition, multiplication and
squaring of some numeric data, and that define extra input and output points,
made available as `fitting[ 'inputs' ][ 'add' ]` and `fitting[ 'outputs' ][
'unsquared' ]`, respectively:

```coffee
#-------------------------------------------------------------
create_frob_fitting = ( settings ) ->
  multiply      = $ ( data, send ) => send data * 2
  add           = $ ( data, send ) => send data + 2
  square        = $ ( data, send ) => send data ** 2
  unsquared     = D.create_throughstream()
  #...........................................................
  inputs        = { add, }
  outputs       = { unsquared, }
  transforms    = [ multiply, add, unsquared, square, ]
  #...........................................................
  return D.create_fitting_from_pipeline transforms, { inputs, outputs, }
```

In case it is preferrable to stick to the `.pipe`ing construction method, the
two ends of a piped stream may be passed into
`create_fitting_from_readwritestreams`:

```coffee
#-------------------------------------------------------------
create_frob_fitting = ( settings ) ->
  multiply      = $ ( data, send ) => send data * 2
  add           = $ ( data, send ) => send data + 2
  square        = $ ( data, send ) => send data ** 2
  unsquared     = D.create_throughstream()
  #...........................................................
  inputs        = { add, }
  outputs       = { unsquared, }
  readstream    = D.create_throughstream()
  writestream   = D.create_throughstream()
  readstream
    .pipe multiply
    .pipe add
    .pipe unsquared
    .pipe square
    .pipe writestream
  #...........................................................
  return D.create_fitting_from_readwritestreams readstream, writestream, { inputs, outputs, }
```


Here's how to use our new frob fitting: we keep an eye on all the data that passes through the pipeline
at the point before it gets squared; also, we want to re-inject a value of `-10` (into the input point
labelled `add`) whenever the pipeline yields a `100`; having set up the workings so far, we then
write our source data into the input:

```coffee
#.............................................................
fitting = create_frob_fitting()
{ input, output, inputs, outputs, } = fitting
#.............................................................
outputs[ 'unsquared' ]
  .pipe $ ( data, send ) ->
    help 'unsquared:', data
#.............................................................
output
  .pipe $ ( data, send ) ->
    inputs[ 'add' ].write -10 if data is 100
    send data
  .pipe D.$show()
#.............................................................
input.write n for n in [ 1 ... 10 ]
input.end()
```


<!-- =================================================================================================== -->
# Aggregation

## $aggregate = ( aggregator, on_end = null ) ->

A generic aggregator. This is how it is used in the PipeDreams source itself:

```coffee
@$count = ( on_end = null ) ->
  count = 0
  return @$aggregate ( -> count += +1 ), on_end
```

```coffee
@$collect = ( on_end = null ) ->
  collector = []
  aggregator = ( data ) ->
    collector.push data
    return collector
  return @$aggregate aggregator, on_end
```

To use `$aggregate`, you have to pass in an `aggregator` function and an option `on_end` handler. The
aggregator will be called once for each piece of data that comes down the stream and should return the
current state of the aggregation (i.e. the intermediate result).

Aggregators display one of two behavioral patterns depending on whether `on_end` has been given. In case
`on_end` has been given, each piece of data that arrives in the aggregator will be passed through the pipe
and `on_end` will be called once with the last intermediate result. If `on_end` has not been given, the
individual data events will *not* be passed on; instead, when the stream has ended, the aggregation
result will be sent downstream.

## $collect(), $count()

Two standard aggregators; `$collect()` collects all data items into a list, and `$count()` counts how many
data items have been encountered in a stream.

<!-- =================================================================================================== -->
# Strings

## $split()

<!-- =================================================================================================== -->
# Sorting

# 'Dense' Sorting

## new_densort()
## $densort()

`new_densort = ( key = 1, first_idx = 0, report_handler = null ) ->`

The motivation for this function is the observation that in order to sort a stream of elements, it is in
the general case necessary to buffer *all* elements before they can be sorted and sent on. This is because
in the general case it is unknown prior to stream completion whether or not yet another element that will
fit into any given position is pending; for example, if you queried a database for a list of words to
be sorted alphabetically, it is, generally, not possible to decide whether between any two words—say,
`'train'` and `'trainspotter'`—a third word is due, say, `'trains'`. This is because the sorting criterion
(i.e. the sequence of letters of each word) is 'sparse'.

I love trains, but i don't like the fact that i will always have to backup potentially large streams in
memory before i can go on with processing.

Fortunately, there is an important class of cases that provide 'dense' sorting criterion coupled with
moderate disorder among the elements: Consider a stream that originates from a database query similar to
`SELECT INDEX(), word FROM words ORDER BY word ASC` (where `INDEX()` is a function to add a zero-based row
index to each record in the result set); we want to send each record to a consumer over a network
connection\*, one record at a time. We can then be reasonably sure that that the order of items arriving
at the consumer is *somewhat* correlated to their original order; at the same time, we may be justified in
suspecting that *some* items might have swapped places; in other words, the `INDEX()` field in each record
will be very similar to a monotonically growing series.

> \*) In fact, network connections—e.g. those using WebSockets—may indeed be order-preserving, but it's
> easy to imagine a transport protocol (like UDP) that isn't, or a result set that is assembled from
> asynchronous calls to a database with each call originating from one piece of data in the stream.
> There may also be cases where a proof of sequentiality is not obvious, and it would be nice to have
> a guaranteed ordering without incurring too much of an overhead in time and space.

This is where `densort` comes in: assuming records are offered in a 'dense' fashion, with some field of
the recording containing an integer index `i`, forming a finite series with a definite lower bound `i0`
and a certain number of elements `n` such that the index of the last element is `i1 = n + i0 - 1` and each
index `i` in the range `i0 <= i <= i1` is associated with exactly one record.
<!--
Given a stream of `data` items with an index available as `data[ key ]`, re-emit data items in order
such that indexes are ordered, and no items are left out. This is is called 'dense sort' as it presupposes
that no single index is left out of the sequence, such that whenever an item with index `n` is seen, it
can be passed on as soon as all items with index m < n have been seen and passed on. Conversely, any item
whose predecessors have not yet been seen and passed on must be buffered. The method my be called as
`$densort k, n0`, where `k` is the key to pick up the index from each data item (defaulting to `1`,
i.e. assuming an 'element list' whose first item is the index element name, the second is the index, and
the rest represents the payload), and `n0` is the lowest index (defaulting to `0` as
well).

In contradistinction to 'agnostic' sorting (which must buffer all data until the stream has ended), the
hope in a dense sort is that buffering will only ever occur over few data items which should hold as long
as the stream originates from a source that emitted items in ascending order over a reasonably 'reliable'
network (i.e. one that does not arbitrarily scramble the ordering of packages); however, it is always
trivial to cause the buffering of *all* data items by withholding the first data item until all others
have been sent; thus, the performance of this method cannot be guaranteed.

To ensure data integrity, this method will throw an exception if the stream should end before all items
between `n0` and the last seen index have been sent (i.e. in cases where the stream was expected to be
dense, but turned out to be sparse), and when a duplicate index has been detected.

You may pass in a `handler` that will be called after the entire stream has been processed; that function,
if present, will be called with a pair `[ n, m, ]` where `n` is the total number of elements encountered,
and `m <= n` is the maximal number of elements that had to be buffered at any one single point in time.
`m` will equal `n` if the logically first item happened to arrive last (and corresponds to the number of
items that have to be buffered with 'sparse', agnostic sorting); `m` will be zero if all items happened
to arrive in their logical order (the optimal case).

 -->


## $sort()






