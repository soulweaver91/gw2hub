_ = require 'lodash'

module.exports = (tags) ->
    tree = []
    lookup = {}

    _.each tags, (tag) ->
        lookup[tag.id] = tag
        tag.children = []

    _.each tags, (tag) ->
        if tag.parent? && lookup[tag.parent]?
            lookup[tag.parent].children.push tag
        else
            tree.push tag

    tree
