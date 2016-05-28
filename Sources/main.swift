import Vapor
import Foundation
import CryptoEssentials
import Fluent
import UUID

/*
    TODO: Send auth token in headers not in params
    TODO: Generate a random auth token instead of hashing username/pw, randomize every signup
    TODO: 
*/

extension String {
    var sha256String: String {
        return Base64.urlSafeEncode((self).sha256())
    }
}

let app = Application()


/**
    Setup database
*/

setupDatabase(models: [User.self, Meal.self])

/**
    Routes
*/

app.get("/guide") { request in
    return Response(status: .ok, json: APIGuide)
}

app.post("/signup") {
    request in
    
    guard let username = request.data["username"] as? String,
          let password = request.data["password"] as? String else {
        return Response(status: .badRequest, text: "missing fields")
    }
    
    var user = User(username: username, password: password)
    
    do {
        try user.save()
    } catch {
        return Response(status: .notAcceptable, text: "\(error)")
    }
    
    return Response(status: .ok, json: Json(["user" : user]))
}


app.post("/login") {
    request in
    
    guard let username = request.data["username"] as? String,
          let password = request.data["password"] as? String else {
        return Response(status: .badRequest, text: "missing fields")
    }
    
    guard let maybeUser = try? User.query.filter("username", username).filter("password", password).first(),
         let user = maybeUser else {
        return Response(status: .unauthorized, text: "Bad username or password")
    }
    
    // update token
    user.token = UUID().description.sha256String
    
    return Response(status: .ok, json: Json(["user": user]))
}


let authware = AuthMiddleware()

app.middleware(authware) {
    
    app.get("/users/me") {
        request in
        
        guard let user = request.storage["user"] as? User else {
            return Response(status: .badRequest, text: "User not found")
        }
        
        return Response(status: .ok, json: Json(["user" : user]))
    }
    
    // TODO: make this method work
    // maybe this can wait. would also need an endpoint to retrieve the image.
    app.post("/users/me/profile_pic") {
        request in
        
        guard let user = request.storage["user"] as? User else {
            return Response(status: .badRequest, text: "User not found")
        }
        
        // guard let data = // how to get full body of the request?
        
        return Response(status: .ok, json: Json(["id": "1"]))
    }
    
    
    app.post("/users/me/meals") {
        request in
        
        guard let user = request.storage["user"] as? User,
             let userId = user.id?.int else {
            return Response(status: .badRequest, text: "User not found")
        }
        
        guard let title = request.data["title"] as? String,
            let caloriesStr = request.data["calories"] as? String,
            let calories = Int(caloriesStr), // this may be broken when we get JSON data.
            let description = request.data["description"] as? String else {
                return Response(status: .badRequest, text: "missing fields")
        }
        
        var meal = Meal(title: title, calories: calories, description: description, rating: 0, userId: userId)
        
        do {
            try meal.save()
        } catch {
            return Response(status: .badRequest, text: "couldn't save meal \(error)")
        }
        
        return Response(status: .ok, json: Json(["meal" : meal]))
    }
    
    app.get("/users/me/meals") {
        request in
        
        guard let user = request.storage["user"] as? User,
             let id = user.id,
             let meals = try? Meal.query.filter("userId",id).all() else {
            return Response(status: .badRequest, text: "User not found")
        }
        
        let mealJson = meals.map { $0.makeJson() }
        
        return Response(status: .ok, json: Json(mealJson))
    }
    
    
    // TODO: this method needs an implementation
    app.post("/users/me/meals", Int.self, "rate") {
        request in
        // return ratings posted by this user
        // returns [["score", "meal_id", "user_id", "comment"]]
        return Response(status: .ok, text: "ola")
    }

}



app.start(port: 8000)



