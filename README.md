<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [PipeDreams Datoms (Data Events)](#pipedreams-datoms-data-events)
  - [`select = ( d, selectors... ) ->`](#select---d-selectors---)
- [Aggregate Transforms](#aggregate-transforms)
- [The XEmitter (XE) Sub-Module](#the-xemitter-xe-sub-module)
  - [XE Sending API](#xe-sending-api)
  - [XE Receiving API](#xe-receiving-api)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->



## PipeDreams Datoms (Data Events)

Data streams—of which [pull-streams](https://pull-stream.github.io/),
[PipeStreams](https://github.com/loveencounterflow/pipestreams), and [NodeJS
Streams](https://nodejs.org/api/stream.html) are examples—do their work by
sending pieces of data (that originate from a data source) through a number of
transforms (to finally end up in a data sink).<sup>*note*</sup>

> (*note*) I will ignore here alternative ways of dealing with streams, especially
> the [`EventEmitter` way of dealing with streamed
> data](https://nodejs.org/api/stream.html#stream_api_for_stream_consumers).
> When I say 'streams', I also implicitly mean 'pipelines'; when I say
> 'pipelines', I also implicitly mean 'pipelines to stream data' and 'streams'
> in general.

When NodeJS streams started out, the thinking about those streams was pretty
much confined to saying that ['a stream is a series of
bytes'](http://dominictarr.com/post/145135293917/history-of-streams). Already back then,
an alternative view took hold (I'm slightly paraphrasing here):

> The core interpretation was that stream could be buffers or strings - but the
> userland interpretation was that a stream could be anything that is
> serializeable [...] it was a sequence of buffers, bytes, strings or objects.
> Why not use the same api?

I will no repeat here [what I've written about perceived shortcomings of NodeJS
streams](https://github.com/loveencounterflow/pipestreams/blob/master/pipestreams-manual/chapter-00-comparison.md);
instead, let me iterate a few observations:

* In streaming, data is just data. There's no need for having [a separate
  'Object Mode'](https://nodejs.org/api/stream.html#stream_object_mode) or
  somesuch.

* There's a single exception to the above rule, and that is when the data item
  being sent down the line is `null`. This has historically—by both NodeJS
  streams and pull-streams—been interpreted as a termination signal, and I'm not
  going to change that (although at some point I might as well).

* When starting out with streams and building fairly simple-minded pipelines,
  sending down either raw pieces of business data or else `null` to indicate
  termination is enough to satisfy most needs. However, when one transitions to
  more complex environments, raw data is not sufficient any more: When
  processing text from one format to another, how could a downstream transform
  tell whether a given piece of text is raw data or the output of an upstream
  transform?

  Another case where raw data becomes insufficient are circular
  pipelines—pipelines that re-compute (some or all) output values in a recursive
  manner. An example which outputs the integer sequences of the [Collatz
  Conjecture](https://en.wikipedia.org/wiki/Collatz_conjecture) is [in the tests
  folder](https://github.com/loveencounterflow/pipedreams/blob/master/src/tests/circular-pipelines.test.coffee#L36).
  There, whenever we see an even number `n`, we send down that even number `n`
  alongside with half its value, `n/2`; whenever we see an odd number `n`, we
  send it on, followed by its value tripled plus one, `3*n+1`. No matter whether
  you put the transform for even numbers in front of that for odd numbers or the
  other way round, there will be numbers that come out at the bottom that need
  to be re-input into the top of the pipeline, and since there's no telling in
  advance how long a Collatz sequence will be for a given integer, it is, in the
  general case, insufficient to build a pipeline made from a (necessarily
  finite) repetitive sequence of copies of those individual transforms. Thus,
  classical streams cannot easily model this kind of processing.

The idea of **datoms**—short for *data atoms*, a term borrowed from [Rich
Hickey's Datomic](https://www.infoq.com/articles/Datomic-Information-Model)—is
to simply to wrap each piece of raw data in a higher-level structure. This is of
course an old idea, but not one that is very prevalent in NodeJS streams, the
fundamental assumption (of classical stream processing) being that all stream
transforms get to process each piece of data, and that all pieces of data are of
equal status (with the exception of `null`).

The PipeDreams sample implementation of Collatz Sequences uses datoms to (1)
wrap the numerical pieces of data, which allows to mark data as processed
(a.k.a. 'stamped'), to (2) mark data as 'to be recycled', and to (3) inject
system-level `sync`hronization signals into the data stream to make sure that
recycled data gets processed before new data is allowed into the stream.

In PipeDreams datoms, **each piece of data is explicitly labelled for its
type**; **each datom may have a different status**: there are **system-level
datoms that serve to orchestrate the flow of data within the pipeline**; there
are **user-level datoms which originate from the application**; there are
**datoms to indicate the opening and closing of regions (phases) in the data
stream**; there are **stream transforms that listen to and act on specific
system-level events**.

Datoms are JS objects that must minimally have a `key` property, a string that
specifies the datom's category, namespace and name; in addition, they may have a
`value` property with the payload (where desired), and any number of other
attributes. The property `$` is used to carry metadata (e.g. from which line in
a source file a given datom was generated from). Thus, we may give the outline
of a datom as (in a rather informal notation) `d := { key, ?value, ?stamped,...,
?$, }`.

The `key` of a datom must be a string that consists of at least two parts, the
`sigil` and the `name`. The `sigil`, a single punctuation character, indicates
the 'category' of each datom; there are two levels and three elementary
categories, giving six types of datoms:

* Application level:
  * `^` for **data datoms** (a.k.a. 'singletons'),
  * `<` for **start-of-region datoms**,
  * `>` for **end-of-region datoms**.

* System level:
  * `~` for **data datoms**,
  * `[` for **start-of-region datoms**,
  * `]` for **end-of-region datoms**.

<!-- System-level events, in particular those without further payload data, are also
called 'signals'; thus, `~collect` is a 'collect signal', and `[data` is a
'start-of-data signal'. Aggregate transforms such as `$collect()`, `$sort()` and
so on listen to the signals of the same name, `~collect` and `~sort`: In the
case of `$collect()`, a collect signal will trigger the sending of the
collection as it looks at that point in time; likewise, `$sort()` will react to
a sort signal by sending all buffered events in the configured ordering.
 -->

Normally, one will probably want to send around business data inside (the
`value` property of) application-level data datoms (hence their name, also
shortened to D-datoms); however, one can also set other properties of datom
objects, or send data around using properties of start- or end-of-region datoms.

Region events are intended to be used e.g. when parsing text with markup; say
you want to turn a snippet of HTML like this:

```
<document><div>Helo <em>world!</em></div></document>
```

into another textual representation, you may want to turn that into a sequence
of datoms similar to these, in the order of sending and regions symbolized by
boxes:<sup>*note*</sup>

```
--------------------------------------------------------+
  { key: '<document',                   }   # d1        |
------------------------------------------------------+ |
  { key: '<div',                        }   # d2      | |
  { key: '^text',     value: "Helo ",   }   # d3      | |
----------------------------------------------------+ | |
  { key: '<em',                         }   # d4    | | |
  { key: '^text'      value: "world!",  }   # d5    | | |
  { key: '>em',                         }   # d6    | | |
----------------------------------------------------+ | |
  { key: '>div',                        }   # d7      | |
------------------------------------------------------+ |
  { key: '>document',                   }   # d8        |
--------------------------------------------------------+
```

> *note* by 'in the order of sending' I mean you'd have to send datom `d1`
> first, then `d2` and so on. Trivial until you imagine you write a pipeline and
> then picture how the events will travel down that pipeline:
>
> `pipeline.push $do_this()             # s1, might be processing d3 right now`<br>
> `pipeline.push $do_that()             # s2, might be processing d2 right now`<br>
> `pipeline.push $do_something_else()   # s3, might be processing d1 right now`<br>
>
> Although there's really no telling whether step `s3` will really process datom
> `d1` at the 'same point in time' that step `s2` processes datom `d2` and so on
> (in the strict sense, this is hardly possible in a single-threaded language
> anyway), the visualization still holds a grain of truth: stream transforms
> that come 'later' (further down) in the pipeline will see events near the top
> of your to-do list first, and vice versa. This can be mildly confusing.


### `select = ( d, selectors... ) ->`

The `select` method can be used to determine whether a given event `d` matches a
set of conditions; typically, one will want to use `select d, ...` to decide
whether a given event is suitable for processing by the stream transform at
hand, or whether it should be passed on unchanged.

Given an event `d` and a number of `selectors`, return whether `d` matches all
of the selectors.

Selectors can be of three kinds:

* **key patterns**: e.g. `'^prfx:myname'` will match all singular events (`^`)
  that have a namespace prefix `prfx` and a name `myname`.

* **boolean functions**: e.g. `( ( d ) -> d.value > 42 )` will match all events
  that have a `value` that is greater than `42`.

* **tags** that configure matching details: e.g. `'#stamped'` will match
  un-`stamped` events as well as `stamped` ones (which are otherwise excluded
  from matching).

A given event will be 'selected' (i.e. `select d, ...` will return `true`) only
if all conditions are met; as a consequence, `select d, '^', 'text'` ('select
singleton events whose name is `'text'`) is equivalent to `( select d, '^' ) and
( select d, 'text' )`. Incidentally, this is also equivalent to `select '^text'`
since sigils and names may be contracted into a single selector.

Observe that

* tags must appear on their own, so `select d, '^text#stamped'` is not OK,
  although it may become legal in the future; FTTB, write `select d, '^text',
  '#stamped'`.

* `'#stamped'` means 'event *may* have property `{ stamped: true, }`, *not* that
  it *must* be `stamped`. In order to only select singleton `text` events that
  are also `stamped`, use a boolean function like `select d, '^text', ( ( d ) ->
  d.stamped ? false )` (in practice, you will probably want to use a named
  function, e.g. `( select '^text', is_stamped )`).

**NOTE** One could argue that a call `( select d )` without any selectors should
be legal and always return `true`; while that is a perfectly logical extension,
in practice it is probably a programmer's error, which is why `( select d )`
throws an error.


## Aggregate Transforms

<!-- ### `$collect = ( settings ) ->`

This is an improved version of `PS.$collect()`. While `PS.$collect()` will merely
buffer all events in a list and send on that list when the stream is terminated,
one can tune `PD.$collect()` with the optional `settings` object, whose defaults are

```
{ select: null, key: 'collection', callback: null, value: null, }
```

* `settings.value` determines which property of each datom to extract:
  * `false`, `undefined`, `null`:  collect `d`;
  * `true`:   collect `d.value`;
  * a string `p`: collect `d[ p ]`;
  * a function `f`: collect the result of `f d`.

* `settings.select` determines which datoms are eligible for collection:
  * `undefined`, `null`: select all datoms except system-level ones (sigil `~`);
  * all other values that may be passed to `select()`: select all datoms for
    which `select d, settings.select` returns `true`.
  Non-eligible datoms are passed through unchanged.

* `settings.key` sets the key (with sigil and namespace prefix) for the
  resulting collective datom(s); this must be a valid datom key.

* with `settings.callback`, you can use a callback function to receive the
  aggregated result, which will be called as `settings.callback collection`
  where applicable. *When a callback is used, elected datoms are not sent down
  the pipeline*, which makes `$collect()` act a bit like `$filter()`.

`$collect()` will send on collected data (or call the callback) when any data
has been collected at all, and any of these conditions is met:

* When the stream has ended;
* when a collect signal (a `~collect` datom) has been received;
* when it encounters a datom that it is not configured to collect.

The last rule ensures that the 'integrity' of the data stream—the sequence of
events—remains undisturbed by `$collect()`; if you send, say, datoms with
numbers and texts `2 — 3 — 4 — 'a text' — 5 — 6` down a pipeline with a
`$collect()` transform that is configured to collect numbers, you will receive
`[ 2, 3, 4, ] — 'a text' — [ 5, 6, ]` on the other hand, with the general
arrangement of the data left intact.
 -->



## The XEmitter (XE) Sub-Module

### XE Sending API

* **`XE.emit          = ( key, d ) ->`**—emit (a.k.a. 'publish', 'send to whom it may concern') an event. To
  be called either as `XE.emit '^mykey', 'myvalue'` or as `XE.emit PD.new_event '^mykey', 'myvalue'` (in
  which latter case the datom's key will become the channel key). When called with await as in
  `return_values = await XE.emit '^foo', ...`, `return_values` will be a list with all values returned by
  all listeners that got called for this event.

* **`XE.delegate      = ( key, d ) ->`**—like `XE.emit()` but will pick out and unwrap the event value
  from the event contractor (see below). If no event contractor was listening, an error will be raised.

### XE Receiving API

* **`XE.listen_to_all = ( self, listener ) ->`**—Register a listener for all events.

* **`XE.listen_to     = ( key, self, listener ) ->`**—Register a listener for events that match `key`. No
  pattern matching is implemented atm, so you can only listen to all keys or a single key.

* **`XE.contract      = ( key, self, listener ) ->`**—Register a contractor (a.k.a. 'result producer') for
  events that match `key`.

For a demo with more coverage, have a look at
[experiments/demo-xemitter.coffee](./blob/master/src/experiments/demo-xemitter.coffee)
                                   <!-- https://github.com/loveencounterflow/pipedreams/blob/master/blob/master/src/experiments/demo-xemitter.coffee -->


