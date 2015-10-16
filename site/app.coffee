angular.module 'gw2hub', [
    'templates-site'
    'ui.router'
    'ui.select'
    'ui.bootstrap'
    'restangular'
    'module.common'
    'module.main'
    'module.gallery'
    'module.media'
    'module.admin'
    'module.characters'
    'module.storage'
    'module.dyes'
    'module.user'
    'service.auth'
]
.config [
    '$stateProvider', '$urlRouterProvider', 'RestangularProvider', 'uiSelectConfig'
    ($stateProvider, $urlRouterProvider, RestangularProvider, uiSelectConfig) ->
        $stateProvider
        .state 'future',
            templateUrl: 'modules/common/future.tpl.html'

        $urlRouterProvider.otherwise '/'

        RestangularProvider.setBaseUrl "#{hubEnv.APIAddress}:#{hubEnv.APIPort}/"

        # Include cookies in the API requests
        RestangularProvider.setDefaultHttpFields {
            withCredentials: true
        }

        uiSelectConfig.theme = 'bootstrap'
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

                if toState.name != 'main'
                    $state.go 'main'
                else
                    # do nothing, we are stuck
]
