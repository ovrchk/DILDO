//
//  Container.swift
//  
//
//  Created by Dmitry Overchuk on 21.10.2021.
//

import Foundation

public protocol Resolver {
    func resolve<T>(_ type: T.Type) -> T?
}

public extension Resolver {
    func forceResolve<T>(_ type: T.Type) -> T {
        resolve(type)!
    }
}

public final class Container: Resolver {
    
    public enum Scope: Int {
        case graph
        case container
    }
    
    private enum Registration<T> {
        case prototype(Scope, (Container) -> T)
        case resolved(T)
    }
    
    private var registrations = [String: Any]()
    private var resolvedObjects = [String: Any]()
    private var resolvationDepth = Int.zero
    
    public init() {}
    
    public func register<T>(_ type: T.Type, scope: Scope, _ factory: @escaping (Resolver) -> T) {
        registrations[getKey(for: type)] = Registration.prototype(scope, factory)
    }
    
    // MARK: - Resolver
    
    public func resolve<T>(_ type: T.Type) -> T? {
        incrementResolvationDepth()
        defer { decrementResolvationDepth() }
        
        let key = getKey(for: T.self)
        
        switch getRegistration(for: key) as Registration<T>? {
        case let .resolved(result):
            return result
        case let .prototype(scope, factory):
            if let resolvedObject = resolvedObjects[key] as? T {
                return resolvedObject
            } else {
                let resolvedObject = factory(self)
                resolvedObjects[key] = resolvedObject
                
                switch scope {
                case .container:
                    registrations[key] = Registration.resolved(resolvedObject)
                case .graph:
                    break
                }
                
                return resolvedObject
            }
        case .none:
            return nil
        }
    }
}

private extension Container {
    private func getRegistration<T>(for key: String) -> Registration<T>? {
        registrations[key] as? Registration<T>
    }
    
    func getKey<T>(for type: T.Type) -> String {
        String(describing: type)
    }
}

private extension Container {
    func incrementResolvationDepth() {
        resolvationDepth += 1
        
        if resolvationDepth > registrations.count {
            fatalError("Circular dependency")
        }
    }
    
    func decrementResolvationDepth() {
        resolvationDepth -= 1
        
        if resolvationDepth == .zero {
            resolvedObjects.removeAll()
        }
    }
}
