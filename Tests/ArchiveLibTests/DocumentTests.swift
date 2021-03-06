//
//  DocumentTests.swift
//  ArchiveLib Tests
//
//  Created by Julian Kahnert on 30.11.18.
//
// swiftlint:disable force_try force_unwrapping type_body_length

@testable import ArchiveLib
import XCTest

class DocumentTests: XCTestCase {

    let tag1 = "tag1"
    let tag2 = "tag2"

    let defaultDownloadStatus = DownloadStatus.local
    let defaaultSize = Int64(1024)

    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    override func setUp() {
        super.setUp()
    }

    // MARK: - Test Document.parseFilename

    func testFilenameParsing1() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/2010-05-12--example-description__tag1_tag2_tag4.pdf")

        // calculate
        let parsingOutput = Document.parseFilename(path)

        // assert
        XCTAssertEqual(parsingOutput.date, dateFormatter.date(from: "2010-05-12"))
        XCTAssertEqual(parsingOutput.specification, "example-description")
        XCTAssertEqual(parsingOutput.tagNames, ["tag1", "tag2", "tag4"])
    }

    func testFilenameParsing2() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/2010-05-12__tag1_tag2_tag4.pdf")

        // calculate
        let parsingOutput = Document.parseFilename(path)

        // assert
        XCTAssertEqual(parsingOutput.date, dateFormatter.date(from: "2010-05-12"))
        XCTAssertNil(parsingOutput.specification)
        XCTAssertEqual(parsingOutput.tagNames, ["tag1", "tag2", "tag4"])
    }

    func testFilenameParsing3() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/scan 1.pdf")

        // calculate
        let parsingOutput = Document.parseFilename(path)

        // assert
        XCTAssertNil(parsingOutput.date)
        XCTAssertEqual(parsingOutput.specification, "scan 1")
        XCTAssertNil(parsingOutput.tagNames)
    }

    func testFilenameParsing4() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/2019-09-02--gfwob abrechnung für 2018__hausgeldabrechung_steuer_wohnung.pdf")

        // calculate
        let parsingOutput = Document.parseFilename(path)

        // assert
        XCTAssertEqual(parsingOutput.date, dateFormatter.date(from: "2019-09-02"))
        XCTAssertEqual(parsingOutput.specification, "gfwob abrechnung für 2018")
        XCTAssertEqual(parsingOutput.tagNames, ["hausgeldabrechung", "steuer", "wohnung"])
    }

    // MARK: - Test Document.getRenamingPath

    func testDocumentRenaming() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/scan1.pdf")
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .untagged)

        document.date = dateFormatter.date(from: "2010-05-12") ?? Date()
        document.specification = "example-description"
        document.tags = Set([tag1, tag2])

        // calculate
        let renameOutput = try? document.getRenamingPath()

        // assert
        XCTAssertNoThrow(try document.getRenamingPath())
        XCTAssertEqual(renameOutput?.foldername, "2010")
        XCTAssertEqual(renameOutput?.filename, "2010-05-12--example-description__tag1_tag2.pdf")
    }

    func testDocumentRenamingWithSpaceInDescriptionSlugify() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/Testscan 1.pdf")

        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .untagged)
        document.specification = "this-is-a-test"
        document.tags = Set([tag1])
        document.date = dateFormatter.date(from: "2010-05-12") ?? Date()

        let renameOutput = try? document.getRenamingPath()

        // assert
        XCTAssertNoThrow(try document.getRenamingPath())
        XCTAssertEqual(renameOutput?.foldername, "2010")
        XCTAssertEqual(renameOutput?.filename, "2010-05-12--this-is-a-test__tag1.pdf")
    }

    func testDocumentRenamingWithFullFilename() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/2010-05-12--example-description__tag1_tag2.pdf")
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .untagged)

        // calculate
        let renameOutput = try? document.getRenamingPath()

        // assert
        XCTAssertNoThrow(try document.getRenamingPath())
        XCTAssertEqual(renameOutput?.foldername, "2010")
        XCTAssertEqual(renameOutput?.filename, "2010-05-12--example-description__tag1_tag2.pdf")
    }

    func testDocumentRenamingWithNoTags() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/scan1.pdf")

        // calculate
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .untagged)

        // assert
        XCTAssertEqual(document.tags.count, 0)
        XCTAssertEqual(document.specification, "scan1")
        XCTAssertThrowsError(try document.getRenamingPath())
    }

    func testDocumentRenamingWithNoSpecification() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/scan1__tag1_tag2.pdf")

        // calculate
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .untagged)
        document.specification = ""

        // assert
        XCTAssertEqual(document.tags.count, 2)
        XCTAssertEqual(document.specification, "")
        XCTAssertThrowsError(try document.getRenamingPath())
    }

    // MARK: - Test Hashable, Comparable, CustomStringConvertible

    func testHashable() {

        // setup
        let document1 = Document(id: UUID(), path: URL(fileURLWithPath: "~/Downloads/2018-05-id: UUID(), 12--aaa-example-description__tag1_tag2.pdf"), size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)
        let document2 = Document(id: UUID(), path: URL(fileURLWithPath: "~/Downloads/2018-05-id: UUID(), 12--bbb-example-description__tag1_tag2.pdf"), size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)
        let document3 = Document(id: UUID(), path: URL(fileURLWithPath: "~/Downloads/2010-05-id: UUID(), 12--aaa-example-description__tag1_tag2.pdf"), size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .untagged)
        let invalidSortDescriptor = NSSortDescriptor(key: "test", ascending: true)
        let filenameSortDescriptor1 = NSSortDescriptor(key: "filename", ascending: true)
        let filenameSortDescriptor2 = NSSortDescriptor(key: "filename", ascending: false)
        let taggingStatusSortDescriptor1 = NSSortDescriptor(key: "taggingStatus", ascending: true)
        let taggingStatusSortDescriptor2 = NSSortDescriptor(key: "taggingStatus", ascending: false)

        let documents = [document1, document2, document3]

        // calculate
        guard let sortedDocuments1 = try? sort(documents, by: [filenameSortDescriptor1]) else { XCTFail("Sorting failed!"); return }
        guard let sortedDocuments2 = try? sort(documents, by: [filenameSortDescriptor2]) else { XCTFail("Sorting failed!"); return }
        guard let sortedDocuments3 = try? sort(documents, by: [taggingStatusSortDescriptor1, filenameSortDescriptor1]) else { XCTFail("Sorting failed!"); return }
        guard let sortedDocuments4 = try? sort(documents, by: [taggingStatusSortDescriptor2, filenameSortDescriptor1]) else { XCTFail("Sorting failed!"); return }

        // assert
        // sort by date
        XCTAssertTrue(document3 < document1)
        // sort by filename
        XCTAssertTrue(document2 < document1)
        // invalid sort descriptor
        XCTAssertThrowsError(try sort(documents, by: [invalidSortDescriptor]))
        // filename sort descriptor ascending
        XCTAssertEqual(sortedDocuments1[0], document3)
        XCTAssertEqual(sortedDocuments1[1], document1)
        XCTAssertEqual(sortedDocuments1[2], document2)
        // filename sort descriptor descending
        XCTAssertEqual(sortedDocuments2[0], document2)
        XCTAssertEqual(sortedDocuments2[1], document1)
        XCTAssertEqual(sortedDocuments2[2], document3)
        // tagging status sort descriptor ascending
        XCTAssertEqual(sortedDocuments3[0], document3)
        XCTAssertEqual(sortedDocuments3[1], document1)
        XCTAssertEqual(sortedDocuments3[2], document2)
        // tagging status sort descriptor ascending
        XCTAssertEqual(sortedDocuments4[0], document1)
        XCTAssertEqual(sortedDocuments4[1], document2)
        XCTAssertEqual(sortedDocuments4[2], document3)
    }

    func testComparable() {

        // setup
        let document1 = Document(id: UUID(), path: URL(fileURLWithPath: "~/Downloads/2018-05-12--example-description__tag1_tag2.pdf"), size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)
        let document2 = Document(id: UUID(), path: URL(fileURLWithPath: "~/Downloads/2018-05-12--example-description__tag1_tag2.pdf"), size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)

        document2.specification = "this is a test"

        // assert
        XCTAssertNotEqual(document1, document2)
        XCTAssertNotEqual(document1.hashValue, document2.hashValue)
    }

    func testComparableWithSameUUID() {

        // setup
        let uuid = UUID()
        let document1 = Document(id: uuid, path: URL(fileURLWithPath: "~/Downloads/2018-05-12--example-description__tag1_tag2.pdf"), size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)
        let document2 = Document(id: uuid, path: URL(fileURLWithPath: "~/Downloads/2018-05-12--example-description__tag1_tag2.pdf"), size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)

        document2.specification = "this is a test"

        // assert
        XCTAssertEqual(document1, document2)
        XCTAssertEqual(document1.hashValue, document2.hashValue)
    }

    func testSearchable() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/2018-05-12--example-description__tag1_tag2.pdf")
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)

        // assert
        XCTAssertEqual(document.searchTerm, path.lastPathComponent)
    }

    // MARK: - Test the whole workflow

    func testDocumentNameParsing() {

        // setup some of the testing variables
        let path = URL(fileURLWithPath: "~/Downloads/2010-05-12--example-description__tag1_tag2_tag4.pdf")

        // create a basic document
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)

        // assert
        XCTAssertEqual(document.specification, "example-description")

        XCTAssertEqual(document.tags.count, 3)
        XCTAssertTrue(document.tags.contains(tag1))
        XCTAssertTrue(document.tags.contains(tag2))
        XCTAssertEqual(document.date, dateFormatter.date(from: "2010-05-12"))
    }

    func testDocumentWithEmptyName() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/scan1.pdf")

        // calculate
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)

        // assert
        XCTAssertNil(document.date)
    }

    func testDocumentDateParsingFormat1() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/2010-05-12 example filename.pdf")

        // calculate
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)

        // assert
        XCTAssertEqual(document.date, dateFormatter.date(from: "2010-05-12"))
        XCTAssertEqual(document.specification, "example filename")
        XCTAssertEqual(document.specificationCapitalized, "Example Filename")
        XCTAssertEqual(document.tags, Set())
    }

    func testDocumentDateParsingFormat2() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/2010_05_12 example filename.pdf")

        // calculate
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)

        // assert
        XCTAssertEqual(document.date, dateFormatter.date(from: "2010-05-12"))
        XCTAssertEqual(document.specification, "example filename")
        XCTAssertEqual(document.specificationCapitalized, "Example Filename")
        XCTAssertEqual(document.tags, Set())
    }

    func testDocumentDateParsingFormat3() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/20100512 example filename.pdf")

        // calculate
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)

        // assert
        XCTAssertEqual(document.date, dateFormatter.date(from: "2010-05-12"))
        XCTAssertEqual(document.specification, "example filename")
        XCTAssertEqual(document.specificationCapitalized, "Example Filename")
        XCTAssertEqual(document.tags, Set())
    }

    func testDocumentDateParsingFormat4() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/2010_05_12__15_17.pdf")

        // calculate
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)

        // assert
        XCTAssertEqual(document.date, dateFormatter.date(from: "2010-05-12"))
        XCTAssertEqual(document.specification, "")
        XCTAssertTrue(document.tags.contains("15"))
        XCTAssertTrue(document.tags.contains("17"))
    }

    func testDocumentDateParsingScanSnapFormat() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/2010_05_12_15_17.pdf")

        // calculate
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)

        // assert
        XCTAssertEqual(document.date, dateFormatter.date(from: "2010-05-12"))
        XCTAssertEqual(document.specification, "15-17")
        XCTAssertEqual(document.specificationCapitalized, "15 17")
        XCTAssertEqual(document.tags, Set())
    }

    func testDocumentRenamingPath() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/scan1.pdf")
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)
        document.date = dateFormatter.date(from: "2010-05-12") ?? Date()
        document.specification = "testing-test-description"
        document.tags = Set([tag1, tag2])

        // calculate
        let newFilename = try? document.getRenamingPath()

        // assert
        XCTAssertNotNil(newFilename)
        XCTAssertEqual(newFilename!.filename, "2010-05-12--testing-test-description__tag1_tag2.pdf")
        XCTAssertEqual(newFilename!.foldername, "2010")
    }

    func testDocumentRenameFailing() {

        // setup
        let path = URL(fileURLWithPath: "~/Downloads/2010/2010-05-12--testing-test-description__tag1_tag2.pdf")
        let document = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)

        // calculate & assert
        XCTAssertThrowsError(try document.rename(archivePath: URL(string: "~/Downloads/")!, slugify: true))
    }

    func testDocumentRename() {

        // setup
        let home = FileManager.default.temporaryDirectory
        let path = home.appendingPathComponent("2010-05-12--testing-test-description__tag1_tag2.pdf")
        try? "THIS IS A TEST, YOU CAN DELETE THIS FILE".write(to: path, atomically: true, encoding: .utf8)
        let document1 = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)

        // cleanup the document, if it already exists
        let newDocumentPathComponents = try! document1.getRenamingPath()
        let newDocumentPath = home.appendingPathComponent(newDocumentPathComponents.foldername).appendingPathComponent(newDocumentPathComponents.filename)
        let exists = try? newDocumentPath.checkResourceIsReachable()
        if exists ?? false {
            try? FileManager.default.removeItem(at: newDocumentPath)
        }

        // calculate & assert
        do {
            try document1.rename(archivePath: home, slugify: true)
        } catch let error {
            XCTFail(error.localizedDescription)
        }

        // create a new document with the same name and try to rename it (again) - this should fail
        try? "THIS IS A TEST, YOU CAN DELETE THIS FILE".write(to: path, atomically: true, encoding: .utf8)
        let document2 = Document(id: UUID(), path: path, size: defaaultSize, downloadStatus: defaultDownloadStatus, taggingStatus: .tagged)
        XCTAssertThrowsError(try document2.rename(archivePath: home, slugify: true))
    }
}
