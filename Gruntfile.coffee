# Use coffeescript everywhere
require 'coffee-script/register'
coffee = require 'coffee-script'

settingsProvider = require('./settings')

module.exports = (grunt) ->
    settingsProvider.init grunt
    settings = settingsProvider.get()

    grunt.loadNpmTasks 'grunt-contrib-uglify'
    grunt.loadNpmTasks 'grunt-contrib-clean'
    grunt.loadNpmTasks 'grunt-contrib-copy'
    grunt.loadNpmTasks 'grunt-contrib-less'
    grunt.loadNpmTasks 'grunt-chokidar'
    grunt.loadNpmTasks 'grunt-html2js'
    grunt.loadNpmTasks 'grunt-express'
    grunt.loadNpmTasks 'grunt-newer'
    grunt.loadNpmTasks 'grunt-webfont'
    grunt.loadNpmTasks 'powerbuild'

    grunt.initConfig {
        less:
            options:
                sourceMap: true
                outputSourceFiles: true
                cleancss: settings.profile != 'dev'
            site:
                files:
                    'intermediate/main.css': 'site/styles/main.less'

        powerbuild:
            options:
                sourceMap: true
                node: false
                handlers:
                    '.coffee': (src, canonicalName) ->
                        { js, v3SourceMap } = coffee.compile src, {
                            sourceMap: true
                            sourceFiles: [canonicalName]
                            bare: true
                        }

                        return {
                            code: js
                            # using a source map sometimes begins to crash powerbuild so disable this for now
                            #map: v3SourceMap
                        }
                minify: settings.profile != 'dev'
            site:
                files: [
                    'intermediate/gw2hub.js': [
                        'site/app.coffee'
                        'site/modules/**/*.coffee'
                    ]
                ]

        uglify:
            options:
                compress: settings.profile != 'dev'
                mangle: false
                beautify: settings.profile == 'dev'
                sourceMap: true
                sourceMapIncludeSources: true
            site:
                files:
                    'intermediate/vendor.js': settings.vendorScripts

        copy:
            options:
                noProcess: '*'
            static:
                files: [
                    expand: true
                    cwd: 'site'
                    src: ['index.html', 'static/*']
                    dest: 'intermediate'
                ]
            vendorFonts:
                files: [
                    expand: true
                    src: ['bower_components/bootstrap/fonts/*']
                    dest: 'intermediate/static'
                    flatten: true
                ]
            site:
                files: [
                    expand: true
                    cwd: 'intermediate'
                    src: ['*', '**/*', '!.gitignore', '!*.less']
                    dest: 'release/' + settings.deployDir
                ]

        clean:
            intermediate: ['intermediate/*', '!intermediate/.gitignore']
            site: ['release/' + settings.deployDir + '/*', '!**/cache']

        chokidar:
            uiStyles:
                files: ['site/**/*.less']
                tasks: ['less:site', 'newer:copy:site']
            uiStatic:
                files: ['site/index.html', 'site/static/*']
                tasks: ['newer:copy:static', 'newer:copy:site']
            uiScripts:
                files: ['site/**/*.html','site/**/*.coffee', 'site/icons/*.svg']
                tasks: ['build']
            media:
                files: ["#{settings.localMediaLocation}/*.+(jpg|mp4)"]
                tasks: ['syncFileDB']

        html2js:
            options:
                base: 'site'
            site:
                src: ['site/**/*.html']
                dest: 'intermediate/templates.js'

        express:
            api:
                options:
                    server: 'api/main.coffee'
                    port: settings.APIPort

        webfont:
            icons:
                src: 'site/icons/*.svg'
                dest: 'intermediate/static'
                destCss: 'intermediate'
                options:
                    font: 'gw2hubicons'
                    templateOptions:
                        baseClass: 'hubicon'
                        classPrefix: 'hubicon-'
                    stylesheet: 'less'
                    relativeFontPath: 'static'
                    htmlDemo: settings.profile == 'dev'
                    engine: 'node'
                    fontHeight: 512
                    descent: -128
    }

    grunt.loadTasks 'grunt'

    # The point of using an intermediate folder is that if the build fails, the live folder won't end up in a broken state
    grunt.registerTask 'build', ['clean:intermediate', 'powerbuild:site', 'uglify:site', 'html2js:site', 'createEnv',
                                 'webfont', 'less', 'copy:static', 'copy:vendorFonts', 'clean:site', 'copy:site']
    grunt.registerTask 'runAPI', ['build', 'syncFileDB', 'express:api', 'express-keepalive']
    grunt.registerTask 'develop', ['build', 'syncFileDB', 'express:api', 'chokidar']

