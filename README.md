

- [PipeDreams](#pipedreams)
- [API](#api)
	- [Stream and Transform Construction](#stream-and-transform-construction)
		- [remit()](#remit)
		- [create_throughstream()](#create_throughstream)
		- ['Retroactive' Sub-Streams: $sub()](#'retroactive'-sub-streams-$sub)
		- [$link()](#$link)
		- [$continue()](#$continue)
	- [Aggregation](#aggregation)
		- [$aggregate = ( aggregator, on_end = null ) ->](#$aggregate-=--aggregator-on_end-=-null--->)
		- [$collect(), $count()](#$collect-$count)
	- [Strings](#strings)
		- [$hyphenate()](#$hyphenate)
		- [$split()](#$split)
		- [`new_hyphenate`](#new_hyphenate)
	- [HTML parsing](#html-parsing)
		- [HTML](#html)
		- [HTML.$collect_closing_tags()](#html$collect_closing_tags)
		- [HTML.$collect_empty_tags()](#html$collect_empty_tags)
		- [HTML.$collect_texts()](#html$collect_texts)
		- [HTML.$parse()](#html$parse)
		- [HTML._new_parser()](#html_new_parser)
	- [Sorting](#sorting)
	- ['Dense' Sorting](#'dense'-sorting)
		- [new_densort()](#new_densort)
		- [$densort()](#$densort)
		- [$sort()](#$sort)
	- [Other](#other)
		- [$filter()](#$filter)
		- [$on_end()](#$on_end)
		- [$on_start()](#$on_start)
		- [$show()](#$show)
		- [$signal_end()](#$signal_end)
		- [$skip_first()](#$skip_first)
		- [$spread()](#$spread)
		- [$throttle_bytes()](#$throttle_bytes)
		- [$throttle_items()](#$throttle_items)

> **Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*


# PipeDreams

![stability-experimental-red](https://img.shields.io/badge/stability-experimental-red.svg)
![npm-0.2.5-yellowgreen](https://img.shields.io/badge/npm-0.2.5-yellowgreen.svg)
![motivation-字面明快排字機-yellow](https://img.shields.io/badge/motivation-字面明快排字機-yellow.svg)

Common operations for piped NodeJS streams.

`npm install --save pipedreams2`

**Caveat** Below examples are all written in CoffeeScript.

<!-- ################################################################################################### -->
# API

<!-- =================================================================================================== -->
## Stream and Transform Construction

### remit()
### create_throughstream()


### 'Retroactive' Sub-Streams: $sub()

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


### $link()

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


### $continue()


<!-- =================================================================================================== -->
## Aggregation

### $aggregate = ( aggregator, on_end = null ) ->

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

### $collect(), $count()

Two standard aggregators; `$collect()` collects all data items into a list, and `$count()` counts how many
data items have been encountered in a stream.

<!-- =================================================================================================== -->
## Strings

### $hyphenate()
### $split()
### `new_hyphenate`

`D.new_hyphenate = ( hyphenation = null, min_length = 2 ) ->`

<!-- =================================================================================================== -->
## HTML parsing

### HTML
### HTML.$collect_closing_tags()
### HTML.$collect_empty_tags()
### HTML.$collect_texts()
### HTML.$parse()
### HTML._new_parser()

<!-- =================================================================================================== -->
## Sorting

## 'Dense' Sorting

### new_densort()
### $densort()

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


### $sort()


<!-- =================================================================================================== -->
## Other

### $filter()
### $on_end()
### $on_start()
### $show()
### $signal_end()
### $skip_first()
### $spread()
### $throttle_bytes()
### $throttle_items()




