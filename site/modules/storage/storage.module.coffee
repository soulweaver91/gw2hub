angular.module 'module.storage', [
    'restangular'
    'ui.router'
    'module.common'
]
.config [
    '$stateProvider',
    ($stateProvider) ->
        $stateProvider
        .state 'storage',
            url: '/s'
            templateUrl: 'modules/storage/storage.tpl.html'
            controller: 'storageController'
            resolve: {
                bankContent: (Restangular) ->
                    Restangular.one 'account/bank'
                    .get()
                itemData: (Restangular, bankContent) ->
                    ids = []
                    _.each bankContent.bank.data, (item) ->
                        if item?
                            ids.push item.id
                            if item.upgrades?
                                ids.push i for i in item.upgrades

                    _.each bankContent.materials.data, (cat) ->
                        _.each cat, (item) ->
                            ids.push item.id

                    Restangular.all 'items'
                    .one _.uniq(ids).join ','
                    .get()
            }
]
.controller 'storageController', [
    '$scope', 'bankContent', 'itemData'
    ($scope, bankContent, itemData) ->
        $scope.bankContent = bankContent
        $scope.itemDB = itemData

        # There doesn't seem to be an API for these at the moment.
        $scope.materialCategories = {
            "5": "Cooking",
            "6": "Common materials",
            "29": "Fine materials",
            "30": "Gemstones",
            "37": "Rare materials",
            "38": "Festive materials",
            "46": "Ascended materials"
        }
]
