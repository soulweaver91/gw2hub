options = require '../tools/optionsroute'
middleware = require '../tools/middleware'
security = require '../tools/security'

httpStatus = require 'http-status-codes'
commonResponses = require '../tools/commonresponses'
privilegeLevels = require '../tools/privilegelevels'
_ = require 'lodash'

module.exports = (app, db) ->
    app.options '/users', options ['GET', 'POST']
    app.options '/users/:id', options ['GET', 'PATCH', 'DELETE']

    app.get '/users'
    , middleware.requireMinPrivilegeLevel(privilegeLevels.admin)
    , (req, res, next) ->
        db.all 'SELECT id, email, name, ulevel FROM tUser', (err, users) ->
            return commonResponses.databaseError res if err?

            res.status httpStatus.OK
            .json users

    app.post '/users'
    , middleware.requireMinPrivilegeLevel(privilegeLevels.admin)
    , (req, res, next) ->
        if !req.body.name? || !req.body.email?
            return res.status httpStatus.BAD_REQUEST
            .json { error: 'required fields missing' }

        # Generate a random password for the user. This will be displayed to the administrator once.
        # Support for sending a registration link to the specified e-mail directly instead might be implemented later.
        passChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz+-_!?".split ''
        tempPass = _.times(10, -> _.sample passChars, 1).join ''

        userLevel = if req.body.ulevel? then req.body.ulevel else privilegeLevels.user

        security.hash tempPass, (err, hash) ->
            if err?
                return res.status httpStatus.INTERNAL_SERVER_ERROR
                .json { 'error': 'password generation failed' }

            db.run 'INSERT INTO tUser (email, name, ulevel, pass) VALUES (?, ?, ?, ?)',
                req.body.email, req.body.name, userLevel, hash, (err) ->
                    if err?
                        if err.code == 'SQLITE_CONSTRAINT'
                            return res.status httpStatus.BAD_REQUEST
                            .json { status: httpStatus.BAD_REQUEST, error: 'email already in use' }
                        else
                            return commonResponses.databaseError res

                    db.get 'SELECT * FROM tUser WHERE id = ?', @lastID, (err, user) ->
                        return commonResponses.databaseError res if err?

                        user.tempPass = tempPass

                        res.status httpStatus.OK
                        .json _.omit user, ['pass']

    app.get '/users/:id', (req, res, next) ->
        db.get 'SELECT * FROM tUser WHERE id = ?', req.params.id, (err, user) ->
            return commonResponses.databaseError if err?

            if !req.user? || (parseInt(req.params.id) != req.user.id && req.user.ulevel < privilegeLevels.admin)
                user = _.omit user, ['email']

            if user?
                res.status httpStatus.OK
                .json _.omit user, ['pass']
            else
                return commonResponses.badID res

    app.patch '/users/:id'
    , middleware.requireMinPrivilegeLevelOrSelfID(privilegeLevels.admin, 'id')
    , (req, res, next) ->
        if req.user.ulevel < privilegeLevels.admin && req.body.ulevel?
            return res.status httpStatus.FORBIDDEN
            .json { error: 'you cannot set your user level' }

        db.get 'SELECT * FROM tUser WHERE id = ?', req.params.id, (err, user) ->
            return commonResponses.databaseError res if err?

            if !user?
                return commonResponses.badID res

            user = _.merge user, _.pick req.body, ['name', 'ulevel', 'email']

            db.run 'UPDATE tUser SET name = ?, email = ?, ulevel = ? WHERE id = ?',
                user.name, user.email, user.ulevel, user.id, (err) ->
                    if err?
                        if err.code == 'SQLITE_CONSTRAINT'
                            return res.status httpStatus.BAD_REQUEST
                            .json { status: httpStatus.BAD_REQUEST, error: 'email already in use' }
                        else
                            return commonResponses.databaseError res

                    res.status httpStatus.OK
                    .json _.omit user, ['pass']


    app.delete '/users/:id'
    , middleware.requireMinPrivilegeLevel(privilegeLevels.admin)
    , (req, res, next) ->
        db.get 'SELECT * FROM tUser WHERE id = ?', req.params.id, (err, user) ->
            return commonResponses.databaseError res if err?

            if !user?
                return commonResponses.badID res

            db.run 'DELETE FROM tUser WHERE id = ?', user.id, (err) ->
                return commonResponses.databaseError res if err?

                res.status httpStatus.OK
                .json { status: httpStatus.OK, message: 'deleted' }
