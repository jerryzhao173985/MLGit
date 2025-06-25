import XCTest
@testable import MLGit

class URLBuilderTests: XCTestCase {
    
    func testPlainURLWithSimplePath() {
        let url = URLBuilder.plain(repositoryPath: "repo/test.git", path: "README.md")
        XCTAssertEqual(url.absoluteString, "https://git.mlplatform.org/repo/test.git/plain/README.md")
    }
    
    func testPlainURLWithNestedPath() {
        let url = URLBuilder.plain(repositoryPath: "repo/test.git", path: "src/main.swift")
        XCTAssertEqual(url.absoluteString, "https://git.mlplatform.org/repo/test.git/plain/src/main.swift")
    }
    
    func testPlainURLWithSpacesInPath() {
        let url = URLBuilder.plain(repositoryPath: "repo/test.git", path: "My Documents/file.txt")
        XCTAssertEqual(url.absoluteString, "https://git.mlplatform.org/repo/test.git/plain/My%20Documents/file.txt")
    }
    
    func testPlainURLWithSpecialCharacters() {
        let url = URLBuilder.plain(repositoryPath: "repo/test.git", path: "file(with)special[chars].txt")
        XCTAssertTrue(url.absoluteString.contains("file(with)special%5Bchars%5D.txt"))
    }
    
    func testBlobURLWithPath() {
        let url = URLBuilder.blob(repositoryPath: "repo/test.git", path: "src/main.swift")
        XCTAssertEqual(url.absoluteString, "https://git.mlplatform.org/repo/test.git/blob/?path=src%2Fmain.swift")
    }
    
    func testBlobURLWithSpacesInPath() {
        let url = URLBuilder.blob(repositoryPath: "repo/test.git", path: "My Documents/file.txt")
        XCTAssertTrue(url.absoluteString.contains("path=My%20Documents%2Ffile.txt"))
    }
    
    func testTreeURLWithPath() {
        let url = URLBuilder.tree(repositoryPath: "repo/test.git", path: "src/components")
        XCTAssertEqual(url.absoluteString, "https://git.mlplatform.org/repo/test.git/tree/?path=src%2Fcomponents")
    }
    
    func testTreeURLWithoutPath() {
        let url = URLBuilder.tree(repositoryPath: "repo/test.git")
        XCTAssertEqual(url.absoluteString, "https://git.mlplatform.org/repo/test.git/tree/")
    }
    
    func testCommitURLWithSHA() {
        let url = URLBuilder.commit(repositoryPath: "repo/test.git", sha: "abc123")
        XCTAssertEqual(url.absoluteString, "https://git.mlplatform.org/repo/test.git/commit/?id=abc123")
    }
    
    func testPatchURLWithSHA() {
        let url = URLBuilder.patch(repositoryPath: "repo/test.git", sha: "abc123")
        XCTAssertEqual(url.absoluteString, "https://git.mlplatform.org/repo/test.git/patch/?id=abc123")
    }
    
    func testDiffURLWithSHA() {
        let url = URLBuilder.diff(repositoryPath: "repo/test.git", sha: "abc123")
        XCTAssertEqual(url.absoluteString, "https://git.mlplatform.org/repo/test.git/diff/?id=abc123")
    }
}