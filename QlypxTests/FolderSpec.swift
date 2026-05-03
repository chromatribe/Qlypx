import Quick
import Nimble
@testable import Qlypx

// swiftlint:disable function_body_length
class FolderSpec: QuickSpec {
    override func spec() {
        var dataService: DataService!
        var testStoragePath: String!

        beforeEach {
            testStoragePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString)
            try? FileManager.default.createDirectory(atPath: testStoragePath, withIntermediateDirectories: true, attributes: nil)
            dataService = DataService(storageDirectory: testStoragePath)
            AppEnvironment.push(dataService: dataService)
        }

        afterEach {
            AppEnvironment.popLast()
            try? FileManager.default.removeItem(atPath: testStoragePath)
        }

        describe("Create new") {

            it("deep copy object") {
                // Save Value
                let savedFolder = QLYFolder()
                savedFolder.index = 100
                savedFolder.title = "saved folder"

                let savedSnippet = QLYSnippet()
                savedSnippet.index = 10
                savedSnippet.title = "saved snippet"
                savedSnippet.content = "content"
                savedFolder.snippets.append(savedSnippet)

                dataService.upsertFolder(savedFolder)

                // Deep copy
                let folder = savedFolder.deepCopy()
                expect(folder.index) == savedFolder.index
                expect(folder.enable) == savedFolder.enable
                expect(folder.title) == savedFolder.title
                expect(folder.identifier) == savedFolder.identifier
                expect(folder.snippets.count) == 1

                let snippet = folder.snippets.first!
                expect(snippet.index) == savedSnippet.index
                expect(snippet.enable) == savedSnippet.enable
                expect(snippet.title) == savedSnippet.title
                expect(snippet.content) == savedSnippet.content
                expect(snippet.identifier) == savedSnippet.identifier
            }

            it("Create folder") {
                let folder = QLYFolder.create()
                expect(folder.title) == "untitled folder"
                expect(folder.index) == 0

                dataService.upsertFolder(folder)

                let folder2 = QLYFolder.create()
                expect(folder2.index) == 1
            }

            it("Create snippet") {
                let folder = QLYFolder()
                let snippet = folder.createSnippet()

                expect(snippet.title) == "untitled snippet"
                expect(snippet.index) == 0

                folder.snippets.append(snippet)

                let snippet2 = folder.createSnippet()
                expect(snippet2.index) == 1
            }

        }

        describe("Sync database") {

            it("Merge snippet") {
                let folder = QLYFolder()
                dataService.upsertFolder(folder)
                let copyFolder = folder.deepCopy()

                let snippet = QLYSnippet()
                let snippet2 = QLYSnippet()
                copyFolder.mergeSnippet(snippet)
                copyFolder.mergeSnippet(snippet2)

                expect(dataService.folders.first?.snippets.count) == 2

                let savedSnippet = dataService.folders.first!.snippets.first!
                let savedSnippet2 = dataService.folders.first!.snippets[1]
                expect(savedSnippet.identifier) == snippet.identifier
                expect(savedSnippet2.identifier) == snippet2.identifier
            }

            it("Insert snippet") {
                let folder = QLYFolder()
                dataService.upsertFolder(folder)
                let copyFolder = folder.deepCopy()

                let snippet = QLYSnippet()
                copyFolder.insertSnippet(snippet, index: 0)
                expect(dataService.folders.first?.snippets.count) == 1
            }

            it("Remove snippet") {
                let folder = QLYFolder()
                let snippet = QLYSnippet()
                folder.snippets.append(snippet)
                dataService.upsertFolder(folder)

                expect(dataService.folders.first?.snippets.count) == 1

                let copyFolder = folder.deepCopy()
                copyFolder.removeSnippet(snippet)

                expect(dataService.folders.first?.snippets.count) == 0
            }

            it("Merge folder") {
                expect(dataService.folders.count) == 0

                let folder = QLYFolder()
                folder.index = 100
                folder.title = "title"
                folder.enable = false
                folder.merge()
                expect(dataService.folders.count) == 1

                let savedFolder = dataService.folders.first(where: { $0.identifier == folder.identifier })
                expect(savedFolder).toNot(beNil())
                expect(savedFolder?.index) == folder.index
                expect(savedFolder?.title) == folder.title
                expect(savedFolder?.enable) == folder.enable

                folder.index = 1
                folder.title = "change title"
                folder.enable = true
                folder.merge()
                expect(dataService.folders.count) == 1

                expect(savedFolder?.index) == folder.index
                expect(savedFolder?.title) == folder.title
                expect(savedFolder?.enable) == folder.enable
            }

            it("Remove folder") {
                let folder = QLYFolder()
                let snippet = QLYSnippet()
                folder.snippets.append(snippet)
                dataService.upsertFolder(folder)

                expect(dataService.folders.count) == 1

                let copyFolder = folder.deepCopy()
                copyFolder.remove()

                expect(dataService.folders.count) == 0
            }

        }

        describe("Rearrange Index") {

            it("Rearrange folder index") {
                let folder = QLYFolder()
                folder.index = 100
                let folder2 = QLYFolder()
                folder2.index = 10

                let folders = [folder, folder2]
                dataService.updateFolders(folders)

                let copyFolder = folder.deepCopy()
                let copyFolder2 = folder2.deepCopy()

                QLYFolder.rearrangesIndex([copyFolder, copyFolder2])

                expect(copyFolder.index) == 0
                expect(copyFolder2.index) == 1
                // The original objects in dataService.folders should be updated because they are classes and shared?
                // Wait, QLYFolder.rearrangesIndex calls merge() on each folder.
                // merge() calls dataService.upsertFolder(self).
                // So the dataService.folders should have the updated values.
                
                expect(dataService.folders.first(where: { $0.identifier == folder.identifier })?.index) == 0
                expect(dataService.folders.first(where: { $0.identifier == folder2.identifier })?.index) == 1
            }

            it("Rearrange snippet index") {
                let folder = QLYFolder()
                let snippet = QLYSnippet()
                snippet.index = 10
                let snippet2 = QLYSnippet()
                snippet2.index = 100
                folder.snippets.append(snippet)
                folder.snippets.append(snippet2)
                dataService.upsertFolder(folder)

                let copyFolder = folder.deepCopy()
                copyFolder.rearrangesSnippetIndex()
                copyFolder.merge()

                let savedFolder = dataService.folders.first!
                let copySnippet = savedFolder.snippets.first!
                let copySnippet2 = savedFolder.snippets[1]
                expect(copySnippet.index) == 0
                expect(copySnippet2.index) == 1
            }

        }

    }
}
