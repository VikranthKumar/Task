//
// Copyright (c) Vatsal Manot
//

import Merge
import SwiftUIX

/// An interactive control representing a `Task<Success, Error>`.
public struct TaskButton<Success, Error: Swift.Error, Label: View>: View {
    private let action: () -> Task<Success, Error>?
    private let label: (Task<Success, Error>.Status) -> Label

    @OptionalEnvironmentObject var taskPipeline: TaskPipeline?
    @OptionalObservedObject var currentTask: Task<Success, Error>?

    @Environment(\.buttonStyle) var buttonStyle
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.taskName) var taskName
    @Environment(\.taskDisabled) var taskDisabled
    @Environment(\.taskInterruptible) var taskInterruptible
    @Environment(\.taskRestartable) var taskRestartable

    public var task: Task<Success, Error>? {
        if let currentTask = currentTask {
            return currentTask
        } else if let taskName = taskName, let task = taskPipeline?[taskName] as? Task<Success, Error> {
            return task
        } else {
            return nil
        }
    }
    
    public var taskStatusDescription: OpaqueTask.StatusDescription {
        return task?.statusDescription
            ?? taskName.flatMap({ taskPipeline?.lastStatus(for: $0) })
            ?? .idle
    }
    
    public var lastTaskStatusDescription: OpaqueTask.StatusDescription? {
        taskName.flatMap({ taskPipeline?.lastStatus(for: $0) })
    }
    
    @State var taskRenewalSubscription: AnyCancellable?
    
    public var body: some View {
        Button(action: trigger) {
            buttonStyle.opaque_makeBody(
                configuration: TaskButtonConfiguration(
                    label: label(task?.status ?? .idle).eraseToAnyView(),
                    isDisabled: taskDisabled,
                    isInterruptible: taskInterruptible,
                    isRestartable: taskRestartable,
                    status: taskStatusDescription,
                    lastStatus: lastTaskStatusDescription
                )
            )
        }
        .disabled(!isEnabled || taskDisabled)
    }
    
    private func trigger() {
        if !taskRestartable && currentTask != nil {
            return
        }
        
        acquireTaskIfNecessary()
    }
    
    private func subscribe(to task: Task<Success, Error>) {
        task.statusValueSubject.sink(storeIn: taskPipeline?.cancellables ?? task.cancellables) {
            self.buttonStyle
                .receive(status: .init(description: $0.description))
        }
        
        currentTask = task
    }
    
    private func acquireTaskIfNecessary() {
        if taskInterruptible {
            if let task = action() {
                return subscribe(to: task)
            }
        }
        
        if let taskName = taskName, let taskPipeline = taskPipeline, let task = taskPipeline[taskName] as? Task<Success, Error> {
            currentTask = task
        } else {
            if let task = action() {
                subscribe(to: task)
            } else {
                currentTask = nil
            }
        }
    }
}

extension TaskButton {
    public init(
        action: @escaping () -> Task<Success, Error>,
        @ViewBuilder label: @escaping (Task<Success, Error>.Status) -> Label
    ) {
        self.action = { action() }
        self.label = label
    }
    
    public init(
        action: @escaping () -> Task<Success, Error>,
        @ViewBuilder label: () -> Label
    ) {
        let _label = label()
        
        self.action = { action() }
        self.label = { _ in _label }
    }
}
