//
// Copyright (c) Vatsal Manot
//

import Merge
import SwiftUIX

public final class TaskPipeline: ObservableObject {
    public let cancellables = Cancellables()
    public let taskStatuses = PassthroughSubject<(name: TaskName, status: OpaqueTask.StatusDescription), Never>()
    
    private weak var parent: TaskPipeline?
    
    @Published private var taskHistory: [TaskName: [OpaqueTask.StatusDescription]] = [:]
    @Published private var taskMap: [TaskName: OpaqueTask] = [:]
    
    public init(parent: TaskPipeline? = nil) {
        self.parent = parent
    }
    
    public subscript(_ taskName: TaskName) -> OpaqueTask? {
        taskMap[taskName]
    }
    
    func track<Success, Error>(_ task: Task<Success, Error>) {
        DispatchQueue.asyncOnMainIfNecessary {
            if task.hasEnded {
                self.taskHistory[task.name, default: []].append(task.statusDescription)
                self.taskMap.removeValue(forKey: task.name)
            } else {
                self.taskMap[task.name] = task
            }
            
            self.taskStatuses.send((task.name, task.statusDescription))
            
            self.objectWillChange.send()
        }
    }
}

extension TaskPipeline {
    public func cancelAllTasks() {
        taskMap.values.forEach({ $0.cancel() })
    }

    public func lastStatus(for taskName: TaskName) -> OpaqueTask.StatusDescription? {
        taskHistory[taskName]?.last
    }
}

// MARK: - Auxiliary Implementation -

extension TaskPipeline {
    public struct EnvironmentKey: SwiftUI.EnvironmentKey {
        public static let defaultValue = TaskPipeline()
    }
}

extension EnvironmentValues {
    public var taskPipeline: TaskPipeline {
        get {
            self[TaskPipeline.EnvironmentKey]
        } set {
            self[TaskPipeline.EnvironmentKey] = newValue
        }
    }
}

// MARK: - API -

extension View {
    @inline(never)
    public func taskPipeline(_ pipeline: TaskPipeline) -> some View {
        environment(\.taskPipeline, pipeline).environmentObject(pipeline)
    }
}
