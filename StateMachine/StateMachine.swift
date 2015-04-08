/// A type representing schema that can be reused by `StateMachine` instances.
///
/// Schema incorporates three generic types: `State` and `Event`, which should
/// be `enum`s, and `Subject`, which represents an object associated with
/// a state machine.  If you don't want to associate any object, use `Void`
/// as `Subject` type.
///
/// Schema indicates the initial state and describes transition logic — how
/// states are connected via events and what code is executed during state
/// transitions.  You specify transition logic as a block that accepts two
/// arguments: current state and event being handled.  It returns an optional
/// tuple of a new state and an optional transition block.  When the tuple is
/// `nil`, it indicates that there is no transition for given state-event
/// pair, i.e. given event should be ignored in given state.  When the tuple
/// is non-`nil`, it specifies the new state that machine should transition to
/// and a block that should be called after the transition.  The transition
/// block is optional and it gets passed a `Subject` object as an argument.
public protocol StateMachineSchemaType {
    typealias State
    typealias Event
    typealias Subject

    var initialState: State { get }
    var transitionLogic: (State, Event) -> (State, (Subject -> ())?)? { get }

    init(initialState: State, transitionLogic: (State, Event) -> (State, (Subject -> ())?)?)
}


/// A state machine schema conforming to `StateMachineSchemaType` protocol.
/// See protocol's documentation for more information.
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


/// State machine for given schema, associated with given subject.  See
/// `StateMachineSchemaType` documentation for more information about schemas
/// and subjects.
///
/// State machine provides the `state` property for inspecting the current
/// state and the `handleEvent` method for triggering state transitions
/// defined in the schema.
///
/// To get notified about state changes, provide a `didTransitionCallback`
/// block.  It is called after a transition with three arguments:
/// the state before the transition, the event causing the transition,
/// and the state after the transition.
public struct StateMachine<T: StateMachineSchemaType> {
    /// Current state of the machine.
    public var state: T.State

    /// Optional block called after a transition with three arguments:
    /// the state before the transition, the event causing the transition,
    /// and the state after the transition.
    public var didTransitionCallback: ((T.State, T.Event, T.State) -> ())?

    /// Schema of the state machine.  See `StateMachineSchemaType`
    /// documentation for more information.
    private let schema: T

    /// Object associated with the state machine.  Can be accessed in
    /// transition blocks.
    private let subject: T.Subject

    public init(schema: T, subject: T.Subject) {
        self.state = schema.initialState
        self.schema = schema
        self.subject = subject
    }

    /// A method for triggering transitions and changing the state of the
    /// machine.  If transition logic of the schema defines a transition
    /// for current state and given event, the state is changed, optional
    /// transition block is executed, and `didTransitionCallback` is called.
    public mutating func handleEvent(event: T.Event) {
        if let (newState, transition) = schema.transitionLogic(state, event) {
            let oldState = state
            state = newState
            transition?(subject)
            didTransitionCallback?(oldState, event, newState)
        }
    }
}
