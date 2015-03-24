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
}


class StateMachineSpec: QuickSpec {
    override func spec() {
        describe("State Machine") {
            var keeper: NumberKeeper!
            var keeperMachine: StateMachine<Number, Operation, NumberKeeper>!

            beforeEach {
                keeper = NumberKeeper(n: 1)

                let structure: StateMachineStructure<Number, Operation, NumberKeeper> = StateMachineStructure(initialState: .One) { (state, event, _, _) in
                    let decrement = { keeper.n -= 1 }
                    let increment = { keeper.n += 1 }

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

                keeperMachine = structure.stateMachineWithSubject(keeper)
            }

            it("can be associated with a subject") {
                expect(keeper.n) == 1
                keeperMachine.handleEvent(.Increment)
                expect(keeper.n) == 2
            }

            it("doesn't have to be associated with a subject") {
                enum State { case S1, S2 }
                enum Event { case E }

                let structure = StateMachineStructure<State, Event, Void>(initialState: .S1) { (state, event, _, _) in
                    switch state {
                        case .S1: switch event {
                            case .E: return (.S2, nil)
                        }

                        case .S2: switch event {
                            case .E: return (.S1, nil)
                        }
                    }
                }
                let machine = structure.stateMachineWithSubject(())

                expect(machine.state) == State.S1
                machine.handleEvent(.E)
                expect(machine.state) == State.S2
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
                fail()
            }

        }
    }
}
