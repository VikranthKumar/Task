//
// Copyright (c) Vatsal Manot
//

import Merge
import SwiftUIX

/// A mutable task.
open class MutableTask<Success, Error: Swift.Error>: Task<Success, Error> {
    public typealias Body = (MutableTask) -> AnyCancellable
    
    private let previousTask: OpaqueTask?
    private let previousTaskCancellable: SingleAssignmentAnyCancellable
    private let body: Body
    private var bodyCancellable: SingleAssignmentAnyCancellable
    
    public required init(previous: OpaqueTask? = nil, body: @escaping Body) {
        self.previousTask = previous
        self.previousTaskCancellable = .init()
        self.body = body
        self.bodyCancellable = .init()
        
        super.init(pipeline: nil)
    }
    
    public func send(status: Status) {
        if let output = status.output {
            statusValueSubject.send(.init(output))
        } else if let failure = status.failure {
            statusValueSubject.send(.init(failure))
        } else {
            assertionFailure()
        }
        
        if status.isTerminal {
            statusValueSubject.send(completion: .finished)
            
            bodyCancellable.cancel()
            cancellables.cancel()
        }
        
        pipeline?.track(self)
    }
    
    private func _start() {
        bodyCancellable.set(body(self as! Self))
        
        send(.started)
    }
    
    /// Start the task.
    public override func start() {
        guard statusDescription == .idle else {
            return
        }
        
        if let previous = previousTask {
            previous.onSuccess { [unowned self] in
                self._start()
            }
            
            previous.onFailure {  [unowned self] in
                self.cancel()
            }
        } else {
            _start()
        }
    }
    
    /// Publishes progress.
    public func progress(_ progress: Progress?) {
        send(status: .progress(progress))
    }
    
    /// Publishes a success.
    public func succeed(with value: Success) {
        send(status: .success(value))
    }
    
    /// Cancel the task.
    public override func cancel() {
        send(status: .canceled)
    }
    
    /// Publishes a failure.
    public func fail(with error: Error) {
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
