express = require 'express'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
expressSession = require 'express-session'
http = require 'http'
fs = require 'fs'

settings = require('../settings').get()

sqlite = require 'sqlite3'
db = new sqlite.Database settings.database

app = express()
server = http.createServer app

# Add JSON, cookie, session and header layers to the server
app.use bodyParser.json()
app.use cookieParser()
app.use expressSession {
    secret: settings.APISecret
    saveUninitialized: true
    resave: true
}

app.use (req, res, next) ->
    res.header "Access-Control-Allow-Origin", settings.siteAddress
    res.header 'Access-Control-Allow-Credentials', true
    next()

# Add all defined routes from the route directory
routes = fs.readdirSync './api/routes'
for file in routes
    if file.match /.*\.coffee$/
        route = require './routes/' + file
        route app, db

exports = module.exports = server
exports.use = (args...) ->
    app.use.apply app, args
