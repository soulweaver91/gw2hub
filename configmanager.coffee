_ = require 'lodash'
fs = require 'fs'
path = require 'path'
git = require 'git-rev-sync'
pjson = require './package.json'

settings = {}

effectiveSettings = null
profile = null

messages = {
    notFoundOrInvalid: '''
                       To run this application, you first need to copy over the
                       settings.template.coffee file at the root of the project to a new file called
                       settings.coffee and replace values with your own. Especially note the
                       APISecret key, it must be defined with a difficult to guess value - it is
                       used for security related bits. Also make sure it is of the same format as
                       the original file, it must return a simple settings object with the defined
                       values.
                       '''
    badAPISecret: '''
                  You haven't defined a unique, difficult to guess API secret key in your
                  settings file. Please do so first as it is used for security related bits in
                  this application.
                  '''
}

vendorScripts = [
    'bower_components/angular/angular.js'
    'bower_components/angular-ui-router/release/angular-ui-router.js'
    'bower_components/angular-ui-select/dist/select.js'
    'bower_components/angular-bootstrap/ui-bootstrap-tpls.js'
    'bower_components/angular-sanitize/angular-sanitize.js'
    'bower_components/restangular/dist/restangular.js'
    'bower_components/lodash/lodash.js'
    'bower_components/moment/moment.js'
    'bower_components/moment/min/moment-with-locales.js'
    'bower_components/moment/locale/*.js'
]

module.exports = {
    init: (grunt) ->
        # Determine the profile to use
        profile = if grunt.option('profile') == 'prod' then 'prod' else 'dev'

        if !fs.existsSync path.join '.', 'settings.coffee'
            grunt.fail.fatal messages.notFoundOrInvalid

        settings = require './settings'

        if !settings? || typeof settings != 'object'
            grunt.fail.fatal messages.notFoundOrInvalid

        # Merge the common settings and the profile specific settings into a combined settings object
        effectiveSettings = _.merge settings.common, settings[profile]
        effectiveSettings.profile = profile
        effectiveSettings.vendorScripts = vendorScripts
        effectiveSettings.appVersion = pjson.version
        try
            gitRev = git.short()
            gitBranch = git.branch()
            _.extend effectiveSettings, {
                gitRev: gitRev
                gitBranch: gitBranch
                fullAppVersion: "GW2 Hub #{pjson.version}-#{gitBranch}\##{gitRev}"
            }
        catch e
            # git not in PATH or project not currently using git
            _.extend effectiveSettings, {
                gitRev: null
                gitBranch: null
                fullAppVersion: "GW2 Hub " + pjson.version
            }

        if effectiveSettings.APISecret == ''
            grunt.fail.fatal messages.badAPISecret

        console.log "#{effectiveSettings.fullAppVersion} initialized with profile #{profile}."

    get: ->
        return effectiveSettings
}

