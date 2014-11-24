async = require 'async'
fs = require 'fs'
_ = require 'lodash'

settings = require('../settings').get()

module.exports = (grunt) ->
    grunt.registerTask 'createEnv', 'Creates the appropriate environment script.', ->
        success = @async()

        fs.writeFile 'intermediate/env.js', "hubEnv = #{
            JSON.stringify _.pick settings,
                ['APIPort', 'APIAddress', 'profile', 'remoteMediaLocation']
            };"
        , (err) ->
            success !err?
