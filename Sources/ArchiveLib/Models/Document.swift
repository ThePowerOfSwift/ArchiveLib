//
//  Document.swift
//  ArchiveLib
//
//  Created by Julian Kahnert on 13.11.18.
//

import Foundation
import os.log
#if os(OSX)
import Quartz
#else
import PDFKit
#endif

/// Download status of a file.
///
/// - iCloudDrive: The file is currently only in iCloud Drive available.
/// - downloading: The OS downloads the file currentyl.
/// - local: The file is locally available.
public enum DownloadStatus: Equatable {
    case iCloudDrive
    case downloading(percentDownloaded: Float)
    case local
}

/// Tagging status of a document.
///
/// - tagged: Document is already tagged.
/// - untagged: Document that is not tagged.
public enum TaggingStatus: String, Comparable {
    case tagged
    case untagged

    public static func < (lhs: TaggingStatus, rhs: TaggingStatus) -> Bool {
        return lhs == .untagged && rhs == .tagged
    }
}

/// Errors which can occur while handling a document.
///
/// - description: A error in the description.
/// - tags: A error in the document tags.
/// - renameFailedFileAlreadyExists: A document with this name already exists in the archive.
public enum DocumentError: Error {
    case date
    case description
    case tags
    case renameFailedFileAlreadyExists
}

extension DocumentError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .date:
            return NSLocalizedString("document_error_description__date_missing", comment: "No date could be found, e.g. while renaming the document.")
        case .description:
            return NSLocalizedString("document_error_description__description_missing", comment: "No description could be found, e.g. while renaming the document.")
        case .tags:
            return NSLocalizedString("document_error_description__tags_missing", comment: "No tags could be found, e.g. while renaming the document.")
        case .renameFailedFileAlreadyExists:
            return NSLocalizedString("document_error_description__rename_failed_file_already_exists", comment: "Rename failed.")
        }
    }

    public var failureReason: String? {
        switch self {
        case .date:
            return NSLocalizedString("document_failure_reason__date_missing", comment: "No date could be found, e.g. while renaming the document.")
        case .description:
            return NSLocalizedString("document_failure_reason__description_missing", comment: "No description could be found, e.g. while renaming the document.")
        case .tags:
            return NSLocalizedString("document_failure_reason__tags_missing", comment: "No tags could be found, e.g. while renaming the document.")
        case .renameFailedFileAlreadyExists:
            return NSLocalizedString("document_failure_reason__rename_failed_file_already_exists", comment: "Rename failed.")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .date:
            return NSLocalizedString("document_recovery_suggestion__date_missing", comment: "No date could be found, e.g. while renaming the document.")
        case .description:
            return NSLocalizedString("document_recovery_suggestion__description_missing", comment: "No description could be found, e.g. while renaming the document.")
        case .tags:
            return NSLocalizedString("document_recovery_suggestion__tags_missing", comment: "No tags could be found, e.g. while renaming the document.")
        case .renameFailedFileAlreadyExists:
            return NSLocalizedString("document_recovery_suggestion__rename_failed_file_already_exists", comment: "Rename failed - file already exists.")
        }
    }
}

/// Main structure which contains a document.
public class Document: SystemLogging, Identifiable {

    // MARK: ArchiveLib essentials

    /// ID of a document
    public let id: UUID

    /// Date of the document.
    public var date: Date?
    /// Details of the document, e.g. "blue pullover".
    public var specification: String {
        didSet {
            specification = specification.replacingOccurrences(of: "_", with: "-").lowercased()
        }
    }

    /// Tags/categories of the document.
    public var tags = Set<String>()

    // MARK: data from filename
    /// Name of the folder, e.g. "2018".
    public private(set) var folder: String
    /// Whole filename, e.g. "scan1.pdf".
    public private(set) var filename: String
    /// Path to the file.
    public private(set) var path: URL

    /// Size of the document, e.g. "1,5 MB".
    public private(set) var size: String?
    /// Download status of the document.
    public var downloadStatus: DownloadStatus
    /// Download status of the document.
    public var taggingStatus: TaggingStatus

    /// Details of the document with capitalized first letter, e.g. "Blue Pullover".
    public var specificationCapitalized: String {
        return specification
            .split(separator: " ")
            .flatMap { String($0).split(separator: "-") }
            .map { String($0).capitalizingFirstLetter() }
            .joined(separator: " ")
    }

    /// Create a new document, which contains the main information (date, specification, tags) of the ArchiveLib.
    /// New documents should only be created by the DocumentManager in this package.
    ///
    /// - Parameters:
    ///   - documentPath: Path of the file on disk.
    ///   - availableTags: Currently available tags in archive.
    ///   - byteSize: Size of this documen in number of bytes.
    ///   - documentDownloadStatus: Download status of the document.
    init(id documentId: UUID, path documentPath: URL, size byteSize: Int64?, downloadStatus documentDownloadStatus: DownloadStatus, taggingStatus documentTaggingStatus: TaggingStatus) {

        id = documentId
        path = documentPath
        filename = documentPath.lastPathComponent
        folder = documentPath.deletingLastPathComponent().lastPathComponent
        downloadStatus = documentDownloadStatus
        taggingStatus = documentTaggingStatus

        if let byteSize = byteSize {
            size = ByteCountFormatter.string(fromByteCount: byteSize, countStyle: .file)
        }

        // parse the current filename
        let parsedFilename = Document.parseFilename(documentPath)
        tags = Set(parsedFilename.tagNames ?? [])

        // add finder file tags
        tags.formUnion(path.fileTags)

        // set the date
        date = parsedFilename.date

        // set the specification
        specification = parsedFilename.specification ?? ""
    }

    /// Get the new foldername and filename after applying the PDF Archiver naming scheme.
    ///
    /// ATTENTION: The specification will not be slugified in this step! Keep in mind to do this before/after this method call.
    ///
    /// - Returns: Returns the new foldername and filename after renaming.
    /// - Throws: This method throws an error, if the document contains no tags or specification.
    public func getRenamingPath() throws -> (foldername: String, filename: String) {

        // create a filename and rename the document
        guard let date = date else {
            throw DocumentError.date
        }
        guard !tags.isEmpty else {
            throw DocumentError.tags
        }
        guard !specification.isEmpty else {
            throw DocumentError.description
        }

        let filename = Document.createFilename(date: date, specification: specification, tags: tags)
        let foldername = String(filename.prefix(4))

        return (foldername, filename)
    }

    /// Parse the filename from an URL.
    ///
    /// - Parameter path: Path which should be parsed.
    /// - Returns: Date, specification and tag names which can be parsed from the path.
    public static func parseFilename(_ path: URL) -> (date: Date?, specification: String?, tagNames: [String]?) {

        // try to parse the current filename
        var date: Date?
        var rawDate = ""
        if let parsed = Document.getFilenameDate(path.lastPathComponent) {
            date = parsed.date
            rawDate = parsed.rawDate
        } else if let parsed = DateParser.parse(path.lastPathComponent) {
            date = parsed.date
            rawDate = parsed.rawDate
        }

        // parse the specification
        var specification: String?

        if let raw = path.lastPathComponent.capturedGroups(withRegex: "--([\\w\\d-]+)__") {

            // try to parse the real specification from scheme
            specification = raw[0]

        } else {

            // save a first "raw" specification
            let tempSepcification = path.lastPathComponent
                // drop the already parsed date
                .dropFirst(rawDate.count)
                // drop the extension and the last .
                .dropLast(path.pathExtension.count + 1)
                // exclude tags, if they exist
                .components(separatedBy: "__")[0]
                // clean up all "_" - they are for tag use only!
                .replacingOccurrences(of: "_", with: "-")
                // remove a pre or suffix from the string
                .trimmingCharacters(in: ["-", " "])

            // save the raw specification, if it is not empty
            if !tempSepcification.isEmpty {
                specification = tempSepcification
            }
        }

        // parse the tags
        var tagNames: [String]?
        let filename = path.deletingPathExtension().lastPathComponent
        let separator = "__"
        if filename.contains(separator),
            let raw = filename.components(separatedBy: separator).last,
            !raw.isEmpty {
            // parse the tags of a document
            tagNames = raw.components(separatedBy: "_")
        }

        return (date, specification, tagNames)
    }

    public static func createFilename(date: Date, specification: String, tags: Set<String>) -> String {
        // get formatted date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: date)

        // get description

        // get tags
        var tagStr = ""
        for tag in tags.sorted() {
            tagStr += "\(tag)_"
        }
        tagStr = String(tagStr.dropLast(1))

        // create new filepath
        return "\(dateStr)--\(specification)__\(tagStr).pdf"
    }

    /// Parse the OCR content of the pdf document try to fetch a date and some tags.
    /// This overrides the current date and appends the new tags.
    ///
    /// ATTENTION: This method needs security access!
    ///
    /// - Parameter tagManager: TagManager that will be used when adding new tags.
    public func parseContent(_ options: ParsingOptions) {

        // skip the calculations if the OptionSet is empty
        guard !options.isEmpty else { return }

        // get the pdf content of every page
        guard let pdfDocument = PDFDocument(url: path) else { return }
        var text = ""
        for index in 0 ..< pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: index),
                let pageContent = page.string else { return }

            text += pageContent
        }

        // verify that we got some pdf content
        guard !text.isEmpty else { return }

        // parse the date
        if options.contains(.date),
            let parsed = DateParser.parse(text) {
           date = parsed.date
        }

        // parse the tags
        if options.contains(.tags) {

            // get new tags
            let newTags = TagParser.parse(text)
            tags.formUnion(newTags)
        }
    }

    /// Rename this document and save in in the archive path.
    ///
    /// - Parameters:
    ///   - archivePath: Path of the archive, where the document should be saved.
    ///   - slugify: Should the document name be slugified?
    /// - Throws: Renaming might fail and throws an error, e.g. because a document with this filename already exists.
    public func rename(archivePath: URL, slugify: Bool) throws {

        if slugify {
            specification = specification.slugified(withSeparator: "-")
        }

        let foldername: String
        let filename: String
        (foldername, filename) = try getRenamingPath()

        // check, if this path already exists ... create it
        let newFilepath = archivePath
            .appendingPathComponent(foldername)
            .appendingPathComponent(filename)
        let fileManager = FileManager.default
        do {
            let folderPath = newFilepath.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: folderPath.path) {
                try fileManager.createDirectory(at: folderPath, withIntermediateDirectories: true, attributes: nil)
            }

            // test if the document name already exists in archive, otherwise move it
            if fileManager.fileExists(atPath: newFilepath.path),
                self.path != newFilepath {
                os_log("File already exists!", log: Document.log, type: .error)
                throw DocumentError.renameFailedFileAlreadyExists
            } else {
                try fileManager.moveItem(at: self.path, to: newFilepath)
            }
        } catch let error as NSError {
            os_log("Error while moving file: %@", log: Document.log, type: .error, error.description)
            throw error
        }

        // update document properties
        self.filename = String(newFilepath.lastPathComponent)
        self.path = newFilepath
        self.taggingStatus = .tagged

        // save file tags
        path.fileTags = tags.sorted()
    }

    /// Save the tags of this document in the filesystem.
    @available(*, deprecated, message: "Use 'url.fileTags' instead.")
    public func saveTagsToFilesystem() {
        path.fileTags = tags.sorted()
    }

    private static func getFilenameDate(_ raw: String) -> (date: Date, rawDate: String)? {
        if let groups = raw.capturedGroups(withRegex: "([\\d-]+)--") {
            let rawDate = groups[0]

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            if let date = dateFormatter.date(from: rawDate) {
                return (date, rawDate)
            }
        }
        return nil
    }
}

extension Document: Hashable, Comparable {

    public static func < (lhs: Document, rhs: Document) -> Bool {

        // first: sort by date
        // second: sort by filename
        if let lhsdate = lhs.date,
            let rhsdate = rhs.date,
            lhsdate != rhsdate {
            return lhsdate < rhsdate
        }
        return lhs.filename > rhs.filename
    }

    public static func == (lhs: Document, rhs: Document) -> Bool {
        // "==" and hashValue must only compare the path to avoid duplicates in sets
        return lhs.id == rhs.id
    }

    // "==" and hashValue must only compare the path to avoid duplicates in sets
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Document: Searchable {

    // Searchable stubs
    public var searchTerm: String { return filename }
}

extension Document: CustomComparable {
    public func isBefore(_ other: Document, _ sort: NSSortDescriptor) throws -> Bool {
        if sort.key == "filename" {
            return sort.ascending ? filename < other.filename : filename > other.filename
        } else if sort.key == "taggingStatus" {
            return sort.ascending ? taggingStatus < other.taggingStatus : taggingStatus > other.taggingStatus
        }
        throw SortDescriptorError.invalidKey
    }
}
