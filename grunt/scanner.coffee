fs = require 'fs'
path = require 'path'
glob = require 'glob'
async = require 'async'
sqlite = require 'sqlite3'
_ = require 'lodash'
checksum = require 'checksum'
moment = require 'moment'
gm = require 'gm'
ffmpeg = require 'fluent-ffmpeg'

settings = require('../configmanager').get()

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

nameIndexRows = (rows) ->
    locators = {}
    _.each rows, (data) ->
        locators[data.locator] = data.hash

    return locators

generateThumb = (fname, hash, cb) ->
    # Create the cache folder if it doesn't exist yet
    if fs.existsSync path.join('release', settings.deployDir, 'cache', "th_#{hash}.jpg")
        console.log "Thumbnail for #{fname} already exists, skipping..."
        return cb()

    fs.mkdir path.join('release', settings.deployDir, 'cache'), (err) ->
        sourceFile = path.join settings.localMediaLocation, fname
        targetFile = path.join 'release', settings.deployDir, 'cache', "th_#{hash}.jpg"
        tempFile = path.join 'release', settings.deployDir, 'cache', "th_#{hash}.tmp.png"

        if err?
            return cb err if err.code != 'EEXIST'

        if path.extname(fname).slice(1) in settings.imageFormats
            console.log "Generating a thumbnail for #{fname} (image)"
            gm sourceFile
            .resize 200
            .quality 90
            .write targetFile, (err) ->
                cb err
        else
            console.log "Generating a thumbnail for #{fname} (video)"
            ffmpeg sourceFile
            .on 'end', ->
                gm tempFile
                .quality 90
                .write targetFile, (err) ->
                    return cb err if err?

                    fs.unlink tempFile, (err) ->
                        cb err
            .on 'error', (err) -> cb err
            .thumbnail {
                timemarks: ['50%']
                size: '200x?'
                folder: path.dirname tempFile
                filename: path.basename tempFile
            }

updateDatabase = (current, previous, db, lastRun, cb) ->
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
            setImmediate done, err
    , settings.scannerConcurrency

    thumbQueue.drain = ->
        return cb errors if errors.length > 0

        console.log "Now syncing database... (adding #{_.keys(add).length}, removing #{del.length}, updating #{_.keys(mov).length})"
        if _.keys(add).length + del.length + _.keys(mov).length > 100
            console.log "Seems like there are quite a bit of changes, so this may take some time."

        setLastCheckTime db, lastRun, ->
            # Don't really care if this one fails. It just means the next scan will go over a few more files.
            true

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

getLastCheckTime = (db, cb) ->
    db.get 'SELECT value FROM tStateVars WHERE key = "lastScanTime"', (err, row) ->
        cb err, parseInt(row.value)

setLastCheckTime = (db, lastRun, cb) ->
    db.run 'UPDATE tStateVars SET value = ? WHERE key = "lastScanTime"', lastRun, (err) ->
        cb err

module.exports = (grunt) ->
    grunt.registerTask 'syncFileDB', 'Scan the folder for changed files.', ->
        success = @async()

        db = new sqlite.Database settings.database
        getLastCheckTime db, (err, lastRun) ->
            return success false if err?

            console.log "Last scan run at #{moment(lastRun).format('ddd Do MMM YYYY LTS')}."

            thisRun = moment().valueOf()
            db.all "SELECT hash, locator FROM tFile", (err, dbFiles) ->
                return success false if err?

                glob "*.+(#{settings.imageFormats.concat(settings.videoFormats).join '|'})", {
                    cwd: settings.localMediaLocation
                },  (err, locNames) ->
                    return success false if err?

                    # dbFiles contains old hashes and locators
                    # locNames contains names of files currently in the folder

                    oldFileHashRels = nameIndexRows dbFiles

                    chgFiles = []
                    async.each locNames, (file, done) ->
                        fs.stat path.join(settings.localMediaLocation, file), (err, stats) ->
                            return done err if err?

                            if Math.max(stats.ctime.getTime(), stats.mtime.getTime()) > lastRun || !oldFileHashRels[file]?
                                chgFiles.push file

                            done()
                    , (err) ->
                        return success false if err?

                        oldFiles = _.difference locNames, chgFiles
                        # chgFiles = files that changed after the last time
                        # oldFiles = files that didn't change since that

                        rels = {}

                        _.each oldFiles, (file) ->
                            hash = oldFileHashRels[file]
                            rels[hash] = file

                        getFileHashes chgFiles, (err, hashes) ->
                            return success false if err?

                            # Add the new files' hash-file relations in, completing the current relation sheet
                            current = _.merge rels, hashes

                            updateDatabase current, hashIndexRows(dbFiles), db, thisRun, (err) ->
                                success !err?
