passport = require 'passport'

options = require '../tools/optionsroute'

module.exports = (app, db) ->
    app.options '/auth/login', options ['POST']
    app.options '/auth/logout', options ['POST']

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
