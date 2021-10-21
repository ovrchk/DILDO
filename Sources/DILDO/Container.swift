//
//  Container.swift
//  
//
//  Created by Dmitry Overchuk on 21.10.2021.
//

import Foundation

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
    
    public func register<T>(
        _ type: T.Type,
        scope: Scope = .graph,
        _ factory: @escaping (Resolver) -> T
    ) {
        registrations[getKey(for: type)] = Registration.prototype(scope, factory)
    }
    
    // MARK: - Resolver
    
    public func resolve<T>(_ type: T.Type) -> Result<T, ResolvationError> {
        do {
            try incrementResolvationDepth()
        } catch ResolvationError.circularDependencyDetected {
            return .failure(.circularDependencyDetected)
        } catch {
            fatalError()
        }
        
        defer {
            decrementResolvationDepth()
        }
        
        let key = getKey(for: T.self)
        
        switch getRegistration(for: key) as Registration<T>? {
        case let .resolved(result):
            return .success(result)
        case let .prototype(scope, factory):
            if let resolvedObject = resolvedObjects[key] as? T {
                return .success(resolvedObject)
            } else {
                let resolvedObject = factory(self)
                resolvedObjects[key] = resolvedObject
                
                switch scope {
                case .container:
                    registrations[key] = Registration.resolved(resolvedObject)
                case .graph:
                    break
                }
                
                return .success(resolvedObject)
            }
        case .none:
            return .failure(.notRegistered)
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
    func incrementResolvationDepth() throws {
        resolvationDepth += 1
        
        if resolvationDepth > registrations.count {
            throw ResolvationError.circularDependencyDetected
        }
    }
    
    func decrementResolvationDepth() {
        resolvationDepth -= 1
        
        if resolvationDepth == .zero {
            resolvedObjects.removeAll()
        }
    }
}
