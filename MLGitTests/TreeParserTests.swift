import XCTest
@testable import GitHTMLParser

class TreeParserTests: XCTestCase {
    let parser = TreeParser()
    
    func testParseFileWithLsBlobClass() throws {
        let html = """
        <table class="list">
        <tr>
            <td>-rw-r--r--</td>
            <td><a class="ls-blob" href="/repo/blob/?path=README.md">README.md</a></td>
            <td>1234</td>
        </tr>
        </table>
        """
        
        let nodes = try parser.parse(html: html)
        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].type, .file)
        XCTAssertEqual(nodes[0].name, "README.md")
    }
    
    func testParseDirectoryWithLsDirClass() throws {
        let html = """
        <table class="list">
        <tr>
            <td>drwxr-xr-x</td>
            <td><a class="ls-dir" href="/repo/tree/?path=src">src</a></td>
            <td>-</td>
        </tr>
        </table>
        """
        
        let nodes = try parser.parse(html: html)
        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].type, .directory)
        XCTAssertEqual(nodes[0].name, "src")
    }
    
    func testParseFileWithMode() throws {
        let html = """
        <table class="list">
        <tr>
            <td>-rw-r--r--</td>
            <td><a href="/repo/blob/?path=file.txt">file.txt</a></td>
            <td>5678</td>
        </tr>
        </table>
        """
        
        let nodes = try parser.parse(html: html)
        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].type, .file)
        XCTAssertEqual(nodes[0].mode, "-rw-r--r--")
    }
    
    func testParseDirectoryWithMode() throws {
        let html = """
        <table class="list">
        <tr>
            <td>drwxr-xr-x</td>
            <td><a href="/repo/tree/?path=docs">docs</a></td>
            <td></td>
        </tr>
        </table>
        """
        
        let nodes = try parser.parse(html: html)
        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].type, .directory)
    }
    
    func testParseSymlinkWithMode() throws {
        let html = """
        <table class="list">
        <tr>
            <td>lrwxrwxrwx</td>
            <td><a href="/repo/blob/?path=link">link</a></td>
            <td>20</td>
        </tr>
        </table>
        """
        
        let nodes = try parser.parse(html: html)
        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].type, .symlink)
    }
    
    func testParseFileWithExtension() throws {
        let html = """
        <table class="list">
        <tr>
            <td></td>
            <td><a href="/repo/blob/?path=main.swift">main.swift</a></td>
            <td>1024</td>
        </tr>
        </table>
        """
        
        let nodes = try parser.parse(html: html)
        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].type, .file)
    }
    
    func testParseCommonFilesWithoutExtension() throws {
        let html = """
        <table class="list">
        <tr>
            <td></td>
            <td><a href="/repo/blob/?path=README">README</a></td>
            <td>1024</td>
        </tr>
        <tr>
            <td></td>
            <td><a href="/repo/blob/?path=LICENSE">LICENSE</a></td>
            <td>2048</td>
        </tr>
        <tr>
            <td></td>
            <td><a href="/repo/blob/?path=Makefile">Makefile</a></td>
            <td>512</td>
        </tr>
        </table>
        """
        
        let nodes = try parser.parse(html: html)
        XCTAssertEqual(nodes.count, 3)
        XCTAssertTrue(nodes.allSatisfy { $0.type == .file })
    }
    
    func testParseDirectoryWithoutExtension() throws {
        let html = """
        <table class="list">
        <tr>
            <td></td>
            <td><a href="/repo/tree/?path=src">src</a></td>
            <td></td>
        </tr>
        </table>
        """
        
        let nodes = try parser.parse(html: html)
        XCTAssertEqual(nodes.count, 1)
        XCTAssertEqual(nodes[0].type, .directory)
    }
    
    func testParseMixedContent() throws {
        let html = """
        <table class="list">
        <tr class="nohover">
            <th>Mode</th>
            <th>Name</th>
            <th>Size</th>
        </tr>
        <tr>
            <td>drwxr-xr-x</td>
            <td><a class="ls-dir" href="/repo/tree/?path=src">src</a></td>
            <td>-</td>
        </tr>
        <tr>
            <td>-rw-r--r--</td>
            <td><a class="ls-blob" href="/repo/blob/?path=README.md">README.md</a></td>
            <td>1.5K</td>
        </tr>
        <tr>
            <td>-rwxr-xr-x</td>
            <td><a href="/repo/blob/?path=build.sh">build.sh</a></td>
            <td>256</td>
        </tr>
        </table>
        """
        
        let nodes = try parser.parse(html: html)
        XCTAssertEqual(nodes.count, 3)
        XCTAssertEqual(nodes[0].type, .directory)
        XCTAssertEqual(nodes[0].name, "src")
        XCTAssertEqual(nodes[1].type, .file)
        XCTAssertEqual(nodes[1].name, "README.md")
        XCTAssertEqual(nodes[2].type, .file)
        XCTAssertEqual(nodes[2].name, "build.sh")
    }
    
    func testParseSizeWithUnits() throws {
        let html = """
        <table class="list">
        <tr>
            <td>-rw-r--r--</td>
            <td><a href="/repo/blob/?path=small.txt">small.txt</a></td>
            <td>512</td>
        </tr>
        <tr>
            <td>-rw-r--r--</td>
            <td><a href="/repo/blob/?path=medium.txt">medium.txt</a></td>
            <td>2K</td>
        </tr>
        <tr>
            <td>-rw-r--r--</td>
            <td><a href="/repo/blob/?path=large.bin">large.bin</a></td>
            <td>10M</td>
        </tr>
        </table>
        """
        
        let nodes = try parser.parse(html: html)
        XCTAssertEqual(nodes.count, 3)
        XCTAssertEqual(nodes[0].size, 512)
        XCTAssertEqual(nodes[1].size, 2048)
        XCTAssertEqual(nodes[2].size, 10485760)
    }
}