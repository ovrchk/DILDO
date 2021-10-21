//
//  Resolver.swift
//  
//
//  Created by Dmitry Overchuk on 21.10.2021.
//

import Foundation

public enum ResolvationError: Error {
    case notRegistered
    case circularDependencyDetected
}

public protocol Resolver {
    func resolve<T>(_ type: T.Type) -> Result<T, ResolvationError>
}

public extension Resolver {
    func tryToResolve<T>(_ type: T.Type) -> T? { try? resolve(type).get() }
    func forceResolve<T>(_ type: T.Type) -> T { try! resolve(type).get() }
}
