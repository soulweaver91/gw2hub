options = require '../tools/optionsroute'
gw2api = require '../tools/gw2api'
httpStatus = require 'http-status-codes'
_ = require 'lodash'

module.exports = (app, db) ->
    app.options '/account/data', options ['GET']
    app.options '/account/bank', options ['GET']

    app.get '/account/data', (req, res, next) ->
        gw2api.getAccount (err, account) ->
            return gw2api.fatalAPIErrorDefaultResponse err, res if err?

            res.status httpStatus.OK
            .json account

    app.get '/account/bank', (req, res, next) ->
        gw2api.getBank (err, bank) ->
            return gw2api.fatalAPIErrorDefaultResponse err, res if err?

            if bank?.materials?.data?
                # Reshape materials to the provided categories.
                categorized = {}
                _.each bank.materials.data, (item) ->
                    if !categorized[item.category]?
                        categorized[item.category] = []

                    categorized[item.category].push item

                bank.materials.data = categorized

            res.status httpStatus.OK
            .json bank

