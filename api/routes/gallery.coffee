options = require '../tools/optionsroute'
commonResponses = require '../tools/commonresponses'

httpStatus = require 'http-status-codes'
moment = require 'moment'
_ = require 'lodash'

getTimespanImages = (db, res, start, end) ->
    db.all 'SELECT * FROM tFile WHERE timestamp >= ? AND timestamp < ? ORDER BY timestamp ASC',
        start.valueOf(), end.valueOf(), (err, rows) ->
            return commonResponses.databaseError res if err?

            res.status httpStatus.OK
            .json rows

statsCache =
    updated: 0,
    cache: {}

module.exports = (app, db) ->
    app.options '/gallery/stats', options ['GET']
    app.options '/gallery/:year', options ['GET']
    app.options '/gallery/:year/:month', options ['GET']
    app.options '/gallery/:year/:month/:day', options ['GET']

    app.get '/gallery/stats', (req, res, next) ->
        if moment().subtract(1, 'minutes').valueOf() > statsCache.updated
            stats = {
                count: 0
                years: {}
            }
            db.all 'SELECT timestamp FROM tFile', (err, rows) ->
                _.each _.pluck(rows, 'timestamp'), (item) ->
                    time = moment item
                    tYear = time.year()
                    tMonth = time.month()

                    if !stats.years[tYear]?
                        stats.years[tYear] =
                            count: 0
                            months: {}

                    if !stats.years[tYear].months[tMonth]?
                        stats.years[tYear].months[tMonth] =
                            count: 0

                    stats.count++
                    stats.years[tYear].count++
                    stats.years[tYear].months[tMonth].count++

                statsCache =
                    updated: moment().valueOf()
                    cache: stats

                res.status httpStatus.OK
                .json statsCache.cache
        else
            res.status httpStatus.OK
            .json statsCache.cache


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
