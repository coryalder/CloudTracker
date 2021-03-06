# CloudTracker API Guide

## Entities

### User

- username: String
- password: String
- token: String

### Meal

- calories: Int
- description: String
- title: String
- imagePath: String - not a full url, just the path on this server. e.g. `/photos/1D5EE0C4-A96E-4B44-9A7C-652E978B3CB5`
- userId: Int
- id: Int
- rating: Int

## Authentication

Authentication token should be sent via the `token` http header for all authenticated endpoints. That means everything except `/login` and `/signup`.

An authentication token can be obtained via the signup or login endpoint. New users (`/signup`) are given a token that is a hash of their username and passsword. The `/login` endpoint invalidates the previous token, and creates a new token.

## Errors

All endpoints return errors as non 200 status codes, as well as a json object in this format:

    {"error": "description of error"}


## Endpoints

### POST - `/Login`

This endpoint is used to trade a login/password for an auth token.

#### Valid parameters

- username: String
- password: String

#### Returns

- user: User

Returns 403 for bad credentials. Token from response can be sent as a header to access authenticated endpoints. Auth token not required.


### POST - `/signup`

This endpoint is used to create a new user.

#### Valid parameters

- username: String
- password: String

#### Returns

- user: User

Returns 400 for malformed/missing data, 409 for existing user. User's returned "token" property can be sent as a header to access authenticated endpoints. Auth token not required.

### GET - `/users/me`

This endpoint retrives the user's profile.

#### Returns

- user: User

Returns 403 if `token` header is missing.

### POST - `/users/me/meals/:id/photo`

Upload a meal's associated image. Body of post should contain raw image data.

#### Returns

- meal: Meal  
	Meal's Contains the path, on this server, to retrieve the image from. e.g. `/photos/1D5EE0C4-A96E-4B44-9A7C-652E978B3CB5`. Images are not modified in any way after uploading, supports `jpg`, `png`, and `gif` images.

Returns 400 if data is missing.

### GET - `/users/me/meals`

This endpoint returns all meals owned by this user.

#### Returns

- ~~meals: [Meal]~~
- [Meal] - due to a compiler bug in the current swift 3 snapshot, I can't seem to get this to return a dictionary instead of a top level array. *sigh*.



### POST - `/users/me/meals`

This endpoint is used to create a meal object owned by the currently authenticated user.

#### Required parameters

- title: String
- calories: Int
- description: String

#### Returns

- meal: Meal

Returns an array of meals, empty if none available, 403 if bad token.

### POST - `/users/me/meals/:id/rate`

This endpoint is used to set the rating on a specific meal object. The :id is an Int that specifies which meal to rate.

#### Required parameters

- rating: Int

#### Returns

- meal: Meal

Returns 403 if bad auth token, 404 if meal not found, 400 if missing request data.

## Curl examples

**Sign up a new user**

Request: `curl -H "Content-Type: application/json" -d '{"username": "cory", "password" : "1234"}' "http://localhost:8000/signup"`

Response: `{"user":{"token":"anGfKOFTTtQ1xwEkkXjieC9K9s4UNu9y0J9BadGhUtE","username":"cory","password":"1234"}}`
    
**Create a meal**
    
Request: `curl -H "Content-Type: application/json" -H "token: anGfKOFTTtQ1xwEkkXjieC9K9s4UNu9y0J9BadGhUtE" -d '{"title": "tacos", "calories" : 1500, "description": "really good, from a local place"}' "http://localhost:8000/users/me/meals"`
    
Response: `{"meal":{"calories":1500,"id":1,"description":"really good, from a local place","title":"tacos","userId":1,"rating":0,"imagePath":""}}`
      

**Rate a meal**

Request: `curl -H "token: anGfKOFTTtQ1xwEkkXjieC9K9s4UNu9y0J9BadGhUtE" -H "Content-Type: application/json" -d '{"rating": 5}' "http://localhost:8000/users/me/meals/1/rate"`
    
Response: `{"meal":{"calories":1500,"id":1,"description":"really good, from a local place","title":"tacos","userId":1,"rating":5,"imagePath":""}}`


