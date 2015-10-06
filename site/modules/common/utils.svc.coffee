angular.module 'service.utils', [

]
.factory 'tagUtilityService', [
    ->
        {
            flattenTree: (tree) ->
                flattened = []
                walkTree = (path, tag) ->
                    newPath = path.concat [tag.name]
                    if tag.depth == 0
                        flattened.push
                            path: newPath
                            icon: tag.icon
                            id: tag.id

                    _.each tag.children, (subtag) ->
                        walkTree newPath, subtag

                _.each tree, (tag) ->
                    walkTree [], tag

                return flattened
        }
]
