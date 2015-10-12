options = require '../tools/optionsroute'
middleware = require '../tools/middleware'
privilegeLevels = require '../tools/privilegelevels'
parseTagTree = require '../tools/tagtree'
commonResponses = require '../tools/commonresponses'

httpStatus = require 'http-status-codes'
_ = require 'lodash'

recursiveTagQuery = '''
WITH cte (id, name, parent, icon, priority, depth) AS (
  SELECT t.id, t.name, t.parent, t.icon, t.priority, 0 FROM tTag t, tFileTagRel r WHERE r.file = ? AND t.id = r.tag
    UNION ALL
  SELECT t.id, t.name, t.parent, t.icon, t.priority, r.depth + 1 FROM tTag t, cte r WHERE t.id = r.parent
)
SELECT DISTINCT cte.* FROM cte
INNER JOIN (
  SELECT id, MIN(depth) AS topmost
  FROM cte
  GROUP BY id
) tmp
ON cte.id = tmp.id
AND cte.depth = tmp.topmost;
'''

module.exports = (app, db) ->
    updateTagRelations = (req, res, row) ->
        db.all 'SELECT tag FROM tFileTagRel WHERE file = ?', row.id, (err, taglist) ->
            return commonResponses.databaseError res if err?

            tagsFromDB = _.pluck taglist, 'tag'

            addTags = _.difference req.body.tagIDs, tagsFromDB
            delTags = _.difference tagsFromDB, req.body.tagIDs

            db.serialize ->
                stmtAdd = db.prepare 'INSERT INTO tFileTagRel (file, tag) VALUES (?, ?)'
                _.each addTags, (tagID) ->
                    stmtAdd.run row.id, tagID

                stmtDel = db.prepare 'DELETE FROM tFileTagRel WHERE file = ? AND tag = ?'
                _.each delTags, (tagID) ->
                    stmtDel.run row.id, tagID

                stmtAdd.finalize()
                stmtDel.finalize()

                db.all recursiveTagQuery, row.id, (err, rows) ->
                    return commonResponses.databaseError res if err?

                    row.tags = parseTagTree rows
                    res.status httpStatus.OK
                    .json row

    app.options '/media/:id', options ['GET', 'PATCH']

    app.get '/media/:id', (req, res, next) ->
        db.get 'SELECT * FROM tFile WHERE hash = ?', req.params.id, (err, row) ->
            return commonResponses.databaseError res if err?

            if row?
                db.all recursiveTagQuery, row.id, (err, rows) ->
                    return commonResponses.databaseError res if err?

                    row.tags = parseTagTree rows
                    res.status httpStatus.OK
                    .json row
            else
                return commonResponses.badID res

    app.patch '/media/:id'
    , middleware.requireMinPrivilegeLevel(privilegeLevels.editor)
    , (req, res, next) ->
        db.get 'SELECT * FROM tFile WHERE hash = ?', req.params.id, (err, row) ->
            return commonResponses.databaseError res if err?

            if row?
                row = _.merge row, _.pick req.body, ['name', 'description']

                db.run 'UPDATE tFile SET name = ?, description = ? WHERE hash = ?', row.name, row.description, req.params.id, (err) ->
                    return commonResponses.databaseError res if err?

                    # Update the tag bindings if the tag array was present
                    if req.body.tagIDs?
                        updateTagRelations req, res, row
                    else
                        db.all recursiveTagQuery, row.id, (err, rows) ->
                            return commonResponses.databaseError res if err?

                            row.tags = parseTagTree rows
                            res.status httpStatus.OK
                            .json row
            else
                return commonResponses.badID res
