verifyLoggedIn = [
    'authService', '$q',
    (authService, $q) ->
        deferred = $q.defer()

        authService.userAsync()
        .then (user) ->
            if !user?
                deferred.reject()
            else
                deferred.resolve user
        , (err) ->
            deferred.reject err

        deferred.promise
]

angular.module 'module.user', [
    'restangular'
    'ui.router'
    'module.common'
]
.config [
    '$stateProvider',
    ($stateProvider) ->
        $stateProvider
        .state 'profile',
            url: '/u/:id'
            templateUrl: 'modules/user/profile.tpl.html'
            controller: 'userProfileController'
            resolve: {
                user: (Restangular, $stateParams) ->
                    Restangular.all 'users'
                    .one $stateParams.id
                    .get()
            }
        .state 'controlPanel',
            url: '/cp'
            templateUrl: 'modules/user/controlpanel.tpl.html'
            controller: 'controlPanelController'
            resolve:
                user: verifyLoggedIn
        .state 'controlPanel.details',
            url: '/details'
            templateUrl: 'modules/user/cp-details.tpl.html'
            controller: 'controlPanelDetailsController'
            resolve:
                user: verifyLoggedIn
        .state 'controlPanel.password',
            url: '/password'
            templateUrl: 'modules/user/cp-password.tpl.html'
            controller: 'controlPanelPasswordController'
            resolve:
                user: verifyLoggedIn
]
.controller 'userProfileController', [
    '$scope', '$state', 'user'
    ($scope, $state, user) ->
        $scope.user = user

        if !user?.name?
            $state.go 'main'
]
.controller 'controlPanelController', [
    '$state', '$scope', 'authService'
    ($state, $scope, authService) ->
        $scope.user = authService.user

        # Prevent using the related state directly.
        if $state.current.name == 'controlPanel'
            $state.go 'controlPanel.details'

        $scope.$on '$stateChangeStart', (event, toState, toParams) ->
            if toState.name == 'controlPanel'
                event.preventDefault()
]
.controller 'controlPanelDetailsController', [
    '$scope'
    ($scope) ->

]
.controller 'controlPanelPasswordController', [
    '$scope', 'Restangular'
    ($scope, Restangular) ->
        emptyFields =
            current: ''
            new: ''
            newConfirm: ''
        $scope.password = angular.copy emptyFields

        $scope.minPassLength = hubEnv.minimumPasswordLength

        $scope.submitPassword = ->
            $scope.message = null

            Restangular.all 'auth/password'
            .post $scope.password
            .then (status) ->
                $scope.message =
                    type: 'success'
                    text: 'Password changed successfully!'
                $scope.password = angular.copy emptyFields
            , (err) ->
                $scope.message =
                    type: 'danger'
                    text: 'Could not change password! Server responded with: ' + err.data.error
]
