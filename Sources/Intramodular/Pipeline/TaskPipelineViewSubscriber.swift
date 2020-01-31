//
// Copyright (c) Vatsal Manot
//

import Merge
import SwiftUI
import SwiftUIX

struct TaskPipelineViewSubscriber: ViewModifier {
    @Environment(\.taskPipeline) var pipeline
    
    let action: ((name: TaskName, status: OpaqueTask.StatusDescription)) -> ()
    
    func body(content: Content) -> some View {
        content.onReceive(pipeline.taskStatuses, perform: self.action)
    }
}

// MARK: - API -

extension View {
    public func onStatus(
        of name: TaskName,
        perform action: @escaping (OpaqueTask.StatusDescription) -> Void
    ) -> some View {
        modifier(TaskPipelineViewSubscriber {
            if $0.name == name {
                action($0.status)
            }
        })
    }
}
