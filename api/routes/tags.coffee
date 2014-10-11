module.exports = (app, db) ->
    app.options '/tags', (req, res, next) ->
        res.header 'Access-Control-Allow-Methods', 'OPTIONS, GET, POST'
        res.header 'Access-Control-Allow-Headers', 'Content-Type'
        res.header 'Access-Control-Max-Age', 0

        res.send 204

    app.get '/tags', (req, res, next) ->
        db.all 'SELECT * FROM tTag', (err, rows) ->
            if err?
                res.status 500
                .json { error: 'Database error' }
            else
                res.status 200
                .json rows

    app.post '/tags', (req, res, next) ->
        res.status 501
        .json { error: 'Not yet implemented' }
