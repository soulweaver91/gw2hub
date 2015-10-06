angular.module 'module.media', [
    'restangular'
    'ui.router'
    'service.auth'
    'service.overlay'
    'module.common'
]
.config [
    '$stateProvider',
    ($stateProvider) ->
        $stateProvider
        .state 'media',
            url: '/m/:hash'
            templateUrl: 'modules/media/media.tpl.html'
            controller: 'mediaViewController'
            resolve:
                user: [
                    'authService',
                    (authService) ->
                        authService.userAsync()
                ]
]
.controller 'mediaViewController', [
    '$scope', '$state', '$stateParams', 'Restangular', 'user', 'authService',
    ($scope, $state, $stateParams, Restangular, user, authService) ->
        Restangular.one('media', $stateParams.hash).get()
        .then (media) ->
            $scope.media = media
            $scope.type = if media.locator.indexOf('.jpg') > 0 then 'image' else 'movie'
            $scope.mediaDate = moment($scope.media.timestamp).format('lll')
            $scope.src = hubEnv.remoteMediaLocation + $scope.media.locator

            $scope.userCanEdit = user.ulevel >= authService.userLevels().editor
        , (err) ->
            console.log err
]
