fs = require 'fs'
path = require 'path'
glob = require 'glob'
async = require 'async'
sqlite = require 'sqlite3'
_ = require 'lodash'
checksum = require 'checksum'
moment = require 'moment'
gm = require 'gm'

settings = require('../settings').get()

filenames = []
relations = {}
lastRun = 0

getFileHashes = (paths, cb) ->
    tmpRelations = {}
    errors = []

    hashQueue = async.queue (file, done) ->
        checksum.file path.join(settings.localMediaLocation, file), (err, sum) ->
            return done err if err?

            console.log "Hash for '#{file}' is #{sum}"
            tmpRelations[sum] = file
            done()
    , settings.scannerConcurrency

    hashQueue.drain = ->
        if errors.length > 0
            cb errors
        else
            cb null, tmpRelations

    hashQueue.push paths, (err) ->
        errors.push err if err?

hashIndexRows = (rows) ->
    hashes = {}
    _.each rows, (data) ->
        hashes[data.hash] = data.locator

    return hashes

generateThumb = (fname, hash, cb) ->
    # Create the cache folder if it doesn't exist yet
    if fs.existsSync path.join('release', settings.deployDir, 'cache', "th_#{hash}.jpg")
        console.log "Thumbnail for #{fname} already exists, skipping..."
        return cb()

    fs.mkdir path.join('release', settings.deployDir, 'cache'), (err) ->
        if err?
            return cb err if err.code != 'EEXIST'

        if path.extname(fname) == '.jpg'
            console.log "Generating a thumbnail for #{fname}"
            gm(path.join settings.localMediaLocation, fname)
            .resize 200
            .quality 90
            .write path.join('release', settings.deployDir, 'cache', "th_#{hash}.jpg"), (err) ->
                cb err
        else
            cb()

updateDatabase = (current, cb) ->
    lastRun = moment().valueOf()

    db = new sqlite.Database settings.database
    db.all "SELECT hash, locator FROM tFile", (err, rows) ->
        return success false if err?

        previous = hashIndexRows rows

        # Find hashes new to the db
        addHashes = _.difference _.keys(current), _.keys(previous)

        # Find hashes that were in the db but aren't in the current set
        del = _.difference _.keys(previous) , _.keys(current)

        # Make a hash-based object of files that were moved
        mov = {}
        _.each _.intersection(_.keys(previous) , _.keys(current)), (key) ->
            if current[key] != previous[key]
                mov[key] = current[key]

        # Make a hash-based object of new file locations
        add = {}
        _.each addHashes, (key) ->
            add[key] = current[key]

        errors = []

        thumbQueue = async.queue (hash, done) ->
            generateThumb add[hash], hash, (err) ->
                done err
        , settings.scannerConcurrency

        thumbQueue.drain = ->
            return cb errors if errors.length > 0

            relations = current

            console.log "Now syncing database... (adding #{_.keys(add).length}, removing #{del.length}, updating #{_.keys(mov).length})"
            if _.keys(add).length + del.length + _.keys(mov).length > 100
                console.log "Seems like there are quite a bit of changes, so this may take some time."

            db.parallelize ->
                stmtAdd = db.prepare "INSERT INTO tFile (hash, locator, name, size, timestamp) VALUES (?, ?, ?, ?, ?)"
                _.each add, (fname, hash) ->
                    stats = fs.statSync path.join settings.localMediaLocation, fname
                    stmtAdd.run hash, fname, fname, stats.size, Math.min(stats.ctime.getTime(), stats.mtime.getTime())
                stmtAdd.finalize()

                stmtDel = db.prepare "DELETE FROM tFile WHERE hash = ?"
                _.each del, (hash) ->
                    stmtDel.run hash
                stmtDel.finalize()

                stmtMov = db.prepare "UPDATE tFile SET locator = ? WHERE hash = ?"
                _.each mov, (fname, hash) ->
                    stmtMov.run fname, hash
                stmtMov.finalize()

            db.close cb

        thumbQueue.push _.keys(add), (err) ->
            errors.push err if err?

module.exports = (grunt) ->
    grunt.registerTask 'fullScan', 'Scan and hash the media folder for new and updated files.', ->
        console.log 'Running a folder-wide scan for file changes...'
        success = @async()

        glob '*.+(jpg|mp4)', {
            cwd: settings.localMediaLocation
        }, (err, res) ->
            return success false if err?

            getFileHashes res, (err, hashes) ->
                return success false if err?

                filenames = _.values hashes

                updateDatabase hashes, (err) ->
                    success !err?


    grunt.registerTask 'listChangedScan', 'Scan added, deleted and moved files and update the database.', ->
        success = @async()

        glob '*.+(jpg|mp4)', {
            cwd: settings.localMediaLocation
        },  (err, res) ->
            return success false if err?
            newFiles = _.difference res, filenames
            missingFiles = _.difference filenames, res

            # Get a partial current list, taking old hash-file relations and removing missing files
            # (here's an assumption none of the files on both lists changed, which should be true if the watch task
            # didn't miss any events to run through filesModifiedScan)
            current = _.omit relations, (fname) ->
                _.contains missingFiles, fname

            getFileHashes newFiles, (err, hashes) ->
                return success false if err?

                # Add the new files' hash-file relations in, completing the current relation sheet
                current = _.merge current, hashes

                # Update the filename cache
                filenames = _.values current

                updateDatabase current, (err) ->
                    success !err?

    grunt.registerTask 'filesModifiedScan', 'Rehash modified files and update the database.', ->
        success = @async()

        glob '*.+(jpg|mp4)', {
            cwd: settings.localMediaLocation
        },  (err, res) ->
            return success false if err?

            changed = []
            async.each res, (file, done) ->
                fs.stat path.join(settings.localMediaLocation, file), (err, stats) ->
                    return done err if err?

                    if Math.max(stats.ctime.getTime(), stats.mtime.getTime()) > lastRun
                        changed.push file
                    done()
            , (err) ->
                return success false if err?

                console.log changed

                # Remove pairs corresponding to changed files temporarily from the hash-relations cache
                current = _.omit relations, (fname) ->
                    _.contains changed, fname

                getFileHashes changed, (err, hashes) ->
                    return success false if err?

                    # Add the new files' hash-file relations in, completing the current relation sheet
                    current = _.merge current, hashes

                    # Update the filename cache
                    filenames = _.values current

                    updateDatabase current, (err) ->
                        success !err?
