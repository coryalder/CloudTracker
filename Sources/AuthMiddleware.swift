import Vapor

class AuthMiddleware: Middleware {

    func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        
        guard let token = request.data["token"] as? String else {
              return Response(status: .badRequest, text: "missing auth token")
        }
        
        do {
            guard let user = try User.query.filter("token", token).first() else {
                return Response(status: .unauthorized, text: "invalid token")
            }
            
            var req = request
            req.storage["user"] = user
            return try chain.respond(to: req)
            
        } catch {
            return Response(status: .unauthorized, text: "invalid token: \(error)")
        }
    }

}