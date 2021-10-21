//
//  TestEntities.swift
//  
//
//  Created by Dmitry Overchuk on 21.10.2021.
//

import Foundation

final class ClassA {
    let b: ClassB
    let c: ClassC
    
    init(b: ClassB, c: ClassC) {
        self.b = b
        self.c = c
    }
}

final class ClassB {
    let c: ClassC
    
    init(c: ClassC) {
        self.c = c
    }
}

protocol ProtocolC {}
final class ClassC: ProtocolC {}
