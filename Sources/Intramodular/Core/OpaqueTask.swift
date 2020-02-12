//
// Copyright (c) Vatsal Manot
//

import Merge
import SwiftUIX

open class OpaqueTask: CustomCombineIdentifierConvertible {
    public let cancellables = Cancellables()

    public var statusDescription: StatusDescription {
        fatalError()
    }
    
    public var statusDescriptionWillChange: AnyPublisher<StatusDescription, Never> {
        fatalError()
    }

    open func cancel() {
        
    }
    
    init() {
        
    }
}

extension OpaqueTask {
    public final func onOutput(perform action: @escaping () -> ()) {
        statusDescriptionWillChange.sink { status in
            if status.isOutput {
                action()
            }
        }
        .store(in: cancellables)
    }
    
    public final func onSuccess(perform action: @escaping () -> ()) {
        statusDescriptionWillChange.sink { status in
            if status == .success {
                action()
            }
        }
        .store(in: cancellables)
    }

    public final func onFailure(perform action: @escaping () -> ()) {
        statusDescriptionWillChange.sink { status in
            if status.isFailure {
                action()
            }
        }
        .store(in: cancellables)
    }
}
