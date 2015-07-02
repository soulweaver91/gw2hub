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
        .state 'adminTags',
            url: '/admin/tags'
            templateUrl: 'modules/admin/tagmanagerframe.tpl.html'
            controller: 'adminTagManagerFrameController'
            resolve:
                user: verifyAdmin
        .state 'adminTags.add',
            url: '/new'
            templateUrl: 'modules/admin/tagmanageredit.tpl.html'
            #controller: 'adminTagManagerAddController'
            resolve:
                user: verifyAdmin
        .state 'adminTags.edit',
            url: '/edit/:id'
            templateUrl: 'modules/admin/tagmanageredit.tpl.html'
            controller: 'adminTagManagerEditController'
            resolve:
                user: verifyAdmin
]
.controller 'adminMainPageController', [
    '$scope',
    ($scope) ->
]
.controller 'adminTagManagerFrameController', [
    '$scope', 'Restangular',
    ($scope, Restangular) ->
        $scope.tags = []

        $scope.tagSettings =
            isActive: (branchState, uiState) ->
                branchState? && parseInt(uiState.id) == branchState.params?.id
            leafClasses: 'glyphicon-tag'

        Restangular.all 'tags'
        .getList()
        .then (tags) ->
            $scope.tags =
                name: 'Tags'
                children: tags

            addStates = (node) ->
                node.count = 0
                if node.id?
                    node.state =
                        name: 'adminTags.edit'
                        params:
                            id: node.id

                _.each node.children, addStates

            addStates $scope.tags
]
.controller 'adminTagManagerAddController', [
    '$scope',
    ($scope) ->
]
.controller 'adminTagManagerEditController', [
    '$scope', '$stateParams',
    ($scope, $stateParams) ->
        $scope.id = $stateParams.id
]
