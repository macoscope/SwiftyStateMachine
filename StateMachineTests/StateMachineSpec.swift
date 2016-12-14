import Quick
import Nimble

import SwiftyStateMachine


private struct NumberKeeper {
    var n: Int
}


private enum Number {
    case one, two, three
}

private enum Operation {
    case increment, decrement
}


extension Number: DOTLabelable {
    static var DOTLabelableItems: [Number] {
        return [.one, .two, .three]
    }
}

extension Operation: DOTLabelable {
    static var DOTLabelableItems: [Operation] {
        return [.increment, .decrement]
    }
}


private enum SimpleState { case s1, s2 }
private enum SimpleEvent { case e }

private func createSimpleSchema<T>(forward: ((T) -> ())? = nil, backward: ((T) -> ())? = nil) -> StateMachineSchema<SimpleState, SimpleEvent, T> {
    return StateMachineSchema(initialState: .s1) { (state, event) in
        switch state {
            case .s1: switch event {
                case .e: return (.s2, { forward?($0) })
            }

            case .s2: switch event {
                case .e: return (.s1, { backward?($0) })
            }
        }
    }
}

private func createSimpleMachine(forward: (() -> ())? = nil, backward: (() -> ())? = nil) -> StateMachine<StateMachineSchema<SimpleState, SimpleEvent, Void>> {
    return StateMachine(schema: createSimpleSchema(forward: { _ in forward?() }, backward: { _ in backward?() }), subject: ())
}


private class Subject {
    typealias SchemaType = StateMachineSchema<SimpleState, SimpleEvent, Subject>

    let schema: SchemaType
    lazy var machine: StateMachine<SchemaType> = { 
        StateMachine(schema: self.schema, subject: self)
    }()

    init(schema: SchemaType) {
        self.schema = schema
    }
}


class StateMachineSpec: QuickSpec {
    override func spec() {
        describe("State Machine") {
            var keeper: NumberKeeper!
            var keeperMachine: StateMachine<StateMachineSchema<Number, Operation, NumberKeeper>>!

            beforeEach {
                keeper = NumberKeeper(n: 1)

                let schema: StateMachineSchema<Number, Operation, NumberKeeper> = StateMachineSchema(initialState: .One) { (state, event) in
                    let decrement: (NumberKeeper) -> () = { _ in keeper.n -= 1 }
                    let increment: (NumberKeeper) -> () = { _ in keeper.n += 1 }

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
                let machine = createSimpleMachine()

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

                let machine = createSimpleMachine(forward: { didExecuteBlock = true })
                expect(didExecuteBlock) == false

                machine.handleEvent(.E)
                expect(didExecuteBlock) == true
            }

            it("can have transition callback") {
                let machine = createSimpleMachine()

                var callbackWasCalledCorrectly = false
                machine.didTransitionCallback = { (oldState: SimpleState, event: SimpleEvent, newState: SimpleState) in
                    callbackWasCalledCorrectly = oldState == .S1 && event == .E && newState == .S2
                }

                machine.handleEvent(.E)
                expect(callbackWasCalledCorrectly) == true
            }

            it("can trigger transition from within transition") {
                let subject = Subject(schema: createSimpleSchema(forward: {
                    $0.machine.handleEvent(.E)
                }))

                subject.machine.handleEvent(.E)
                expect(subject.machine.state) == SimpleState.S1
            }

            it("doesn't cause machine-subject reference cycles") {
                final class MachineOwner {
                    var machine: StateMachine<StateMachineSchema<SimpleState, SimpleEvent, MachineOwner>>!

                    init() {
                        machine = StateMachine(
                            schema: StateMachineSchema(initialState: .S1) { _ in nil },
                            subject: self)
                    }
                }

                weak var reference: MachineOwner?
                do { reference = MachineOwner() }
                expect(reference).to(beNil())
            }

        }

        describe("Graphable State Machine") {

            it("has representation in DOT format") {
                let schema: GraphableStateMachineSchema<Number, Operation, Void> = GraphableStateMachineSchema(initialState: .One) { (state, event) in
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
                }

                expect(schema.DOTDigraph) == "digraph {\n    graph [rankdir=LR]\n\n    0 [label=\"\", shape=plaintext]\n    0 -> 1 [label=\"START\"]\n\n    1 [label=\"One\"]\n    2 [label=\"Two\"]\n    3 [label=\"Three\"]\n\n    1 -> 2 [label=\"Increment\"]\n    2 -> 3 [label=\"Increment\"]\n    2 -> 1 [label=\"Decrement\"]\n    3 -> 2 [label=\"Decrement\"]\n}"
            }

            it("escapes double quotes in labels") {

                let schema = GraphableStateMachineSchema<State, Event, Void>(initialState: .S) { _ in
                    (.S, nil)
                }

                expect(schema.DOTDigraph) == "digraph {\n    graph [rankdir=LR]\n\n    0 [label=\"\", shape=plaintext]\n    0 -> 1 [label=\"START\"]\n\n    1 [label=\"An \\\"awesome\\\" state\"]\n\n    1 -> 1 [label=\"An \\\"awesome\\\" event\"]\n}"
            }

        }
    }
}


enum State: DOTLabelable {
    case s
    var DOTLabel: String { return "An \"awesome\" state" }
    static var DOTLabelableItems: [State] { return [.s] }
}

enum Event: DOTLabelable {
    case e
    var DOTLabel: String { return "An \"awesome\" event" }
    static var DOTLabelableItems: [Event] { return [.e] }
}
