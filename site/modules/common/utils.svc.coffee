angular.module 'service.utils', [

]
.factory 'tagUtilityService', [
    ->
        {
            flattenTree: (tree) ->
                flattened = []
                walkTree = (path, tag, lastIcon) ->
                    newPath = path.concat [tag.name]
                    newIcon = if tag.icon? then tag.icon else lastIcon

                    if tag.depth == 0
                        flattened.push
                            path: newPath
                            icon: newIcon
                            id: tag.id

                    _.each tag.children, (subtag) ->
                        walkTree newPath, subtag, newIcon

                _.each tree, (tag) ->
                    walkTree [], tag, null

                return flattened
        }
]
