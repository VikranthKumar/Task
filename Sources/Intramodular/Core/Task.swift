//
// Copyright (c) Vatsal Manot
//

import Merge
import SwiftUIX

/// An opinionated definition of a task.
open class Task<Success, Error: Swift.Error>: OpaqueTask {
    let queue = DispatchQueue(label: "com.vmanot.Task")
    let statusValueSubject = CurrentValueSubject<Status, Never>(.idle)
    
    public private(set) var name: TaskName = .init(UUID())
    
    weak var pipeline: TaskPipeline? {
        didSet {
            pipeline?.track(self)
        }
    }
    
    public var status: Status {
        get {
            statusValueSubject.value
        } set {
            statusValueSubject.value = newValue
        }
    }
    
    public override var statusDescription: StatusDescription {
        return .init(status)
    }
    
    public override var statusDescriptionWillChange: AnyPublisher<StatusDescription, Never> {
        objectWillChange
            .map({ .init($0) })
            .eraseToAnyPublisher()
    }
    
    public init(pipeline: TaskPipeline?) {
        self.pipeline = pipeline
    }
    
    public func start() {
        fatalError()
    }
    
    public func cancel() {
        fatalError()
    }
}

extension Task {
    public func setName(_ name: TaskName) {
        guard self.pipeline == nil else {
            fatalError()
        }
        
        self.name = name
    }
    
    public func insert(into pipeline: TaskPipeline) {
        guard self.pipeline == nil else {
            return assertionFailure("\(self) is already part of an pipleine")
        }
        
        self.pipeline = pipeline
    }
}

// MARK: - Protocol Implementations -

extension Task: ObservableObject {
    public var objectWillChange: AnyPublisher<Status, Never> {
        statusValueSubject.eraseToAnyPublisher()
    }
}

extension Task: Publisher {
    open func receive<S: Subscriber>(
        subscriber: S
    ) where S.Input == Output, S.Failure == Failure {
        objectWillChange
            .setFailureType(to: Failure.self)
            .flatMap({ status -> AnyPublisher<Output, Failure> in
                if let output = status.output {
                    return Just(output)
                        .setFailureType(to: Failure.self)
                        .eraseToAnyPublisher()
                } else if let failure = status.failure {
                    return Fail<Output, Failure>(error: failure)
                        .eraseToAnyPublisher()
                } else {
                    return Empty<Output, Failure>()
                        .eraseToAnyPublisher()
                }
            })
            .receive(subscriber: subscriber)
    }
}

extension Task: Subscription {
    public func request(_ demand: Subscribers.Demand) {
        guard demand != .none, statusDescription == .idle else {
            return
        }
        
        start()
    }
}
