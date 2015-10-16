angular.module 'module.dyes', [
    'restangular'
]
.config [
    '$stateProvider'
    ($stateProvider) ->
        $stateProvider
        .state 'dyes',
            url: '/d'
            templateUrl: 'modules/dyes/dyes.tpl.html'
            controller: 'dyeListController'
            resolve:
                dyes: (Restangular) ->
                    Restangular.one 'account/unlocks/dyes'
                    .get()
]
.controller 'dyeListController', [
    '$scope', 'dyes'
    ($scope, dyes) ->
        $scope.dyeData = dyes.data
        $scope.catUnlockCounts = {}

        $scope.filters =
            grouping: 2
            display: 0
            search: ''
            groupingTypes: [
                { idx: 0, name: 'Colour' }
                { idx: 1, name: 'Material' }
                { idx: 2, name: 'Rarity' }
            ]
            displayTypes: [
                { idx: 0, name: 'All' }
                { idx: 1, name: 'Locked' }
                { idx: 2, name: 'Unlocked' }
            ]
            filterByUnlockStatus: (val) ->
                switch $scope.filters.display
                    when 0 then true
                    when 1 then !val?.unlocked
                    when 2 then val?.unlocked

        selectDyeGrouping = (grouping) ->
            $scope.dyes = _.groupBy $scope.dyeData, (dye) ->
                dye.categories[grouping]

            _.each $scope.dyes, (cat, name) ->
                $scope.catUnlockCounts[name] = _.compact(_.pluck(cat, 'unlocked')).length

        $scope.$watch 'filters.grouping', (val) ->
            selectDyeGrouping val
]
