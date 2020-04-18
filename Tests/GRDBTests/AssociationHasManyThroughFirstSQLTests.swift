import XCTest
import GRDB

/// Test SQL generation

// TODO: test request(for: hasManyThrough(hasMany.first, hasMany) (all comments of the last message in a chat)
class AssociationHasManyThroughFirstSQLTests: GRDBTestCase {
    
    func testBelongsToHasMany() throws {
        struct A: TableRecord, EncodableRecord {
            static let b = belongsTo(B.self)
            static let c = hasMany(C.self, through: b, using: B.c)
            func encode(to container: inout PersistenceContainer) {
                container["bId"] = 1
            }
        }
        struct B: TableRecord {
            static let c = hasMany(C.self)
        }
        struct C: TableRecord {
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.write { db in
            try db.create(table: "b") { t in
                t.autoIncrementedPrimaryKey("id")
            }
            try db.create(table: "a") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("bId").references("b")
            }
            try db.create(table: "c") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("bId").references("b")
            }
            
            do {
                let association = A.c.first
                try assertMatchSQL(db, A.all().including(required: association), """
                    SELECT "a".*, "c".*
                    FROM "a"
                    JOIN "b" ON "b"."id" = "a"."bId"
                    JOIN "c" ON "c"."id" = (SELECT "c"."id" FROM "c" WHERE "c"."bId" = "b"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, A.all().including(optional: association), """
                    SELECT "a".*, "c".*
                    FROM "a"
                    LEFT JOIN "b" ON "b"."id" = "a"."bId"
                    LEFT JOIN "c" ON "c"."id" = (SELECT "c"."id" FROM "c" WHERE "c"."bId" = "b"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, A.all().joining(required: association), """
                    SELECT "a".*
                    FROM "a"
                    JOIN "b" ON "b"."id" = "a"."bId"
                    JOIN "c" ON "c"."id" = (SELECT "c"."id" FROM "c" WHERE "c"."bId" = "b"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, A.all().joining(optional: association), """
                    SELECT "a".*
                    FROM "a"
                    LEFT JOIN "b" ON "b"."id" = "a"."bId"
                    LEFT JOIN "c" ON "c"."id" = (SELECT "c"."id" FROM "c" WHERE "c"."bId" = "b"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, A().request(for: association), """
                    SELECT "c".*
                    FROM "c"
                    JOIN "b" ON ("b"."id" = "c"."bId") AND ("b"."id" = 1)
                    LIMIT 1
                    """)
            }
        }
    }
    
    func testHasOneHasMany() throws {
        struct A: TableRecord, EncodableRecord {
            static let b = hasOne(B.self)
            static let c = hasMany(C.self, through: b, using: B.c)
            func encode(to container: inout PersistenceContainer) {
                container["id"] = 1
            }
        }
        struct B: TableRecord {
            static let c = hasMany(C.self)
        }
        struct C: TableRecord {
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.write { db in
            try db.create(table: "a") { t in
                t.autoIncrementedPrimaryKey("id")
            }
            try db.create(table: "b") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("aId").references("a")
            }
            try db.create(table: "c") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("bId").references("b")
            }
            
            do {
                let association = A.c.first
                try assertMatchSQL(db, A.all().including(required: association), """
                    SELECT "a".*, "c".*
                    FROM "a"
                    JOIN "b" ON "b"."aId" = "a"."id"
                    JOIN "c" ON "c"."id" = (SELECT "c"."id" FROM "c" WHERE "c"."bId" = "b"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, A.all().including(optional: association), """
                    SELECT "a".*, "c".*
                    FROM "a"
                    LEFT JOIN "b" ON "b"."aId" = "a"."id"
                    LEFT JOIN "c" ON "c"."id" = (SELECT "c"."id" FROM "c" WHERE "c"."bId" = "b"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, A.all().joining(required: association), """
                    SELECT "a".*
                    FROM "a"
                    JOIN "b" ON "b"."aId" = "a"."id"
                    JOIN "c" ON "c"."id" = (SELECT "c"."id" FROM "c" WHERE "c"."bId" = "b"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, A.all().joining(optional: association), """
                    SELECT "a".*
                    FROM "a"
                    LEFT JOIN "b" ON "b"."aId" = "a"."id"
                    LEFT JOIN "c" ON "c"."id" = (SELECT "c"."id" FROM "c" WHERE "c"."bId" = "b"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, A().request(for: association), """
                    SELECT "c".*
                    FROM "c"
                    JOIN "b" ON ("b"."id" = "c"."bId") AND ("b"."aId" = 1) LIMIT 1
                    """)
            }
        }
    }
    
    func testHasManyBelongsTo() throws {
        struct A: TableRecord, EncodableRecord {
            static let b = hasMany(B.self)
            static let c = hasMany(C.self, through: b, using: B.c)
            func encode(to container: inout PersistenceContainer) {
                container["id"] = 1
            }
        }
        struct B: TableRecord {
            static let c = belongsTo(C.self)
        }
        struct C: TableRecord {
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.write { db in
            try db.create(table: "a") { t in
                t.autoIncrementedPrimaryKey("id")
            }
            try db.create(table: "c") { t in
                t.autoIncrementedPrimaryKey("id")
            }
            try db.create(table: "b") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("cId").references("c")
                t.column("aId").references("a")
            }
            
            do {
                let association = A.c.first
                try assertMatchSQL(db, A.all().including(required: association), """
                    SELECT "a".*, "c".*
                    FROM "a"
                    JOIN "b" ON "b"."id" = (SELECT "b"."id" FROM "b" JOIN "c" ON "c"."id" = "b"."cId" WHERE "b"."aId" = "a"."id" LIMIT 1)
                    JOIN "c" ON "c"."id" = "b"."cId"
                    """)
                try assertMatchSQL(db, A.all().including(optional: association), """
                    SELECT "a".*, "c".*
                    FROM "a"
                    LEFT JOIN "b" ON "b"."id" = (SELECT "b"."id" FROM "b" LEFT JOIN "c" ON "c"."id" = "b"."cId" WHERE "b"."aId" = "a"."id" LIMIT 1)
                    LEFT JOIN "c" ON "c"."id" = "b"."cId"
                    """)
                try assertMatchSQL(db, A.all().joining(required: association), """
                    SELECT "a".*
                    FROM "a"
                    JOIN "b" ON "b"."id" = (SELECT "b"."id" FROM "b" JOIN "c" ON "c"."id" = "b"."cId" WHERE "b"."aId" = "a"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, A.all().joining(optional: association), """
                    SELECT "a".*
                    FROM "a"
                    LEFT JOIN "b" ON "b"."id" = (SELECT "b"."id" FROM "b" LEFT JOIN "c" ON "c"."id" = "b"."cId" WHERE "b"."aId" = "a"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, A().request(for: association), """
                    SELECT "c".*
                    FROM "c"
                    JOIN "b" ON "b"."id" = (SELECT "b"."id" FROM "b" WHERE ("b"."cId" = "c"."id") AND ("b"."aId" = 1) LIMIT 1)
                    LIMIT 1
                    """)
            }
        }
    }
    
    func testHasManyHasOne() throws {
        struct A: TableRecord, EncodableRecord {
            static let b = hasMany(B.self)
            static let c = hasMany(C.self, through: b, using: B.c)
            func encode(to container: inout PersistenceContainer) {
                container["id"] = 1
            }
        }
        struct B: TableRecord {
            static let c = hasOne(C.self)
        }
        struct C: TableRecord {
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.write { db in
            try db.create(table: "a") { t in
                t.autoIncrementedPrimaryKey("id")
            }
            try db.create(table: "b") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("aId").references("a")
            }
            try db.create(table: "c") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("bId").references("b")
            }
            
            do {
                let association = A.c.first
                try assertMatchSQL(db, A.all().including(required: association), """
                    SELECT "a".*, "c".*
                    FROM "a"
                    JOIN "b" ON "b"."id" = (SELECT "b"."id" FROM "b" JOIN "c" ON "c"."bId" = "b"."id" WHERE "b"."aId" = "a"."id" LIMIT 1)
                    JOIN "c" ON "c"."bId" = "b"."id"
                    """)
                try assertMatchSQL(db, A.all().including(optional: association), """
                    SELECT "a".*, "c".*
                    FROM "a"
                    LEFT JOIN "b" ON "b"."id" = (SELECT "b"."id" FROM "b" LEFT JOIN "c" ON "c"."bId" = "b"."id" WHERE "b"."aId" = "a"."id" LIMIT 1)
                    LEFT JOIN "c" ON "c"."bId" = "b"."id"
                    """)
                try assertMatchSQL(db, A.all().joining(required: association), """
                    SELECT "a".*
                    FROM "a"
                    JOIN "b" ON "b"."id" = (SELECT "b"."id" FROM "b" JOIN "c" ON "c"."bId" = "b"."id" WHERE "b"."aId" = "a"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, A.all().joining(optional: association), """
                    SELECT "a".*
                    FROM "a"
                    LEFT JOIN "b" ON "b"."id" = (SELECT "b"."id" FROM "b" LEFT JOIN "c" ON "c"."bId" = "b"."id" WHERE "b"."aId" = "a"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, A().request(for: association), """
                    SELECT "c".*
                    FROM "c"
                    JOIN "b" ON "b"."id" = (SELECT "b"."id" FROM "b" WHERE ("b"."id" = "c"."bId") AND ("b"."aId" = 1) LIMIT 1)
                    LIMIT 1
                    """)
            }
        }
    }
    
    func testAssociationFilteredByOtherAssociation() throws {
        struct Pet: TableRecord {
            static let child = belongsTo(Child.self)
        }
        struct Toy: TableRecord { }
        struct Child: TableRecord {
            static let toy = hasOne(Toy.self)
            static let pets = hasMany(Pet.self)
        }
        struct Parent: TableRecord, EncodableRecord {
            static let children = hasMany(Child.self)
            func encode(to container: inout PersistenceContainer) {
                container["id"] = 1
            }
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            try db.create(table: "parent") { t in
                t.autoIncrementedPrimaryKey("id")
            }
            try db.create(table: "child") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("parentId", .integer).references("parent")
            }
            try db.create(table: "toy") { t in
                t.column("childId", .integer).references("child")
            }
            try db.create(table: "pet") { t in
                t.column("childId", .integer).references("child")
            }
        }
        
        try dbQueue.inDatabase { db in
            do {
                let association = Parent.hasMany(
                    Pet.self,
                    through: Parent.children.joining(required: Child.toy),
                    using: Child.pets)
                    .first
                try assertMatchSQL(db, Parent.all().including(required: association), """
                    SELECT "parent".*, "pet".*
                    FROM "parent"
                    JOIN "child" ON "child"."id" = (
                        SELECT "child"."id"
                        FROM "child"
                        JOIN "toy" ON "toy"."childId" = "child"."id"
                        JOIN "pet" ON "pet"."rowid" = (
                            SELECT "pet"."rowid"
                            FROM "pet" WHERE "pet"."childId" = "child"."id"
                            LIMIT 1)
                        WHERE "child"."parentId" = "parent"."id"
                        LIMIT 1)
                    JOIN "pet" ON "pet"."rowid" = (SELECT "pet"."rowid" FROM "pet" WHERE "pet"."childId" = "child"."id" LIMIT 1)
                    """)
                try assertMatchSQL(db, Parent.all().joining(required: association), """
                    SELECT "parent".*
                    FROM "parent"
                    JOIN "child" ON "child"."id" = (
                        SELECT "child"."id"
                        FROM "child"
                        JOIN "toy" ON "toy"."childId" = "child"."id"
                        JOIN "pet" ON "pet"."rowid" = (
                            SELECT "pet"."rowid"
                            FROM "pet" WHERE "pet"."childId" = "child"."id"
                            LIMIT 1)
                        WHERE "child"."parentId" = "parent"."id"
                        LIMIT 1)
                    """)
                try assertMatchSQL(db, Parent().request(for: association), """
                    SELECT "pet".*
                    FROM "pet"
                    JOIN "child" ON "child"."id" = (
                        SELECT "child"."id"
                        FROM "child"
                        JOIN "toy" ON "toy"."childId" = "child"."id"
                        WHERE ("child"."id" = "pet"."childId") AND ("child"."parentId" = 1)
                        LIMIT 1)
                    LIMIT 1
                    """)
            }
            do {
                let association = Parent.hasMany(
                    Pet.self,
                    through: Parent.children.filter(sql: "1 + 1"),
                    using: Child.pets.joining(required: Pet.child.filter(sql: "1").joining(required: Child.toy)))
                    .first
                try assertMatchSQL(db, Parent.all().including(required: association), """
                    SELECT "parent".*, "pet".*
                    FROM "parent"
                    JOIN "child" ON "child"."id" = (
                        SELECT "child"."id"
                        FROM "child"
                        JOIN "pet" ON "pet"."rowid" = (
                            SELECT "pet"."rowid"
                            FROM "pet"
                            JOIN "child" ON ("child"."id" = "pet"."childId") AND (1)
                            JOIN "toy" ON "toy"."childId" = "child"."id"
                            WHERE "pet"."childId" = "child"."id"
                            LIMIT 1)
                        WHERE ("child"."parentId" = "parent"."id") AND (1 + 1)
                        LIMIT 1)
                    JOIN "pet" ON "pet"."rowid" = (
                        SELECT "pet"."rowid"
                        FROM "pet"
                        JOIN "child" ON ("child"."id" = "pet"."childId") AND (1)
                        JOIN "toy" ON "toy"."childId" = "child"."id"
                        WHERE "pet"."childId" = "child"."id"
                        LIMIT 1)
                    """)
                try assertMatchSQL(db, Parent.all().joining(required: association), """
                    SELECT "parent".*
                    FROM "parent"
                    JOIN "child" ON "child"."id" = (
                        SELECT "child"."id"
                        FROM "child"
                        JOIN "pet" ON "pet"."rowid" = (
                            SELECT "pet"."rowid"
                            FROM "pet"
                            JOIN "child" ON ("child"."id" = "pet"."childId") AND (1)
                            JOIN "toy" ON "toy"."childId" = "child"."id"
                            WHERE "pet"."childId" = "child"."id"
                            LIMIT 1)
                        WHERE ("child"."parentId" = "parent"."id") AND (1 + 1)
                        LIMIT 1)
                    """)
                try assertMatchSQL(db, Parent().request(for: association), """
                    SELECT "pet".*
                    FROM "pet"
                    JOIN "child" "child1" ON ("child1"."id" = "pet"."childId") AND (1)
                    JOIN "toy" ON "toy"."childId" = "child1"."id"
                    JOIN "child" "child2" ON "child2"."id" = (
                        SELECT "child2"."id"
                        FROM "child" "child2"
                        WHERE ("child2"."id" = "pet"."childId") AND (1 + 1) AND ("child2"."parentId" = 1)
                        LIMIT 1)
                    LIMIT 1
                    """)
            }
            do {
                let association = Parent.hasMany(
                    Pet.self,
                    through: Parent.children.filter(sql: "1 + 1"),
                    using: Child.pets)
                    .joining(required: Pet.child.filter(sql: "1").joining(required: Child.toy))
                    .first
                try assertMatchSQL(db, Parent.all().including(required: association), """
                    SELECT "parent".*, "pet".*
                    FROM "parent"
                    JOIN "child" ON "child"."id" = (
                        SELECT "child"."id"
                        FROM "child"
                        JOIN "pet" ON "pet"."rowid" = (
                            SELECT "pet"."rowid"
                            FROM "pet"
                            JOIN "child" ON ("child"."id" = "pet"."childId") AND (1)
                            JOIN "toy" ON "toy"."childId" = "child"."id"
                            WHERE "pet"."childId" = "child"."id"
                            LIMIT 1)
                        WHERE ("child"."parentId" = "parent"."id") AND (1 + 1)
                        LIMIT 1)
                    JOIN "pet" ON "pet"."rowid" = (
                        SELECT "pet"."rowid"
                        FROM "pet"
                        JOIN "child" ON ("child"."id" = "pet"."childId") AND (1)
                        JOIN "toy" ON "toy"."childId" = "child"."id"
                        WHERE "pet"."childId" = "child"."id"
                        LIMIT 1)
                    """)
                try assertMatchSQL(db, Parent.all().joining(required: association), """
                    SELECT "parent".*
                    FROM "parent"
                    JOIN "child"
                    ON "child"."id" = (
                        SELECT "child"."id"
                        FROM "child"
                        JOIN "pet" ON "pet"."rowid" = (
                            SELECT "pet"."rowid"
                            FROM "pet"
                            JOIN "child" ON ("child"."id" = "pet"."childId") AND (1)
                            JOIN "toy" ON "toy"."childId" = "child"."id"
                            WHERE "pet"."childId" = "child"."id"
                            LIMIT 1)
                        WHERE ("child"."parentId" = "parent"."id") AND (1 + 1)
                        LIMIT 1)
                    """)
                // TODO: no need for "child2" in the subquery
                try assertMatchSQL(db, Parent().request(for: association), """
                    SELECT "pet".*
                    FROM "pet"
                    JOIN "child" "child1" ON ("child1"."id" = "pet"."childId") AND (1)
                    JOIN "toy" ON "toy"."childId" = "child1"."id"
                    JOIN "child" "child2" ON "child2"."id" = (
                        SELECT "child2"."id" FROM "child" "child2"
                        WHERE ("child2"."id" = "pet"."childId") AND (1 + 1) AND ("child2"."parentId" = 1)
                        LIMIT 1)
                    LIMIT 1
                    """)
            }
        }
    }
}