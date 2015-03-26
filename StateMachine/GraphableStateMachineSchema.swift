//
//  GraphableStateMachineSchema.swift
//  SwiftyStateMachine
//
//  Created by Maciej Konieczny on 2015-03-26.
//  Copyright (c) 2015 Macoscope. All rights reserved.
//

import Foundation


public protocol DOTLabelable {
    var DOTLabel: String { get }
    static var DOTLabelableItems: [Self] { get }
}


public struct GraphableStateMachineSchema<A: DOTLabelable, B: DOTLabelable, C>: StateMachineSchemaType {
    typealias State = A
    typealias Event = B
    typealias Subject = C

    public let initialState: State
    public let transitionLogic: (State, Event) -> (State, (Subject -> ())?)?
    public let DOTDigraph: String

    public init(initialState: State, transitionLogic: (State, Event) -> (State, (Subject -> ())?)?) {
        self.initialState = initialState
        self.transitionLogic = transitionLogic
        self.DOTDigraph = GraphableStateMachineSchema.DOTDigraphGivenInitialState(initialState, transitionLogic: transitionLogic)
    }

    #if os(OSX)
    // TODO: Figure out how detect scenario "I'm running my Mac app from Xcode".
    //
    // Verify if [`AmIBeingDebugged`][1] can be used here.  In particular, figure out
    // if this means that an app will be rejected during App Review:
    //
    // > Important: Because the definition of the kinfo_proc structure (in <sys/sysctl.h>) 
    // > is conditionalized by __APPLE_API_UNSTABLE, you should restrict use of the above
    // > code to the debug build of your program.
    // 
    //   [1]: https://developer.apple.com/library/mac/qa/qa1361/_index.html
    #else
    public func saveDOTDigraphIfRunningInSimulator(#filepathRelativeToCurrentFile: String, file: String = __FILE__) {
        if TARGET_IPHONE_SIMULATOR == 1 {
            let filepath = file.stringByDeletingLastPathComponent.stringByAppendingPathComponent(filepathRelativeToCurrentFile)
            DOTDigraph.writeToFile(filepath, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        }
    }
    #endif

    private static func DOTDigraphGivenInitialState(initialState: State, transitionLogic: (State, Event) -> (State, (Subject -> ())?)?) -> String {
        let states = State.DOTLabelableItems
        let events = Event.DOTLabelableItems

        var stateIndexesByLabel: [String: Int] = [:]
        for (i, state) in enumerate(states) {
            stateIndexesByLabel[label(state)] = i + 1
        }

        func index(state: State) -> Int {
            return stateIndexesByLabel[label(state)]!
        }

        var digraph = "digraph {\n    graph [rankdir=LR]\n\n    0 [label=\"\", shape=plaintext]\n    0 -> \(index(initialState)) [label=\"START\"]\n\n"

        for state in states {
            digraph += "    \(index(state)) [label=\"\(label(state))\"]\n"
        }

        digraph += "\n"

        for fromState in states {
            for event in events {
                if let (toState, _) = transitionLogic(fromState, event) {
                    digraph += "    \(index(fromState)) -> \(index(toState)) [label=\"\(label(event))\"]\n"
                }
            }
        }

        digraph += "}"

        return digraph
    }
}


/// Helper function used when generating DOT digraph strings.
private func label<T: DOTLabelable>(x: T) -> String {
    return x.DOTLabel.stringByReplacingOccurrencesOfString("\"", withString: "\\\"", options: .LiteralSearch, range: nil)
}
