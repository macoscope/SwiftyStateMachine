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


public class StateMachineStructure<S, E, T> {
    public let initialState: S
    private let transitionLogic: (S, E, T, StateMachine<S, E, T>) -> (S, (() -> ())?)?

    public init(initialState: S, transitionLogic: (S, E, T, StateMachine<S, E, T>) -> (S, (() -> ())?)?) {
        self.initialState = initialState
        self.transitionLogic = transitionLogic
    }

    public func stateMachineWithSubject(subject: T) -> StateMachine<S, E, T> {
        return StateMachine(structure: self, subject: subject)
    }
}


public class GraphableStateMachineStructure<S: DOTLabel, E: DOTLabel, T>: StateMachineStructure<S, E, T> {
    public let DOTDigraph: String

    public init(graphStates: [S], graphEvents: [E], graphSubject: T, initialState: S, transitionLogic: (S, E, T, StateMachine<S, E, T>) -> (S, (() -> ())?)?) {
        DOTDigraph = GraphableStateMachineStructure.DOTDigraphGivenStates(graphStates, events: graphEvents, stateMachine: StateMachineStructure(initialState: initialState, transitionLogic: transitionLogic).stateMachineWithSubject(graphSubject))
        super.init(initialState: initialState, transitionLogic: transitionLogic)
    }

    private class func DOTDigraphGivenStates(states: [S], events: [E], stateMachine machine: StateMachine<S, E, T>) -> String {
        var stateIndexesByLabel: [String: Int] = [:]
        var digraph = "digraph {\n    graph [rankdir=LR]\n\n    0 [label=\"\", shape=plaintext]\n    0 -> 1 [label=\"START\"]\n\n"

        for (i, state) in enumerate(states) {
            let index = i + 1
            let label = state.DOTLabel
            stateIndexesByLabel[label] = index

            digraph += "    \(index) [label=\"\(label)\"]\n"
        }

        digraph += "\n"

        for fromState in states {
            for event in events {
                if let (toState, _) = machine.structure.transitionLogic(fromState, event, machine.subject, machine) {
                    let fromIndex = stateIndexesByLabel[fromState.DOTLabel]!
                    let toIndex = stateIndexesByLabel[toState.DOTLabel]!

                    digraph += "    \(fromIndex) -> \(toIndex) [label=\"\(event.DOTLabel)\"]\n"
                }
            }
        }

        digraph += "}"

        return digraph
    }
}


public struct StateMachine<S, E, T> {
    public var state: S
    public var didTransitionCallback: ((S, E, S) -> ())?

    private let structure: StateMachineStructure<S, E, T>
    private let subject: T

    public init(structure: StateMachineStructure<S, E, T>, subject: T) {
        self.state = structure.initialState
        self.structure = structure
        self.subject = subject
    }

    public mutating func handleEvent(event: E) {
        if let (newState, transition) = structure.transitionLogic(state, event, subject, self) {
            let oldState = state
            state = newState
            transition?()
            didTransitionCallback?(oldState, event, newState)
        }
    }
}
