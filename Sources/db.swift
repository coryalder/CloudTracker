
import Fluent
import FluentSQLite

/* schema:

// in Database/main.sqlite:
*/

protocol Schemable {
    static var schema: String { get }
}


func setupDatabase(models: [Schemable.Type]) {
    do {
        let driver = try SQLiteDriver()
        Database.default = Database(driver: driver)
    
        for m in models {
            _ = try driver.raw(m.schema)
        }
        
    
        let results = try driver.raw("SELECT sqlite_version();")
    
        if
            let row = results.first,
            let version = row["sqlite_version()"]?.string
        {
            print("SQLite Version: \(version)")
        }
    
    } catch {
        print("Could not initialize driver: \(error)")
    }
}