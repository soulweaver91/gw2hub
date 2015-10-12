angular.module 'module.main', [
    'restangular'
]
.config [
    '$stateProvider'
    ($stateProvider) ->
        $stateProvider
        .state 'main',
            url: '/'
            templateUrl: 'modules/main/main.tpl.html'
            controller: 'hubMainController'
            resolve:
                account: (Restangular) ->
                    Restangular.one 'account', 'data'
                    .get()
]
.controller 'hubMainController', [
    '$scope', 'Restangular', 'account'
    ($scope, Restangular, account) ->
        console.log account

        accountPieces = account.name.split '.', 2

        $scope.account = {
            name: accountPieces[0]
            idnum: accountPieces[1]
            createdOn: moment account.created
            ap:
                permanent: 4207
                historical: 0
                daily: 1671
                monthly: 498
            luck:
                level: 98
                progress: 3370
                next: 3880
            bonuses:
                gold: 4
                karma: 4
                mf: 4
                xp: 6
            wvw:
                rank: 26
                progress: 1703
                medal:
                    rank: 2
                    progress: 1089
                    next: 3000
            pvp:
                level: 2
                rank: 1
                progress: 1174
                next: 8500
            world:
                rank: 4
                progress: 100
            orders:
                whispers: yes
                priory: yes
                vigil: yes
            legendary: no
        }
        $scope.tags = []

        Restangular.all 'tags'
        .getList()
        .then (tags) ->
            console.log tags
            $scope.tags = tags

        $scope.rankName = (rank) ->
            ranks = [
                { rank: 1,     name: 'Invader' }
                { rank: 5,     name: 'Assaulter' }
                { rank: 10,    name: 'Raider' }
                { rank: 15,    name: 'Recruit' }
                { rank: 20,    name: 'Scout' }
                { rank: 30,    name: 'Soldier' }
                { rank: 40,    name: 'Squire' }
                { rank: 50,    name: 'Footman' }
                { rank: 60,    name: 'Knight' }
                { rank: 70,    name: 'Major' }
                { rank: 80,    name: 'Colonel' }
                { rank: 90,    name: 'General' }
                { rank: 100,   name: 'Veteran' }
                { rank: 110,   name: 'Champion' }
                { rank: 120,   name: 'Legend' }
                { rank: 150,   name: 'Bronze Invader' }
                { rank: 180,   name: 'Bronze Assaulter' }
                { rank: 210,   name: 'Bronze Raider' }
                { rank: 240,   name: 'Bronze Recruit' }
                { rank: 270,   name: 'Bronze Scout' }
                { rank: 300,   name: 'Bronze Soldier' }
                { rank: 330,   name: 'Bronze Squire' }
                { rank: 360,   name: 'Bronze Footman' }
                { rank: 390,   name: 'Bronze Knight' }
                { rank: 420,   name: 'Bronze Major' }
                { rank: 450,   name: 'Bronze Colonel' }
                { rank: 480,   name: 'Bronze General' }
                { rank: 510,   name: 'Bronze Veteran' }
                { rank: 540,   name: 'Bronze Champion' }
                { rank: 570,   name: 'Bronze Legend' }
                { rank: 620,   name: 'Silver Invader' }
                { rank: 670,   name: 'Silver Assaulter' }
                { rank: 720,   name: 'Silver Raider' }
                { rank: 770,   name: 'Silver Recruit' }
                { rank: 820,   name: 'Silver Scout' }
                { rank: 870,   name: 'Silver Soldier' }
                { rank: 920,   name: 'Silver Squire' }
                { rank: 970,   name: 'Silver Footman' }
                { rank: 1020,  name: 'Silver Knight' }
                { rank: 1070,  name: 'Silver Major' }
                { rank: 1120,  name: 'Silver Colonel' }
                { rank: 1170,  name: 'Silver General' }
                { rank: 1220,  name: 'Silver Veteran' }
                { rank: 1270,  name: 'Silver Champion' }
                { rank: 1320,  name: 'Silver Legend' }
                { rank: 1395,  name: 'Gold Invader' }
                { rank: 1470,  name: 'Gold Assaulter' }
                { rank: 1545,  name: 'Gold Raider' }
                { rank: 1620,  name: 'Gold Recruit' }
                { rank: 1695,  name: 'Gold Scout' }
                { rank: 1770,  name: 'Gold Soldier' }
                { rank: 1845,  name: 'Gold Squire' }
                { rank: 1920,  name: 'Gold Footman' }
                { rank: 1995,  name: 'Gold Knight' }
                { rank: 2070,  name: 'Gold Major' }
                { rank: 2145,  name: 'Gold Colonel' }
                { rank: 2220,  name: 'Gold General' }
                { rank: 2295,  name: 'Gold Veteran' }
                { rank: 2370,  name: 'Gold Champion' }
                { rank: 2445,  name: 'Gold Legend' }
                { rank: 2545,  name: 'Platinum Invader' }
                { rank: 2645,  name: 'Platinum Assaulter' }
                { rank: 2745,  name: 'Platinum Raider' }
                { rank: 2845,  name: 'Platinum Recruit' }
                { rank: 2945,  name: 'Platinum Scout' }
                { rank: 3045,  name: 'Platinum Soldier' }
                { rank: 3145,  name: 'Platinum Squire' }
                { rank: 3245,  name: 'Platinum Footman' }
                { rank: 3345,  name: 'Platinum Knight' }
                { rank: 3445,  name: 'Platinum Major' }
                { rank: 3545,  name: 'Platinum Colonel' }
                { rank: 3645,  name: 'Platinum General' }
                { rank: 3745,  name: 'Platinum Veteran' }
                { rank: 3845,  name: 'Platinum Champion' }
                { rank: 3945,  name: 'Platinum Legend' }
                { rank: 4095,  name: 'Mithril Invader' }
                { rank: 4245,  name: 'Mithril Assaulter' }
                { rank: 4395,  name: 'Mithril Raider' }
                { rank: 4545,  name: 'Mithril Recruit' }
                { rank: 4695,  name: 'Mithril Scout' }
                { rank: 4845,  name: 'Mithril Soldier' }
                { rank: 4995,  name: 'Mithril Squire' }
                { rank: 5145,  name: 'Mithril Footman' }
                { rank: 5295,  name: 'Mithril Knight' }
                { rank: 5445,  name: 'Mithril Major' }
                { rank: 5595,  name: 'Mithril Colonel' }
                { rank: 5745,  name: 'Mithril General' }
                { rank: 5895,  name: 'Mithril Veteran' }
                { rank: 6045,  name: 'Mithril Champion' }
                { rank: 6195,  name: 'Mithril Legend' }
                { rank: 6445,  name: 'Diamond Invader' }
                { rank: 6695,  name: 'Diamond Assaulter' }
                { rank: 6945,  name: 'Diamond Raider' }
                { rank: 7195,  name: 'Diamond Recruit' }
                { rank: 7445,  name: 'Diamond Scout' }
                { rank: 7695,  name: 'Diamond Soldier' }
                { rank: 7945,  name: 'Diamond Squire' }
                { rank: 8195,  name: 'Diamond Footman' }
                { rank: 8445,  name: 'Diamond Knight' }
                { rank: 8695,  name: 'Diamond Major' }
                { rank: 8945,  name: 'Diamond Colonel' }
                { rank: 9195,  name: 'Diamond General' }
                { rank: 9445,  name: 'Diamond Veteran' }
                { rank: 9695,  name: 'Diamond Champion' }
                { rank: 9945,  name: 'Diamond Legend' }
            ]

            if rank < 1
                return 'Unknown'

            for i, j in ranks
                if rank < i.rank
                    return ranks[j-1].name

            return ranks[ranks.length-1].name
]
