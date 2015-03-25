//
//  StateMachine.swift
//  StateMachine
//
//  Created by Maciej Konieczny on 2015-03-24.
//  Copyright (c) 2015 Macoscope. All rights reserved.
//

public protocol DOTLabelable {
    var DOTLabel: String { get }
    static var DOTLabelableItems: [Self] { get }
}


public protocol StateMachineSchemaType {
    typealias State
    typealias Event
    typealias Subject

    var initialState: State { get }
    var transitionLogic: (State, Event) -> (State, (Subject -> ())?)? { get }
}


public struct StateMachineSchema<A, B, C>: StateMachineSchemaType {
    typealias State = A
    typealias Event = B
    typealias Subject = C

    public let initialState: State
    public let transitionLogic: (State, Event) -> (State, (Subject -> ())?)?

    public init(initialState: State, transitionLogic: (State, Event) -> (State, (Subject -> ())?)?) {
        self.initialState = initialState
        self.transitionLogic = transitionLogic
    }
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


public struct StateMachine<T: StateMachineSchemaType> {
    public var state: T.State
    public var didTransitionCallback: ((T.State, T.Event, T.State) -> ())?

    private let schema: T
    private let subject: T.Subject

    public init(schema: T, subject: T.Subject) {
        self.state = schema.initialState
        self.schema = schema
        self.subject = subject
    }

    public mutating func handleEvent(event: T.Event) {
        if let (newState, transition) = schema.transitionLogic(state, event) {
            let oldState = state
            state = newState
            transition?(subject)
            didTransitionCallback?(oldState, event, newState)
        }
    }
}


/// Helper function used when generating DOT digraph strings.
private func label<T: DOTLabelable>(x: T) -> String {
    return x.DOTLabel.stringByReplacingOccurrencesOfString("\"", withString: "\\\"", options: .LiteralSearch, range: nil)
}
