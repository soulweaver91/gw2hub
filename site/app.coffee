angular.module 'gw2hub', [
    'templates-site'
    'ui.router'
    'restangular'
    'hubMain'
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
]
