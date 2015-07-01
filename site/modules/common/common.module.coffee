angular.module 'module.common', [
    'service.auth'
]
.controller 'navbarController', [
    '$scope', 'authService',
    ($scope, authService) ->
        $scope.user = null
        $scope.credentials = {
            email: ''
            pass: ''
        }

        # Keep the user up to date (esp. when waiting for the server check for existing session to resolve)
        $scope.$watch ->
            return authService.user()
        , (user) ->
            $scope.user = user

        $scope.login = ->
            if $scope.credentials.email == '' || $scope.credentials.pass == ''
                return

            authService.login $scope.credentials.email, $scope.credentials.pass
            .then ->
                $scope.credentials = {
                    email: ''
                    pass: ''
                }

        $scope.logout = ->
            authService.logout()
]
.filter 'filesize', ->
    (input) ->
        if _.isNumber input
            if input < 0
                input
            else
                units = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB']
                i = 0
                while input > 1024
                    i++
                    input /= 1024

                input.toFixed(1) + ' ' + units[Math.min i, units.length - 1]
        else
            input
.directive 'tagList', ->
    restrict: 'A'
    replace: true
    templateUrl: 'modules/common/taglist.html'
    scope:
        tags: '='
    controller: [
        '$scope',
        ($scope) ->
            $scope.$watch 'tags', (newVal, oldVal) ->
                $scope.tagsParsed = []
                walkTree = (path, tag) ->
                    newPath = path.concat [tag.name]
                    if tag.depth == 0
                        $scope.tagsParsed.push newPath

                    _.each tag.children, (subtag) ->
                        walkTree newPath, subtag

                _.each newVal, (tag) ->
                    walkTree [], tag
                console.log $scope.tagsParsed
    ]
.directive 'userNameTag', ->
    restrict: 'A'
    replace: true
    templateUrl: 'modules/common/username.tpl.html'
    scope:
        user: '='
    controller: [
        '$scope', 'authService',
        ($scope, authService) ->
            $scope.ulevels = authService.userLevels()
    ]
