fs = require 'fs'
path = require 'path'
_ = require 'lodash'

module.exports = (grunt) ->
    grunt.registerTask 'delete-powerbuild-cache', 'Deletes the cache file that powerbuild messes up occasionally.', ->
        success = @async()

        file = path.join 'node_modules', 'powerbuild', 'powerbuild-cache'
        if fs.existsSync file
            fs.unlink file, (err) ->
                success !err?
        else
            success true
