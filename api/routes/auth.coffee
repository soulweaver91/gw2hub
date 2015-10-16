passport = require 'passport'
httpStatus = require 'http-status-codes'

options = require '../tools/optionsroute'
middleware = require '../tools/middleware'
security = require '../tools/security'
commonResponses = require '../tools/commonresponses'
settings = require('../../configmanager').get()

module.exports = (app, db) ->
    app.options '/auth/login', options ['POST']
    app.options '/auth/logout', options ['POST']
    app.options '/auth/status', options ['GET']
    app.options '/auth/password', options ['POST']

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

    app.post '/auth/password'
    , middleware.requireLoggedIn
    , (req, res, next) ->

        db.get 'SELECT pass FROM tUser WHERE id = ?', req.user.id, (err, user) ->
            return commonResponses.databaseError res if err?

            if !user?
                # Could not find the user
                req.logout()

                return res.status httpStatus.UNAUTHORIZED
                .json { error: 'not logged in' }

            if !req.body.current? || !req.body.new? || !req.body.newConfirm?
                return res.status httpStatus.BAD_REQUEST
                .json { error: 'required fields missing' }

            if req.body.new != req.body.newConfirm
                return res.status httpStatus.BAD_REQUEST
                .json { error: 'new password was different on confirmation field' }

            pwLength = if typeof settings.minimumPasswordLength == 'number' then settings.minimumPasswordLength else 8
            if req.body.new.length < pwLength
                return res.status httpStatus.BAD_REQUEST
                .json { error: "password must be at least #{pwLength} characters long" }

            security.compare req.body.current, user.pass, (err, result) ->
                if err?
                    return res.status httpStatus.INTERNAL_SERVER_ERROR
                    .json { error: 'failed to compare passwords' }

                if !result
                    return res.status httpStatus.FORBIDDEN
                    .json { error: 'invalid current password' }

                security.hash req.body.new, (err, val) ->
                    if err?
                        return res.status httpStatus.INTERNAL_SERVER_ERROR
                        .json { error: 'failed to save new password' }

                    db.run 'UPDATE tUser SET pass = ? WHERE id = ?', val, req.user.id, (err) ->
                        return commonResponses.databaseError res if err?

                        res.status httpStatus.OK
                        .json { status: httpStatus.OK, message: 'changed' }
