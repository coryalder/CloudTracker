import Vapor
import Foundation
import CryptoEssentials
import Fluent
import UUID
import S4


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
    
    guard let username = request.data["username"].string,
          let password = request.data["password"].string else {
        return Response(status: .badRequest, text: "missing fields \(request.data)")
    }
    
    var user = User(username: username, password: password)
    
    do {
        try user.save()
    } catch {
        return Response(status: .notAcceptable, text: "\(error)")
    }
    
    return Response(status: .ok, json: JSON(["user" : user]))
}


app.post("/login") {
    request in
    
    guard let username = request.data["username"] as? String,
          let password = request.data["password"] as? String else {
        return Response(status: .badRequest, text: "missing fields")
    }
    
    guard let maybeUser = try? User.query.filter("username", username).filter("password", password).first(),
         var user = maybeUser else {
        return Response(status: .unauthorized, text: "Bad username or password")
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
            return Response(status: .badRequest, text: "User not found")
        }
        
        var out: [String: String] = [
            "username": user.username,
            "password": user.password,
            "token": user.token
        ]
        
        if let p = user.profile_pic_url {
            out["profile_pic_url"] = p
        }
        
        let jsoned = JSON(out)
        
        return Response(status: .ok, json: ["user" : jsoned ])
    }
    
    // TODO: make this method work
    // maybe this can wait. would also need an endpoint to retrieve the image.
    group.post("/users/me/profile_pic") {
        request in
        
        guard var user = request.storage["user"] as? User else {
            return Response(status: .badRequest, text: "User not found")
        }
        
        var request = request
        
        guard let rawData = try? request.body.becomeBuffer() else {
            throw ClientError.badRequest
        }
        
        if let currentPicName = user.profile_pic_url {
            try NSFileManager().removeItem(atPath: "./Public/\(currentPicName)")
        }
        
        let data = NSData(bytes: rawData.bytes as [UInt8], length: rawData.bytes.count)
        let fileName = UUID().description
        try data.write(toFile:"./Public/\(fileName)")
        
        user.profile_pic_url = fileName
        try user.save()
        
        return Response(status: .ok, json: JSON(["url": fileName]))
    }
    
    group.post("/users/me/meals") {
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
        
        return Response(status: .ok, json: JSON(["meal" : meal]))
    }
    
    group.get("/users/me/meals") {
        request in
        
        guard let user = request.storage["user"] as? User,
             let id = user.id,
             let meals = try? Meal.query.filter("userId",id).all() else {
            return Response(status: .badRequest, text: "User not found")
        }
        
        let mealJson = meals.map { $0.makeJson() }
        
        return Response(status: .ok, json: JSON(mealJson))
    }
    
    group.post("/users/me/meals", Int.self, "rate") {
        request, mealId in
        
        guard let user = request.storage["user"] as? User,
            let id = user.id else {
            return Response(status: .badRequest, text: "User not found")
        }
        
        do {
            guard let meal = try Meal.query.filter("userId", id).filter("id", mealId).first() else {
                throw ClientError.notFound
            }
            return Response(status: .ok, json: JSON(["meal": meal]))
        } catch {
            return Response(status: .notFound, text: "meal not found")
        }
    }

}



app.start()



