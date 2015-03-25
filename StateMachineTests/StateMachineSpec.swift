//
//  StateMachineSpec.swift
//  StateMachineSpec
//
//  Created by Maciej Konieczny on 2015-03-24.
//  Copyright (c) 2015 Macoscope. All rights reserved.
//

import Quick
import Nimble

import StateMachine


private struct NumberKeeper {
    var n: Int
}


private enum Number: DebugPrintable {
    case One, Two, Three

    var debugDescription: String {
        switch self {
            case .One: return "One"
            case .Two: return "Two"
            case .Three: return "Three"
        }
    }
}

private enum Operation {
    case Increment, Decrement

    var debugDescription: String {
        switch self {
            case .Increment: return "Increment"
            case .Decrement: return "Decrement"
        }
    }
}


extension Number: DOTLabel {
    var DOTLabel: String {
        return debugDescription
    }
}

extension Operation: DOTLabel {
    var DOTLabel: String {
        return debugDescription
    }
}


private enum SimpleState { case S1, S2 }
private enum SimpleEvent { case E }

private func createSimpleMachine(forward: (() -> ())? = nil, backward: (() -> ())? = nil) -> StateMachine<StateMachineSchema<SimpleState, SimpleEvent, Void>> {
    let schema = StateMachineSchema<SimpleState, SimpleEvent, Void>(initialState: .S1) { (state, event) in
        switch state {
            case .S1: switch event {
                case .E: return (.S2, { _ in forward?() })
            }

            case .S2: switch event {
                case .E: return (.S1, { _ in backward?() })
            }
        }
    }

    return StateMachine(schema: schema, subject: ())
}


class StateMachineSpec: QuickSpec {
    override func spec() {
        describe("State Machine") {
            var keeper: NumberKeeper!
            var keeperMachine: StateMachine<StateMachineSchema<Number, Operation, NumberKeeper>>!

            beforeEach {
                keeper = NumberKeeper(n: 1)

                let schema: StateMachineSchema<Number, Operation, NumberKeeper> = StateMachineSchema(initialState: .One) { (state, event) in
                    let decrement: NumberKeeper -> () = { _ in keeper.n -= 1 }
                    let increment: NumberKeeper -> () = { _ in keeper.n += 1 }

                    switch state {
                        case .One: switch event {
                            case .Decrement: return nil
                            case .Increment: return (.Two, increment)
                        }

                        case .Two: switch event {
                            case .Decrement: return (.One, decrement)
                            case .Increment: return (.Three, increment)
                        }

                        case .Three: switch event {
                            case .Decrement: return (.Two, decrement)
                            case .Increment: return nil
                        }
                    }
                }

                keeperMachine = StateMachine(schema: schema, subject: keeper)
            }

            it("can be associated with a subject") {
                expect(keeper.n) == 1
                keeperMachine.handleEvent(.Increment)
                expect(keeper.n) == 2
            }

            it("doesn't have to be associated with a subject") {
                var machine = createSimpleMachine()

                expect(machine.state) == SimpleState.S1
                machine.handleEvent(.E)
                expect(machine.state) == SimpleState.S2
            }

            it("changes state on correct event") {
                expect(keeperMachine.state) == Number.One
                keeperMachine.handleEvent(.Increment)
                expect(keeperMachine.state) == Number.Two
            }

            it("doesn't change state on ignored event") {
                expect(keeperMachine.state) == Number.One
                keeperMachine.handleEvent(.Decrement)
                expect(keeperMachine.state) == Number.One
            }

            it("executes transition block on transition") {
                var didExecuteBlock = false

                var machine = createSimpleMachine(forward: { didExecuteBlock = true })
                expect(didExecuteBlock) == false

                machine.handleEvent(.E)
                expect(didExecuteBlock) == true
            }

            it("can have transition callback") {
                var machine = createSimpleMachine()

                var callbackWasCalledCorrectly = false
                machine.didTransitionCallback = { (oldState: SimpleState, event: SimpleEvent, newState: SimpleState) in
                    callbackWasCalledCorrectly = oldState == .S1 && event == .E && newState == .S2
                }

                machine.handleEvent(.E)
                expect(callbackWasCalledCorrectly) == true
            }

        }

        describe("Graphable State Machine") {

            it("has representation in DOT format") {
                let schema: GraphableStateMachineSchema<Number, Operation, Void> = GraphableStateMachineSchema(
                    graphStates: [.One, .Two, .Three],
                    graphEvents: [.Increment, .Decrement],
                    initialState: .One,
                    transitionLogic: { (state, event) in
                        switch state {
                            case .One: switch event {
                                case .Decrement: return nil
                                case .Increment: return (.Two, nil)
                            }

                            case .Two: switch event {
                                case .Decrement: return (.One, nil)
                                case .Increment: return (.Three, nil)
                            }

                            case .Three: switch event {
                                case .Decrement: return (.Two, nil)
                                case .Increment: return nil
                            }
                        }
                    })

                expect(schema.DOTDigraph) == "digraph {\n    graph [rankdir=LR]\n\n    0 [label=\"\", shape=plaintext]\n    0 -> 1 [label=\"START\"]\n\n    1 [label=\"One\"]\n    2 [label=\"Two\"]\n    3 [label=\"Three\"]\n\n    1 -> 2 [label=\"Increment\"]\n    2 -> 3 [label=\"Increment\"]\n    2 -> 1 [label=\"Decrement\"]\n    3 -> 2 [label=\"Decrement\"]\n}"
            }

            it("has correct initial state regardless of first state in an array") {
                let schema: GraphableStateMachineSchema<Number, Operation, Void> = GraphableStateMachineSchema(
                    graphStates: [.Two, .One, .Three],
                    graphEvents: [.Increment, .Decrement],
                    initialState: .One,
                    transitionLogic: { (state, event) in
                        switch state {
                            case .One: switch event {
                                case .Decrement: return nil
                                case .Increment: return (.Two, nil)
                            }

                            case .Two: switch event {
                                case .Decrement: return (.One, nil)
                                case .Increment: return (.Three, nil)
                            }

                            case .Three: switch event {
                                case .Decrement: return (.Two, nil)
                                case .Increment: return nil
                            }
                        }
                    })

                expect(schema.DOTDigraph) == "digraph {\n    graph [rankdir=LR]\n\n    0 [label=\"\", shape=plaintext]\n    0 -> 2 [label=\"START\"]\n\n    1 [label=\"Two\"]\n    2 [label=\"One\"]\n    3 [label=\"Three\"]\n\n    1 -> 3 [label=\"Increment\"]\n    1 -> 2 [label=\"Decrement\"]\n    2 -> 1 [label=\"Increment\"]\n    3 -> 1 [label=\"Decrement\"]\n}"
            }

            it("escapes doubles quotes in labels") {
                enum State: DOTLabel {
                    case S

                    var DOTLabel: String {
                        return "An \"awesome\" state"
                    }
                }

                enum Event: DOTLabel {
                    case E

                    var DOTLabel: String {
                        return "An \"awesome\" event"
                    }
                }

                let schema = GraphableStateMachineSchema<State, Event, Void>(
                    graphStates: [.S],
                    graphEvents: [.E],
                    initialState: .S,
                    transitionLogic: { _ in (.S, nil) }
                )

                expect(schema.DOTDigraph) == "digraph {\n    graph [rankdir=LR]\n\n    0 [label=\"\", shape=plaintext]\n    0 -> 1 [label=\"START\"]\n\n    1 [label=\"An \\\"awesome\\\" state\"]\n\n    1 -> 1 [label=\"An \\\"awesome\\\" event\"]\n}"
            }

        }
    }
}
