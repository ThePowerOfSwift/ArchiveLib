//
//  UntaggedDocumentManager.swift
//  ArchiveLib-iOS
//
//  Created by Julian Kahnert on 11.12.18.
//

import Foundation

public protocol DocumentManagerHandling: AnyObject {
    var years: Set<String> { get }

    func getAvailableTags(with searchterms: [String]) -> Set<String>

    func get(scope: SearchScope, searchterms: [String], status: TaggingStatus) -> Set<Document>
    func add(from path: URL, size: Int64?, downloadStatus: DownloadStatus, status: TaggingStatus, parse: ParsingOptions)
    func remove(_ removableDocuments: Set<Document>)
    func removeAll(_ status: TaggingStatus)
    func update(_ document: Document)
    func update(from path: URL, size: Int64?, downloadStatus: DownloadStatus, status: TaggingStatus, parse: ParsingOptions) -> Document
    func archive(_ document: Document)
}

class DocumentManager: Logging {

    var documents = Atomic(Set<Document>())

    func add(_ addedDocument: Document) {
        add(Set([addedDocument]))
    }

    func add(_ addedDocuments: Set<Document>) {
        documents.mutate { $0.formUnion(addedDocuments) }
    }

    func remove(_ removableDocument: Document) {
        remove(Set([removableDocument]))
    }

    func remove(_ removableDocuments: Set<Document>) {
        documents.mutate { $0.subtract(removableDocuments) }
    }

    func removeAll() {
        documents.mutate { $0 = Set<Document>() }
    }

    func update(_ updatedDocument: Document) {
        documents.mutate { $0.update(with: updatedDocument) }
    }
}

extension DocumentManager: Searcher {
    typealias Element = Document

    var allSearchElements: Set<Document> {
        return Set(documents.value)
    }
}

enum DocumentManagerError: Error {
    case archivableDocumentNotFound
}
