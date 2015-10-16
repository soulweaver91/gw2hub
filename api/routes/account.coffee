options = require '../tools/optionsroute'
gw2api = require '../tools/gw2api'
commonResponses = require '../tools/commonresponses'
httpStatus = require 'http-status-codes'
_ = require 'lodash'

module.exports = (app, db) ->
    app.options '/account/data', options ['GET']
    app.options '/account/bank', options ['GET']
    app.options '/account/unlocks/dyes', options ['GET']

    app.get '/account/data', (req, res, next) ->
        gw2api.getAccount (err, account) ->
            return gw2api.fatalAPIErrorDefaultResponse err, res if err?

            res.status httpStatus.OK
            .json account

    app.get '/account/bank', (req, res, next) ->
        gw2api.getBank (err, bank) ->
            return gw2api.fatalAPIErrorDefaultResponse err, res if err?

            if bank?.bank?.data?
                _.each bank.bank.data, (item) ->
                    # Infusions and other upgrades are all the same to us.
                    if item?.infusions?
                        item.upgrades = [] if !item.upgrades?
                        item.upgrades = item.upgrades.concat item.infusions
                        delete item.infusions

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

    app.get '/account/unlocks/dyes', (req, res, next) ->
        db.all 'SELECT * FROM tDyeCache', (err, dbDyes) ->
            commonResponses.databaseError res if err?

            existingIDs = _.pluck dbDyes, 'id'

            gw2api.getDyes existingIDs, (err, dyes) ->
                return gw2api.fatalAPIErrorDefaultResponse err, res if err?

                stmtAdd = db.prepare '''INSERT INTO tDyeCache (id, name, red, green, blue, unlockItem, categories) VALUES (?, ?, ?, ?, ?, ?, ?)'''
                _.each dyes.noncached, (dye) ->
                    stmtAdd.run dye.id, dye.name, dye.leather.rgb[0], dye.leather.rgb[1], dye.leather.rgb[2], dye.item, dye.categories.join(',')
                    , (err) ->
                        if err?
                            # It is possible the dye database was called again after a first run was still storing new values.
                            # Unique key violations don't matter here really if the record was ultimately stored.
                            console.log err
                            console.trace()

                stmtAdd.finalize()

                allDyeData = dbDyes.concat dyes.noncached

                combinedDyes = {}
                combinedDyes.cachedResponse = dyes.cachedResponse
                combinedDyes.data = _.map allDyeData, (dye) ->
                    {
                        id: dye.id
                        name: dye.name
                        red: if dye.red? then dye.red else dye.leather?.rgb[0]
                        green: if dye.green? then dye.green else dye.leather?.rgb[1]
                        blue: if dye.blue? then dye.blue else dye.leather?.rgb[2]
                        unlocked: dyes.unlocked.indexOf(dye.id) >= 0
                        unlockItem: dye.unlockItem || dye.item
                        categories: if _.isString(dye.categories) then dye.categories.split(',') else dye.categories
                    }

                # ID 1 is Dye Remover. It isn't a real dye, so it has incomplete data and is marked as not unlocked.
                # We don't want it included.
                _.remove combinedDyes.data, (item) ->
                    item.id == 1

                res.status httpStatus.OK
                .json combinedDyes
