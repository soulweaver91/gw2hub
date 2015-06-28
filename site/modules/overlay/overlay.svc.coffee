angular.module 'service.overlay', [
    'restangular',
    'ui.bootstrap'
    'module.common'
]
.factory 'overlayService', [
    'Restangular', '$modal'
    (Restangular, $modal) ->
        display: (media) ->
            $modal.open
                templateUrl: 'modules/overlay/overlay.tpl.html'
                windowClass: 'media-overlay'
                controller: [
                    '$scope', '$state',
                    ($scope, $state) ->
                        $scope.media = media
                        $scope.type = if media.locator.indexOf('.jpg') > 0 then 'image' else 'movie'
                        $scope.src = hubEnv.remoteMediaLocation + $scope.media.locator

                        $scope.openMain = ->
                            $state.go 'media', { hash: $scope.media.hash }
                            $scope.$close()
                ]
]
