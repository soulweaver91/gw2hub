express = require 'express'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
expressSession = require 'express-session'
http = require 'http'
fs = require 'fs'
passport = require 'passport'
strategy = require('passport-local').Strategy
_ = require 'lodash'

settings = require('../settings').get()
security = require './tools/security'

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

# Create the passport strategy to validate credentials
passport.use new strategy {
    usernameField: 'email',
    passwordField: 'pass'
}, (email, password, done) ->
    db.get 'SELECT * FROM tUser WHERE email = ?', email, (err, row) ->
        return done err if err?
        return done null, false if !row?

        security.compare password, row.pass, (err, res) ->
            return done err if err?
            return done null, false if !res
            done null, _.omit row, ['pass']

passport.serializeUser (user, done) ->
    done null, user.id

passport.deserializeUser (id, done) ->
    db.get 'SELECT * FROM tUser WHERE id = ?', id, (err, row) ->
        done err, _.omit row, ['pass']

# Add passport to the server
app.use passport.initialize()
app.use passport.session()

# Only allow connections from the defined UI server
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
