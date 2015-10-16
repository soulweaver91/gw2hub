fs = require 'fs'
async = require 'async'
sqlite = require 'sqlite3'
q = require 'q'

settings = require('../configmanager').get()
security = require '../api/tools/security'
privilegeLevels = require '../api/tools/privilegelevels'

module.exports = (grunt) ->
    grunt.registerTask 'deleteDB', 'Deletes the database file used by the current profile', ->
        success = @async()
        fs.unlink settings.database, (err) ->
            success !err?

    grunt.registerTask 'initDB', 'Initializes the tables used by the software.', ->
        success = @async()

        console.log 'Creating tables...'

        db = new sqlite.Database settings.database

        tablesCreated = q.ninvoke db, 'exec', '''
            CREATE TABLE tUser (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email TEXT UNIQUE,
                name TEXT UNIQUE,
                ulevel INTEGER,
                pass TEXT
            );

            CREATE TABLE tTag (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                parent INTEGER,
                icon TEXT,
                priority INTEGER,
                FOREIGN KEY (parent) REFERENCES tTag (id) ON DELETE SET NULL
            );

            CREATE TABLE tFile (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                hash TEXT NOT NULL,
                locator TEXT,
                name TEXT,
                description TEXT,
                size INTEGER,
                timestamp INTEGER
            );

            CREATE TABLE tFileTagRel (
                file INTEGER NOT NULL,
                tag INTEGER NOT NULL,
                FOREIGN KEY (file) REFERENCES tFile (id) ON DELETE CASCADE,
                FOREIGN KEY (tag) REFERENCES tTag (id) ON DELETE CASCADE,
                PRIMARY KEY (file, tag)
            );

            CREATE TABLE tStateVars (
                key STRING NOT NULL,
                value STRING NOT NULL
            );

            CREATE TABLE tCharacterCache (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE,
                race STRING NOT NULL,
                profession STRING NOT NULL,
                gender STRING NOT NULL,
                created STRING NOT NULL,
                deleted INTEGER NOT NULL
            );

            CREATE TABLE tItemCache (
                id INTEGER PRIMARY KEY,
                build INTEGER NOT NULL,
                fromapi INTEGER NOT NULL,
                name TEXT NOT NULL,
                icon TEXT,
                description TEXT,
                type TEXT NOT NULL,
                rarity TEXT NOT NULL,
                level INTEGER,
                vendorValue INTEGER,
                flags TEXT,
                restrictedTo TEXT,
                chatLink TEXT,
                detailsObject BLOB
            );

            CREATE TABLE tDyeCache (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                red INTEGER NOT NULL,
                green INTEGER NOT NULL,
                blue INTEGER NOT NULL,
                unlockItem INTEGER,
                categories TEXT
            );
        '''

        tablesCreated.then ->
            console.log 'Adding initial data points...'

            stateVarsCreated = q.ninvoke db, 'exec', '''
                INSERT INTO tStateVars (key, value) VALUES ("lastScanTime", "0");
                '''
            .then ->
                console.log 'State variables initialized.'

            tagsCreated = q.ninvoke db, 'exec', '''
                INSERT INTO tTag (name, parent) VALUES ("Map", null);
                INSERT INTO tTag (name, parent) VALUES
                    ("Plains of Ashford", 1),
                    ("Wayfarer Foothills", 1),
                    ("Lion's Arch", 1),
                    ("Blue Borderlands", 1);
                '''
            .then ->
                console.log 'Five tags created.'

            userCreated = q.defer()
            passHashCreated = q.nfcall security.hash, "default"
            .then (hashed) ->
                q.ninvoke db, 'run', '''
                INSERT INTO tUser (email, name, ulevel, pass) VALUES (
                    "user@db",
                    "Default User",
                    ?,
                    ?
                );
                ''', privilegeLevels.admin, hashed
                .then (err) ->
                    if err?
                        userCreated.reject()
                    else
                        console.log 'User created.'
                        userCreated.resolve()

            q.all [tagsCreated, userCreated, passHashCreated, stateVarsCreated]
            .then ->
                success true
            , ->
                success false
        , ->
            console.log 'Could not create tables.'
            success false


    grunt.registerTask 'resetDB', ['deleteDB', 'initDB']
