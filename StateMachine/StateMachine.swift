//
//  StateMachine.swift
//  StateMachine
//
//  Created by Maciej Konieczny on 2015-03-24.
//  Copyright (c) 2015 Macoscope. All rights reserved.
//

public protocol DOTLabel {
    var DOTLabel: String { get }
}


public protocol StateMachineStructureType {
    typealias State
    typealias Event
    typealias Subject

    var initialState: State { get }
    var transitionLogic: (State, Event) -> (State, (Subject -> ())?)? { get }
}


public struct StateMachineStructure<A, B, C>: StateMachineStructureType {
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


public struct GraphableStateMachineStructure<A: DOTLabel, B: DOTLabel, C>: StateMachineStructureType {
    typealias State = A
    typealias Event = B
    typealias Subject = C

    public let initialState: State
    public let transitionLogic: (State, Event) -> (State, (Subject -> ())?)?
    public let DOTDigraph: String

    public init(graphStates: [State], graphEvents: [Event], initialState: State, transitionLogic: (State, Event) -> (State, (Subject -> ())?)?) {
        self.initialState = initialState
        self.transitionLogic = transitionLogic
        self.DOTDigraph = GraphableStateMachineStructure.DOTDigraphGivenTransitionLogic(transitionLogic, initialState: initialState, states: graphStates, events: graphEvents)
    }

    private static func DOTDigraphGivenTransitionLogic(transitionLogic: (State, Event) -> (State, (Subject -> ())?)?, initialState: State, states: [State], events: [Event]) -> String {
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


public struct StateMachine<T: StateMachineStructureType> {
    public var state: T.State
    public var didTransitionCallback: ((T.State, T.Event, T.State) -> ())?

    private let structure: T
    private let subject: T.Subject

    public init(structure: T, subject: T.Subject) {
        self.state = structure.initialState
        self.structure = structure
        self.subject = subject
    }

    public mutating func handleEvent(event: T.Event) {
        if let (newState, transition) = structure.transitionLogic(state, event) {
            let oldState = state
            state = newState
            transition?(subject)
            didTransitionCallback?(oldState, event, newState)
        }
    }
}


/// Helper function used when generating DOT digraph strings.
private func label<T: DOTLabel>(x: T) -> String {
    return x.DOTLabel
}
