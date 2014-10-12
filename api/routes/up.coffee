options = require '../tools/optionsroute'

module.exports = (app, db) ->
    app.options '/up', options ['GET']

    app.get '/up', (req, res, next) ->
        db.run "SELECT COUNT(*) FROM tUser"
        , (err) ->
            if err?
                res.status 200
                .json { status: 200, api_status: 'down' }
            else
                res.status 200
                .json { status: 200, api_status: 'up' }
