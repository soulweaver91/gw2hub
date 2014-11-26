_ = require 'lodash'

module.exports = (options) ->
    if not _.isArray options
        options = [options]
    options.push 'OPTIONS'

    (req, res, next) ->
        res.header 'Access-Control-Allow-Methods', options.join ", "
        res.header 'Access-Control-Allow-Headers', 'Content-Type'
        res.header 'Access-Control-Max-Age', 0

        res.status 204
        .end()
