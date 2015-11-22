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
        .state 'character',
            url: '/c/:id'
            templateUrl: 'modules/characters/characterpage.tpl.html'
            controller: 'characterPageController'
            resolve:
                character: (Restangular, $stateParams) ->
                    Restangular.one 'characters', $stateParams.id
                    .one 'full'
                    .get()
                itemData: (Restangular, character) ->
                    ids = []
                    addItemAndUpgrades = (item) ->
                        if item?
                            ids.push item.id
                            if item.upgrades?
                                ids.push i for i in item.upgrades

                    _.each character.bags, (bag) ->
                        return if !bag?
                        ids.push bag.id
                        _.each bag.inventory, addItemAndUpgrades

                    _.each character.equipment, (section, key) ->
                        if ['accessories', 'rings', 'gathering'].indexOf(key) >= 0
                            _.each section, addItemAndUpgrades
                        else if ['weapons'].indexOf(key) >= 0
                            _.each section, (weaponType) ->
                                _.each weaponType, addItemAndUpgrades
                        else
                            addItemAndUpgrades section

                    if ids.length > 0
                        Restangular.all 'items'
                        .one _.uniq(ids).join ','
                        .get()
                    else
                        []
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
.controller 'characterPageController', [
    '$scope', 'character', 'itemData'
    ($scope, character, itemData) ->
        $scope.character = character
        $scope.itemDB = itemData
        $scope.mode =
            underwater: false
            traitPage: 'pve'
            activeBag: null

        $scope.modeNames =
            pve: 'PvE'
            pvp: 'SPvP'
            wvw: 'WvW'

        $scope.specUnlockLevels = [21, 45, 71]

        # Flatten the inventory to enable more compact wrapping for all bags mode.
        inventory = []
        _.each $scope.character.bags, (bag, idx) ->
            if bag?
                _.each bag.inventory, (item) ->
                    inventory.push {
                        bag: idx
                        item: item
                    }
        $scope.character.inventory = inventory

        $scope.stats =
            power: 0
            precision: 0
            toughness: 0
            vitality: 0
            boonDuration: 0 # Concentration
            conditionDuration: 0 # Expertise
            conditionDamage: 0
            critDamage: 0 # Ferocity
            healingPower: 0
            derived:
                armor: 0
                health: 0
                critChance: 0
                boonDuration: 0 # Percentage
                conditionDuration: 0 # Percentage
                critDamage: 0 # Percentage
            incomplete: false

        basePrimary = [   0,
                         37,   44,   51,   58,   65,   72,   79,   86,   93,  100,
                        100,  110,  110,  120,  120,  130,  130,  140,  140,  150,
                        150,  164,  164,  178,  178,  193,  193,  209,  209,  225,
                        225,  245,  245,  265,  265,  285,  285,  305,  305,  325,
                        325,  349,  349,  373,  373,  398,  398,  424,  424,  450,
                        450,  480,  480,  510,  510,  540,  540,  570,  570,  600,
                        600,  634,  634,  668,  668,  703,  703,  739,  739,  775,
                        775,  819,  819,  863,  863,  908,  908,  954,  954, 1000]

        critChanceFactor = 1 +         Math.min(20, $scope.character.level     )  * 0.1 +
                           Math.max(0, Math.min(20, $scope.character.level - 20)) * 0.2 +
                           Math.max(0, Math.min(20, $scope.character.level - 40)) * 0.3 +
                           Math.max(0, Math.min(20, $scope.character.level - 60)) * 0.4

        baseHealthIncrements = switch $scope.character.profession
            when 'Warrior', 'Necromancer' then [28, 70, 140, 210, 280]
            when 'Revenant', 'Ranger', 'Mesmer', 'Engineer' then [18, 45, 90, 135, 180]
            when 'Guardian', 'Thief', 'Elementalist' then [5, 12.5, 25, 37.5, 50]

        baseHealth =             Math.min(19, $scope.character.level     )  * baseHealthIncrements[0] +
                     Math.max(0, Math.min(20, $scope.character.level - 19)) * baseHealthIncrements[1] +
                     Math.max(0, Math.min(20, $scope.character.level - 39)) * baseHealthIncrements[2] +
                     Math.max(0, Math.min(20, $scope.character.level - 59)) * baseHealthIncrements[3] +
                     Math.max(0, Math.min( 1, $scope.character.level - 79)) * baseHealthIncrements[4]

        recalculateStats = ->
            if !$scope.character.level?
                return

            e = $scope.character.equipment
            lv = $scope.character.level

            $scope.stats.incomplete = false

            # Get all of the current equipment and their stats.
            effectiveEquipment = []
            effectiveEquipment.push e.shoulders, e.coat, e.leggings, e.gloves, e.boots, e.amulet, e.rings[0],
                e.rings[1], e.accessories[0], e.accessories[1], e.backpack
            if $scope.mode.underwater
                effectiveEquipment.push e.breather, e.weapons.aquatic[0]
            else
                effectiveEquipment.push e.helm, e.weapons.main[0], e.weapons.main[1]
            effectiveEquipment = _.compact effectiveEquipment

            ids = []
            _.each effectiveEquipment, (item) ->
                ids.push item.id
                if item.upgrades?
                    ids = ids.concat item.upgrades

            addedStats = {
                defense: 0
            }
            activeRuneSets = {}
            _.each ids, (id) ->
                item = $scope.itemDB[id]
                if item?.detailsObject?.defense?
                    addedStats.defense += item.detailsObject.defense

                if item?.detailsObject?.infix_upgrade?
                    _.each item.detailsObject.infix_upgrade, (upgrade, type) ->
                        if type != 'buff'
                            _.each upgrade, (attribute) ->
                                name = attribute?.attribute
                                if name?
                                    name = name[0].toLowerCase() + name[1..]

                                    if !addedStats[name]?
                                        addedStats[name] = 0

                                    addedStats[name] += attribute.modifier
                else
                    $scope.stats.incomplete = true

                if item?.detailsObject?.bonuses?
                    if activeRuneSets[id]?
                        activeRuneSets[id].count++
                    else
                        activeRuneSets[id] = {
                            count: 1
                            bonuses: item.detailsObject.bonuses
                        }

            # Meh, error-prone parsing, but no other way to get this data easily now
            _.each activeRuneSets, (set) ->
                for i in [0..Math.min(set.count, set.bonuses.length)]
                    m = /^\+(\d+) ([a-zA-Z]+( [a-zA-Z]+)?)$/.exec set.bonuses[i]
                    if m?
                        name = _.camelCase m[2]
                        name = switch name
                            when 'Expertise' then 'conditionDuration'
                            when 'Concentration' then 'boonDuration'
                            when 'Ferocity' then 'critDamage'
                            when 'Condition Damage' then 'conditionDamage'
                            else name

                        # Non-stat buffs might end up in the stats array if they match the regex.
                        # We don't care, they won't be used either way.
                        if !addedStats[name]?
                            addedStats[name] = 0

                        addedStats[name] += parseInt m[1]

            $scope.stats.power = basePrimary[lv] + (addedStats.power || 0)
            $scope.stats.precision = basePrimary[lv] + (addedStats.precision || 0)
            $scope.stats.toughness = basePrimary[lv] + (addedStats.toughness || 0)
            $scope.stats.vitality = basePrimary[lv] + (addedStats.vitality || 0)
            $scope.stats.boonDuration = addedStats.boonDuration || 0
            $scope.stats.conditionDuration = addedStats.conditionDuration || 0
            $scope.stats.conditionDamage = addedStats.conditionDamage || 0
            $scope.stats.critDamage = addedStats.critDamage || 0
            $scope.stats.healingPower = addedStats.healingPower || 0

            $scope.stats.derived.critChance = ($scope.stats.precision - basePrimary[lv]) / critChanceFactor + 4
            $scope.stats.derived.armor = $scope.stats.toughness + addedStats.defense
            $scope.stats.derived.health = $scope.stats.vitality * 10 + baseHealth
            $scope.stats.derived.boonDuration = $scope.stats.boonDuration / 15
            $scope.stats.derived.conditionDuration = $scope.stats.conditionDuration / 15
            $scope.stats.derived.critDamage = 150 + $scope.stats.critDamage / 15

        recalculateStats()
        $scope.$watch 'mode', recalculateStats, true
]
.filter 'charAge', ->
    (secs) ->
        m = moment.duration(secs * 1000)

        "#{Math.floor(m.asDays())}d #{m.hours()}h #{m.minutes()}m"
