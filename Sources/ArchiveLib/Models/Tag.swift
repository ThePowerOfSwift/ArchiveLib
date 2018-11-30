//
//  Tag.swift
//  ArchiveLib
//
//  Created by Julian Kahnert on 13.11.18.
//

import Foundation

/// Structure which represents a Tag.
public struct Tag {

    /// Name of the tag.
    public let name: String

    /// Count of how many tags with this name exist.
    public var count: Int

    /// Create a new tag.
    ///
    /// - Parameters:
    ///   - name: Name of the Tag.
    ///   - count: Number which indicates how many times this tag is used.
    public init(name: String, count: Int) {
        self.name = name
        self.count = count
    }
}

extension Tag: Hashable, CustomStringConvertible {
    public static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.name == rhs.name
    }
    public var hashValue: Int { return name.hashValue }
    public var description: String { return "\(name) (\(count))" }
}
