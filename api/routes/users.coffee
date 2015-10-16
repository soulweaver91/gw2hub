options = require '../tools/optionsroute'
middleware = require '../tools/middleware'

httpStatus = require 'http-status-codes'
commonResponses = require '../tools/commonresponses'
privilegeLevels = require '../tools/privilegelevels'

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

    app.post '/users', (req, res, next) ->
        res.status httpStatus.NOT_IMPLEMENTED
        .json { status: httpStatus.NOT_IMPLEMENTED }

    app.get '/users/:id', (req, res, next) ->
        res.status httpStatus.NOT_IMPLEMENTED
        .json { status: httpStatus.NOT_IMPLEMENTED }

    app.patch '/users/:id', (req, res, next) ->
        res.status httpStatus.NOT_IMPLEMENTED
        .json { status: httpStatus.NOT_IMPLEMENTED }

    app.delete '/users/:id', (req, res, next) ->
        res.status httpStatus.NOT_IMPLEMENTED
        .json { status: httpStatus.NOT_IMPLEMENTED }
