angular.module 'module.gallery', [
    'restangular'
    'ui.router'
    'service.overlay'
    'module.common'
]
.config [
    '$stateProvider',
    ($stateProvider) ->
        $stateProvider
        .state 'gallery',
            url: '/g'
            templateUrl: 'modules/gallery/galleryframe.tpl.html'
            controller: 'galleryRedirectController'
            resolve: {
                stats: [
                    'Restangular', '$q',
                    (Restangular, $q) ->
                        deferred = $q.defer()

                        Restangular.all('gallery').one('stats').get()
                        .then (stats) ->
                            deferred.resolve stats.plain()
                        , (err) ->
                            deferred.reject err

                        deferred.promise
                ]
            }
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
    '$state', '$scope', 'stats',
    ($state, $scope, stats) ->
        if $state.current.name is 'gallery'
            $state.go 'gallery.year', { year: moment().year() }

        $scope.navtree = {
            name: 'Navigation'
            count: stats.count
            children: []
        }
        _.each stats.years, (yearData, year) ->
            months = []
            _.each yearData.months, (monthData, month) ->
                months.push {
                    name: moment(M: parseInt(month)).format 'MMMM'
                    count: monthData.count.toString()
                    state:
                        name: 'gallery.month'
                        params:
                            year: parseInt(year)
                            month: parseInt(month) + 1
                    children: []
                }

            $scope.navtree.children.push {
                name: year
                count: yearData.count.toString()
                state:
                    name: 'gallery.year'
                    params:
                        year: parseInt(year)
                children: months
            }

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
        '$scope', '$window', 'overlayService'
        ($scope, $window, overlayService) ->
            $scope.image.friendlyDate = moment($scope.image.timestamp).format('lll')

            $scope.openImg = ->
                overlayService.display $scope.image
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
