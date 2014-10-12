passport = require 'passport'

module.exports = (app, db) ->
    app.options '/auth/login', (req, res, next) ->
        res.header 'Access-Control-Allow-Methods', 'OPTIONS, POST'
        res.header 'Access-Control-Allow-Headers', 'Content-Type'
        res.header 'Access-Control-Max-Age', 0

        res.send 204

    app.post '/auth/login',
        passport.authenticate('local', { failWithError: true })
        , (req, res, next) ->
            # Login succeeded
            res.status 200
            .json req.user
        , (err, req, res, next) ->
            # Login failed
            res.status 401
            .json { error: 'invalid credentials' }

    app.options '/auth/logout', (req, res, next) ->
        res.header 'Access-Control-Allow-Methods', 'OPTIONS, POST'
        res.header 'Access-Control-Allow-Headers', 'Content-Type'
        res.header 'Access-Control-Max-Age', 0

        res.send 204

    app.post '/auth/logout', (req, res, next) ->
        req.logout()

        res.status 200
        .json { status: 200 }
