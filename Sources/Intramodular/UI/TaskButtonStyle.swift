//
// Copyright (c) Vatsal Manot
//

import Merge
import SwiftUIX

public protocol opaque_TaskButtonStyle {
    func opaque_makeBody(configuration: TaskButtonConfiguration) -> AnyView
    
    func receive(status: TaskButtonStatus)
}

public protocol TaskButtonStyle: opaque_TaskButtonStyle {
    associatedtype Body: View
    
    typealias Configuration = TaskButtonConfiguration
    
    func makeBody(configuration: TaskButtonConfiguration) -> Body
    func receive(status: TaskButtonStatus)
}

extension TaskButtonStyle {
    @inlinable
    public func receive(status: TaskButtonStatus) {
        
    }
}

// MARK: - Implementation -

extension opaque_TaskButtonStyle where Self: TaskButtonStyle {
    public func opaque_makeBody(configuration: TaskButtonConfiguration) -> AnyView {
        return makeBody(configuration: configuration).eraseToAnyView()
    }
}

// MARK: - Auxiliary Implementation -

fileprivate struct TaskButtonStyleEnvironmentKey: EnvironmentKey {
    static let defaultValue: opaque_TaskButtonStyle = DefaultTaskButtonStyle()
}

extension EnvironmentValues {
    @usableFromInline
    var buttonStyle: opaque_TaskButtonStyle {
        get {
            self[TaskButtonStyleEnvironmentKey]
        } set {
            self[TaskButtonStyleEnvironmentKey] = newValue
        }
    }
}

// MARK: - Concrete Implementations -

public struct DefaultTaskButtonStyle: TaskButtonStyle {
    @inlinable
    public init() {
        
    }
    
    @inlinable
    public func makeBody(configuration: TaskButtonConfiguration) -> some View {
        return configuration.label
    }
}

// MARK: - API -

extension View {
    @inlinable
    public func buttonStyle<Style: TaskButtonStyle>(_ style: Style) -> some View {
        environment(\.buttonStyle, style)
    }
}
