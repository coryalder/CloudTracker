import Vapor
import Foundation
import CryptoEssentials
import Fluent
import UUID
import S4


let app = Application()

/**
    Setup database
*/

setupDatabase(models: [User.self, Meal.self])

func jsonError(_ string: String) -> JSON {
    return JSON(["error": string])
}

/**
    Routes
*/

app.post("/signup") {
    request in
    
    guard let username = request.data["username"].string,
          let password = request.data["password"].string else {
        return Response(status: .badRequest, json: jsonError("missing fields \(request.data)"))
    }
    
    // Check for an existing user
    let existing = try User.query.filter("username", username).first()
    if existing != nil {
        return Response(status: .conflict, json: jsonError("Username already in use"))
    }
    
    // Create and save a new user
    var user = User(username: username, password: password)
    try user.save()
    
    return Response(status: .ok, json: JSON(["user" : user]))
}


app.post("/login") {
    request in
    
    guard let username = request.data["username"].string,
          let password = request.data["password"].string else {
        return Response(status: .badRequest, json: jsonError("Missing a 'username' and/or 'password'"))
    }
    
    guard let maybeUser = try? User.query.filter("username", username).filter("password", password).first(),
         var user = maybeUser else {
        return Response(status: .forbidden, json: jsonError("Bad username or password"))
    }
    
    // update token
    user.token = UUID().description.sha256String
    
    try user.save()
    
    return Response(status: .ok, json: JSON(["user": user]))
}


let authware = AuthMiddleware()

app.grouped(authware) {
    group in
    
    group.get("/users/me") {
        request in
        
        guard let user = request.storage["user"] as? User else {
            return Response(status: .badRequest, json: jsonError("User not found"))
        }
        
        return Response(status: .ok, json: JSON(["user" : user ]))
    }
    
    group.post("/users/me/meals", Int.self, "photo") {
        request, mealId in
        
        guard let user = request.storage["user"] as? User,
            let id = user.id else {
            return Response(status: .badRequest, json: jsonError("User not found"))
        }
        
        guard var meal = try Meal.query.filter("userId", id).filter("id", mealId).first() else {
            return Response(status: .notFound, json: jsonError("Meal not found"))
        }
        
        var request = request
        
        guard let rawData = try? request.body.becomeBuffer() else {
            return Response(status: .badRequest, json: jsonError("Image data not supplied"))
        }
        
        // delete old meal url
        if let currentPicName = meal.imagePath {
            try NSFileManager().removeItem(atPath: "./Public\(currentPicName)")
        }
        
        // save new meal url
        let data = NSData(bytes: rawData.bytes as [UInt8], length: rawData.bytes.count)
        let fileName = "/photos/" + UUID().description
        try data.write(toFile:"./Public\(fileName)")
        
        meal.imagePath = fileName
        try meal.save()
        
        return Response(status: .ok, json: JSON(["meal": meal]))
    }
    
    group.post("/users/me/meals") {
        request in
        
        guard let user = request.storage["user"] as? User,
             let userId = user.id?.int else {
            return Response(status: .badRequest, json: jsonError("User not found"))
        }
        
        guard let title = request.data["title"].string,
            let caloriesStr = request.data["calories"].string,
            let calories = Int(caloriesStr), // this may be broken when we get JSON data.
            let description = request.data["description"].string else {
                return Response(status: .badRequest, json: jsonError("missing fields"))
        }
        
        var meal = Meal(title: title, calories: calories, description: description, rating: 0, userId: userId)
        try meal.save()
    
        return Response(status: .ok, json: JSON(["meal" : meal]))
    }
   
    group.get("/users/me/meals") {
        request in
        
        guard let user = request.storage["user"] as? User,
             let id = user.id,
             let meals = try? Meal.query.filter("userId",id).all() else {
            return Response(status: .badRequest, json: jsonError("User not found"))
        }
        
        let mealJson = meals.map { $0.makeJson() }
        
        return Response(status: .ok, json: JSON(mealJson))
    }
  
    group.post("/users/me/meals", Int.self, "rate") {
        request, mealId in
        
        guard let user = request.storage["user"] as? User,
            let id = user.id else {
            return Response(status: .badRequest, json: jsonError("User not found"))
        }
        
        do {
            guard var meal = try Meal.query.filter("userId", id).filter("id", mealId).first() else {
                throw ClientError.notFound
            }
         
            guard let ratingStr = request.data["rating"].string,
                 let rating = Int(ratingStr) else {
                throw ClientError.badRequest
            }
        
            meal.rating = max(0,min(5, rating))
        
            try meal.save()

            return Response(status: .ok, json: JSON(["meal": meal]))
        } catch {
            return Response(status: .badRequest, json: jsonError("\(error)"))
        }
    }
    
}



app.start()



