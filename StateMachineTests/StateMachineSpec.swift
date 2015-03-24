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
            var keeperMachine: StateMachine<Number, Operation, NumberKeeper>!

            beforeEach {
                var keeper = NumberKeeper(n: 1)
                let structure: StateMachineStructure<Number, Operation, NumberKeeper> = StateMachineStructure(initialState: .One) { (state, event, _, _) in
                    switch state {
                        case .One: switch event {
                            case .Decrement: return nil
                            case .Increment: return (.Two, {})
                        }

                        case .Two: switch event {
                            case .Decrement: return (.One, {})
                            case .Increment: return (.Three, {})
                        }

                        case .Three: switch event {
                            case .Decrement: return (.Two, {})
                            case .Increment: return nil
                        }
                    }
                }

                keeperMachine = structure.stateMachineWithSubject(keeper)
            }

            it("can be associated with a subject") {
                fail()
            }

            it("doesn't have to be associated with a subject") {
                fail()
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
