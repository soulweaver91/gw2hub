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
    'service.utils'
    'ui.select'
    'restangular'
    'ngSanitize'
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
            controller: 'adminTagManagerEditController'
            resolve:
                user: verifyAdmin
                tag: [
                    '$q',
                    ($q) ->
                        deferred = $q.defer()
                        deferred.resolve
                            name: ''
                            id: -1
                            parent: null
                            icon: null

                        deferred.promise
                ]

        .state 'adminTags.edit',
            url: '/edit/:id'
            templateUrl: 'modules/admin/tagmanageredit.tpl.html'
            controller: 'adminTagManagerEditController'
            resolve:
                user: verifyAdmin,
                tag: [
                    'Restangular', '$stateParams',
                    (Restangular, $stateParams) ->
                        Restangular.one 'tags', $stateParams.id
                        .get()
                ]
            params:
                msg: null
        .state 'adminMedia',
            url: '/admin/media'
            template: '<div ui-view></div>'
        .state 'adminMedia.edit',
            url: '/edit/:id'
            templateUrl: 'modules/admin/mediaedit.tpl.html'
            controller: 'adminMediaEditController'
            resolve:
                user: verifyAdmin,
                media: [
                    'Restangular', '$stateParams',
                    (Restangular, $stateParams) ->
                        Restangular.one 'media', $stateParams.id
                        .get()
                ]
            params:
                msg: null
]
.controller 'adminMainPageController', [
    '$scope',
    ($scope) ->
]
.controller 'adminTagManagerFrameController', [
    '$scope', 'Restangular',
    ($scope, Restangular) ->
        $scope.tags =
            name: 'Loading tags...'
            children: []

        $scope.tagSettings =
            isActive: (branchState, uiState) ->
                branchState? && parseInt(uiState.id) == branchState.params?.id
            leafClasses: 'g:tag'
            maxExpand: 1

        Restangular.all 'tags'
        .getList()
        .then (tags) ->
            $scope.tags =
                name: 'Tags'
                children: tags

            addStates = (node) ->
                if node.id?
                    node.state =
                        name: 'adminTags.edit'
                        params:
                            id: node.id

                _.each node.children, addStates

            addStates $scope.tags
]
.controller 'adminTagManagerEditController', [
    '$scope', '$state', '$stateParams', 'tag', 'Restangular',
    ($scope, $state, $stateParams, tag, Restangular) ->
        $scope.tag = tag
        $scope.tagOriginalName = tag.name
        $scope.icons =
            items: [
                { value: null,                      name: 'Default' }
                { value: 'h:player-marker',         name: 'Player' }
                { value: 'h:npc-marker',            name: 'NPC' }
                { value: 'h:enemy-marker',          name: 'Enemy' }
                { value: 'h:dungeon',               name: 'Dungeon' }
                { value: 'h:point-of-interest',     name: 'Point of interest' }
                { value: 'h:vista',                 name: 'Vista' }
                { value: 'h:hero-challenge',        name: 'Hero challenge' }
                { value: 'h:renown-heart',          name: 'Renown heart' }
                { value: 'h:waypoint',              name: 'Waypoint' }
                { value: 'h:compass',               name: 'Map location' }
                { value: 'h:asura-gate',            name: 'Asura gate' }
            ]
            options: {}

        $scope.selectFields =
            parentTag: null

        noParentItem =
            id: null
            name: 'No parent'
            icon: 'g:remove-sign'
        $scope.tagSuggestions = [noParentItem]
        $scope.loadTagSuggestions = (query) ->
            return if query.length == 0
            return $scope.tagSuggestions = [noParentItem] if query.length < 3

            Restangular.all 'tags/suggest'
            .post
                q: query
            .then (res) ->
                $scope.tagSuggestions = [noParentItem].concat res

        if $scope.tag.parent?
            Restangular.all 'tags'
            .get tag.parent
            .then (res) ->
                $scope.selectFields.parentTag = res
        else
            $scope.selectFields.parentTag = noParentItem

        $scope.msg = $stateParams.msg

        $scope.submitTag = ->
            values = _.pick $scope.tag, [
                'name', 'icon', 'priority'
            ]
            values.parent = $scope.selectFields.parentTag?.id

            if tag.id != -1
                tag.patch values
                .then (res) ->
                    $state.go 'adminTags.edit',
                        id: $scope.tag.id
                        msg: 'successEdited'
                    ,
                        reload: true
                , (err) ->
                    $scope.msg = 'failureEdited'
            else
                Restangular.all 'tags'
                .post tag
                .then (res) ->
                    $state.go 'adminTags.edit',
                        id: res.id
                        msg: 'successAdded'
                    ,
                        reload: true
                , (err) ->
                    $scope.msg = 'failureAdded'
]
.controller 'adminMediaEditController', [
    '$scope', '$state', '$stateParams', 'Restangular', 'media', 'tagUtilityService',
    ($scope, $state, $stateParams, Restangular, media, tagUtilityService) ->
        $scope.media = media
        $scope.msg = $stateParams.msg

        $scope.selectFields = {
            selectedTags: []
        }
        if $scope.media.tags?
            _.each tagUtilityService.flattenTree($scope.media.tags), (tagHierarchy) ->
                $scope.selectFields.selectedTags.push
                    name: _.last tagHierarchy.path
                    icon: tagHierarchy.icon
                    id: tagHierarchy.id

        $scope.loadTagSuggestions = (query) ->
            return if query.length == 0
            return $scope.tagSuggestions = [] if query.length < 3

            Restangular.all 'tags/suggest'
            .post
                q: query
            .then (res) ->
                $scope.tagSuggestions = res

        $scope.submitMedia = ->
            values = _.pick $scope.media, [
                'name', 'description'
            ]

            values.tagIDs = _.pluck $scope.selectFields.selectedTags, 'id'

            # Cannot patch via the element directly, as Restangular attempts to use the ID instead of going by
            # the URL the resource was loaded from, and the hash is used as the endpoint identifier for the media
            Restangular.all('media').one($scope.media.hash).patch values
            .then (res) ->
                $state.go 'adminMedia.edit',
                    id: $scope.media.hash
                    msg: 'successEdited'
                ,
                    reload: true
            , (err) ->
                $scope.msg = 'failureEdited'
]
