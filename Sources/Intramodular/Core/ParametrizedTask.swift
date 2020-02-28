//
// Copyright (c) Vatsal Manot
//

import Merge
import SwiftUIX

open class ParametrizedTask<Parameter, Success, Error: Swift.Error>: MutableTask<Success, Error> {
    public var parameter: Parameter?
    
    required public init(
        body: @escaping (ParametrizedTask) -> AnyCancellable
    ) {
        super.init(body: { body($0 as! ParametrizedTask) })
    }
    
    convenience public init(
        _ parameter: Parameter,
        body: @escaping (ParametrizedTask) -> AnyCancellable
    ) {
        self.init(body: body)
        
        self.parameter = parameter
    }
    
    public func receive(_ parameter: Parameter) {
        self.parameter = parameter
    }
}

extension ParametrizedTask where Success == Void {
    public class func action(
        _ action: @escaping (ParametrizedTask) -> Void
    ) -> Self {
        .action({ action($0 as! ParametrizedTask) })
    }
}

extension ParametrizedTask {
    public func unwrap(_ body: (Parameter) -> ()) -> Void {
        if let parameter = parameter {
            body(parameter)
        } else {
            assertionFailure()
        }
    }
}
