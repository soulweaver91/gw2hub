options = require '../tools/optionsroute'
gw2api = require '../tools/gw2api'
httpStatus = require 'http-status-codes'
_ = require 'lodash'
# Not in 2.x, which is required by dependencies for now
_mapKeys = require 'lodash.mapkeys'

parseDescriptionTags = (item) ->
    # Pre-parse the color markup tags in descriptions. (Simple regex replace, assumes markup is valid and not nested.)

    tagExpr = /<c=@([a-zA-Z]+)>(.+?)<\/c>/g
    tagRepl = '<span class="description-$1">$2</span>'
    brExpr = /\r?\n/g
    brRepl = '<br>'

    replacer = (str) ->
        str.replace(tagExpr, tagRepl).replace(brExpr, brRepl)

    if item.description?
        item.description = replacer item.description

    if item.detailsObject?.description?
        item.detailsObject.description = replacer item.detailsObject.description

    if item.detailsObject?.infix_upgrade?.buff?.description?
        item.detailsObject.infix_upgrade.buff.description = replacer item.detailsObject.infix_upgrade.buff.description

    if item.detailsObject?.bonuses?
        item.detailsObject.bonuses = _.map item.detailsObject.bonuses, replacer

    item

sendFinalizedItemList = (res, ids, fromDB, fromAPI) ->
    # Unescape escaped data from own database.
    fromDB = _.map fromDB, (item) ->
        item.flags = _.compact item.flags.split ',' if _.isString item.flags
        item.restrictedTo = _.compact item.restrictedTo.split ',' if _.isString item.restrictedTo
        try
            item.detailsObject = JSON.parse item.detailsObject if _.isString item.detailsObject
        catch e
            item.detailsObject = {}

        return item

    # Rename direct-from-API field names and remove the probably few fields we don't need.
    # (right now: game modes)
    fromAPI = _.map fromAPI, (item) ->
        _mapKeys item, (val, key) ->
            switch key
                 when 'restrictions' then 'restrictedTo'
                 when 'chat_link' then 'chatLink'
                 when 'details' then 'detailsObject'
                 when 'vendor_value' then 'vendorValue'
                 else key

    items = fromDB.concat fromAPI
    _.each items, (item, idx) ->
        items[idx].missing = false
        items[idx] = _.pick item, ['id', 'missing', 'name', 'description', 'icon', 'type', 'rarity', 'description',
                                   'level', 'vendorValue', 'flags', 'restrictedTo', 'chatLink', 'detailsObject']
        items[idx] = parseDescriptionTags items[idx]

    idsToStub = _.difference ids, _.pluck items, 'id'
    _.each idsToStub, (id) ->
        items.push {
            id: id
            missing: true
        }

    items = _mapKeys items, (val, idx) -> val.id

    return res.status httpStatus.OK
    .json items

storeItemsToDatabase = (err, db, buildID, items, toUpdate, toAdd, cb) ->
    if err?
        # Could not load items from the API. They'll be filled as unknowns in the next step, don't fail here.
        (cb)()
    else
        db.serialize ->
            stmtUpdate = db.prepare '''UPDATE tItemCache SET build = ?, fromapi = 1, name = ?, icon = ?,
                         description = ?, type = ?, rarity = ?, level = ?, vendorValue = ?, flags = ?,
                         restrictedTo = ?, chatLink = ?, detailsObject = ? WHERE id = ?'''
            _.each toUpdate, (id) ->
                data = _.find items, (item) -> item.id == id
                if data?
                    stmtUpdate.run buildID, data.name, data.icon, data.description, data.type, data.rarity, data.level,
                        data.vendor_value, data.flags?.join(','), data.restrictions?.join(','), data.chat_link,
                        JSON.stringify(data.details || {}), id
                    , (err) ->
                        if err?
                            console.log err
                            console.stack()

            stmtAdd = db.prepare '''INSERT INTO tItemCache (id, build, fromapi, name, icon, description, type, rarity,
                      level, vendorValue, flags, restrictedTo, chatLink, detailsObject)
                      VALUES (?, ?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'''
            _.each toAdd, (id) ->
                data = _.find items, (item) -> item.id == id
                if data?
                    stmtAdd.run id, buildID, data.name, data.icon, data.description, data.type, data.rarity, data.level,
                        data.vendor_value, data.flags?.join(','), data.restrictions?.join(','), data.chat_link,
                        JSON.stringify(data.details || {})
                    , (err) ->
                        if err?
                            console.log err
                            console.stack()

            stmtUpdate.finalize()
            stmtAdd.finalize()

            (cb)()

module.exports = (app, db) ->
    app.options '/items/:idList', options ['GET']

    app.get '/items/:idList', (req, res, next) ->

        gw2api.getBuild (err, build) ->
            gw2api.fatalAPIErrorDefaultResponse err if err?

            if !/^\d+(,\d+)*$/.test req.params.idList
                return res.status httpStatus.BAD_REQUEST
                .json { status: httpStatus.BAD_REQUEST, error: 'invalid id list, only comma separated integers supported' }

            ids = _.uniq _.map req.params.idList.split(','), (id) -> parseInt id

            # With the above strict validity check, this _should_ be safe; the sqlite module doesn't provide a way to
            # do a prepared statement at the moment and getting a large number of IDs would be way too taxing.
            db.all "SELECT * FROM tItemCache WHERE id IN (#{ids.join ', '})", (err, items) ->

                # Reject the items whose data might have been changed.
                existingButStale = _.remove items, (item) -> item.build < build.id
                existingButStale = _.pluck existingButStale, 'id'

                # Remove the OK items from the to-fetch list.
                idsToGet = _.difference ids, _.pluck items, 'id'

                # Get the other half of the get ids to find out exactly which ones to add and which to update.
                missing = _.without idsToGet, existingButStale

                if idsToGet.length > 0
                    gw2api.getItems idsToGet, (err, apiItems) ->
                        apiItems = { data: [] } if !apiItems?
                        storeItemsToDatabase err, db, build.id, apiItems.data, existingButStale, missing, ->
                            sendFinalizedItemList res, ids, items, apiItems.data
                else
                    sendFinalizedItemList res, ids, items, []
