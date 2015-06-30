verifyAdmin = [
    'authService', '$q',
    (authService, $q) ->
        deferred = $q.defer()

        authService.userAsync()
        .then (user) ->
            if !user? || user.ulevel < authService.userLevels().admin
                deferred.reject()
            else
                deferred.resolve user
        , (err) ->
            deferred.reject err

        deferred.promise
]

angular.module 'module.admin', [
    'service.auth'
]
.config [
    '$stateProvider',
    ($stateProvider) ->
        $stateProvider
        .state 'adminMain',
            url: '/admin'
            templateUrl: 'modules/admin/mainpage.tpl.html'
            controller: 'adminMainPageController'
            resolve:
                user: verifyAdmin
]
.controller 'adminMainPageController', [
    '$scope',
    ($scope) ->
]
