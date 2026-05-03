import Quick
import Nimble
@testable import Qlypx

class SnippetSpec: QuickSpec {
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

        describe("Snippet actions") {

            it("Merge snippet") {
                let folder = QLYFolder()
                dataService.upsertFolder(folder)

                let snippet = QLYSnippet()
                snippet.title = "untitled"
                folder.snippets.append(snippet)
                dataService.upsertFolder(folder)

                let snippet2 = QLYSnippet()
                snippet2.identifier = snippet.identifier
                snippet2.index = 100
                snippet2.title = "title"
                snippet2.content = "content"
                snippet2.merge()

                let savedFolder = dataService.folders.first!
                let savedSnippet = savedFolder.snippets.first!
                
                expect(savedSnippet.index) == snippet2.index
                expect(savedSnippet.title) == snippet2.title
                expect(savedSnippet.content) == snippet2.content
            }

            it("Remove snippet") {
                let folder = QLYFolder()
                let snippet = QLYSnippet()
                folder.snippets.append(snippet)
                dataService.upsertFolder(folder)

                expect(dataService.folders.first?.snippets.count) == 1

                let snippet2 = QLYSnippet()
                snippet2.identifier = snippet.identifier
                snippet2.remove()

                expect(dataService.folders.first?.snippets.count) == 0
            }

        }

    }
}
