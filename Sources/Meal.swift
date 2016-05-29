import Vapor
import Fluent
import FluentSQLite

class Meal {
    var id: Value?
    var userId: Int
    
    var title: String
    var calories: Int
    var description: String
    var rating: Int
    
    var imagePath: String?
    
    init(title: String, calories: Int, description: String, rating: Int, userId: Int) {
        self.title = title
        self.calories = calories
        self.description = description
        self.userId = userId
        self.rating = rating
    }
    
    required init(serialized: [String: Value]) {
    	id = serialized["id"]
        
    	title = serialized["title"]?.string ?? ""
    	calories = serialized["calories"]?.int ?? 0
    	description = serialized["description"]?.string ?? ""
    	userId = serialized["userId"]?.int ?? 0
        rating = serialized["rating"]?.int ?? 0
        
        imagePath = serialized["imagePath"]?.string
    }
    
}

extension Meal: Schemable {
    static let schema = "CREATE TABLE IF NOT EXISTS meals(" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT," +
        "userId INTEGER NOT NULL," +
        "rating INTEGER NOT NULL," +
        "title TEXT NOT NULL," +
        "calories INTEGER NOT NULL," +
        "description TEXT NOT NULL," +
        "imagePath TEXT);"
}

extension Meal: Model {
    func serialize() -> [String: Value?] {
        return [
            "title" : title,
            "calories" : calories,
            "description" : description,
            "rating" : self.rating,
            "imagePath" : self.imagePath,
            "userId" : userId
        ]
    }
    
    class var table: String {
    	return "meals"
    }
}


extension Meal: JSONRepresentable {
    func makeJson() -> JSON {
        return JSON([
            "id" : self.id?.int ?? 0,
            "title": self.title,
            "calories": self.calories,
            "userId" : self.userId,
            "rating" : self.rating,
            "imagePath" : self.imagePath ?? "",
            "description": self.description
        ])
    }
}
