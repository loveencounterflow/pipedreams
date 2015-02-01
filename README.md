

- [Breaking News](#breaking-news)
	- [Changes](#changes)
	- ['Retroactive' Sub-Streams](#'retroactive'-sub-streams)
	- ['Dense' Sorting](#'dense'-sorting)
	- [🚫 Proceed with care; outdated docs below 🚫](#🚫-proceed-with-care;-outdated-docs-below-🚫)

> **Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*


# Breaking News

![stability-experimental-red](https://img.shields.io/badge/stability-experimental-red.svg)
![npm-0.2.5-yellowgreen](https://img.shields.io/badge/npm-0.2.5-yellowgreen.svg)
![motivation-字面明快排字機-yellow](https://img.shields.io/badge/motivation-字面明快排字機-yellow.svg)

This is the incubator for PipeDreams v2 (D2 for short), which will introduce breaking changes to some APIs.
I will slowly build up functionalities as i see use for them as i'm using PipeDreams v1 (D1 hereafter) in a
rather largeish project where it would be very cumbersome to migrate everything at once.

The major reason for PipeDreams v2 is [detailed in this gist](https://gist.github.com/loveencounterflow/65fd8ec711cf78950aa0)
and an accompanying [issue for the `through` package](https://github.com/dominictarr/through/issues/27).

I've since switched to [`through2`](https://github.com/rvagg/through2) to provide the underlying stream
handling; `through2` appears to work fine for my use case. In any event, PipeDreams v1 has a pretty uneven
implementation structure, since i started writing it when i was rather new to streams. It served me well
as a notebook of sorts on how to do streams in NodeJS, but now that i feel it to be too much of a hassle
to get asynchronous stream transformers right with version one, it's time for a rewrite.

<!-- ## Important

**When migrating and/or mixing D2 methods with stream methods from other libraries, watch out for
incompatibilities. Some parts of `through2` are known not to work well with some parts of `through` (and,
therefore, some parts of `event-stream`). Since D2 is based on `through2` and D1 is based on `event-stream`,
even mixing D2 and D1 may fail in interesting ways.**
 -->
<!--
## Changes

* (2014-10-18) `D2.remit` is the successor to `D1.remit` and the first function to be implemented in D2.

  Its interface has
  changed slightly, mainly to avoid silent failures when migrating. The major thing is that where you could
  previously call `send` as often as you wanted and never had to indicate whether your method would eventually
  issue more calls to `send`, you now

  * cannot call `send` any more (except to trigger an informative error message);
  * instead, you have to call either
    * `send.done()` (to issue zero items),
    * `send.done data` (to issue exactly one data item) or
    * `send.one a; send.one b; ... send.one z; send.done()` to issue an arbitrary
      number of data items. -->


## 'Retroactive' Sub-Streams


The PipeDreams v2 `$sub` method allows to formulate pipes which 'talk back', as it were, to upstream
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

Output:

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

## 'Dense' Sorting

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
## 🚫 Proceed with care; outdated docs below 🚫

For the time being, the implementation is the primary documentation;
all the greyed-out text below that is marked with a triple band to the left is not necessarily up to date.

> > > # PipeDreams
> > >
> > > Common operations for piped NodeJS streams.
> > >
> > > `npm install --save pipedreams`
> > >
> > > **Caveat** Below examples are all written in CoffeeScript.
> > >
> > > ## Highlights
> > >
> > > ### `P.remit`
> > >
> > > PipeDreams' `remit` method is my personal favorite to define pipe transformations. With `P.remit` you can
> > >
> > > * reject unwanted data items in the stream;
> > > * replace or modify data items;
> > > * add new data items;
> > > * send errors;
> > > * optionally, determine the end of the stream (at the time when you are looking at the last data item in the
> > >   stream).
> > >
> > > The versatility and easy of use make `remit` a good replacement for both the `map` and the `through` methods
> > > of `event-stream`. Let's have a look at some examples to demonstrate both points.
> > >
> > > #### The Problem
> > >
> > > PipeDreams is a library that is built on top of Dominic Tarr's great
> > > [event-stream](https://github.com/dominictarr/event-stream), which is "a toolkit to make creating and
> > > working with streams easy".
> > >
> > > Having worked a bit with `ES` and pipes, i soon found out that the dichotomy that exists in `event-stream`
> > > (`ES`) between `ES.map ( data, handler ) -> ...` and `ES.through on_data, on_end` is causing a lot of source
> > > code refactorings for me. This is because they work in fundamentally different ways.
> > >
> > > Let's say you want a data tranformer and define, like,
> > >
> > > ```coffee
> > > @$transform = ->
> > >   ### NB the fat arrow implicitly aliases `this` a.k.a. `@`
> > >   so we still refer to the module or class inside the function ###
> > >   return ES.map ( data, handler ) =>
> > >     return handler new Error "can't handle empty string" if data is ''
> > >     data = @do_some_fancy_stuff data
> > >     handler null, data
> > >
> > > input
> > >   .pipe $transform()
> > >   ...
> > > ```
> > >
> > > Later on, you discover you'd rather count empty `data` strings and, when the stream is done, emit a single
> > > error that tells the user how many illegal data items were found (with lengthy streams it can indeed be very
> > > handy to offer a summary of issues rather than to just stop processing at the very first one).
> > >
> > > To achieve this goal, you could go and define a module-level counter and another method that you tack to
> > > `input.on 'end'`. It's much cleaner though to have the counter encapsulated and stay with a single method
> > > in the pipe. `ES.through` let's you do that, but the above code does need some refactoring. To wit:
> > >
> > > ```coffee
> > > @$transform = ->
> > >   ### we need an alias because `this` a.k.a `@`
> > >   is not *this* 'this' inside `on_data`... ###
> > >   do_some_fancy_stuff = @do_some_fancy_stuff.bind @
> > >   count               = 0
> > >   #..........................................................................................
> > >   on_data = ( data ) ->
> > >     if data is ''
> > >       count += 1
> > >       return
> > >     data = do_some_fancy_stuff data
> > >     @emit 'data', data
> > >   #..........................................................................................
> > >   on_end = ->
> > >     @emit 'error', new Error "encountered #{count} illegal empty data strings" if count > 0
> > >     @emit 'end'
> > >   #..........................................................................................
> > >   return ES.through on_data, on_end
> > >
> > > input
> > >   .pipe $transform()
> > >   ...
> > > ```
> > >
> > > The differences are plenty:
> > >
> > > * we now have two functions instead of one;
> > > * we have to rewrite `ES.map X` as `ES.through Y, Z`;
> > > * there is no more `handler` (a.k.a. `callback`);
> > > * we have to call `@emit` and specify the event type (`data`, `error`, or `end`);
> > > * `this` has been re-bound by `ES.through`, much to my chagrin.
> > >
> > > The refactored code works, but after the *n* th time switching between callback-based and event-based
> > > methodologies i became weary of this and set out to write one meta-method to rule them all: PipeDream's
> > > `remit`.
> > >
> > > #### The Solution
> > >
> > > Continuing with the above example, this is what our transformer looks like with 'immediate' error reporting:
> > >
> > > ```coffee
> > > @$transform = ->
> > >   return P.remit ( data, send ) =>
> > >     return send.error new Error "can't handle empty string" if data is ''
> > >     data = @do_some_fancy_stuff data
> > >     send data
> > >
> > > input
> > >   .pipe $transform()
> > >   ...
> > > ```
> > >
> > > Now that's snappy. `remit` expects a method with two or three arguments; in this case, it's got a method
> > > with two arguments, where the first one represents the current `data` that is being piped, and the second
> > > one is specifically there to send data or (with `send.error`) errors. Quite neat.
> > >
> > > Now one interesting thing about `send` is that *it can be called an arbitrary number of times*, which lifts
> > > another limitation of doing it with `ES.map ( data, handler ) -> ...` where only a *single* call to
> > > `handler` is legal. If we wanted to, we could do
> > >
> > > ```coffee
> > > @$transform = ->
> > >   return P.remit ( data, send ) =>
> > >     return send.error new Error "can't handle empty string" if data is ''
> > >     send @do_some_fancy_stuff   data
> > >     send @do_other_fancy_stuff  data
> > > ```
> > >
> > > to make several data items out of a single one. If you wanted to silently drop a piece of data, just don't
> > > call `send`—there's no need to make an 'empty' call to `handler()` as you'd have to with `ES.map`.
> > >
> > > We promised easier code refactorings, and PipeDreams `remit` delivers. Here's the on-input-end sensitive
> > > version:
> > >
> > > ```coffee
> > > @$transform = ->
> > >   count = 0
> > >   return P.remit ( data, send, end ) =>
> > >     return count += 1 if data is ''
> > >     data = @do_some_fancy_stuff data
> > >     send data
> > >     if end?
> > >       send.error 'error', new Error "encountered #{count} illegal empty data strings" if count > 0
> > >       end()
> > >
> > > input
> > >   .pipe $transform()
> > >   ...
> > > ```
> > >
> > > The changes are subtle, quickly done, and do not affect the processing model:
> > >
> > > * add a third argument `end` to your transformer function;
> > > * check for `end?` (JavaScript: `end != null`) to know whether the end of the stream has been reached;
> > > * make sure you actually do call `end()` when you're done.
> > >
> > > You can still `send` as many data items as you like upon receiving `end`. Also note that, behind the scenes,
> > > PipeDreams buffers the most recent data item, so you will receive the very last item in the stream
> > > *together* with a non-empty `end` argument. This is good because you can then do your data processing
> > > upfront and the `end` event handling in the rear part of your code.
> > >
> > > **Caveat 1**: There's one thing to watch out for: **if the stream is completely empty, `data` will be `null`
> > > on the first call**. This may become a problem if you're like me and like to use CoffeeScript's
> > > destructuring assignments, viz.:
> > >
> > > ```coffee
> > > @$transform = ->
> > >   count = 0
> > >   return P.remit ( [ line_nr, name, street, city, phone, ], send, end ) =>
> > >     ...
> > > ```
> > >
> > > I will possibly address this by passing a special empty object singleton as `data` that will cause
> > > structured assingment-signatures as this one to fail silently; you'd still be obliged to check whether
> > > your arguments have values other than `undefined`. In the meantime, if you suspect a stream *could* be empty,
> > > just use
> > >
> > > ```coffee
> > > @$transform = ->
> > >   count = 0
> > >   return P.remit ( data, send, end ) =>
> > >     if data?
> > >       [ line_nr, name, street, city, phone, ] = data
> > >       ... process data ...
> > >     if end?
> > >       ... finalize ...
> > > ```
> > >
> > > and you should be fine.
> > >
> > > **Caveat 2**: Can you spot what's wrong with this code?:
> > >
> > > ```coffee
> > > @$count_good_beans_toss_bad_ones = ->
> > >   good_bean_count = 0
> > >   return P.remit ( bean, send, end ) =>
> > >     return if bean isnt 'good'
> > >     good_bean_count += 1
> > >     send bean
> > >     if end?
> > >       "we have #{good_bean_count} good beans!"
> > >       end()
> > > ```
> > >
> > > This source code has (almost) all of the features of an orderly written `remit` method, yet it will
> > > sometimes fail silently—but only if the very last bean is not a good one. The reason is the premature
> > > `return` statement which in that case prevents the `if end?` clause from ever being reached. **Avoid
> > > premature `return` statements in `remit` methods**. This code fixes the issue:
> > >
> > > ```coffee
> > > @$count_good_beans_toss_bad_ones = ->
> > >   good_bean_count = 0
> > >   return P.remit ( bean, send, end ) =>
> > >     if bean is 'good'
> > >       good_bean_count += 1
> > >       send bean
> > >     if end?
> > >       "we have #{good_bean_count} good beans!"
> > >       end()
> > > ```
> > > <!--
> > > **Caveat 3**: **Always use `end()` with methods that issue asynchronous calls.**
> > >
> > > The short:
> > >
> > > ```coffee
> > > @$address_from_name = ->
> > >   return P.remit ( name, send, end ) => # ⬅ ⬅ ⬅ remember to use `end` with async stream transformers
> > >     if name?
> > >       db.get_address name, ( error, address ) =>
> > >         return send.error if error?
> > >         send [ name, address, ]
> > >         end() if end? # ⬅ ⬅ ⬅ remember to actually call `end()` when it's present
> > > ```
> > >
> > > The reason: I believe when you issue an asynchronous call from an asynchronous method (or any other place
> > > in the code), then NodeJS should be smart enough to put a hold so those async calls can finish before
> > > the process terminates.
> > >
> > > However, it would appear that the stream API's `end` events (or maybe those
> > > of `event-stream`) are lacking these smarts. The diagnostic is the odd last line that's missing from your
> > > final output. I always use PipeDreams' `$show()` method in the pipe to get a quick overview of what's going
> > > on; and, sure enough, when moving the `.pipe P.$show()` line from top to bottom in your pipe and repeating the streaming
> > > process, somewhere a stream transformer will show up that does take the final piece of data as input but
> > > is late to the game when it's ready to pass back the results.
> > >
> > > The workaround is to use `remit` with three arguments
> > > `( data, send, end )`; that way, you 'grab' the `end` token and put everything on hold 'manually', as it
> > > were. Think of it as the baton in a relay race: you don't hold the baton—anyone could have it and finish the
> > > race. You hold the baton—you may walk as slowly as you like, and the game won't be over until you cross
> > > the finish or pass the baton.
> > >  -->
> > >
> > > ## Motivation
> > >
> > > > **a stream is just a series of things over time**. if you were to re-implement your
> > > > library to use your own stream implementation, you'd end up with an 80% clone
> > > > of NodeJS core streams (and get 20% wrong). so why not just use core streams?—*paraphrased
> > > > from Dominic Tarr, Nodebp April 2014: The History of Node.js Streams.*
> > >
> > > So i wanted to read those huge [GTFS](https://developers.google.com/transit/gtfs/reference) files for
> > > my nascent [TimeTable](https://github.com/loveencounterflow/timetable) project, and all went well
> > > except for those *humongous* files with millions and millions of lines.
> > >
> > > I stumbled over the popular [`csv-parse`](https://github.com/wdavidw/node-csv-parse#using-the-pipe-function)
> > > package that is widely used by NodeJS projects, and, looking at the `pipe` interface, i found it
> > > very enticing and suitable, so i started using it.
> > >
> > > Unfortunately, it so turned out that i kept loosing records from my data. Most blatantly, some data sets
> > > ended up containing a consistent number of 16384 records, although the affected sources contain many more
> > > and each one a different number of records.
> > > I've since found out that, alas, `csv-parse` has some issues related to stream backpressure not being handled
> > > correctly (see my [question on StackOverflow](http://stackoverflow.com/questions/25181441/how-to-work-with-large-files-nodejs-streams-and-pipes)
> > > and the related [issue on GitHub]()).
> > >
> > > More research revealed two things:
> > >
> > > * NodeJS streams *can* be difficult to grasp. They're new, they're hot, they're much talked about but
> > >   also somewhat underdocumented, and their API is just shy of being convoluted. Streams are so hard to
> > >   get right the NodeJS team saw it fit to introduce a second major version in 0.10.x—although
> > >   streams had been part of NodeJS from very early on.
> > >
> > > * More than a few projects out there provide software that use a non-core (?) stream implementation as part
> > >   of their project and expose the relevant methods in their API; `csv-parse`
> > >   is one of those, and hence its problems. Having looked at a few projects, i started to suspect that this
> > >   is wrong: CSV-parser-with-streams-included libraries are often very specific in what they allow you to do, and, hence, limited;
> > >   moreover, there is a tendency for those stream-related methods to eclipse what a CSV parser, at its core, should
> > >   be good at (parsing CSV).
> > >
> > >   Have a look at the [`fast-csv` API](http://c2fo.github.io/fast-csv/index.html)
> > >   to see what i mean: you get a lot of `fastcsv.createWriteStream`, `fastcsv.fromStream` and so on methods.
> > >   Thing is, you don't need that stuff to work with streams, and you don't need that stuff to parse
> > >   CSV files, so those methods are simply superfluous.
> > >
> > > **A good modern NodeJS CSV parser should be
> > > *compatible* with streams, it should *not replace* or emulate NodeJS core streams—that is a violation
> > > of the principle of [Separation of Concerns (SoC)](http://en.wikipedia.org/wiki/Separation_of_concerns).**
> > >
> > > A nice side effect of this maxime is that the individual functions i write to handle and manipulate got
> > > simpler upon rejecting solutions that had all the batteries and the streams included in their supposedly
> > > convenient setups. It's a bit like when you want a new mat to sit on when driving: you'd probably
> > > prefer that standalone / small / cheap / focused offering over the one that includes all of the upholstering, as that would be
> > > quite a hassle to get integrated with your existing vehicle. It's maybe no accident that all the solutions
> > > i found on the websites promoting all-in-one solutions give a *lot* of snippets how you can turn their
> > > APIs inside-out from piping to event-based to making pancakes, but they never show you a real-world example
> > > that shows how to weave those solutions into a long pipeline of data transformations, which is what stream
> > > pipelines are there for and excel at.
> > >
> > > Scroll down a bit to see a real-world example built with PipeDreams.
> > >
> > > ## Overview
> > >
> > > PipeDreams—as the name implies—is centered around the pipeline model of working with streams. A quick
> > > (CoffeeScript) example is in place:
> > >
> > > ```coffee
> > > P = require 'pipedreams'                                                  #  1
> > >                                                                           #  2
> > > @read_stop_times = ( registry, route, handler ) ->                        #  3
> > >   input = P.create_readstream route, 'stop_times'                         #  4
> > >   input.pipe P.$split()                                                   #  5
> > >     .pipe P.$sample                     1 / 1e4, headers: true            #  6
> > >     .pipe P.$skip_empty()                                                 #  7
> > >     .pipe P.$parse_csv()                                                  #  8
> > >     .pipe @$clean_stoptime_record()                                       #  9
> > >     .pipe P.$set                        '%gtfs-type',     'stop_times'    # 10
> > >     .pipe P.$delete_prefix              'trip_'                           # 11
> > >     .pipe P.$dasherize_field_names()                                      # 12
> > >     .pipe P.$rename                     'id',             '%gtfs-trip-id' # 13
> > >     .pipe P.$rename                     'stop-id',        '%gtfs-stop-id' # 14
> > >     .pipe P.$rename                     'arrival-time',   'arr'           # 15
> > >     .pipe P.$rename                     'departure-time', 'dep'           # 16
> > >     .pipe @$add_stoptimes_gtfsid()                                        # 17
> > >     .pipe @$register                    registry                          # 18
> > >     .on 'end', ->                                                         # 19
> > >       info 'ok: stoptimes'                                                # 20
> > >       return handler null, registry                                       # 21
> > > ```
> > >
> > > i agree that there's a bit of line noise here, so let's rewrite that piece in cleaned-up pseudo-code:
> > >
> > > ```coffee
> > > P = require 'pipedreams'                                                  #  1
> > >                                                                           #  2
> > > read_stop_times = ( registry, route, handler ) ->                         #  3
> > >   input = create_readstream route, 'stop_times'                           #  4
> > >     | split()                                                             #  5
> > >     | sample                     1 / 1e4, headers: true                   #  6
> > >     | skip_empty()                                                        #  7
> > >     | parse_csv()                                                         #  8
> > >     | clean_stoptime_record()                                             #  9
> > >     | set                        '%gtfs-type',      'stop_times'          # 10
> > >     | delete_prefix              'trip_'                                  # 11
> > >     | dasherize_field_names()                                             # 12
> > >     | rename                     'id',             '%gtfs-trip-id'        # 13
> > >     | rename                     'stop-id',        '%gtfs-stop-id'        # 14
> > >     | rename                     'arrival-time',   'arr'                  # 15
> > >     | rename                     'departure-time', 'dep'                  # 16
> > >     | add_stoptimes_gtfsid()                                              # 17
> > >     | register                    registry                                # 18
> > >     .on 'end', ->                                                         # 19
> > >       info 'ok: stoptimes'                                                # 20
> > >       return handler null, registry                                       # 21
> > > ```
> > >
> > > What happens here is, roughly:
> > >
> > > * On **line #4**, `input` is a PipeDreams ReadStream object created as `create_readstream route,
> > > label`. PipeDreams ReadStreams are nothing but what NodeJS gives you with `fs.createReadStream`; they're
> > > just a bit pimped so you get a [nice progress bar on the console](https://github.com/visionmedia/node-progress)
> > > which is great because those files can take *minutes* to process completely, and it's nasty to stare at
> > > a silent command line that doesn't keep you informed what's going on. Having a progress bar pop up is
> > > great because i used to report progress numbers manually, and now i get a better solution for free.
> > >
> > > * On **line #5**, we put a `split` operation (as `P.$split()`) into the pipeline, which is just
> > > `eventstream.split()` and splits whatever is read from the file into (chunks that are) lines. You do not
> > > want that if you're reading, say, `blockbusters.avi` from the disk, but you certainly want that if you're
> > > reading `all-instances-where-a-bus-stopped-at-a-bus-stop-in-northeast-germany-in-fall-2014.csv`, which,
> > > if left unsplit, is an unwieldy *mass* of data. As the CSV format mandates an optional header line and
> > > one record per line of text, splitting into lines is a good preparation for getting closer to the data.
> > >
> > > > For those who have never worked with streams or piping, observe that we have a pretty declarative interface
> > > > here that does not readily reveal *how* things are done and on *which* arguments. That's great for building
> > > > an abstraction—the code looks a lot like a Table of Contents where actions are labeled (and not
> > > > described in detail), but it can be hard to wrap one's mind around. Fear you not, we'll have a look at some
> > > > sample methods later on; those are pretty straightforward. Believe me when i say **you don't have to pass
> > > > an exam on the [gritty details of the NodeJS Streams API](http://nodejs.org/api/stream.html) to use
> > > > PipeDreams**.
> > > >
> > > > For the moment being, it's just important to know that what is passed between line #4
> > > > `input = ...` and line #5 `split` are some arbitrarily-sized chunks of binary data which get transformed
> > > > into chunks of line-sized text and passed into line #6 `sample ...`. The basic idea is that each step
> > > > does something small / fast / elementary / generic to whatever it receives from above, and passes the result
> > > > to the next stop in the pipe.
> > >
> > > * On **line #6**, we have `P.$sample 1 / 1e4, headers: true` (for non-CS-folks:
> > > `P.$sample( 1 / 1e4, { headers: true} )`). Let's dissect that one by one:
> > >
> > >   * `P`, of course, is simply the
> > >     result of `P = require 'pipedreams'`. I'm not much into abbreviations in coding, but since this
> > >     particular reference will appear, like, *all* over the place, let's make it a snappy one.
> > >
> > >   * `$sample` is a method of `P`. I adopt the convention of prefixing all methods that are suitable as an
> > >     argument to a `pipe` method with `$`. This is to signal that **not `sample` itself, but rather its
> > >     return value** should be put into the pipe. When you start to write your own pipes, you will often
> > >     inadvertently write `input_A.pipe f`, `input_B.pipe f` and you'll have a problem: typically you do not
> > >     want to share state between two unrelated streams, so each stream must get its unique pipe members.
> > >     **Your piping functions are all piping function producers**—higher-order functions, that is. The
> > >     `$` sigil is there to remind you of that: *$ == 'you must call this function in order to get the function
> > >     you want in the pipe'*.
> > >
> > >   * What does `$sample` do?—From the documentation:
> > >
> > >     > Given a `0 <= p <= 1`, interpret `p` as the <b>P</b>robability to <b>P</b>ick a given record and otherwise toss
> > >     > it, so that `$sample 1` will keep all records, `$sample 0` will toss all records, and
> > >     > `$sample 0.5` (the default) will toss (on average) every other record.
> > >
> > >     In other words, the argument `1 / 1e4` signals: pick one out of 10'000 records, toss (delete / skip
> > >     / omit / forget / drop / ignore, you get the idea) everything else. The use of the word 'record' is
> > >     customary here; in fact, it means 'whatever you get passed as data when called'. That could be
> > >     a CSV record, a line of text, a number, a list of values, anything. `$sample`, like many PipeDreams
> > >     methods, is fully generic and agnostic. Just as the quote above says, "a stream is just a series of things over time".
> > >     In the previous step we `split`ted a binary stream into lines of text, so a 'record' at this
> > >     particular point is just that, a line of text. Move `$sample` two steps downstream, and it'll get to see a
> > >     parsed CSV record instead.
> > >
> > >     Now the file that is being read here happens to contain 3'722'578 records, and this is why there's that
> > >     `$sample` command (and why it is place in front of the actual CSV parsing): to fully process every
> > >     single record takes minutes, which is tedious for
> > >     testing. When a record is tossed, none of the ensuing pipe methods get anything to work on; this
> > >     reduces minutes of processing to seconds. Of course, you do not get the full amount of data, but you do get to work
> > >     on a representative sample, which is invaluable for developing (you can even make it so that the
> > >     random sample stays the *same* across runs, which can also be important).—You probably want to make
> > >     the current ratio (here: `1 / 1e4`) a configuration variable that is set to `1` in production.
> > >
> > >     The second argument to `$sample`, `headers: true`, is there to ensure `$sample` won't accidentally
> > >     toss out the CSV header with the field names, as that would damage the data.
> > >
> > > > It's already becoming clear that PipeDreams is centered around two things: parsing CSV files, and
> > > > dealing with big files. This is due to the circumstances leading to its creation. That said, i try
> > > > to keep it as general as possible to be useful for other use-cases that can profit from streams.
> > >
> > >   * On **line #7**, it's `P.$skip_empty()`. Not surprisingly, this step eliminates all empty lines. On
> > >     second thought, that step should appear in front of the call to `$sample`, don't you think?
> > >
> > >   * On **line #8**, it's time to `P.$parse_csv()`. For those among us who are good at digesting CoffeeScript,
> > >     here is the implementation; you can see it's indeed quite straightforward:
> > >
> > >     ```coffee
> > >     ### http://stringjs.com/ ###
> > >     S = require 'string'
> > >
> > >     @$parse_csv = ->
> > >       field_names = null
> > >       return @$ ( record, handler ) =>
> > >         values = ( S record ).parseCSV ',', '"', '\\'
> > >         if field_names is null
> > >           field_names = values
> > >           return handler()
> > >         record = {}
> > >         record[ field_names[ idx ] ] = value for value, idx in values
> > >         handler null, record
> > >     ```
> > >     For pure-JS aficionados, the outline of that is, basically,
> > >
> > >     ```javascript
> > >     this.$parse_csv = function() {
> > >       var field_names = null;
> > >       return this.$( function( record, handler ) {
> > >         ...
> > >         })
> > >       }
> > >     ```
> > >     which makes it clear that `$parse_csv` is a function that returns a function. Incidentally, it also
> > >     keeps some state in its closure, as `field_names` is bound to become a list of names the moment that
> > >     the pipeline hits the first line of the file. This clarifies what we talked about earlier: you do
> > >     not want to share this state across streams—one stream has one set of CSV headers, another stream,
> > >     another set. That's why it's so important to individualize members of a stream's pipe.
> > >
> > >     > It's also quite clear that this implementation is both quick and dirty: it assumes the CSV does have
> > >     > headers, that fields are separated by commas, strings may be surrounded by double quotes, and so on.
> > >     > Those details should really be made configurable, which hasn't yet happened here. Again, the moment
> > >     > you call `P.$parse_csv` would be a perfect moment to fill out those details and get a bespoke
> > >     > method that suits the needs at hand.
> > >
> > >     One more important detail: the `record` that comes into (the function returned by) `$parse_csv` is
> > >     a line of text; the `record` that goes out of it is a plain old object with named values. All the
> > >     pipe member functions work in essentially this way: they accept whatever they're wont to accept and
> > >     pass on whatever they see fit.
> > >
> > >     > ...which puts a finger on another sore spot, the glaring absence of meaningful type checking and
> > >     > error handling in this model function.
> > >
> > >
> > > Now let's dash a little faster across the remaining lines:
> > >
> > >   * On **lines #9—#18**,
> > >
> > >     ```coffee
> > >     .pipe @$clean_stoptime_record()                                       #  9
> > >     .pipe P.$set                        '%gtfs-type', 'stop_times'        # 10
> > >     .pipe P.$delete_prefix              'trip_'                           # 11
> > >     .pipe P.$dasherize_field_names()                                      # 12
> > >     .pipe P.$rename                     'id', '%gtfs-trip-id'             # 13
> > >     # ...
> > >     .pipe @$add_stoptimes_gtfsid()                                        # 17
> > >     .pipe @$register                    registry                          # 18
> > >     ```
> > >
> > >     we (**#9**) clean the record of unwanted fields (there are quite a few in the data); then we (**#10**)
> > >     set a field `%gtfs-type` to value `'stop_times'` (the same for all records in the pipeline). Next
> > >     (**#11**) we delete a redundant field name prefix using a PipeDreams method, (**#12**) change all the
> > >     underscored field names to dashed style, (**#13**) rename a field and then some; we then (**#17**) call
> > >     a custom method to add an ID field and, finally, on **line #18**, we register the record in
> > >     a registry.
> > >
> > >
> > >
