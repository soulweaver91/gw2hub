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
                media: [
                    'Restangular', '$stateParams'
                    (Restangular, $stateParams) ->
                        Restangular.one 'media', $stateParams.hash
                        .get()
                ]
                character: [
                    'Restangular', 'media',
                    (Restangular, media) ->
                        if media.character?
                            Restangular.one 'characters', media.character
                            .one 'brief'
                            .get()
                        else
                            null
                ]
]
.controller 'mediaViewController', [
    '$scope', '$state', '$stateParams', 'user', 'media', 'character', 'authService', 'fileKindChecker',
    ($scope, $state, $stateParams, user, media, character, authService, fileKindChecker) ->
        $scope.media = media
        $scope.character = character

        $scope.type = fileKindChecker media.locator
        $scope.mediaDate = moment($scope.media.timestamp).format('lll')
        $scope.src = hubEnv.remoteMediaLocation + $scope.media.locator

        $scope.userCanEdit = user?.ulevel >= authService.userLevels().editor
]
