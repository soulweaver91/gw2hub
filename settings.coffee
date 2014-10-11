_ = require 'lodash'
APISecret = require './apisecret'

settings = {
    dev:
        deployDir: 'dev'
        APIPort: 12500
        database: 'db/dev.sqlite'
    prod:
        deployDir: 'prod'
        APIPort: 12501
        database: 'db/prod.sqlite'
    common:
        vendorScripts: [
            'bower_components/angular/angular.js'
            'bower_components/angular-ui-router/release/angular-ui-router.js'
            'bower_components/restangular/src/restangular.js'
            'bower_components/lodash/dist/lodash.js'
        ]
        APISecret: APISecret
        APIAddress: 'http://soul-weaver.tk'
        siteAddress: 'http://soul-weaver.tk'
        saltRounds: 12
}

effectiveSettings = null
profile = null

module.exports = {
    init: (grunt) ->
        # Determine the profile to use
        profile = if grunt.option('profile') == 'prod' then 'prod' else 'dev'

        # Merge the common settings and the profile specific settings into a combined settings object
        effectiveSettings = _.merge settings.common, settings[profile]
        effectiveSettings.profile = profile

    get: ->
        return effectiveSettings
}

