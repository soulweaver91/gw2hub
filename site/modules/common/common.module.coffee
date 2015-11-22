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
                        <span class="navtree_toggler {{settings.leafClasses | tagIconToClasses}}"
                            ng-if="branch.children.length == 0 && !branch.icon"></span>
                        <span class="navtree_toggler {{branch.icon | tagIconToClasses}}"
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
.filter 'tagIconToClasses', ->
    (icon) ->
        if !icon? || !_.isString icon || icon.indexOf(':') < 0
            return 'glyphicon glyphicon-tag'

        parts = icon.split ':', 2
        switch parts[0]
            when 'g'
                return "glyphicon glyphicon-#{parts[1]}"
            when 'h'
                return "hubicon hubicon-#{parts[1]}"
.directive 'spanAp', ->
    restrict: 'E'
    scope:
        ap: '='
        pre: '@'
        post: '@'
    template: '<span class="ap">{{pre}}{{ap | number}}{{post}}<span class="hubicon hubicon-arenanet"></span></span>'
.directive 'spanCoin', ->
    restrict: 'E'
    scope:
        coin: '='
        pre: '@'
        post: '@'
        mode: '='
        round: '='
    template: '''
              <span class="coin" ng-class="{'coin-negative': negative}">
                {{pre}}<span ng-if="units.g == 0 && mode == 'gsc' && negative">-</span
                ><span class="coin-gold" ng-if="units.g !== null">{{units.g | number}}<span class="hubicon hubicon-coin"></span></span>
                <span class="coin-silver" ng-if="units.s !== null">{{units.s | number}}<span class="hubicon hubicon-coin"></span></span>
                <span class="coin-copper" ng-if="units.c !== null">{{units.c | number}}<span class="hubicon hubicon-coin"></span></span>{{post}}
              </span>
              '''
    controller: ($scope) ->
        if !$scope.mode?
            $scope.mode = 'gsc'
        $scope.units = { g: null, s: null, c: null }
        $scope.negative = false

        updateUnits = (coin) ->
            coin = parseFloat coin

            # Store negativity and make positive, it'll be added back later
            $scope.negative = false
            if coin < 0
                $scope.negative = true
                coin *= -1

            switch $scope.mode
                when 'g'
                    $scope.units = { g: coin / 10000, s: null, c: null }
                when 's'
                    $scope.units = { g: null, s: coin / 100, c: null }
                when 'c'
                    $scope.units = { g: null, s: null, c: coin }
                when 'gsc', 'gscbrief'
                    $scope.units = {
                        g: Math.floor(coin / 10000),
                        s: Math.floor(coin / 100) % 100,
                        c: coin % 100
                    }

            if $scope.mode == 'gscbrief'
                $scope.units = _.each $scope.units, (v, k) -> $scope.units[k] = if v > 0 then v else null
                if _.all($scope.units, (unit) -> unit == null)
                    $scope.units.c = 0

            if $scope.round
                $scope.units = _.each $scope.units, (v, k) -> $scope.units[k] = if v != null then Math.floor v else null

            # Make the highest displayed unit negative.
            if $scope.negative
                _.each $scope.units, (v, k) ->
                    if v != null
                        $scope.units[k] *= -1

                        # Return from _.each
                        false

            $scope.units = _.each $scope.units, (v, k) -> $scope.units[k] = if _.isNaN(v) then 0 else v

        updateUnits $scope.coin
        $scope.$watch 'coin', updateUnits
.filter 'momentTime', ->
    (timestamp, format) ->
        if !format?
            format = 'lll'

        moment(timestamp).format format
.filter 'momentHumanize', ->
    (ms) ->
        m = moment.duration ms

        m.humanize()

.directive 'itemIcon', ->
    restrict: 'E'
    scope:
        item: '='
        qty: '='
        upgrades: '='
        itemDatabase: '='
    templateUrl: 'modules/common/itemicon.tpl.html'
    controller: [
        '$scope', '$document'
        ($scope, $document) ->
            # Transparent pixel
            $scope.defaultIcon = 'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'
            $scope.displayTooltip = false
            $scope.tooltipOnLeft = false

            $scope.prepareTooltipDisplay = ($event) ->
                elemX = $event.target.getBoundingClientRect().left
                elemWidth = $event.target.clientWidth
                width = $document[0].body.clientWidth

                $scope.tooltipOnLeft = (elemX + (elemWidth / 2)) > (width / 2)
                $scope.displayTooltip = $scope.item?
    ]
.directive 'itemAttrData', ->
    restrict: 'E'
    scope:
        upgrade: '='
        minPower: '='
        maxPower: '='
        defense: '='
        assumeStatsSelectable: '='
    require: '^itemIcon'
    templateUrl: 'modules/common/itemattrdata.tpl.html'

.directive 'itemUpgradeData', ->
    restrict: 'E'
    scope:
        item: '='
    require: '^itemIcon'
    templateUrl: 'modules/common/itemupgradedata.tpl.html'
.filter 'attributeName', ->
    (name) ->
        switch (name)
            when 'CritDamage' then 'Ferocity'
            when 'ConditionDamage' then 'Condition Damage'
            when 'ConditionDuration' then 'Expertise'
            when 'BoonDuration' then 'Concentration'
            else name
.filter 'weaponTypeName', ->
    (name) ->
        switch (name)
            when 'ShortBow' then 'Shortbow'
            else name
.directive 'userLevelAsText', ->
    restrict: 'A'
    replace: true
    template: '<span>{{level}}</span>'
    scope:
        user: '='
    controller: [
        '$scope', 'authService',
        ($scope, authService) ->
            ulevels = authService.userLevels()
            lvName = _.findKey ulevels, (lv) -> lv == $scope.user.ulevel


            $scope.level = switch lvName
                when 'admin' then 'Administrator'
                when 'editor' then 'Editor'
                when 'privileged' then 'VIP'
                when 'trusted' then 'Trusted'
                when 'user' then 'User'
                when 'disabled' then 'Limited'
                else 'Unknown user level'

    ]
