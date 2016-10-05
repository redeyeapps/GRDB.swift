import XCTest
#if USING_SQLCIPHER
    import GRDBCipher
#elseif USING_CUSTOMSQLITE
    import GRDBCustomSQLite
#else
    import GRDB
#endif

class FTS3TableBuilderTests: GRDBTestCase {
    
    func testWithoutBody() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.create(virtualTable: "documents", using: FTS3())
                XCTAssertTrue(sqlQueries.contains("CREATE VIRTUAL TABLE \"documents\" USING fts3"))
                
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["abc"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["abc"])!, 1)
            }
        }
    }
    
    func testOptions() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.create(virtualTable: "documents", ifNotExists: true, using: FTS3())
                XCTAssertTrue(sqlQueries.contains("CREATE VIRTUAL TABLE IF NOT EXISTS \"documents\" USING fts3"))
                
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["abc"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["abc"])!, 1)
            }
        }
    }
    
    func testSimpleTokenizer() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.create(virtualTable: "documents", using: FTS3()) { t in
                    t.tokenizer = .simple
                }
                XCTAssertTrue(sqlQueries.contains("CREATE VIRTUAL TABLE \"documents\" USING fts3(tokenize=simple)"))
                
                // simple match
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["abcDÉF"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["abcDÉF"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // English stemming
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["database"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["databases"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["eéÉ"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["Èèe"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // TODO: test NFKC and NFKD http://unicode.org/reports/tr15/
                
                // diacritics in latin characters (NFC-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{00E9}\u{00C9}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{00C8}\u{00E8}e"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFD-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{0065}\u{0301}\u{0045}\u{0300}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{00C8}\u{00E8}e"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFC-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{00E9}\u{00C9}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{0045}\u{0300}\u{0065}\u{0300}e"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFD-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{0065}\u{0301}\u{0045}\u{0300}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{0045}\u{0300}\u{0065}\u{0300}e"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // unicode case
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["jérôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["JÉRÔME"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFC-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{00E9}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{00C9}RÔME"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFD-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{0065}\u{0301}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{00C9}RÔME"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFC-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{00E9}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{0045}\u{0301}RÔME"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFD-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{0065}\u{0301}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{0045}\u{0301}RÔME"])!, 0)
                try db.execute("DELETE FROM documents")
            }
        }
    }
    
    func testPorterTokenizer() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.create(virtualTable: "documents", using: FTS3()) { t in
                    t.tokenizer = .porter
                }
                XCTAssertTrue(sqlQueries.contains("CREATE VIRTUAL TABLE \"documents\" USING fts3(tokenize=porter)"))
                
                // simple match
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["abcDÉF"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["abcDÉF"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // English stemming
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["database"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["databases"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["eéÉ"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["Èèe"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFC-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{00E9}\u{00C9}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{00C8}\u{00E8}e"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFD-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{0065}\u{0301}\u{0045}\u{0300}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{00C8}\u{00E8}e"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFC-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{00E9}\u{00C9}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{0045}\u{0300}\u{0065}\u{0300}e"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFD-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{0065}\u{0301}\u{0045}\u{0300}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{0045}\u{0300}\u{0065}\u{0300}e"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // unicode case
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["jérôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["JÉRÔME"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFC-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{00E9}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{00C9}RÔME"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFD-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{0065}\u{0301}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{00C9}RÔME"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFC-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{00E9}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{0045}\u{0301}RÔME"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFD-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{0065}\u{0301}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{0045}\u{0301}RÔME"])!, 0)
                try db.execute("DELETE FROM documents")
            }
        }
    }
    
    func testUnicode61Tokenizer() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.create(virtualTable: "documents", using: FTS3()) { t in
                    t.tokenizer = .unicode61()
                }
                XCTAssertTrue(sqlQueries.contains("CREATE VIRTUAL TABLE \"documents\" USING fts3(tokenize=unicode61)"))
                
                // simple match
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["abcDÉF"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["abcDÉF"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // English stemming
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["database"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["databases"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["eéÉ"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["Èèe"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFC-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{00E9}\u{00C9}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{00C8}\u{00E8}e"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFD-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{0065}\u{0301}\u{0045}\u{0300}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{00C8}\u{00E8}e"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFC-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{00E9}\u{00C9}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{0045}\u{0300}\u{0065}\u{0300}e"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFD-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{0065}\u{0301}\u{0045}\u{0300}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{0045}\u{0300}\u{0065}\u{0300}e"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // unicode case
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["jérôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["JÉRÔME"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFC-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{00E9}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{00C9}RÔME"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFD-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{0065}\u{0301}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{00C9}RÔME"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFC-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{00E9}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{0045}\u{0301}RÔME"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFD-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{0065}\u{0301}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{0045}\u{0301}RÔME"])!, 1)
                try db.execute("DELETE FROM documents")
            }
        }
    }
    
    func testUnicode61TokenizerRemoveDiacritics() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.create(virtualTable: "documents", using: FTS3()) { t in
                    t.tokenizer = .unicode61(removeDiacritics: false)
                }
                XCTAssertTrue(sqlQueries.contains("CREATE VIRTUAL TABLE \"documents\" USING fts3(tokenize=unicode61 \"remove_diacritics=0\")"))
                
                // simple match
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["abcDÉF"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["abcDÉF"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // English stemming
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["database"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["databases"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["eéÉ"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["Èèe"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFC-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{00E9}\u{00C9}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{00C8}\u{00E8}e"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFD-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{0065}\u{0301}\u{0045}\u{0300}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{00C8}\u{00E8}e"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFC-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{00E9}\u{00C9}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{0045}\u{0300}\u{0065}\u{0300}e"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // diacritics in latin characters (NFD-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["e\u{0065}\u{0301}\u{0045}\u{0300}"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["\u{0045}\u{0300}\u{0065}\u{0300}e"])!, 0)
                try db.execute("DELETE FROM documents")
                
                // unicode case
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["jérôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["JÉRÔME"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFC-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{00E9}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{00C9}RÔME"])!, 1)
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFD-NFC)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{0065}\u{0301}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{00C9}RÔME"])!, 0) // surprising
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFC-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{00E9}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{0045}\u{0301}RÔME"])!, 0) // surprising
                try db.execute("DELETE FROM documents")
                
                // unicode case (NFD-NFD)
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["j\u{0065}\u{0301}rôme"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["J\u{0045}\u{0301}RÔME"])!, 1)
                try db.execute("DELETE FROM documents")
            }
        }
    }
    
    func testUnicode61TokenizerSeparators() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.create(virtualTable: "documents", using: FTS3()) { t in
                    t.tokenizer = .unicode61(separators: ["X"])
                }
                XCTAssertTrue(sqlQueries.contains("CREATE VIRTUAL TABLE \"documents\" USING fts3(tokenize=unicode61 \"separators=X\")"))
                
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["abcXdef"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["abcXdef"])!, 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["abc"])!, 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["def"])!, 1)
            }
        }
    }
    
    func testUnicode61TokenizerTokenCharacters() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.create(virtualTable: "documents", using: FTS3()) { t in
                    t.tokenizer = .unicode61(tokenCharacters: Set(".-".characters))
                }
                XCTAssertTrue(sqlQueries.contains("CREATE VIRTUAL TABLE \"documents\" USING fts3(tokenize=unicode61 \"tokenchars=.-\")") || sqlQueries.contains("CREATE VIRTUAL TABLE \"documents\" USING fts3(tokenize=unicode61 \"tokenchars=-.\")"))
                
                try db.execute("INSERT INTO documents VALUES (?)", arguments: ["2016-10-04.txt"])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["2016-10-04.txt"])!, 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["2016"])!, 0)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM documents WHERE documents MATCH ?", arguments: ["txt"])!, 0)
            }
        }
    }
    
    func testColumns() {
        assertNoError {
            let dbQueue = try makeDatabaseQueue()
            try dbQueue.inDatabase { db in
                try db.create(virtualTable: "books", using: FTS3()) { t in
                    t.column("author")
                    t.column("title")
                    t.column("body")
                }
                XCTAssertTrue(sqlQueries.contains("CREATE VIRTUAL TABLE \"books\" USING fts3(author, title, body)"))
                
                try db.execute("INSERT INTO books VALUES (?, ?, ?)", arguments: ["Melville", "Moby Dick", "Call me Ishmael."])
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM books WHERE books MATCH ?", arguments: ["Melville"])!, 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM books WHERE books MATCH ?", arguments: ["title:Melville"])!, 0)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM books WHERE title MATCH ?", arguments: ["Melville"])!, 0)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM books WHERE books MATCH ?", arguments: ["author:Melville"])!, 1)
                XCTAssertEqual(Int.fetchOne(db, "SELECT COUNT(*) FROM books WHERE author MATCH ?", arguments: ["Melville"])!, 1)
            }
        }
    }
}
