fs = require 'fs'
async = require 'async'
sqlite = require 'sqlite3'
_ = require 'lodash'

settings = require('../settings').get()

normalizeTagName = (name, fullPath) ->
    name = name.replace(/_/g, ' ')
               .replace(/([^a-z'\-\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u00FF]|^)([a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u00FF])/g,
                    (match, p1, p2) ->
                        p1 + String.fromCharCode p2.charCodeAt(0) - 0x20
               )

    if 'player' not in fullPath.split '/'
        _.each ['A', 'An', 'The', 'As', 'Of', 'In', 'On', 'For', 'By', 'And', 'But', 'At', 'To', 'Up', 'Or', 'Nor', 'With'], (word) ->
            re = new RegExp "(?!^)\\b#{word}\\b", 'g'
            name = name.replace re, word.toLowerCase()

    name

module.exports = (grunt) ->
    grunt.registerTask 'importTags', 'Load an old format tag file and import both tags and tag relations from it', (filename) ->
        success = @async()

        if !filename?
            return grunt.fail.fatal 'No filename was provided!'

        fs.readFile filename, {
            encoding: 'utf-8'
        },  (err, data) ->
            if err?
                return grunt.fail.fatal 'Reading the file failed!'

            tagList = {}
            relList = {}
            index = 0

            # Store the tags in addition order to enforce that parents are always added before children
            orderedTagArray = []

            checkTagTreeBranch = (file, tag) ->
                tagHierarchy = tag.split '/'
                tagFragment = ''
                while tagHierarchy.length > 0
                    oldFragment = tagFragment
                    section = tagHierarchy.shift()
                    if oldFragment == ''
                        tagFragment = section
                    else
                        tagFragment += '/' + section

                    if !tagList[tagFragment]?
                        newIndex = index++
                        tagList[tagFragment] =
                            index: newIndex
                            name: normalizeTagName section, tagFragment
                            parent: if oldFragment == '' then null else tagList[oldFragment].index
                            parentFragment: oldFragment
                        relList[tagFragment] = []
                        orderedTagArray.push tagFragment

                relList[tag].push file

            data = data.replace(/\r\n/g, '\n').split '\n'
            _.each data, (line) ->
                if line.length > 0 && line[0] != '#' && line.indexOf ':' != -1
                    line = line.split ':', 2

                    filename = line[0]
                    tags = line[1].split ' '

                    _.each tags, (tag) ->
                        checkTagTreeBranch filename, tag

            rels = _.reduce relList, (total, tag) ->
                total += tag.length
            , 0

            console.log "Tag file parsed. Found #{Object.keys(tagList).length} tags and #{rels} relations."

            console.log _.pluck tagList, 'name'
            return

            db = new sqlite.Database settings.database

            async.eachSeries orderedTagArray, (tagName, cb) ->
                # First, add tags. These need to go in series to ensure the parent tag has always been added by the
                # point its childrens are being added respectively.
                tag = tagList[tagName]
                realParentID = if tag.parentFragment == '' then null else tagList[tag.parentFragment].realID
                db.run 'INSERT INTO tTag (name, parent, icon, priority) VALUES (?, ?, ?, ?)',
                    tag.name, realParentID, null, null, (err) ->
                        if err?
                            success false
                            throw err
                        else
                            tagList[tagName].realID = @lastID
                            console.log "ID for #{tagName} is #{@lastID}"
                            cb()
            , (err) ->
                console.log 'Adding relations for the recently added tags.'
                db.all 'SELECT id, locator FROM tFile', (err, files) ->
                    fileIDs = _.transform files, (result, file) ->
                        result[file.locator] = file.id
                    , {}

                    if err?
                        success false
                        throw err
                    else
                        # Then, add tag relations. These can go to the database in any order.
                        async.forEachOf relList, (filenames, tagName, cb) ->
                            async.each filenames, (file, cb2) ->
                                if fileIDs[file]?
                                    db.run 'INSERT INTO tFileTagRel (file, tag) VALUES (?, ?)',
                                        fileIDs[file], tagList[tagName].realID, (err) ->
                                            console.log "Added a relation between #{file} and #{tagName}."
                                            cb2()
                            , cb
                        , (err) ->
                            success err
