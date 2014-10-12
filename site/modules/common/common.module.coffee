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
