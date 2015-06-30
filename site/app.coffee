angular.module 'gw2hub', [
    'templates-site'
    'ui.router'
    'restangular'
    'module.common'
    'module.main'
    'module.gallery'
    'module.media'
    'module.admin'
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
        authService.init()

        moment.locale 'en'

        $rootScope.$on '$stateNotFound', (event) ->
            event.preventDefault()
            $state.go 'future'

        $rootScope.$on '$stateChangeError', (event, toState, toParams, fromState, fromParams, error) ->
            if fromState.name == ''
                # Failure upon initializing, probably tried to go to a restricted page.
                # Usually, we'd just prevent the state change and stay where we were, but now we have no state we're
                # coming from, so go to the front page instead
                $state.go 'main'
]
