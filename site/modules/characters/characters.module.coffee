angular.module 'module.characters', [
    'restangular'
]
.config [
    '$stateProvider'
    ($stateProvider) ->
        $stateProvider
        .state 'characterList',
            url: '/c'
            templateUrl: 'modules/characters/characterlist.tpl.html'
            controller: 'characterListController'
            resolve:
                characters: (Restangular) ->
                    Restangular.one 'characters'
                    .get()
]
.controller 'characterListController', [
    '$scope', '$filter', 'characters'
    ($scope, $filter, characters) ->
        $scope.characters = characters.data

        # Fill in some data if it's missing to fix ordering.
        _.each $scope.characters, (char, idx) ->
            _.each ['level', 'age'], (prop) ->
                if !char[prop]?
                    $scope.characters[idx][prop] = 0

        $scope.races = ["Human", "Norn", "Charr", "Sylvari", "Asura"]
        $scope.professions = ["Warrior", "Guardian", "Revenant", "Engineer", "Ranger", "Thief", "Mesmer", "Elementalist", "Necromancer"]
        $scope.genders = ["Male", "Female"]

        $scope.filters =
            races: {}
            professions: {}
            genders: {}
            sort: '-age'
            sortOptions: [
                { key: '+name', label: 'Name' }
                { key: '-level', label: 'Level, highest first' }
                { key: '+level', label: 'Level, lowest first' }
                { key: '+race', label: 'Race' }
                { key: '+profession', label: 'Profession' }
                { key: '+created', label: 'Birthday, oldest first' }
                { key: '-created', label: 'Birthday, newest first' }
                { key: '-age', label: 'Play time, longest first' }
                { key: '+age', label: 'Play time, shortest first' }
            ]
            search: ''

        $scope.filterChars = (char) ->
            nameMatch = $scope.filters.search.length == 0 ||
                _.deburr(char.name).toLowerCase().indexOf(_.deburr($scope.filters.search).toLowerCase()) >= 0
            toggleMatch = $scope.filters.races[char.race] &&
                          $scope.filters.professions[char.profession] &&
                          $scope.filters.genders[char.gender]

            nameMatch && toggleMatch

        $scope.filters.races[n] = true for n in $scope.races
        $scope.filters.professions[n] = true for n in $scope.professions
        $scope.filters.genders[n] = true for n in $scope.genders

]
.filter 'charAge', ->
    (secs) ->
        m = moment.duration(secs * 1000)

        "#{Math.floor(m.asDays())}d #{m.hours()}h #{m.minutes()}m"
