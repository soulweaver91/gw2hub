angular.module 'module.gallery', [
    'restangular'
    'ui.router'
]
.config [
    '$stateProvider',
    ($stateProvider) ->
        $stateProvider
        .state 'gallery',
            url: '/g'
            templateUrl: 'modules/gallery/galleryframe.tpl.html'
            controller: 'galleryRedirectController'
        .state 'gallery.year',
            url: '/:year'
            templateUrl: 'modules/gallery/gallery.tpl.html'
            controller: 'galleryController'
            data:
                mode: 'y'
        .state 'gallery.month',
            url: '/:year/:month'
            templateUrl: 'modules/gallery/gallery.tpl.html'
            controller: 'galleryController'
            data:
                mode: 'm'
        .state 'gallery.day',
            url: '/:year/:month/:day'
            templateUrl: 'modules/gallery/gallery.tpl.html'
            controller: 'galleryController'
            data:
                mode: 'd'
]
.controller 'galleryRedirectController', [
    '$state', '$scope',
    ($state, $scope) ->
        if $state.current.name is 'gallery'
            $state.go 'gallery.year', { year: moment().year() }

        # Build a temporary navigation tree for 2012-2014. This will be pulled from the API with stats later.
        $scope.navtree = {
            name: 'Navigation'
            count: 9001
            children: []
        }
        $scope.navtree.children.push {
            name: y.toString()
            count: '?'
            state:
                name: 'gallery.year'
                params:
                    year: y
            children: []
        } for y in [2012..2014]
        _.each $scope.navtree.children, (item) ->
            item.children.push {
                name: moment(M: m - 1).format 'MMMM'
                count: '?'
                state:
                    name: 'gallery.month'
                    params:
                        year: item.state.params.year
                        month: m
                children: []
            } for m in [1..12]
]
.controller 'galleryController', [
    '$scope', '$state', '$stateParams', 'Restangular',
    ($scope, $state, $stateParams, Restangular) ->
        $scope.mode = $state.current.data.mode
        $scope.images = []

        $scope.day = parseInt $stateParams.day or 0
        $scope.month = parseInt $stateParams.month or 0
        $scope.year = parseInt $stateParams.year or moment().year()

        $scope.dateMoment = moment {
            d: Math.max $scope.day, 1
            M: Math.max $scope.month - 1, 0
            y: $scope.year
        }

        galleryAPI = Restangular.all('gallery').all $scope.year
        switch $scope.mode
            when 'y'
                $scope.title = "Screenshots: #{$scope.year}"

            when 'm'
                if !moment([$scope.year, $scope.month - 1]).isValid()
                    return $state.go 'gallery.year', { year: $scope.year }

                galleryAPI = galleryAPI.all($scope.month)
                $scope.title = "Screenshots: " + $scope.dateMoment.format "MMMM YYYY"

            when 'd'
                if !moment([$scope.year, $scope.month - 1, $scope.day]).isValid()
                    return $state.go 'gallery.month', { year: $scope.year, month: $scope.month }

                galleryAPI = galleryAPI.all($scope.month).all($scope.day)
                $scope.title = "Screenshots: " + $scope.dateMoment.format "ll"

        galleryAPI.getList()
        .then (images) ->
            $scope.images = images
]
.directive 'hubGalleryItem', ->
    restrict: 'A'
    replace: true
    templateUrl: 'modules/gallery/item.tpl.html'
    scope:
        image: '='
    controller: [
        '$scope', '$window',
        ($scope, $window) ->
            $scope.image.friendlyDate = moment($scope.image.timestamp).format('lll')

            $scope.openImg = ->
                $window.location.href = hubEnv.remoteMediaLocation + $scope.image.locator
    ]
.directive 'navtree', ['$compile',
    ($compile) ->
        restrict: 'E'
        replace: false
        #templateUrl: 'modules/gallery/navtree.tpl.html'
        scope:
            branch: '='
        controller: [
            '$scope', '$state', '$stateParams',
            ($scope, $state, $stateParams) ->
                $scope.childToggle = true

                $scope.activeBranch = ->
                    $scope.branch.state? &&
                    parseInt($stateParams.year) == $scope.branch.state.params.year &&
                    ((!$stateParams.month? && !$scope.branch.state.params.month?) ||
                        parseInt($stateParams.month) == $scope.branch.state.params.month)

                $scope.select = ->
                    $scope.childToggle = true
                    if $scope.branch.state.name?
                        $state.go $scope.branch.state.name, $scope.branch.state.params
        ]
        link: ($scope, element) ->
            # Has to be defined this way for recursion to not cause an infinite loop
            template = '''
            <div class="navtree_branch" ng-class="{'navtree_active': activeBranch()}">
                <div class="navtree_title">
                    <span class="navtree_toggler glyphicon"
                        ng-click="childToggle = !childToggle"
                        ng-class="{
                            'glyphicon-folder-open': childToggle,
                            'glyphicon-folder-close': !childToggle,
                            'hidden': branch.children.length == 0
                        }"
                    ></span>
                    <a href="" ng-if="branch.state" ng-click="select()">
                        <span class="navtree_toggler glyphicon glyphicon-calendar"
                            ng-if="branch.children.length == 0"></span>
                        {{branch.name}}
                    </a>
                    <span ng-if="!branch.state">{{branch.name}}</span>
                    <span class="navtree_count">{{branch.count}}</span>
                </div>
                <div class="navtree_children" ng-show="childToggle">
                    <navtree ng-repeat="sub in branch.children" branch="sub"></navtree>
                </div>
            </div>
            '''
            $template = angular.element template
            $compile($template)($scope)
            element.append $template
    ]
.filter 'filesize', ->
    (input) ->
        if _.isNumber input
            if input < 0
                input
            else
                units = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB']
                i = 0
                while input > 1024
                    i++
                    input /= 1024

                input.toFixed(1) + ' ' + units[Math.min i, units.length - 1]
        else
            input
