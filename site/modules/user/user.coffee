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
]
.controller 'userProfileController', [
    '$scope', '$state', 'user'
    ($scope, $state, user) ->
        $scope.user = user

        if !user?.name?
            $state.go 'main'
]
