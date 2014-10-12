angular.module 'gw2hub', [
    'templates-site'
    'ui.router'
    'restangular'
    'module.common'
    'module.main'
    'service.auth'
]
.config [
    '$stateProvider', '$urlRouterProvider', 'RestangularProvider'
    ($stateProvider, $urlRouterProvider, RestangularProvider) ->
        $stateProvider
        .state 'main',
            url: '/'
            templateUrl: 'modules/main/main.tpl.html'
            controller: 'hubMainController'

        $urlRouterProvider.otherwise '/'

        RestangularProvider.setBaseUrl "#{hubEnv.APIAddress}:#{hubEnv.APIPort}/"

        # Include cookies in the API requests
        RestangularProvider.setDefaultHttpFields {
            withCredentials: true
        }
]
.run [
    'authService',
    (authService) ->
        authService.update()
]
