import Vapor

let APIGuide: Json = Json([
    "Login":
        [
            "description" : "Trade a login/password for a session token",
            "endpoint": "/login",
            "methods": ["post"],
            "post_parameters" : ["username", "password"],
            "returns": ["session_token"],
            "notes" : "returns 403 for bad credentials"
        ],
    "Signup":
        [
            "description" : "Create a new user",
            "endpoint": "/signup",
            "methods": ["post"],
            "post_parameters" : ["username", "password"],
            "returns": ["session_token"],
            "notes" : "returns 400 for malformed/missing data"
    ],
    "Profile":
        [
            "description" : "The authenticated user's profile",
            "endpoint": "/users/me",
            "methods": ["post", "get"],
            "post_parameters" : ["name"],
            "returns": ["name", "profile_pic_url", "username", "id"],
            "notes" : "returns 403 if session_token is missing"
    ],
    "Upload photo":
        [
            "description" : "Upload a photo for the authenticated user",
            "endpoint": "/users/me/profile_pic",
            "methods": ["post"],
            "post_parameters" : [],
            "returns": ["profile_pic_url"],
            "notes" : "post should include raw image data, not wrapped in json. returns 400 if data is not an image or not included"
    ],
    "Meals":
        [
            "description" : "Meals posted by this user",
            "endpoint": "/user/me/meals",
            "methods": ["post", "get"],
            "post_parameters" : ["title", "calories", "description"],
            "returns": [["title", "calories", "id", "description"]],
            "notes" : "returns an array of meals, empty if none available, 403 if bad session_token"
    ],
    "Get ratings":
        [
            "description" : "Ratings posted by this user",
            "endpoint": "/users/me/ratings",
            "methods": ["get"],
            "returns": [["score", "meal_id", "user_id", "comment"]],
            "notes" : "403 if bad session, empty array otherwise"
    ],
    "Update rating":
        [
            "description" : "Add a rating, or update an existing rating if it already exists?",
            "endpoint": "/users/me/meals/:id/ratings",
            "methods": ["post"],
            "post_parameters" : ["score", "comment"],
            "returns": ["score", "meal_id", "user_id", "comment"],
            "notes" : "403 if bad session, 404 if meal not found, 400 if bad data"
    ]
])