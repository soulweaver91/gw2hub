options = require '../tools/optionsroute'
middleware = require '../tools/middleware'
privilegeLevels = require '../tools/privilegelevels'
parseTagTree = require '../tools/tagtree'
commonResponses = require '../tools/commonresponses'

httpStatus = require 'http-status-codes'
_ = require 'lodash'

module.exports = (app, db) ->
    app.options '/tags', options ['GET', 'POST']
    app.options '/tags/:id', options ['GET', 'PATCH', 'DELETE']
    app.options '/tags/suggest', options ['POST']

    app.get '/tags', (req, res, next) ->
        db.all '''
            SELECT *, (
                SELECT COUNT(*) FROM tFileTagRel WHERE tag = tTag.id
            ) AS selfCount
            FROM tTag
        ''', (err, rows) ->
            return commonResponses.databaseError res if err?

            res.status httpStatus.OK
            .json parseTagTree rows

    app.post '/tags'
    , middleware.requireMinPrivilegeLevel(privilegeLevels.editor)
    , (req, res, next) ->
        if !req.body.name?
            res.status httpStatus.BAD_REQUEST
            .json { status: httpStatus.BAD_REQUEST, error: 'name field missing' }
            return

        db.run 'INSERT INTO tTag (name, parent, icon, priority) VALUES (?, ?, ?, ?)',
            req.body.name, req.body.parent, req.body.icon, req.body.priority, (err) ->
                if err?
                    if err.code == 'SQLITE_CONSTRAINT'
                        res.status httpStatus.BAD_REQUEST
                        .json { status: httpStatus.BAD_REQUEST, error: 'invalid parent tag' }
                    else
                        return commonResponses.databaseError res
                else
                    db.get 'SELECT * FROM tTag WHERE id = ?', @lastID, (err, row) ->
                        return commonResponses.databaseError res if err?

                        res.status httpStatus.OK
                        .json row

    app.get '/tags/:id', (req, res, next) ->
        db.get 'SELECT * FROM tTag WHERE id = ?', req.params.id, (err, row) ->
            return commonResponses.databaseError res if err?

            if row?
                res.status httpStatus.OK
                .json row
            else
                return commonResponses.badID res

    app.delete '/tags/:id'
    , middleware.requireMinPrivilegeLevel(privilegeLevels.editor)
    , (req, res, next) ->
        db.get 'SELECT * FROM tTag WHERE id = ?', req.params.id, (err, row) ->
            return commonResponses.databaseError res if err?

            if row?
                db.run 'DELETE FROM tTag WHERE id = ?', req.params.id, (err) ->
                    return commonResponses.databaseError res if err?

                    res.status httpStatus.OK
                    .json row
            else
                return commonResponses.badID res

    app.patch '/tags/:id'
    , middleware.requireMinPrivilegeLevel(privilegeLevels.editor)
    , (req, res, next) ->
        db.get 'SELECT * FROM tTag WHERE id = ?', req.params.id, (err, row) ->
            return commonResponses.databaseError res if err?

            if row?
                row = _.merge row, _.pick req.body, ['name', 'parent', 'icon', 'priority']

                db.run 'UPDATE tTag SET name = ?, parent = ?, icon = ?, priority = ? WHERE id = ?',
                    row.name, row.parent, row.icon, row.priority, req.params.id, (err) ->
                        if err?
                            if err.code == 'SQLITE_CONSTRAINT'
                                res.status httpStatus.BAD_REQUEST
                                .json { status: httpStatus.BAD_REQUEST, error: 'invalid parent tag' }
                            else
                                return commonResponses.databaseError res
                        else
                            res.status httpStatus.OK
                            .json row
            else
                return commonResponses.badID res

    app.post '/tags/suggest', (req, res, next) ->
        if !req.body.q?
            res.status httpStatus.BAD_REQUEST
            .json { status: httpStatus.BAD_REQUEST, error: 'query is required' }
        else

            db.all '''
                SELECT id, name, icon
                FROM tTag
                WHERE name LIKE ?
                ORDER BY name ASC
                LIMIT 10
            ''', req.body.q + '%', (err, rows) ->
                return commonResponses.databaseError res if err?

                res.status httpStatus.OK
                .json rows
