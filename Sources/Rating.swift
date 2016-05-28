import Vapor
import Fluent
import FluentSQLite

// ["score", "meal_id", "user_id", "comment"]
class Rating {
    var id: Value?
    var userId: Int
    var mealId: Int
    
    var comment: String
    var score: Int
    
    init(userId: Int, mealId: Int, score: Int, comment: String) {
        self.userId = userId
        self.score = score
        self.comment = comment
        self.mealId = mealId
    }
    
    required init(serialized: [String: Value]) {
    	id = serialized["id"]
        
    	comment = serialized["comment"]?.string ?? ""
    	score = serialized["score"]?.int ?? 0
    	userId = serialized["userId"]?.int ?? 0
    	mealId = serialized["mealId"]?.int ?? 0
    }
}

extension Rating: Schemable {   
    static let schema = "CREATE TABLE IF NOT EXISTS ratings(" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT," +
        "userId INTEGER NOT NULL," +
        "mealId INTEGER NOT NULL," +
        "comment TEXT NOT NULL," +
        "score INTEGER NOT NULL);"
}

extension Rating: Model {
    func serialize() -> [String: Value?] {
        return [
            "comment" : comment,
            "score" : score,
            "mealId" : mealId,
            "userId" : userId
        ]
    }
    
    class var table: String {
    	return "ratings"
    }
}


extension Rating: JsonRepresentable {
    func makeJson() -> Json {
        return Json([
            "id" : id?.int ?? 0,
            "comment" : comment,
            "score" : score,
            "mealId" : mealId,
            "userId" : userId
        ])
    }
}
