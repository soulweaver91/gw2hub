angular.module 'module.common', [
    'service.auth'
    'service.utils'
]
.controller 'navbarController', [
    '$scope', 'authService',
    ($scope, authService) ->
        $scope.user = null
        $scope.credentials = {
            email: ''
            pass: ''
        }

        # Keep the user up to date (esp. when waiting for the server check for existing session to resolve)
        $scope.$watch ->
            return authService.user()
        , (user) ->
            $scope.user = user

        $scope.login = ->
            if $scope.credentials.email == '' || $scope.credentials.pass == ''
                return

            authService.login $scope.credentials.email, $scope.credentials.pass
            .then ->
                $scope.credentials = {
                    email: ''
                    pass: ''
                }

        $scope.logout = ->
            authService.logout()
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
.directive 'tagList', ->
    restrict: 'A'
    replace: true
    templateUrl: 'modules/common/taglist.tpl.html'
    scope:
        tags: '='
    controller: [
        '$scope', 'tagUtilityService'
        ($scope, tagUtilityService) ->
            $scope.$watch 'tags', (newVal, oldVal) ->
                $scope.tagsParsed = tagUtilityService.flattenTree newVal
    ]
.directive 'userNameTag', ->
    restrict: 'A'
    replace: true
    templateUrl: 'modules/common/username.tpl.html'
    scope:
        user: '='
    controller: [
        '$scope', 'authService',
        ($scope, authService) ->
            $scope.ulevels = authService.userLevels()
    ]
.directive 'navtree', ['$compile',
    ($compile) ->
        restrict: 'E'
        replace: false
        scope:
            branch: '='
            settings: '='
            level: '@'
        controller: [
            '$scope', '$state', '$stateParams',
            ($scope, $state, $stateParams) ->
                if !$scope.level?
                    $scope.level = 0
                $scope.level = parseInt $scope.level
                $scope.nextLevel = $scope.level + 1

                if $scope.settings.maxExpand?
                    $scope.childToggle = $scope.settings.maxExpand > $scope.level
                else
                    $scope.childToggle = true

                $scope.select = ->
                    $scope.childToggle = true
                    if $scope.branch.state.name?
                        $state.go $scope.branch.state.name, $scope.branch.state.params

                $scope.getIsActive = ->
                    if _.isFunction $scope.settings.isActive
                        $scope.settings.isActive $scope.branch.state, $stateParams
                    else
                        false
        ]
        link: ($scope, element) ->
            # Has to be defined this way for recursion to not cause an infinite loop
            template = '''
            <div class="navtree_branch" ng-class="{'navtree_active': getIsActive()}">
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
                        <span class="navtree_toggler glyphicon {{settings.leafClasses}}"
                            ng-if="branch.children.length == 0 && !branch.icon"></span>
                        <span class="navtree_toggler glyphicon glyphicon-{{branch.icon}}"
                            ng-if="branch.children.length == 0 && branch.icon"></span>
                        {{branch.name}}
                    </a>
                    <span ng-if="!branch.state">{{branch.name}}</span>
                    <span class="navtree_count" ng-if="branch.count || branch.count === 0">{{branch.count}}</span>
                </div>
                <div class="navtree_children" ng-if="childToggle">
                    <navtree ng-repeat="sub in branch.children" branch="sub" settings="settings" level="{{nextLevel}}"></navtree>
                </div>
            </div>
            '''
            $template = angular.element template
            $compile($template)($scope)
            element.append $template
]
