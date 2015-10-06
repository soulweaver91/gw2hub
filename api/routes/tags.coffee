options = require '../tools/optionsroute'
middleware = require '../tools/middleware'
privilegeLevels = require '../tools/privilegelevels'
parseTagTree = require '../tools/tagtree'

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
            if err?
                res.status 500
                .json { status: 500, error: 'Database error' }
            else
                res.status 200
                .json parseTagTree rows

    app.post '/tags'
    , middleware.requireMinPrivilegeLevel(privilegeLevels.editor)
    , (req, res, next) ->
        if !req.body.name?
            res.status 400
            .json { status: 400, error: 'name field missing' }
            return

        db.run 'INSERT INTO tTag (name, parent, icon, priority) VALUES (?, ?, ?, ?)',
            req.body.name, req.body.parent, req.body.icon, req.body.priority, (err) ->
                if err?
                    if err.code == 'SQLITE_CONSTRAINT'
                        res.status 400
                        .json { status: 400, error: 'invalid parent tag' }
                    else
                        res.status 500
                        .json { status: 500, error: 'database error' }
                else
                    db.get 'SELECT * FROM tTag WHERE id = ?', @lastID, (err, row) ->
                        if err?
                            res.status 500
                            .json { status: 500, error: 'database error' }
                        else
                            res.status 200
                            .json row

    app.get '/tags/:id', (req, res, next) ->
        db.get 'SELECT * FROM tTag WHERE id = ?', req.params.id, (err, row) ->
            if err?
                res.status 500
                .json { status: 500, error: 'database error' }
            else
                if row?
                    res.status 200
                    .json row
                else
                    res.status 404
                    .json { status: 404, error: 'no such id' }

    app.delete '/tags/:id'
    , middleware.requireMinPrivilegeLevel(privilegeLevels.editor)
    , (req, res, next) ->
        db.get 'SELECT * FROM tTag WHERE id = ?', req.params.id, (err, row) ->
            if err?
                res.status 500
                .json { status: 500, error: 'database error' }
            else
                if row?
                    db.run 'DELETE FROM tTag WHERE id = ?', req.params.id, (err) ->
                        if err?
                            res.status 500
                            .json { status: 500, error: 'database error' }
                        else
                            res.status 200
                            .json row
                else
                    res.status 404
                    .json { status: 404, error: 'no such id' }

    app.patch '/tags/:id'
    , middleware.requireMinPrivilegeLevel(privilegeLevels.editor)
    , (req, res, next) ->
        db.get 'SELECT * FROM tTag WHERE id = ?', req.params.id, (err, row) ->
            if err?
                res.status 500
                .json { status: 500, error: 'database error' }
            else
                if row?
                    row = _.merge row, _.pick req.body, ['name', 'parent', 'icon', 'priority']

                    db.run 'UPDATE tTag SET name = ?, parent = ?, icon = ?, priority = ? WHERE id = ?',
                        row.name, row.parent, row.icon, row.priority, req.params.id, (err) ->
                            if err?
                                if err.code == 'SQLITE_CONSTRAINT'
                                    res.status 400
                                    .json { status: 400, error: 'invalid parent tag' }
                                else
                                    res.status 500
                                    .json { status: 500, error: 'database error' }
                            else
                                res.status 200
                                .json row
                else
                    res.status 404
                    .json { status: 404, error: 'no such id' }

    app.post '/tags/suggest', (req, res, next) ->
        if !req.body.q?
            res.status 400
            .json { status: 400, error: 'query is required' }
        else

            db.all '''
                SELECT id, name, icon
                FROM tTag
                WHERE name LIKE ?
                ORDER BY name ASC
                LIMIT 10
            ''', req.body.q + '%', (err, rows) ->
                if err?
                    res.status 500
                    .json { status: 500, error: 'database error' }
                else
                    res.status 200
                    .json rows
