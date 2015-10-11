passport = require 'passport'
httpStatus = require 'http-status-codes'

options = require '../tools/optionsroute'

module.exports = (app, db) ->
    app.options '/auth/login', options ['POST']
    app.options '/auth/logout', options ['POST']
    app.options '/auth/status', options ['GET']

    app.post '/auth/login',
        passport.authenticate('local', { failWithError: true })
        , (req, res, next) ->
            # Login succeeded
            res.status httpStatus.OK
            .json req.user
        , (err, req, res, next) ->
            # Login failed
            res.status httpStatus.UNAUTHORIZED
            .json { error: 'invalid credentials' }

    app.post '/auth/logout', (req, res, next) ->
        req.logout()

        res.status httpStatus.OK
        .json { status: httpStatus.OK }

    app.get '/auth/status', (req, res, next) ->
        if req.isAuthenticated()
            res.status httpStatus.OK
            .json {
                status: httpStatus.OK
                logged_in: true
                user: req.user
            }
        else
            res.status httpStatus.OK
            .json {
                status: httpStatus.OK
                logged_in: false
                user: null
            }
