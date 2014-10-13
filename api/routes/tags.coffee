options = require '../tools/optionsroute'
middleware = require '../tools/middleware'
privilegeLevels = require '../tools/privilegelevels'

module.exports = (app, db) ->
    app.options '/tags', options ['GET', 'POST']
    app.options '/tags/:id', options ['GET', 'PATCH', 'DELETE']

    app.get '/tags', (req, res, next) ->
        db.all 'SELECT * FROM tTag', (err, rows) ->
            if err?
                res.status 500
                .json { status: 500, error: 'Database error' }
            else
                res.status 200
                .json rows

    app.post '/tags'
    , middleware.requireMinPrivilegeLevel(privilegeLevels.editor)
    , (req, res, next) ->
        {
            name,
            parent,
            icon,
            priority
        } = req.body

        if !name?
            res.status 400
            .json { status: 400, error: 'name field missing' }
            return

        db.run 'INSERT INTO tTag (name, parent, icon, priority) VALUES (?, ?, ?, ?)',
            name, parent, icon, priority, (err) ->
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

    app.patch '/tags/:id', (req, res, next) ->
        res.status 501
        .json { status: 501, error: 'not yet implemented' }
