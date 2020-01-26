//
// Copyright (c) Vatsal Manot
//

import Merge
import SwiftUIX

extension Task {
    public func onStatus(
        _ status: StatusDescription,
        perform action: @escaping (Status) -> ()
    ) {
        objectWillChange.sink { _status in
            if status == _status.description  {
                action(_status)
            }
        }
        .store(in: cancellables)
    }
    
    public func toSuccessErrorPublisher() -> AnyPublisher<Success, Error> {
        self.compactMap({ Task.Status($0).successValue })
            .mapError({ Task.Status($0).errorValue! })
            .eraseToAnyPublisher()
    }
}
