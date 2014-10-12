passport = require 'passport'

options = require '../tools/optionsroute'

module.exports = (app, db) ->
    app.options '/auth/login', options ['POST']
    app.options '/auth/logout', options ['POST']
    app.options '/auth/status', options ['GET']

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

    app.post '/auth/logout', (req, res, next) ->
        req.logout()

        res.status 200
        .json { status: 200 }

    app.get '/auth/status', (req, res, next) ->
        if req.isAuthenticated()
            res.status 200
            .json {
                status: 200
                logged_in: true
                user: req.user
            }
        else
            res.status 200
            .json {
                status: 200
                logged_in: false
                user: null
            }
