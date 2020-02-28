//
// Copyright (c) Vatsal Manot
//

import Merge
import SwiftUIX

/// A mutable task.
open class MutableTask<Success, Error: Swift.Error>: Task<Success, Error> {
    public typealias Body = (MutableTask) -> AnyCancellable
    
    private let body: Body
    private var bodyCancellable: AnyCancellable = .empty()
    
    public required init(body: @escaping Body) {
        self.body = body
        
        super.init(pipeline: nil)
    }
    
    required convenience public init(action: @escaping () -> Success) {
        self.init { (task: MutableTask<Success, Error>) in
            task.start()
            task.succeed(with: action())
            
            return .empty()
        }
    }
    
    required convenience public init(_ attemptToFulfill: @escaping (@escaping
        (Result<Success, Error>) -> ()) -> Void) {
        self.init { (task: MutableTask<Success, Error>) in
            attemptToFulfill { result in
                switch result {
                    case .success(let value):
                        task.succeed(with: value)
                    case .failure(let value):
                        task.fail(with: value)
                }
            }
            
            return .init(EmptyCancellable())
        }
    }
    
    required convenience public init(_ attemptToFulfill: @escaping (@escaping
        (Result<Success, Error>) -> ()) -> AnyCancellable) {
        self.init { (task: MutableTask<Success, Error>) in
            return attemptToFulfill { result in
                switch result {
                    case .success(let value):
                        task.succeed(with: value)
                    case .failure(let value):
                        task.fail(with: value)
                }
            }
        }
    }
    
    required convenience public init(_ publisher: AnyPublisher<Success, Error>) {
        self.init { attemptToFulfill in
            publisher.sinkResult(attemptToFulfill)
        }
    }
    
    required convenience public init<P: Publisher>(_ publisher: P) where P.Output == Success, P.Failure == Error {
        self.init { attemptToFulfill in
            publisher.sinkResult(attemptToFulfill)
        }
    }
    
    open func willSend(status: Status) {
        
    }

    open func didSend(status: Status) {
        
    }
    
    public func send(status: Status) {
        willSend(status: status)
        
        defer {
            didSend(status: status)
        }
        
        if let output = status.output {
            statusValueSubject.send(.init(output))
        } else if let failure = status.failure {
            statusValueSubject.send(.init(failure))
        } else {
            assertionFailure()
        }
        
        if status.isTerminal {
            statusValueSubject.send(completion: .finished)
            
            queue.async {
                self.bodyCancellable.cancel()
                self.cancellables.cancel()
            }
        }
        
        pipeline?.track(self)
    }
    
    /// Start the task.
    final override public func start() {
        func _start() {
            send(status: .started)
            
            bodyCancellable = body(self as! Self)
        }
        
        guard statusDescription == .idle else {
            return
        }
        
        _start()
    }
    
    /// Publishes progress.
    final public func progress(_ progress: Progress?) {
        send(status: .progress(progress))
    }
    
    /// Publishes a success.
    final public func succeed(with value: Success) {
        send(status: .success(value))
    }
    
    /// Cancel the task.
    final override public func cancel() {
        send(status: .canceled)
    }
    
    /// Publishes a failure.
    final public func fail(with error: Error) {
        send(status: .error(error))
    }
}

// MARK: - Protocol Implementations -

extension MutableTask: Subject {
    /// Sends a value to the subscriber.
    ///
    /// - Parameter value: The value to send.
    public func send(_ output: Output) {
        send(status: .init(output))
    }
    
    /// Sends a completion signal to the subscriber.
    ///
    /// - Parameter failure: The failure to send.
    public func send(_ failure: Failure) {
        send(status: .init(failure))
    }
    
    /// Sends a completion signal to the subscriber.
    ///
    /// - Parameter completion: A `Completion` instance which indicates whether publishing has finished normally or failed with an error.
    public func send(completion: Subscribers.Completion<Failure>) {
        switch completion {
            case .finished:
                break
            case .failure(let failure):
                send(status: .init(failure))
        }
    }
    
    public func send(subscription: Subscription) {
        subscription.request(.unlimited)
    }
}

// MARK: - API -

extension MutableTask {
    final public class func just(_ result: Result<Success, Error>) -> Self {
        self.init { attemptToFulfill in
            attemptToFulfill(result)
        }
    }
    
    final public class func success(_ success: Success) -> Self {
        .just(.success(success))
    }
    
    final public class func error(_ error: Error) -> Self {
        .just(.failure(error))
    }
}

extension MutableTask where Success == Void {
    final public class func action(_ action: @escaping (MutableTask<Success, Error>) -> Void) -> Self {
        .init { (task: MutableTask<Success, Error>) in
            task.start()
            task.succeed(with: action(task))
            
            return .empty()
        }
    }
    
    final public class func action(_ action: @escaping () -> Void) -> Self {
        .action({ _ in action() })
    }
}
