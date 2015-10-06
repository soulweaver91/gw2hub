_ = require 'lodash'

module.exports = (tags) ->
    tree = []
    lookup = {}

    _.each tags, (tag) ->
        lookup[tag.id] = tag
        tag.children = []

    if tags[0]?.selfCount?
        addParentCount = (tag, countToAdd) ->
            if !tag.parent?
                return

            lookup[tag.parent].count += countToAdd
            addParentCount lookup[tag.parent], countToAdd

        _.each tags, (tag) ->
            tag.count = tag.selfCount

        _.each tags, (tag) ->
            addParentCount tag, tag.selfCount

    _.each tags, (tag) ->
        if tag.parent? && lookup[tag.parent]?
            lookup[tag.parent].children.push tag
        else
            tree.push tag

    tree
