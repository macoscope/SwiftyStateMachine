//
//  StateMachine.swift
//  StateMachine
//
//  Created by Maciej Konieczny on 2015-03-24.
//  Copyright (c) 2015 Macoscope. All rights reserved.
//

public struct StateMachineStructure<S, E, T> {
    public let initialState: S
    private let transitionLogic: (S, E, T?, StateMachine<S, E, T>) -> (S, (() -> ())?)?

    public init(initialState: S, transitionLogic: (S, E, T?, StateMachine<S, E, T>) -> (S, (() -> ())?)?) {
        self.initialState = initialState
        self.transitionLogic = transitionLogic
    }

    public func stateMachineWithSubject(subject: T?) -> StateMachine<S, E, T> {
        return StateMachine(structure: self, subject: subject)
    }
}


public class StateMachine<S, E, T> {
    public var state: S

    private let structure: StateMachineStructure<S, E, T>
    private let subject: T?

    public init(structure: StateMachineStructure<S, E, T>, subject: T?) {
        self.state = structure.initialState
        self.structure = structure
        self.subject = subject
    }

    public func handleEvent(event: E) {
        if let (newState, transition) = structure.transitionLogic(state, event, subject, self) {
            state = newState
            transition?()
        }
    }
}
