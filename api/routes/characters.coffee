options = require '../tools/optionsroute'
gw2api = require '../tools/gw2api'
commonResponses = require '../tools/commonresponses'

httpStatus = require 'http-status-codes'
_ = require 'lodash'

module.exports = (app, db) ->
    app.options '/characters', options ['GET']
    app.options '/characters/:id/full', options ['GET']
    app.options '/characters/:id/brief', options ['GET']

    app.get '/characters', (req, res, next) ->
        gw2api.getCharacters (err, characters) ->
            return gw2api.fatalAPIErrorDefaultResponse err, res if err?

            attachIdsAndRespond = ->
                # Cache should be up to speed at this point.
                db.all 'SELECT * FROM tCharacterCache', (err, cachedChars) ->
                    return commonResponses.databaseError res if err?

                    resultChars = { cachedResponse: characters.cachedResponse, data: [] }

                    _.each characters.data, (char) ->
                        c = _.findWhere cachedChars, { name: char.name }
                        if c?
                            char.id = c.id
                            char.deleted = 0

                        resultChars.data.push _.pick char, ['id', 'name', 'created', 'gender', 'profession', 'race',
                                                            'level', 'deaths', 'age', 'created', 'crafting', 'deleted']

                    resultChars.data = resultChars.data.concat _.filter cachedChars, (char) -> char.deleted

                    # Convert to booleans
                    _.each resultChars.data, (char, idx) ->
                        resultChars.data[idx].deleted = char.deleted == 1

                        # Prevent breaking from the loop
                        return true

                    res.status httpStatus.OK
                    .json resultChars

            if !characters.cachedResponse
                # Update the character cache first.
                charFields = ['name', 'created', 'gender', 'profession', 'race']

                db.all 'SELECT * FROM tCharacterCache', (err, cachedChars) ->
                    return commonResponses.databaseError res if err?

                    charsToUpdate = []
                    charsToAdd = []
                    charsToRemove = _.pluck cachedChars, 'id'
                    _.each characters.data, (char) ->
                        data = _.pick char, charFields
                        data.deleted = false

                        # We are going by character name, as the API doesn't currently provide immutable IDs.
                        # This will not be compatible with name changing contracts!
                        # https://github.com/arenanet/api-cdi/issues/32
                        cachedChar = _.findWhere cachedChars, { name: char.name }
                        if cachedChar? && !_.isEqual char, _.pick cachedChar, charFields
                            _.pull charsToRemove, cachedChar.id
                            charsToUpdate.push _.merge char, { id: cachedChar.id }
                        else
                            charsToAdd.push data


                    db.serialize ->
                        stmtAdd = db.prepare 'INSERT INTO tCharacterCache (name, created, gender, profession, race, deleted) VALUES (?, ?, ?, ?, ?, 0)'
                        _.each charsToAdd, (char) ->
                            stmtAdd.run char.name, char.created, char.gender, char.profession, char.race

                        stmtUpdate = db.prepare 'UPDATE tCharacterCache SET created = ?, gender = ?, profession = ?, race = ?, deleted = 0 WHERE id = ?'
                        _.each charsToUpdate, (char) ->
                            stmtUpdate.run char.created, char.gender, char.profession, char.race, char.id

                        stmtDel = db.prepare 'UPDATE tCharacterCache SET deleted = 1 WHERE id = ?'
                        _.each charsToRemove, (id) ->
                            stmtDel.run id

                        stmtAdd.finalize()
                        stmtUpdate.finalize()
                        stmtDel.finalize()

                        # Cannot get the IDs back easily, so query them again.
                        attachIdsAndRespond()
            else
                attachIdsAndRespond()

    app.get '/characters/:id/brief', (req, res, next) ->
        db.get 'SELECT * FROM tCharacterCache WHERE id = ?', req.params.id, (err, row) ->
            return commonResponses.databaseError res if err?

            if row?
                res.status httpStatus.OK
                .json row
            else
                return commonResponses.badID res

    app.get '/characters/:id/full', (req, res, next) ->
        db.get 'SELECT * FROM tCharacterCache WHERE id = ?', req.params.id, (err, row) ->
            return commonResponses.databaseError res if err?

            if row?
                if row.deleted
                    res.status httpStatus.OK
                    .json row
                else
                    gw2api.getCharacter row.name, (err, char) ->
                        return gw2api.fatalAPIErrorDefaultResponse err, res if err?

                        char.id = req.params.id

                        _.each char.equipment, (item) ->
                            # Infusions and other upgrades are all the same to us.
                            if item?.infusions?
                                item.upgrades = [] if !item.upgrades?
                                item.upgrades = item.upgrades.concat item.infusions
                                delete item.infusions

                        # Transform equipment to a more sensible arrangement, by slot rather than a random array
                        equipment = {
                            helm:      _.findWhere char.equipment, { slot: 'Helm' }        || null
                            shoulders: _.findWhere char.equipment, { slot: 'Shoulders' }   || null
                            coat:      _.findWhere char.equipment, { slot: 'Coat' }        || null
                            gloves:    _.findWhere char.equipment, { slot: 'Gloves' }      || null
                            leggings:  _.findWhere char.equipment, { slot: 'Leggings' }    || null
                            boots:     _.findWhere char.equipment, { slot: 'Boots' }       || null
                            breather:  _.findWhere char.equipment, { slot: 'HelmAquatic' } || null
                            backpack:  _.findWhere char.equipment, { slot: 'Backpack' }    || null
                            accessories: [
                                _.findWhere char.equipment, { slot: 'Accessory1' } || null
                                _.findWhere char.equipment, { slot: 'Accessory2' } || null
                            ]
                            rings: [
                                _.findWhere char.equipment, { slot: 'Ring1' } || null
                                _.findWhere char.equipment, { slot: 'Ring2' } || null
                            ]
                            amulet:    _.findWhere char.equipment, { slot: 'Amulet' }      || null
                            weapons:
                                main: [
                                    _.findWhere char.equipment, { slot: 'WeaponA1' } || null
                                    _.findWhere char.equipment, { slot: 'WeaponA2' } || null
                                ]
                                secondary: [
                                    _.findWhere char.equipment, { slot: 'WeaponB1' } || null
                                    _.findWhere char.equipment, { slot: 'WeaponB2' } || null
                                ]
                                aquatic: [
                                    _.findWhere char.equipment, { slot: 'WeaponAquaticA' } || null
                                    _.findWhere char.equipment, { slot: 'WeaponAquaticB' } || null
                                ]
                            gathering:
                                axe:    _.findWhere char.equipment, { slot: 'Axe' }    || null
                                pick:   _.findWhere char.equipment, { slot: 'Pick' }   || null
                                sickle: _.findWhere char.equipment, { slot: 'Sickle' } || null
                        }

                        char.equipment = equipment

                        res.status httpStatus.OK
                        .json char

            else
                return commonResponses.badID res

