*This document describes an unreleased, work-in-progress version of the
framework.  [Visit this link](https://github.com/macoscope/SwiftyStateMachine/tree/0.2.0#swiftystatemachine)
to go back in time and view the latest released version.*


SwiftyStateMachine [![codebeat badge](https://codebeat.co/badges/2180c3a3-30b6-48c3-a0e1-ea1f6af25f66)](https://codebeat.co/projects/github-com-macoscope-swiftystatemachine)
==================

A Swift µframework for creating [finite-state machines][FSM], designed
for clarity and maintainability.  Can create diagrams:

![example digraph](example-digraph.png)

- Version 0.3.0-work-in-progress (following [Semantic Versioning][])
- Developed and tested under Swift 2.1 (Xcode 7.1)
- Published under the [MIT License](LICENSE)
- [Carthage][] compatible
- [CocoaPods][] compatible

  [FSM]: http://en.wikipedia.org/wiki/Finite-state_machine
  [Semantic Versioning]: http://semver.org/
  [Carthage]: https://github.com/Carthage/Carthage
  [CocoaPods]: https://cocoapods.org/


Table of Contents
-----------------

- [Features](#features)
- [Documentation](#documentation)
- [Installation](#installation)
- [Example](#example)
- [Development](#development)
- [Copyright](#copyright)


Features
--------

- Diagrams that can be automatically saved in your repo each time you run
  the app in the simulator
- Immutable, reusable state machine schemas
- Readable state and event names — no long prefixes
- Type safety: errors will appear at compilation when a state or an event
  are absent from  schema, when passing an event from a different state
  machine, etc.


Documentation
-------------

API documentation is in the source.  See [Example](#example) for code
samples with an explanation.  For more introduction, see [the post on
the Macoscope blog][blog].

  [blog]: http://macoscope.com/blog/swifty-state-machine/


Installation
------------

SwiftyStateMachine is a framework — you can build it and drag it to your
project.  We provide built frameworks for iOS and OS X in ZIP files on
our [Releases](https://github.com/macoscope/SwiftyStateMachine/releases)
page.

If you want to automate the installation and future updates, we recommend
using [Carthage][Carthage add]:

    # Cartfile
    github "macoscope/SwiftyStateMachine" == 0.3.0

  [Carthage add]: https://github.com/Carthage/Carthage#adding-frameworks-to-an-application


You can also use [CocoaPods][]:

    # Podfile
    pod 'SwiftyStateMachine', '0.3.0'


Example
-------

In this example, we're going to implement a simple state machine you've
seen at the beginning of this file:

![example digraph](example-digraph.png)

Let's start with defining `enum`s for states and events:

```swift
enum Number {
    case One, Two, Three
}

enum Operation {
    case Increment, Decrement
}
```

Next, we have to specify the state machine layout.  In SwiftyStateMachine,
that means creating a schema.  Schemas are immutable `struct`s that can be
used by many `StateMachine` instances.  They indicate the initial state
and describe transition logic, i.e. how states are connected via events and
what code is executed during state transitions.

Schemas incorporate three generic types: `State` and `Event`, which we
defined above, and `Subject` which represents an object associated with
a state machine.  To keep things simple we won't use subject right now,
so we'll specify its type as `Void`:

```swift
import SwiftyStateMachine

let schema = StateMachineSchema<Number, Operation, Void>(initialState: .One) { (state, event) in
    switch state {
        case .One: switch event {
            case .Decrement: return nil
            case .Increment: return (.Two, { _ in print("1 → 2") })
            // we used nil to ignore the event
            // and _ to ignore the subject
        }

        case .Two: switch event {
            case .Decrement: return (.One, { _ in print("2 → 1") })
            case .Increment: return (.Three, { _ in print("2 → 3") })
        }

        case .Three: switch event {
            case .Decrement: return (.Two, nil)  // nil transition block
            case .Increment: return nil
        }
    }
}
```

You probably expected nested `switch` statements after defining two
`enum`s. :wink:

To understand the above snippet, it's helpful to look at the initializer's
signature:

```swift
init(initialState: State,
     transitionLogic: (State, Event) -> (State, (Subject -> ())?)?)
```

We specify transition logic as a block.  It accepts two arguments: the
current state and the event being handled.  It returns an optional tuple
of a new state and an optional transition block.  When the tuple is
`nil`, it indicates that there is no transition for a given state-event
pair, i.e. a given event should be ignored in a given state.  When the
tuple is non-`nil`, it specifies the new state that the machine should
transition to and a block that should be called after the transition.
The transition block is optional.  It gets passed a `Subject` object
as an argument, which we ignored in this example by using `_`.

Now, let's create a machine based on the schema and test it:

```swift
// we use () as subject because subject type is Void
var machine = StateMachine(schema: schema, subject: ())

machine.handleEvent(.Decrement)  // nothing happens
if machine.state == .One { print("one") }  // prints "one"

machine.handleEvent(.Increment)  // prints "1 → 2"
if machine.state == .Two { print("two") }  // prints "two"
```

Cool.  We can also get notified about transitions by providing a
`didTransitionCallback` block.  It is called after a transition with
three arguments: the state before the transition, the event causing the
transition, and the state after the transition:

```swift
machine.didTransitionCallback = { (oldState, event, newState) in
    print("changed state!")
}
```

OK, what about the diagram?  SwiftyStateMachine can create diagrams in
the [DOT graph description language][DOT].  To create a diagram, we have
to use `GraphableStateMachineSchema` which has the same initializer as
the regular `StateMachineSchema`, but requires state and event types to
conform to the [`DOTLabelable`][DOTLabelable] protocol.  This protocol
makes sure that all elements have nice readable labels and that they are
present on the graph (there's no way to automatically find all
`enum` cases):

  [DOT]: http://en.wikipedia.org/wiki/DOT_%28graph_description_language%29
  [DOTLabelable]: StateMachine/GraphableStateMachineSchema.swift

```swift
extension Number: DOTLabelable {
    static var DOTLabelableItems: [Number] {
        return [.One, .Two, .Three]
    }

    // Implementing this property in not required but we show it here for the
    // sake of completeness.  You can use it to customize labels on the graph.
    // In the following implementation we are basically returning `"\(self)"`.
    // In fact, this protocol already has a default implementation that does
    // just that.  Because of this, we will skip `DOTLabel` when implementing
    // `DOTLabelable` extension of `Operation`.
    var DOTLabel: String {
        switch self {
            case .One: return "One"
            case .Two: return "Two"
            case .Three: return "Three"
        }
    }
}

extension Operation: DOTLabelable {
    static var DOTLabelableItems: [Operation] {
        return [.Increment, .Decrement]
    }
}
```

When our types conform to `DOTLabelable`, we can define our structure as
before, but this time using `GraphableStateMachineSchema`.  Then we can
print the diagram:

```swift
let schema = GraphableStateMachineSchema// ...
print(schema.DOTDigraph)
```

```dot
digraph {
    graph [rankdir=LR]

    0 [label="", shape=plaintext]
    0 -> 1 [label="START"]

    1 [label="One"]
    2 [label="Two"]
    3 [label="Three"]

    1 -> 2 [label="Increment"]
    2 -> 3 [label="Increment"]
    2 -> 1 [label="Decrement"]
    3 -> 2 [label="Decrement"]
}
```

[On iOS][] we can even have the graph file saved in the repo each time
we run the app in the simulator:

  [On iOS]: https://github.com/macoscope/SwiftyStateMachine/commit/9b4963c26a934915b56d5023f84e42ff128f6a1d

```swift
try schema.saveDOTDigraphIfRunningInSimulator(filepathRelativeToCurrentFile: "123.dot")
```

[DOT][] files can be viewed by a number of applications, including the free
[Graphviz][].  If you use [Homebrew][], you can install Graphviz with
the following commands:

    brew update
    brew install graphviz --with-app
    brew linkapps graphviz

  [Graphviz]: http://www.graphviz.org/
  [Homebrew]: http://brew.sh/

Graphviz comes with a `dot` command which can be used to generate graph
images without launching the GUI app:

    dot -Tpng 123.dot > 123.png

This ends our example and the tour of SwiftyStateMachine's API.
Enjoy improving your code by explicitly defining distinct states and
transitions between them!  While you do so, please keep two things in
mind:

1) Your subjects are probably reference types (classes).  Storing a
state machine as a property of a subject normally would create a reference
cycle, so SwiftyStateMachine uses weak references for class-based subjects.
This means you have to keep a strong reference to a subject somewhere else,
but you usually already do this.  When subject references become `nil`,
transitions are no longer performed.

2) Remember that [Swift `enum`s][enums] can have associated values — you
can pass additional information with events or store data in states.
For example, if you had a game with a [heads-up display][HUD], you could
do something like this:

```swift
enum HUDEvent {
    case TakeDamage(Double)
    // ...
}

// ...

machine.handleEvent(.TakeDamage(13.37))
```

  [enums]: https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/Enumerations.html
  [HUD]: http://en.wikipedia.org/wiki/HUD_%28video_gaming%29


Development
-----------

If you see a way to improve the project, please leave a comment, open
an [issue][] or start a [pull request][].  It's better to begin with
an issue rather than a pull request, though, because we might disagree
whether the proposed change is an actual improvement. :wink:

To run tests, install [Carthage][] and run `carthage update` to download
and build test frameworks.

When introducing changes, please try to conform to the style present in
the project — both with respect to code formatting and commit messages.
We recommend following [GitHub Swift Style Guide][] with one important
difference: 4 spaces instead of tabs.

Thanks! :v:

  [issue]: https://github.com/macoscope/SwiftyStateMachine/issues
  [pull request]: https://github.com/macoscope/SwiftyStateMachine/pulls
  [GitHub Swift Style Guide]: https://github.com/github/swift-style-guide


Copyright
---------

Published under the [MIT License](LICENSE).
Copyright (c) 2015 [Macoscope][] sp. z o.o.

  [Macoscope]: http://macoscope.com
