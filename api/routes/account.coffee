options = require '../tools/optionsroute'
gw2api = require '../tools/gw2api'
httpStatus = require 'http-status-codes'

module.exports = (app, db) ->
    app.options '/account/data', options ['GET']

    app.get '/account/data', (req, res, next) ->
        gw2api.getAccount (err, account) ->
            return gw2api.fatalAPIErrorDefaultResponse err, res if err?

            res.status httpStatus.OK
            .json account

