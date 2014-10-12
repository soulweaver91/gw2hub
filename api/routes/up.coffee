module.exports = (app, db) ->
    app.options '/up', (req, res, next) ->
        res.header 'Access-Control-Allow-Methods', 'OPTIONS, GET'
        res.header 'Access-Control-Allow-Headers', 'Content-Type'
        res.header 'Access-Control-Max-Age', 0

        res.send 204

    app.get '/up', (req, res, next) ->
        db.run "SELECT COUNT(*) FROM tUser"
        , (err) ->
            if err?
                res.status 200
                .json { status: 200, api_status: 'down' }
            else
                res.status 200
                .json { status: 200, api_status: 'up' }
