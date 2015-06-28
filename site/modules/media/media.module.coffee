angular.module 'module.media', [
    'restangular'
    'ui.router'
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
]
.controller 'mediaViewController', [
    '$scope', '$state', '$stateParams', 'Restangular',
    ($scope, $state, $stateParams, Restangular) ->
        Restangular.one('media', $stateParams.hash).get()
        .then (media) ->
            $scope.media = media
            $scope.type = if media.locator.indexOf('.jpg') > 0 then 'image' else 'movie'
            $scope.mediaDate = moment($scope.media.timestamp).format('lll')
            $scope.src = hubEnv.remoteMediaLocation + $scope.media.locator
        , (err) ->
            console.log err
]
