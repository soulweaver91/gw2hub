options = require '../tools/optionsroute'
httpStatus = require 'http-status-codes'

module.exports = (app, db) ->
    app.options '/up', options ['GET']

    app.get '/up', (req, res, next) ->
        db.run "SELECT COUNT(*) FROM tUser"
        , (err) ->
            if err?
                res.status httpStatus.OK
                .json { status: httpStatus.OK, api_status: 'down' }
            else
                res.status httpStatus.OK
                .json { status: httpStatus.OK, api_status: 'up' }
