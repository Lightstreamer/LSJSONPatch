//
//  JSONEquality.swift
//  JSONPatch
//
//  Created by Raymond Mccrae on 14/11/2018.
//  Copyright © 2018 Raymond McCrae. All rights reserved.
//

import Foundation

protocol JSONEquatable {
    func isJSONEquals(to element: JSONElement) -> Bool
}

extension NSNumber: JSONEquatable {
    var isBoolean: Bool {
        return CFNumberGetType(self) == .charType
    }

    func isJSONEquals(to element: JSONElement) -> Bool {
        guard case let .number(num) = element else {
            return false
        }

        let selfBool = isBoolean
        let otherBool = num.isBoolean
        switch (selfBool, otherBool) {
        case (false, false), (true, true):
            return isEqual(to: num)
        default:
            return false
        }
    }
}

extension NSString: JSONEquatable {
    func isJSONEquals(to element: JSONElement) -> Bool {
        guard case let .string(str) = element else {
            return false
        }

        return isEqual(str)
    }
}

extension NSNull: JSONEquatable {
    func isJSONEquals(to element: JSONElement) -> Bool {
        guard case .null = element else {
            return false
        }

        return true
    }
}

extension NSArray: JSONEquatable {
    func isJSONEquals(to element: JSONElement) -> Bool {
        switch element {
        case let .array(arr) where arr.count == count,
             let .mutableArray(arr as NSArray) where arr.count == count:
            for index in 0..<count {
                let selfItem = self[index] as! JSONEquatable
                let arrItem = try! JSONElement(any: arr[index])

                if !selfItem.isJSONEquals(to: arrItem) {
                    return false
                }
            }
            return true
        default:
            return false
        }
    }
}

extension NSDictionary: JSONEquatable {
    func isJSONEquals(to element: JSONElement) -> Bool {
        switch element {
        case let .object(dict) where dict.count == count,
             let .mutableObject(dict as NSDictionary) where dict.count == count:
            let keys = self.allKeys
            for key in keys {
                guard
                    let dictValue = dict[key],
                    let dictElement = try? JSONElement(any: dictValue) else {
                    return false
                }
                let selfValue = self[key] as! JSONEquatable
                if !selfValue.isJSONEquals(to: dictElement) {
                    return false
                }
            }
            return true
        default:
            return false
        }
    }
}
