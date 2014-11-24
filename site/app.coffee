angular.module 'gw2hub', [
    'templates-site'
    'ui.router'
    'restangular'
    'module.common'
    'module.main'
    'module.gallery'
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
        .state 'future',
            templateUrl: 'modules/common/future.tpl.html'

        $urlRouterProvider.otherwise '/'

        RestangularProvider.setBaseUrl "#{hubEnv.APIAddress}:#{hubEnv.APIPort}/"

        # Include cookies in the API requests
        RestangularProvider.setDefaultHttpFields {
            withCredentials: true
        }
]
.run [
    'authService', '$rootScope', '$state'
    (authService, $rootScope, $state) ->
        authService.update()

        moment.locale 'en'

        $rootScope.$on '$stateNotFound', (event) ->
            event.preventDefault()
            $state.go 'future'
]
