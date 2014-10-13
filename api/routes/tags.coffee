options = require '../tools/optionsroute'
middleware = require '../tools/middleware'
privilegeLevels = require '../tools/privilegelevels'

module.exports = (app, db) ->
    app.options '/tags', options ['GET', 'POST']

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
