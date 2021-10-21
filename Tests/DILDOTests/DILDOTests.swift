import XCTest
import DILDO
    
final class DILDOTests: XCTestCase {
    
    private var container: Container!
    
    override func setUp() {
        super.setUp()
        
        container = Container()
    }
    
    /// Registration with `graph` scope produces new instance each time
    func test_resolvingGraphObject_producesNewObjectEachTime() {
        // Given
        container.register(ClassC.self, scope: .graph) { _ in ClassC() }
        
        // When
        let a = container.forceResolve(ClassC.self)
        let b = container.forceResolve(ClassC.self)
        let c = container.forceResolve(ClassC.self)
        
        // Then
        XCTAssertTrue(a !== b)
        XCTAssertTrue(b !== c)
        XCTAssertTrue(c !== a)
    }
    
    /// Registration with `container` scope produces same object each time
    func test_resolvingContainerObject_producesSameObjectEachTime() {
        // Given
        container.register(ClassC.self, scope: .container) { _ in ClassC() }
        
        // When
        let a = container.forceResolve(ClassC.self)
        let b = container.forceResolve(ClassC.self)
        let c = container.forceResolve(ClassC.self)
        
        // Then
        XCTAssertTrue(a === b)
        XCTAssertTrue(b === c)
        XCTAssertTrue(c === a)
    }
    
    /// Registration with `graph` will produce the same object during graph resolvation
    func test_resolvingGraphObject_willProduceSameObjectDuringResolvation() {
        // Given
        container.register(ClassA.self, scope: .graph) { resolver in
            ClassA(
                b: resolver.forceResolve(ClassB.self),
                c: resolver.forceResolve(ClassC.self)
            )
        }
        
        container.register(ClassB.self, scope: .graph) { resolver in
            ClassB(
                c: resolver.forceResolve(ClassC.self)
            )
        }
        
        container.register(ClassC.self, scope: .graph) { _ in ClassC() }
        
        // When
        let a = container.forceResolve(ClassA.self)
        
        // Then
        XCTAssertTrue(a.b.c === a.c)
    }
    
    /// Resolving unregistered object will produce `nil`
    func test_resolvingUnregisteredObject_willProduceNil() {
        // Given
        container.register(ProtocolC.self, scope: .graph) { _ in ClassC() }
        
        // When
        let a = container.tryToResolve(ProtocolC.self)
        let b = container.tryToResolve(ClassC.self)
        
        // Then
        XCTAssertNotNil(a)
        XCTAssertNil(b)
    }
    
    /// Circular dependencies will be detected
    func test_circularDependency_willBeDetected() {
        // Given
        var isCircularDependencyDetected = false
        
        container.register(ClassAA.self) { resolver in
            ClassAA(
                bb: resolver.tryToResolve(ClassBB.self)
            )
        }
        
        container.register(ClassBB.self) { resolver in
            ClassBB(
                cc: resolver.forceResolve(ClassCC.self)
            )
        }
        
        container.register(ClassCC.self) { resolver in
            do {
                _ = try resolver.resolve(ClassAA.self).get()
            } catch ResolvationError.circularDependencyDetected {
                isCircularDependencyDetected = true
            } catch { }
            
            return ClassCC(aa: nil)
        }
        
        // When
        _ = container.resolve(ClassAA.self)
        
        // Then
        XCTAssertTrue(isCircularDependencyDetected)
    }
}
