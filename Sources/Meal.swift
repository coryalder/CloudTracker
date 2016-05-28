import Vapor
import Fluent
import FluentSQLite

class Meal {
    var id: Value?
    var userId: Int
    
    var title: String
    var calories: Int
    var description: String
    
    init(title: String, calories: Int, description: String, userId: Int) {
        self.title = title
        self.calories = calories
        self.description = description
        self.userId = userId
    }
    
    required init(serialized: [String: Value]) {
    	id = serialized["id"]
        
    	title = serialized["title"]?.string ?? ""
    	calories = serialized["calories"]?.int ?? 0
    	description = serialized["description"]?.string ?? ""
    	userId = serialized["userId"]?.int ?? 0
    }
    
}

extension Meal: Schemable {
    static let schema = "CREATE TABLE IF NOT EXISTS meals(" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT," +
        "userId INTEGER NOT NULL," +
        "title TEXT NOT NULL," +
        "calories INTEGER NOT NULL," +
        "description TEXT NOT NULL);"
}

extension Meal: Model {
    func serialize() -> [String: Value?] {
        return [
            "title" : title,
            "calories" : calories,
            "description" : description,
            "userId" : userId
        ]
    }
    
    class var table: String {
    	return "meals"
    }
}


extension Meal: JsonRepresentable {
    func makeJson() -> Json {
        return Json([
            "id" : self.id?.int ?? 0,
            "title": self.title,
            "calories": self.calories,
            "userId" : self.userId,
            "description": self.description
        ])
    }
}