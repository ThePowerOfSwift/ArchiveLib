//
//  Search.swift
//  ArchiveLib
//
//  Created by Julian Kahnert on 13.11.18.
//

import Foundation

/// Protocol for objects which should be searched.
protocol Searchable: Hashable {

    /// Term which will be used for the search
    var searchTerm: String { get }
}

/// Protocol for objects which can search.
protocol Searcher {
    associatedtype Element: Searchable

    /// Set of all the searchable elements.
    var allSearchElements: Set<Element> { get }

    func filterBy(_ searchTerm: String) -> Set<Element>
    func filterBy(_ searchTerms: [String]) -> Set<Element>
}

// MARK: - Implementation of the Searcher functions.
extension Searcher {

    /// Filter the "Searchable" objects by a search term.
    ///
    /// - Parameter searchTerm: Searchable object must contain the specified search term.
    /// - Returns: All objects which stickt to the constraints.
    func filterBy(_ searchTerm: String) -> Set<Element> {
        return filterBy(searchTerm, allSearchElements)
    }

    /// Filter the "Searchable" objects by all search terms.
    ///
    /// - Parameter searchTerms: Searchable object must contain all the specified search terms.
    /// - Returns: All objects which stickt to the constraints.
    func filterBy(_ searchTerms: [String]) -> Set<Element> {
        // all searchTerms must be machted

        var currentElements = allSearchElements
        for searchTerm in searchTerms {
            currentElements = filterBy(searchTerm, currentElements)
        }
        return currentElements
    }

    /// Internal filter function.
    ///
    /// - Parameters:
    ///   - searchTerm: Searchable object must contain the specified search term.
    ///   - searchElements: Objects which should be searched.
    /// - Returns: All objects which stickt to the constraints.
    private func filterBy(_ searchTerm: String, _ searchElements: Set<Element>) -> Set<Element> {
        return searchElements.filter { $0.searchTerm.contains(searchTerm) }
    }
}