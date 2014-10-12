options = require '../tools/optionsroute'

module.exports = (app, db) ->
    app.options '/tags', options ['GET', 'POST']

    app.get '/tags', (req, res, next) ->
        db.all 'SELECT * FROM tTag', (err, rows) ->
            if err?
                res.status 500
                .json { status: 500, error: 'Database error' }
            else
                res.status 200
                .json rows

    app.post '/tags', (req, res, next) ->
        res.status 501
        .json { status: 501, error: 'Not yet implemented' }
