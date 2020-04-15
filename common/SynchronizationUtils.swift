//
//  SynchronizationUtils.swift
//  common
//
//  Created by Ben Zhang on 2020-04-14.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

import Foundation

// https://medium.com/@TomZurkan/creating-an-atomic-property-in-swift-988fa55cc71
@propertyWrapper
class AtomicProperty<T> {
    private let lock: DispatchQueue = {
        var name = "AtomicProperty" + String(Int.random(in: 0...100000))
        let clzzName = String(describing: T.self)
        name += clzzName
        return DispatchQueue(label: name, attributes: .concurrent)
    }()
    private var _property: T?
    
    var wrappedValue: T? {
        get {
            var retVal: T?
            lock.sync {
                retVal = _property
            }
            return retVal
        }
        set {
            lock.async(flags: DispatchWorkItemFlags.barrier) {
                self._property = newValue
            }
        }
    }
    init(property: T) {
        self.wrappedValue = property
    }
}
