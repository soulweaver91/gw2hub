options = require '../tools/optionsroute'

moment = require 'moment'
_ = require 'lodash'

getTimespanImages = (db, res, start, end) ->
    db.all 'SELECT * FROM tFile WHERE timestamp >= ? AND timestamp < ? ORDER BY timestamp ASC',
        start.valueOf(), end.valueOf(), (err, rows) ->
            if err?
                res.status 500
                .json { status: 500, error: 'Database error' }
            else
                res.status 200
                .json rows

module.exports = (app, db) ->
    app.options '/gallery/:year', options ['GET']
    app.options '/gallery/:year/:month', options ['GET']
    app.options '/gallery/:year/:month/:day', options ['GET']

    app.get '/gallery/:year', (req, res, next) ->
        start = moment {y: parseInt(req.params.year)}
        end = start.clone().add(1, 'years')
        getTimespanImages db, res, start, end

    app.get '/gallery/:year/:month', (req, res, next) ->
        start = moment {y: parseInt(req.params.year), M: parseInt(req.params.month) - 1}
        end = start.clone().add(1, 'months')
        getTimespanImages db, res, start, end

    app.get '/gallery/:year/:month/:day', (req, res, next) ->
        start = moment {y: parseInt(req.params.year), M: parseInt(req.params.month) - 1, d: parseInt(req.params.day)}
        end = start.clone().add(1, 'days')
        getTimespanImages db, res, start, end
